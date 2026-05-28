# Migración Decidim 0.30.4 → 0.31.5 — Authorization Handler Galdakao

> **Rama:** `feature/zone-verifications-0.31-rebased`
> **Entorno destino:** Ruby 3.3.10 · Node 22.14.0 · Rails 7.2 · Shakapacker 8.3.0
> **Estado:** Pasos 1-9 completados. Pendiente migraciones, smoke test y UI fixes.

---

## Contexto

Se ha desarrollado un `CensusAuthorizationHandler` con integración en el panel de administración (zonas, calles, autorización por padrón municipal) sobre Decidim 0.30.4. Producción ha sido actualizada a 0.31.5. Esta hoja recoge todos los cambios realizados y los pendientes.

---

## ✅ Paso 0 — Preparación de rama

Se partió de la rama `decidim_galdakao-0.31.5` (ya construida y funcional sobre 0.31.5) y se creó `feature/zone-verifications-0.31-rebased`. Los commits de la rama `feature/zone-verifications-v0.30.4` se aplicaron mediante cherry-pick sobre esta base.

```bash
git cherry-pick 66375cad..2a381a4d
```

Los conflictos resueltos durante el cherry-pick se documentan a continuación en cada paso relevante.

---

## ✅ Paso 1 — Registro del workflow de verificación

**Fichero:** `config/initializers/census_authorization.rb`

```ruby
# frozen_string_literal: true

if Decidim.module_installed? :verifications
  Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
    workflow.form = "CensusAuthorizationHandler"
    workflow.action_authorizer = "CensusActionAuthorizer"
    workflow.options do |options|
      options.attribute :zones, type: :string, required: false
    end
  end
end
```

> **Nota:** En 0.31.5 el bloque `Decidim::Verifications.configure` con `document_types` ya está gestionado por el `decidim.rb` base de la instalación. No se duplica aquí.

---

## ✅ Paso 2 — Eliminación de initializers y ficheros obsoletos

En 0.31 desaparecen `config/initializers/decidim.rb` y `config/secrets.yml`. Ambos fueron eliminados durante la resolución de conflictos del cherry-pick:

```bash
git rm config/initializers/decidim.rb
git rm config/secrets.yml
```

La configuración custom (maps, etherpad, API, etc.) que había en el `decidim.rb` antiguo ya está integrada en el `decidim.rb` base de la instalación 0.31.5 de Galdakao, que lee de `Rails.application.secrets.*` mapeado desde variables de entorno.

---

## ✅ Paso 3 — Autoload de clases y rutas del engine de admin

En lugar de declarar las rutas en `config/routes.rb` (patrón 0.30), en 0.31 las rutas propias se inyectan en el engine de admin desde un initializer. El `config/routes.rb` queda limpio, idéntico al de la base 0.31.5.

**Fichero:** `config/initializers/galdakao_census.rb`

```ruby
# frozen_string_literal: true

# Autoload de las clases de Galdakao y registro de rutas del engine de admin.
Rails.application.config.to_prepare do
  GaldakaoStreet
  GaldakaoWebservice
  CensusActionAuthorizer
end

Rails.application.initializer "galdakao_census.routes", after: :add_routing_paths do
  Decidim::Admin::Engine.routes.draw do
    resources :galdakao, only: [:index] do
      collection do
        get  :streets
        post :sync
        post :check
      end
    end
    scope "/galdakao", as: :galdakao do
      resources :zones do
        resources :zone_streets
      end
    end
  end
end
```

> **⚠️ IMPORTANTE — Bug resuelto en sesión 2026-05-28:**
> El patrón original ponía el bloque `Decidim::Admin::Engine.routes.draw` **dentro** de `to_prepare`. Esto rompe el login en Rails 7.2 / Decidim 0.31 porque `to_prepare` se ejecuta después de que Warden/Devise ya han configurado sus estrategias, invalidando el estado interno del router y haciendo que `current_user` devuelva un Array en lugar de un objeto User (`NoMethodError: undefined method 'admin?' for an instance of Array`).
>
> La solución es separar el autoload de clases (que va en `to_prepare`) de las rutas (que van en un initializer nombrado con `after: :add_routing_paths`).

**Fichero:** `config/routes.rb` (versión final limpia)

```ruby
# frozen_string_literal: true
require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end
  mount Decidim::Core::Engine => "/"
end
```

> **Eliminado:** `mount Decidim::FileAuthorizationHandler::AdminEngine => "/admin"` — en 0.31 el engine monta sus propias rutas internamente. Ver [PR #13294](https://github.com/decidim/decidim/pull/13294).

---

## ✅ Paso 4 — Corregir `unique_id` en `CensusAuthorizationHandler`

**Fichero:** `app/services/census_authorization_handler.rb`

```ruby
# ❌ Antes (rompe en Rails 7.2 — secrets deprecado)
def unique_id
  Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secrets.secret_key_base}")
end

# ✅ Después
def unique_id
  Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secret_key_base}")
end
```

> ⚠️ **Aviso:** Si el valor de `secret_key_base` cambia entre entornos al migrar, los `unique_id` existentes se invalidan y los usuarios tendrán que reautorizarse. Planificarlo con el equipo antes del deploy a producción.

---

## ✅ Paso 5 — Eliminar fallback a `secrets` en `census_url`

En Rails 7.2 `Rails.application.secrets` está deprecado. La URL del webservice SOAP debe venir exclusivamente de `ENV["CENSUS_URL"]`.

**Fichero:** `app/services/census_authorization_handler.rb`

```ruby
# ❌ Antes
census_url = ENV["CENSUS_URL"] || Rails.application.secrets.census_url

# ✅ Después
census_url = ENV["CENSUS_URL"]
```

**Fichero:** `app/services/galdakao_webservice.rb`

```ruby
# ❌ Antes
census_url = ENV["CENSUS_URL"] || Rails.application.secrets.census_url

# ✅ Después
census_url = ENV["CENSUS_URL"]
```

Verificar que `CENSUS_URL` está definida en el entorno de producción antes del deploy.

---

## ✅ Paso 6 — Corregir `manifest` en `CensusActionAuthorizer`

**Fichero:** `app/services/census_action_authorizer.rb`

```ruby
# ❌ Antes (puede fallar silenciosamente en 0.31)
def manifest
  Decidim.authorization_handlers.find { |m| m.name == "census_authorization_handler" }
end

# ✅ Después
def manifest
  Decidim::Verifications.find_workflow_manifest("census_authorization_handler")
end
```

---

## ✅ Paso 7 — Vista `authorization_workflows/index.html.erb`

Verificada contra la original de 0.31.5. La estructura base es idéntica — mismas clases CSS, mismo cell `revocations`, mismo layout. La tercera columna de gestión (botones "Calles" y "Zonas") está correctamente añadida. No requirió cambios.

```erb
<td class="!text-left">
  <% if workflow.key == "census_authorization_handler" %>
    <div class="flex gap-2">
      <%= link_to t("decidim.admin.galdakao.streets.title"),
            decidim_admin.galdakao_index_path,
            class: "button button__sm button__secondary" %>
      <%= link_to t("decidim.admin.galdakao.zones.index.title"),
            decidim_admin.galdakao_zones_path,
            class: "button button__sm button__secondary" %>
    </div>
  <% end %>
</td>
```

El cell `decidim/verifications/revocations` existe en 0.31.5 confirmado:

```
/usr/local/bundle/bundler/gems/decidim-989b6a0f3920/decidim-verifications/app/cells/decidim/verifications/revocations_cell.rb
```

---

## ✅ Paso 8 — Migración select2 → tom-select y limpieza del concern

Se completó la migración de select2 a tom-select antes de la migración a 0.31. tom-select entra por el pack principal de admin (`application.js`), por lo que el concern `NeedsMultiselectSnippets` ya no necesita inyectar tags externos.

**Fichero:** `app/controllers/concerns/decidim/admin/needs_multiselect_snippets.rb`

```ruby
# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Admin
    module NeedsMultiselectSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets
      end

      def snippets
        @snippets ||= Decidim::Snippets.new
      end
    end
  end
end
```

**Fichero:** `app/packs/src/decidim/admin/application.js`

```js
import "tom-select/dist/css/tom-select.default.css";
import "../../resource_permissions_multiselect";
```

**Fichero:** `app/packs/src/resource_permissions_multiselect.js` — reescrito completo con tom-select, ver documento de desarrollo para detalles.

---

## ✅ Paso 9 — Build y verificación de login

Build sin cache con la imagen correcta:

```bash
docker build --no-cache . -t erabaki-galdakao:local && docker compose up -d --force-recreate app
```

**Verificaciones realizadas:**

- `Warden::JWTAuth.config.secret` devuelve `nil` — **el JWT no es necesario** para que funcione el login en Decidim 0.31. `DECIDIM_API_JWT_SECRET` es opcional y solo necesario si se usa la API con autenticación forzada.
- Login funciona correctamente con `SECRET_KEY_BASE` definido en `.env` y sin JWT.
- El error `NoMethodError: undefined method 'admin?' for an instance of Array` era causado exclusivamente por `Decidim::Admin::Engine.routes.draw` dentro de `to_prepare` — resuelto en Paso 3.

---

## 🟡 Paso 10 — Ejecutar migraciones y tareas de upgrade

```bash
docker exec decidim_production bundle exec rails db:migrate
```

Tareas específicas de upgrade de 0.31:

```bash
bin/rails decidim:upgrade
bin/rails decidim:upgrade:decidim_update_valuators
bin/rails decidim:upgrade:decidim_action_log_valuation_assignment
bin/rails decidim:upgrade:decidim_paper_trail_valuation_assignment
bin/rails decidim:upgrade:fix_nickname_casing
bin/rails decidim:upgrade:clean:invalid_private_exports
bin/rails decidim:verifications:revoke:sms
bin/rails decidim_surveys:upgrade:fix_survey_permissions
bin/rails decidim:upgrade:user_groups:remove
bin/rails decidim:upgrade:fix_action_log
bin/rails decidim:upgrade:clean:remove_private_exports_attachments
bin/rails data:migrate
```

---

## 🟡 Paso 11 — Smoke test del flujo completo

Verificar manualmente en el entorno de staging:

- [ ] El panel admin arranca sin errores
- [ ] La página `/admin/authorization_workflows` carga correctamente con el layout de 0.31
- [ ] Los botones "Calles" y "Zonas" aparecen junto al census handler
- [ ] El formulario de verificación (`CensusAuthorizationHandler`) funciona y llama al SOAP
- [ ] La autorización se graba correctamente en `decidim_authorizations`
- [ ] El `CensusActionAuthorizer` restringe correctamente por zona/calle
- [ ] El multiselect de zonas en los permisos de componente funciona (JS/CSS de tom-select)
- [ ] `CENSUS_URL` está definida en el entorno y el handler la lee correctamente

---

## 🟡 Paso 12 — Mejoras de UI y seguridad (post smoke test)

Una vez el flujo funcional esté validado:

- [ ] Revisar y mejorar la UI del formulario de autorización de usuario (se ve fea)
- [ ] Implementar límite de intentos de login — actualmente sin límite, vulnerable a fuerza bruta

---

## Resumen de ficheros

| Fichero | Estado | Tipo de cambio |
|---|---|---|
| `config/initializers/decidim.rb` | ✅ Eliminado | Desaparece en 0.31 |
| `config/secrets.yml` | ✅ Eliminado | Desaparece en 0.31 |
| `config/routes.rb` | ✅ Limpio | Sin rutas propias, van al initializer |
| `config/initializers/census_authorization.rb` | ✅ Creado | Registro del workflow |
| `config/initializers/galdakao_census.rb` | ✅ Corregido | Autoload en `to_prepare` + rutas en initializer nombrado |
| `config/initializers/decidim_patches.rb` | ✅ Creado | Fix onboarding loop + fix `current_path` en `AuthorizationStatus` |
| `app/services/census_authorization_handler.rb` | ✅ Corregido | `secret_key_base` y `census_url` |
| `app/services/galdakao_webservice.rb` | ✅ Corregido | `census_url` |
| `app/services/census_action_authorizer.rb` | ✅ Corregido | Método `manifest` |
| `app/views/decidim/admin/authorization_workflows/index.html.erb` | ✅ Verificado | Sin cambios necesarios |
| `app/controllers/concerns/decidim/admin/needs_multiselect_snippets.rb` | ✅ Limpiado | Eliminadas referencias a select2 |
| `app/packs/src/resource_permissions_multiselect.js` | ✅ Migrado | select2 → tom-select |
| `app/packs/src/decidim/admin/application.js` | ✅ Actualizado | Import tom-select CSS |

---

## Notas de entorno

- **JWT:** `DECIDIM_API_JWT_SECRET` **no es necesario** para el login web en Decidim 0.31. Solo añadir si se activa autenticación forzada de API (`DECIDIM_API_FORCE_API_AUTHENTICATION=1`).
- **Build:** Usar siempre `docker build --no-cache . -t erabaki-galdakao:local` para garantizar que los cambios de initializers se recogen correctamente.
- **Redis:** Ante problemas de sesión, limpiar con `docker exec redis redis-cli FLUSHDB` (no `FLUSHALL` — ese borra también los datos de otros servicios).

---

## Referencias

- [Release notes v0.31.0](https://github.com/decidim/decidim/releases/tag/v0.31.0)
- [PR #13294 — Refactor modules mounting routes](https://github.com/decidim/decidim/pull/13294)
- [Upgrading Decidim docs](https://docs.decidim.org/en/develop/install/update.html)
- [Rails 7.2 upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Decidim docs — Customizing logic](https://docs.decidim.org/en/develop/customize/logic.html)Mi
