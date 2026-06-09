# Migración Decidim 0.30.4 → 0.31.5 — Authorization Handler Galdakao

> **Rama:** `local-gem-0.31.5`
> **Entorno destino:** Ruby 3.3.10 · Node 22.14.0 · Rails 7.2 · Shakapacker 8.3.0
> **Estado:** Pasos 1-11 completados. Pendiente commit limpio y smoke test completo.

---

## Contexto

Se ha desarrollado un `CensusAuthorizationHandler` con integración en el panel de administración (zonas, calles, autorización por padrón municipal) sobre Decidim 0.30.4. Producción ha sido actualizada a 0.31.5. Esta hoja recoge todos los cambios realizados y los pendientes.

Todo el código propio ha sido extraído a una **gem local** en `gems/decidim-galdakao_census/`, siguiendo el patrón de otros módulos de Decidim (decidim-awesome, etc.). La aplicación principal (`app/`) queda limpia de código propio salvo los overrides que no pueden ir en la gem.

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

> **Nota:** Este initializer se mantiene en la aplicación principal (no en la gem) porque registra el workflow en Decidim, que es responsabilidad de la app host. La gem proporciona las clases `CensusAuthorizationHandler` y `CensusActionAuthorizer` pero no las registra ella misma.

---

## ✅ Paso 2 — Eliminación de initializers y ficheros obsoletos

En 0.31 desaparecen `config/initializers/decidim.rb` y `config/secrets.yml`. Ambos fueron eliminados durante la resolución de conflictos del cherry-pick:

```bash
git rm config/initializers/decidim.rb
git rm config/secrets.yml
```

También se eliminó `config/initializers/galdakao_census.rb` al migrar el código al engine de la gem.

---

## ✅ Paso 3 — Gem local: estructura y engine

Todo el código propio se ha extraído a `gems/decidim-galdakao_census/`. La estructura final de la gem es:

```
gems/decidim-galdakao_census/
├── app/
│   ├── commands/decidim/galdakao_census/admin/
│   │   ├── create_galdakao_zone.rb
│   │   ├── create_galdakao_zone_street.rb
│   │   ├── update_galdakao_zone.rb
│   │   └── update_galdakao_zone_street.rb
│   ├── controllers/decidim/galdakao_census/admin/
│   │   ├── galdakao_controller.rb
│   │   ├── zone_streets_controller.rb
│   │   └── zones_controller.rb
│   ├── forms/decidim/galdakao_census/admin/
│   │   ├── galdakao_zone_form.rb
│   │   └── galdakao_zone_street_form.rb
│   ├── models/
│   │   ├── galdakao_street.rb
│   │   ├── galdakao_zone.rb
│   │   └── galdakao_zone_street.rb
│   ├── overrides/
│   │   ├── decidim/admin/authorization_workflows/index/
│   │   │   ├── add_management_td.html.erb.deface
│   │   │   └── add_management_th.html.erb.deface
│   │   └── layouts/decidim/admin/_header/
│   │       └── add_galdakao_census_tags.html.erb.deface
│   ├── packs/
│   │   ├── entrypoints/
│   │   │   └── decidim_admin_galdakao_census.js
│   │   └── src/
│   │       ├── decidim/admin/
│   │       │   └── galdakao_census_admin.js
│   │       └── resource_permissions_multiselect.js
│   ├── services/
│   │   ├── census_action_authorizer.rb
│   │   ├── census_authorization_handler.rb
│   │   └── galdakao_webservice.rb
│   └── views/
│       ├── census_authorization/
│       │   └── _form.html.erb
│       └── decidim/galdakao_census/admin/
│           ├── galdakao/
│           │   ├── index.html.erb
│           │   └── streets.html.erb
│           ├── zone_streets/
│           │   ├── _form.html.erb
│           │   ├── edit.html.erb
│           │   └── new.html.erb
│           └── zones/
│               ├── _form.html.erb
│               ├── edit.html.erb
│               ├── index.html.erb
│               ├── new.html.erb
│               └── show.html.erb
├── config/
│   ├── assets.rb
│   └── locales/
│       ├── en_census_authorizer_galdakao.yml
│       ├── es_census_authorizer_galdakao.yml
│       └── eu_census_authorizer_galdakao.yml
├── decidim-galdakao_census.gemspec
└── lib/
    ├── decidim-galdakao_census.rb
    └── decidim/galdakao_census/
        └── admin_engine.rb
```

**Fichero:** `gems/decidim-galdakao_census/lib/decidim/galdakao_census/admin_engine.rb`

```ruby
# frozen_string_literal: true
module Decidim
  module GaldakaoCensus
    module Admin
    end
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus::Admin
      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      paths["app/overrides"] ||= ["app/overrides"]

      routes do
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

      initializer "galdakao_census.admin_mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::GaldakaoCensus::AdminEngine,
                at: "/admin/galdakao_census",
                as: "decidim_admin_galdakao_census"
        end
      end
    end
  end
end
```

**Fichero:** `gems/decidim-galdakao_census/config/assets.rb`

```ruby
# frozen_string_literal: true
base_path = File.expand_path("..", __dir__)

Decidim::Shakapacker.register_path("#{base_path}/app/packs")

Decidim::Shakapacker.register_entrypoints(
  decidim_admin_galdakao_census: "#{base_path}/app/packs/entrypoints/decidim_admin_galdakao_census.js"
)
```

> **⚠️ IMPORTANTE:** Usar `Decidim::Shakapacker` (no `Decidim::Webpacker`, que está deprecado en 0.31).

**Fichero:** `gems/decidim-galdakao_census/decidim-galdakao_census.gemspec`

```ruby
# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name        = "decidim-galdakao_census"
  s.version     = "0.1.0"
  s.authors     = ["Alabs"]
  s.email       = []
  s.summary     = "Galdakao census authorization for Decidim"
  s.description = "Provides census-based authorization and zone management for Decidim in Galdakao."
  s.homepage    = ""
  s.license     = "AGPL-3.0"
  s.files = Dir["app/**/*", "config/**/*", "lib/**/*"]
  s.require_paths = ["lib"]
  s.add_dependency "decidim-core", "~> 0.31"
  s.add_dependency "decidim-admin", "~> 0.31"
  s.add_dependency "decidim-verifications", "~> 0.31"
  s.add_dependency "deface", "~> 1.0"
end
```

**Fichero:** `Gemfile` (extracto relevante)

```ruby
gem "decidim-galdakao_census", path: "gems/decidim-galdakao_census"
```

> **Nota:** Tras cualquier cambio en el gemspec hay que regenerar el Gemfile.lock desde dentro del contenedor:
> ```bash
> docker exec decidim_production bash -c "cd /app && bundle config set frozen false && bundle lock --update decidim-galdakao_census"
> docker cp decidim_production:/app/Gemfile.lock .
> ```

---

## ✅ Paso 4 — Corregir `unique_id` en `CensusAuthorizationHandler`

**Fichero:** `gems/decidim-galdakao_census/app/services/census_authorization_handler.rb`

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

---

## ✅ Paso 5 — Eliminar fallback a `secrets` en `census_url`

**Ficheros:** `census_authorization_handler.rb` y `galdakao_webservice.rb`

```ruby
# ❌ Antes
census_url = ENV["CENSUS_URL"] || Rails.application.secrets.census_url

# ✅ Después
census_url = ENV["CENSUS_URL"]
```

---

## ✅ Paso 6 — Corregir `manifest` en `CensusActionAuthorizer`

**Fichero:** `gems/decidim-galdakao_census/app/services/census_action_authorizer.rb`

```ruby
# ❌ Antes
def manifest
  Decidim.authorization_handlers.find { |m| m.name == "census_authorization_handler" }
end

# ✅ Después
def manifest
  Decidim::Verifications.find_workflow_manifest("census_authorization_handler")
end
```

---

## ✅ Paso 7 — Deface overrides desde la gem

La columna de gestión (botones "Calles" y "Zonas") en la vista `authorization_workflows/index` se inyecta mediante dos ficheros `.deface` en la gem. **No hay ningún override en `app/views/` de la aplicación principal.**

**Fichero:** `gems/decidim-galdakao_census/app/overrides/decidim/admin/authorization_workflows/index/add_management_th.html.erb.deface`

```erb
<!-- insert_after "thead tr th:last-child" -->
<th class="!text-left"><%= t("decidim.admin.galdakao.authorization_workflows.management") %></th>
```

**Fichero:** `gems/decidim-galdakao_census/app/overrides/decidim/admin/authorization_workflows/index/add_management_td.html.erb.deface`

```erb
<!-- insert_after "tbody tr td.\\!text-left" -->
<td class="!text-left">
  <% if workflow.key == "census_authorization_handler" %>
    <div class="flex gap-2">
      <%= link_to t("decidim.admin.galdakao.streets.title"),
            decidim_admin_galdakao_census.galdakao_index_path,
            class: "button button__sm button__secondary",
            style: "color: #fff" %>
      <%= link_to t("decidim.admin.galdakao.zones.index.title"),
            decidim_admin_galdakao_census.galdakao_zones_path,
            class: "button button__sm button__secondary",
            style: "color: #fff" %>
    </div>
  <% end %>
</td>
```

> **⚠️ IMPORTANTE — Reglas de Deface desde una gem engine:**
>
> 1. El engine debe declarar `paths["app/overrides"] ||= ["app/overrides"]` en el `AdminEngine`.
> 2. Los ficheros `.deface` deben estar en `app/overrides/` siguiendo **exactamente** la misma estructura de directorios que la vista original, **incluyendo el nombre de la acción como subdirectorio**. Para sobreescribir `decidim/admin/authorization_workflows/index.html.erb` los ficheros van en `app/overrides/decidim/admin/authorization_workflows/index/`.
> 3. Cada fichero `.deface` debe contener **una sola acción**.
> 4. El `style="color: #fff"` es necesario porque una regla CSS de Decidim 0.31 (`.table-list td a`) sobreescribe el color de los botones dentro de tablas.

---

## ✅ Paso 8 — JS desde la gem: entrypoint y carga en el layout

**Fichero:** `gems/decidim-galdakao_census/app/packs/entrypoints/decidim_admin_galdakao_census.js`

```js
import "src/decidim/admin/galdakao_census_admin";
```

**Fichero:** `gems/decidim-galdakao_census/app/packs/src/decidim/admin/galdakao_census_admin.js`

```js
import "../../resource_permissions_multiselect";
```

**Fichero:** `gems/decidim-galdakao_census/app/packs/src/resource_permissions_multiselect.js`

```js
import TomSelect from "tom-select";

const URL_ZONES = "/admin/galdakao_census/galdakao/zones";
const SELECTOR = "input[id*='authorization_handlers_options'][id*='zones']";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

// ... (implementación completa con TomSelect)

document.addEventListener("turbo:load", () => {
  initAllSelects(false);
  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      setTimeout(() => initAllSelects(true), 50);
    }
  });
});
```

> **⚠️ IMPORTANTE — Tres lecciones aprendidas sobre JS en gems:**
>
> 1. **Nombre del fichero fuente:** No usar `application.js` ni rutas que coincidan con las de Decidim (`src/decidim/admin/application`). Webpack resuelve ese path contra el bundle principal de decidim y acaba compilando todo el código de decidim admin dos veces, rompiendo la inicialización de Stimulus. El fichero fuente debe tener nombre propio (`galdakao_census_admin.js`).
>
> 2. **Registro del path:** Usar `Decidim::Shakapacker.register_path` y `Decidim::Shakapacker.register_entrypoints` en `config/assets.rb` (no `Decidim::Webpacker`, que está deprecado). Esto permite que shakapacker compile el entrypoint de la gem durante el build.
>
> 3. **Evento DOM correcto:** Decidim 0.31 usa Turbo. El evento correcto para inicializar JS que necesita el DOM es `turbo:load`, no `DOMContentLoaded`. Los scripts añadidos con `append_javascript_pack_tag` sin `defer: false` se ejecutan antes de que el DOM esté listo si se usa `DOMContentLoaded`.

**Deface para cargar el JS en el layout de admin:**

**Fichero:** `gems/decidim-galdakao_census/app/overrides/layouts/decidim/admin/_header/add_galdakao_census_tags.html.erb.deface`

```erb
<!-- insert_after "erb[loud]:contains('append_stylesheet_pack_tag')" -->
<% append_javascript_pack_tag("decidim_admin_galdakao_census", defer: false) %>
```

---

## ✅ Paso 9 — Build y verificación

Workflow de build tras cualquier cambio:

```bash
# Si cambia el gemspec:
docker exec decidim_production bash -c "cd /app && bundle config set frozen false && bundle lock --update decidim-galdakao_census"
docker cp decidim_production:/app/Gemfile.lock .

# Build limpio:
docker build . -t erabaki-galdakao:local && docker compose up -d
```

Para cambios solo en ficheros Ruby o vistas (sin cambios en JS ni gemspec), basta con:

```bash
docker cp <fichero> decidim_production:<ruta_destino>
docker exec decidim_production rm -rf /app/tmp/cache/bootsnap* /app/tmp/cache/deface*
docker compose restart app
```

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

- [x] El panel admin arranca sin errores
- [x] La página `/admin/authorization_workflows` carga correctamente con columna "Gestión"
- [x] Los botones "Calles" y "Zonas" aparecen junto al census handler con color correcto
- [x] Las vistas de zonas (index, new, edit, show) funcionan
- [x] Las vistas de calles (index, streets) funcionan
- [x] Las vistas de zone_streets (new, edit) funcionan
- [x] El multiselect de zonas en los permisos de componente funciona (TomSelect)
- [ ] El formulario de verificación (`CensusAuthorizationHandler`) funciona y llama al SOAP
- [ ] La autorización se graba correctamente en `decidim_authorizations`
- [ ] El `CensusActionAuthorizer` restringe correctamente por zona/calle
- [ ] `CENSUS_URL` está definida en el entorno y el handler la lee correctamente

---

## 🟡 Paso 12 — Commit limpio y build definitivo

```bash
git add -A
git commit -m "refactor: migrar código galdakao_census a gem local con namespace correcto"
docker build . -t erabaki-galdakao:local && docker compose up -d
```

---

## 🟡 Paso 13 — Mejoras de UI y seguridad (post smoke test)

- [ ] Revisar y mejorar la UI del formulario de autorización de usuario
- [ ] Implementar límite de intentos de login — actualmente sin límite, vulnerable a fuerza bruta

---

## Resumen de ficheros

### Gem local (`gems/decidim-galdakao_census/`)

| Fichero | Estado | Notas |
|---|---|---|
| `app/commands/decidim/galdakao_census/admin/*.rb` | ✅ | Namespace `Decidim::GaldakaoCensus::Admin` |
| `app/controllers/decidim/galdakao_census/admin/*.rb` | ✅ | Namespace `Decidim::GaldakaoCensus::Admin` |
| `app/forms/decidim/galdakao_census/admin/*.rb` | ✅ | Namespace `Decidim::GaldakaoCensus::Admin` |
| `app/models/*.rb` | ✅ | Clases top-level, sin namespace |
| `app/services/*.rb` | ✅ | Clases top-level, sin namespace |
| `app/views/decidim/galdakao_census/admin/**/*.erb` | ✅ | Rutas del engine con isolate_namespace |
| `app/views/census_authorization/_form.html.erb` | ✅ | Vista del formulario de autorización frontend |
| `app/overrides/decidim/admin/authorization_workflows/index/*.deface` | ✅ | Inyecta columna Gestión |
| `app/overrides/layouts/decidim/admin/_header/*.deface` | ✅ | Carga el JS del multiselect |
| `app/packs/entrypoints/decidim_admin_galdakao_census.js` | ✅ | Entrypoint compilado por shakapacker |
| `app/packs/src/decidim/admin/galdakao_census_admin.js` | ✅ | Importa el multiselect |
| `app/packs/src/resource_permissions_multiselect.js` | ✅ | TomSelect para zonas en permisos |
| `config/assets.rb` | ✅ | Registra path y entrypoint en shakapacker |
| `config/locales/*.yml` | ✅ | i18n es/eu/en |
| `decidim-galdakao_census.gemspec` | ✅ | Dependencias: core, admin, verifications, deface |
| `lib/decidim/galdakao_census/admin_engine.rb` | ✅ | Engine con rutas, mount y deface path |

### Aplicación principal (`app/`)

| Fichero | Estado | Notas |
|---|---|---|
| `config/initializers/census_authorization.rb` | ✅ | Registro del workflow — se queda en la app |
| `app/packs/` | ✅ Limpio | Sin código propio de galdakao |
| `app/views/` | ✅ Limpio | Sin overrides propios de galdakao |
| `app/overrides/decidim/devise/shared/_omniauth_buttons/add_gmail_login_info.html.erb.deface` | ✅ | Override de login — se queda en la app |

---

## Notas de entorno

- **JWT:** `DECIDIM_API_JWT_SECRET` no es necesario para el login web en Decidim 0.31.
- **Build:** Usar siempre `docker build . -t erabaki-galdakao:local` para garantizar que los assets JS se compilan correctamente.
- **Deface cache:** Ante problemas con deface, limpiar con `docker exec decidim_production rm -rf /app/tmp/cache/deface*` antes de reiniciar.
- **Redis:** Ante problemas de sesión, limpiar con `docker exec redis redis-cli FLUSHDB`.

---

## Referencias

- [Release notes v0.31.0](https://github.com/decidim/decidim/releases/tag/v0.31.0)
- [PR #13294 — Refactor modules mounting routes](https://github.com/decidim/decidim/pull/13294)
- [Upgrading Decidim docs](https://docs.decidim.org/en/develop/install/update.html)
- [Rails 7.2 upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Decidim docs — Customizing logic](https://docs.decidim.org/en/develop/customize/logic.html)


## 🟡 Paso 14 — Mover el registro del workflow a la gema local y desactivar renovación

### Objetivo

Completar la migración del módulo `galdakao_census` a la gema local eliminando el último elemento funcional que permanece en la aplicación host: el registro del workflow de verificación.

Además, incorporar la funcionalidad solicitada en producción para impedir la renovación manual de autorizaciones mediante `workflow.renewable = false`.

---

### Situación anterior

El workflow se registraba desde la aplicación principal:

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

Esto provocaba que la gema no fuese completamente autocontenida, ya que una instalación nueva requería copiar también un initializer en la aplicación host para que el authorization handler apareciese en Decidim.

La gema tampoco disponía de un Engine principal — solo existía `AdminEngine` — porque el desarrollo se había hecho de forma incremental y este initializer había quedado fuera.

---

### Análisis previo al cambio

Antes de actuar se evaluó si el initializer podía añadirse al `AdminEngine` existente. La conclusión fue que **no es semánticamente correcto**: el `AdminEngine` gestiona rutas y lógica del panel de administración. El registro de un workflow de verificación es funcionalidad del core de Decidim y pertenece a un Engine principal.

Por tanto, fue necesario **crear el Engine principal** que faltaba en la gema.

---

### Cambios aplicados

#### 1. Crear el Engine principal

**Fichero nuevo:** `gems/decidim-galdakao_census/lib/decidim/galdakao_census/engine.rb`

```ruby
# frozen_string_literal: true
module Decidim
  module GaldakaoCensus
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus

      initializer "galdakao_census.verification_workflow" do
        Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
          workflow.form = "CensusAuthorizationHandler"
          workflow.action_authorizer = "CensusActionAuthorizer"
          workflow.renewable = false

          workflow.options do |options|
            options.attribute :zones, type: :string, required: false
          end
        end
      end
    end
  end
end
```

#### 2. Registrar el Engine principal en el punto de entrada de la gema

**Fichero:** `gems/decidim-galdakao_census/lib/decidim-galdakao_census.rb`

```ruby
# frozen_string_literal: true
require "decidim/galdakao_census/engine"
require "decidim/galdakao_census/admin_engine"
```

El Engine principal debe cargarse **antes** que el AdminEngine.

#### 3. Desactivar el initializer de la aplicación host

```text
config/initializers/census_authorization.rb  →  renombrado a .back
```

---

### Eliminación de código obsoleto

Una vez verificado el correcto funcionamiento, el fichero `.back` puede eliminarse definitivamente:

```text
config/initializers/census_authorization.rb.back
```

---

### Motivo técnico

La documentación oficial de Decidim para módulos de verificación registra los workflows desde los propios Engines mediante initializers.

La gema ya contiene:

* `CensusAuthorizationHandler`
* `CensusActionAuthorizer`
* vistas del authorization handler
* lógica de autorización
* assets
* overrides
* panel de administración

Por tanto, el registro del workflow forma parte de la responsabilidad del propio módulo y no de la aplicación host.

---

### Funcionalidad añadida

```ruby
workflow.renewable = false
```

Impide que Decidim muestre la opción de renovar una autorización existente del tipo `census_authorization_handler`.

Comportamiento esperado:

* La autorización sigue siendo válida.
* La verificación sigue funcionando con normalidad.
* No aparece el botón de renovación para el usuario.
* Solo se permitirá una nueva autorización si la existente ha expirado o ha sido revocada por Decidim.

---

### Verificación manual

Comprobar en staging:

* [x] El workflow `census_authorization_handler` aparece en `/admin/authorization_workflows`
* [x] El formulario de autorización sigue cargando correctamente
* [x] La autorización se registra en `decidim_authorizations`
* [x] `CensusActionAuthorizer` sigue resolviendo correctamente las zonas
* [x] No aparece la opción de renovar la autorización desde la interfaz de usuario
* [x] La aplicación arranca correctamente sin `config/initializers/census_authorization.rb`
* [x] Sin DEPRECATION WARNING del initializer

----

## Punto 15 — Migración de Webpacker a Shakapacker en assets.rb

**Problema detectado:** Al arrancar la consola de Rails aparecían dos DEPRECATION WARNING:
- `Decidim::Webpacker.register_path is deprecated. Please use Decidim::Shakapacker.register_path instead.`
- `Decidim::Webpacker.register_entrypoints is deprecated. Please use Decidim::Shakapacker.register_entrypoints instead.`

**Archivo afectado:**
`gems/decidim-galdakao_census/config/assets.rb`

**Cambio realizado:**
Sustitución global de `Decidim::Webpacker` por `Decidim::Shakapacker`.

**Nota importante:**
Este cambio **no requiere restart**, requiere un `assets:precompile` para que surta efecto en los assets compilados. Pendiente de ejecutar junto con el testeo completo tras los 4 parches adicionales.

**Archivos actualizados en host y docker:**
- `gems/decidim-galdakao_census/config/assets.rb` ✓
- `decidim_production:/app/gems/decidim-galdakao_census/config/assets.rb` ✓

**Nota importante:**
Este cambio requiere un `assets:precompile` para que surta efecto en los assets compilados. ~~Pendiente de ejecutar junto con el testeo completo tras los 4 parches adicionales.~~ **Ejecutado en el build del 04/06/2026.**

### Verificación manual

* [x] Sin DEPRECATION WARNING de Webpacker
* [x] Build `assets:precompile` completado correctamente el 04/06/2026


---

## 🟡 Paso 16 — Override de ManagedUserErrorEvent: eliminar datos personales del email de conflicto de verificación

### Objetivo

Eliminar la exposición de datos personales de terceros en el email que Decidim envía a los administradores cuando se produce un conflicto de verificación (dos usuarios intentando autorizarse con el mismo `unique_id`).

---

### Contexto y motivo

Cuando un usuario intenta verificarse con datos que ya están en uso por otro usuario, Decidim publica el evento `decidim.events.verifications.managed_user_error_event` que envía un email a todos los administradores de la organización.

El email original incluye:
- Nombre y enlace al perfil del usuario que **intenta** autorizarse
- Nombre y enlace al perfil del usuario que **ya tiene** esa autorización

Esto supone enviar datos personales de terceros por email, canal no seguro. El administrador dispone del panel **Back Office → Participantes → Conflictos de Verificación** para resolver el problema con toda la información necesaria, por lo que no es necesario incluir esos datos en el email.

El archivo original en el core de Decidim 0.31:

> /usr/local/bundle/bundler/gems/decidim-989b6a0f3920/decidim-verifications/app/events/decidim/verifications/managed_user_error_event.rb

Expone en el email: `resource_path`, `resource_url`, `resource_title`, `managed_user_path`, `managed_user_url`, `managed_user_name`.

---

### Solución aplicada

Override de la clase mediante `config.to_prepare` en el Engine principal de la gema, que pone a `nil` todos los campos con datos personales y mantiene únicamente el enlace al panel de conflictos.

> **Nota técnica:** Se intentó inicialmente con `initializer after: "decidim_verifications.mount_routes"` pero fallaba en el `assets:precompile` con `NameError: uninitialized constant Decidim::Verifications::ManagedUserErrorEvent` porque la clase no estaba cargada en ese momento. `config.to_prepare` garantiza que el override se aplica después de que todas las clases están cargadas, tanto en desarrollo como en producción.

---

### Archivos modificados

#### 1. Engine principal — añadido `config.to_prepare`

**Fichero:** `gems/decidim-galdakao_census/lib/decidim/galdakao_census/engine.rb`

Añadido bloque `config.to_prepare` que sobrescribe:
- `resource_path` → `nil`
- `resource_url` → `nil`
- `resource_title` → `nil`
- `default_i18n_options` → solo incluye `conflicts_path` y `conflicts_url`

```ruby
config.to_prepare do
  Decidim::Verifications::ManagedUserErrorEvent.class_eval do
    include Rails.application.routes.mounted_helpers

    def resource_path
      nil
    end

    def resource_url
      nil
    end

    def resource_title
      nil
    end

    def default_i18n_options
      super.merge({ conflicts_path: decidim_admin.conflicts_path,
                    conflicts_url: decidim_admin.conflicts_url })
    end

    private

    def decidim_admin
      @decidim_admin ||= Decidim::EngineRouter.new("decidim_admin", { host: organization.host })
    end

    def organization
      resource.current_user.organization
    end
  end
end
```

#### 2. Textos i18n — sobreescritos en los tres idiomas

Los textos originales de Decidim referenciaban `%{resource_url}`, `%{resource_title}`, `%{managed_user_url}` y `%{managed_user_name}`. Los nuevos textos son genéricos y solo usan `%{conflicts_url}`.

**Ficheros modificados:**
- `gems/decidim-galdakao_census/config/locales/es_census_authorizer_galdakao.yml`
- `gems/decidim-galdakao_census/config/locales/en_census_authorizer_galdakao.yml`
- `gems/decidim-galdakao_census/config/locales/eu_census_authorizer_galdakao.yml`

Clave añadida en los tres bajo `decidim.events.verifications.verify_with_managed_user`:

```yaml
email_intro: Una participante ha intentado verificarse con datos que ya están en uso por otra participante.
email_outro: Comprueba la <a href="%{conflicts_url}">lista de conflictos de verificaciones</a> para ver los detalles y resolver el problema.
email_subject: Error al intentar verificarse contra otra participante
notification_title: Una participante ha intentado verificarse con datos que ya están en uso por otra participante.
```

---

### Comportamiento resultante

- El admin recibe un email indicando que hay un conflicto de verificación.
- El email incluye un enlace directo al panel de conflictos.
- El email **no incluye** ningún dato personal de ninguno de los usuarios implicados.
- El admin resuelve el conflicto desde el panel de admin con toda la información disponible de forma segura.

---

### Nota importante para el manual de administración

El email de conflicto se envía de forma **inmediata o diferida** según la configuración de notificaciones del administrador:

- **En tiempo real** → el admin recibe el email en el momento del conflicto.
- **Diariamente** → el email se acumula en el resumen diario y no llega de forma inmediata.
- **Semanalmente** → ídem, con resumen semanal.
- **Ninguna** → no se envía email.

Para garantizar que los conflictos de verificación se atienden con rapidez, **se recomienda que el administrador tenga la frecuencia de notificaciones configurada en "En tiempo real"**. Esta configuración se gestiona desde:

> Mi cuenta → Configuración de las notificaciones → ¿Con qué frecuencia quieres recibir el correo resumen de notificaciones?

Independientemente de la configuración de email, el conflicto **siempre queda registrado** en el panel de administración en:

> Back Office → Participantes → Conflictos de Verificación

---

### Verificación manual

- [x] Provocar un conflicto de verificación en staging (dos usuarios con el mismo DNI y fecha de nacimiento)
- [x] Comprobar que el admin recibe el email sin datos personales
- [x] Comprobar que el email incluye el enlace al panel de conflictos
- [x] Comprobar que el conflicto aparece en Back Office → Participantes → Conflictos de Verificación
- [x] Comprobar que el admin puede resolver el conflicto desde el panel
- [x] Verificar comportamiento con frecuencia "Diariamente" — email no inmediato, conflicto registrado
- [x] Verificar comportamiento con frecuencia "En tiempo real" — email inmediato sin datos personales


## 🟡 Paso 17 — Sistema de bloqueo de autorizaciones (LockoutManager)

### Objetivo

Implementar un sistema de bloqueo progresivo para los intentos fallidos de autorización con el padrón municipal, persistiendo el estado en `extended_data` del usuario. Añadir notificación al administrador cuando el bloqueo es indefinido y panel de gestión en el admin.

---

### Modo de funcionamiento

- Tras cada intento fallido: bloqueo de 30 segundos.
- Al tercer intento fallido: bloqueo de 5 minutos.
- Al sexto intento fallido: bloqueo indefinido — el usuario debe contactar con la administración.
- En caso de éxito: se reinicia el registro de intentos.

---

### Arquitectura

La lógica se modulariza en `Decidim::GaldakaoCensus::LockoutManager` bajo `app/services/` de la gema, manteniendo el `CensusAuthorizationHandler` como archivo de flujo. El handler delega en el manager sin contener lógica de bloqueo.

---

### Archivos creados

- `gems/decidim-galdakao_census/app/services/decidim/galdakao_census/lockout_manager.rb`
- `gems/decidim-galdakao_census/app/events/decidim/galdakao_census/user_locked_event.rb`
- `gems/decidim-galdakao_census/app/controllers/decidim/galdakao_census/admin/blocked_users_controller.rb`
- `gems/decidim-galdakao_census/app/views/decidim/galdakao_census/admin/blocked_users/index.html.erb`

### Archivos modificados

- `gems/decidim-galdakao_census/app/services/census_authorization_handler.rb` — integración del lockout mediante `validate :check_lockout` y delegación en `LockoutManager`
- `gems/decidim-galdakao_census/lib/decidim/galdakao_census/admin_engine.rb` — rutas para `blocked_users` con acción `unlock`
- `gems/decidim-galdakao_census/config/locales/{es,en,eu}_census_authorizer_galdakao.yml` — textos del lockout y del evento de notificación

---

### Persistencia

El estado de bloqueo se guarda en `Decidim::User#extended_data` bajo la clave `authorizations.census_authorization_handler`:

```json
{
  "authorizations": {
    "census_authorization_handler": {
      "failed_attempts": 6,
      "last_attempt_at": "2026-06-05T17:00:00Z",
      "locked_until": "infinite"
    }
  }
}
```

---

### Notificación al admin

Cuando el bloqueo es indefinido, se publica el evento `decidim.events.galdakao_census.user_locked` via `Decidim::EventsManager`, que envía un email a todos los admins de la organización con un enlace al panel de autorizaciones bloqueadas. Sin datos personales en el email.

---

### Panel de administración

Accesible desde el submenú de Impersonaciones → Autorizaciones bloqueadas. Lista usuarios bloqueados indefinidamente con nombre, email, número de intentos, fecha del último intento y botón de desbloqueo con confirmación.

**Para desbloquear un usuario manualmente desde consola:**
```ruby
user = Decidim::User.find_by(email: "correo@ejemplo.com")
data = user.extended_data["authorizations"] || {}
data.delete("census_authorization_handler")
user.update!(extended_data: user.extended_data.merge("authorizations" => data))
```

---

### Verificación manual

- [x] Introducir datos incorrectos y verificar mensaje de espera de 30 segundos
- [x] Al tercer intento verificar bloqueo de 5 minutos
- [x] Al sexto intento verificar bloqueo indefinido y recepción de email por el admin
- [x] Verificar panel de autorizaciones bloqueadas en el admin
- [x] Desbloquear usuario desde el panel y verificar que puede volver a intentarlo
- [x] Verificar que un intento exitoso limpia el registro de intentos

---

## 🟡 Paso 18 — Mejoras visuales del formulario de autorización

### Objetivo

Mejorar la vista del formulario de autorización del padrón municipal para que sea más clara e informativa para el usuario, especialmente en los casos de error y bloqueo.

### Archivo modificado

- `gems/decidim-galdakao_census/app/views/census_authorization/_form.html.erb`

### Verificación manual

- [x] Verificar que el formulario carga correctamente
- [x] Verificar que los mensajes de error se muestran correctamente
- [x] Verificar que el mensaje de bloqueo temporal se muestra correctamente
- [x] Verificar que el mensaje de bloqueo indefinido se muestra correctamente