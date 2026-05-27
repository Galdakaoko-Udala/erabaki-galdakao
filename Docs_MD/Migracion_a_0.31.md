AUN NO COMENZADA

# Migración Decidim 0.30.4 → 0.31.0 — Authorization Handler Galdakao

> **Rama sugerida:** `feature/migration-decidim-031`  
> **Entorno destino:** Ruby 3.3.10 · Node 22.14.0 · Rails 7.2 · Shakapacker 8.3.0  
> Revisar con el repo de 0.31 de Galdakao como base. Completar en orden.

---

## Contexto

Se ha desarrollado un `CensusAuthorizationHandler` con integración en el panel de administración (zonas, calles, autorización por padrón municipal) sobre Decidim 0.30.4. Producción ha sido actualizada a 0.31.0. Esta hoja recoge todos los cambios necesarios identificados mediante revisión del changelog oficial y del código fuente de la app.

---

## Paso 0 — Preparación de rama y entorno

```bash
git checkout -b feature/migration-decidim-031
rbenv install 3.3.10 && rbenv local 3.3.10   # o el gestor que uses
nvm install 22.14.0 && nvm use 22.14.0
```

Actualizar `Gemfile`:
```ruby
gem "decidim", "0.31.0"
gem "decidim-dev", "0.31.0"
```

---

## Paso 1 — 🔴 Extraer el registro del workflow ANTES de tocar el initializer

> **Riesgo si se omite:** el handler deja de registrarse y nadie puede verificarse.

Crear `config/initializers/census_authorization.rb` con el contenido:

```ruby
# frozen_string_literal: true

if Decidim.module_installed? :verifications
  Decidim::Verifications.configure do |config|
    config.document_types = ENV.fetch("VERIFICATIONS_DOCUMENT_TYPES", "identification_number,passport").split(",")
  end

  Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
    workflow.form = "CensusAuthorizationHandler"
    workflow.action_authorizer = "CensusActionAuthorizer"
    workflow.options do |options|
      options.attribute :zones, type: :string, required: false
    end
  end
end
```

Solo después de tener este fichero guardado y commiteado, proceder con el paso 2.

---

## Paso 2 — 🔴 Eliminar el initializer de Decidim y migrar a ENV vars

El fichero `config/initializers/decidim.rb` desaparece en 0.31. Todo usa `Rails.application.secrets.*` que queda deprecado con Rails 7.2.

```bash
git rm config/initializers/decidim.rb
git rm config/secrets.yml

# Descargar los nuevos ficheros base de 0.31
wget https://raw.githubusercontent.com/decidim/decidim/refs/heads/develop/decidim-generators/lib/decidim/generators/app_templates/storage.yml -O config/storage.yml
wget https://github.com/decidim/decidim/releases/download/v0.31.0.rc1/production.rb -O config/environments/production.rb
```

Toda la configuración custom (maps, etherpad, API, etc.) que había en el initializer pasa a un fichero propio que solo lee de `ENV`. Ejemplo para los bloques que teníamos:

```ruby
# config/initializers/decidim_custom.rb  (nuevo fichero)
# Aquí va la configuración de maps, etherpad, etc. leída de ENV
# NO usar Rails.application.secrets.*
```

Actualizar `config/application.rb`:
```bash
sed -i "s/config\.load_defaults 6\.1/config\.load_defaults 7.2/g" config/application.rb
```

---

## Paso 3 — 🔴 Corregir `unique_id` en `CensusAuthorizationHandler`

**Fichero:** `app/services/census_authorization_handler.rb`

```ruby
# ❌ Antes (rompe en Rails 7.2)
def unique_id
  Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secrets.secret_key_base}")
end

# ✅ Después
def unique_id
  Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secret_key_base}")
end
```

> ⚠️ **Aviso importante:** si el valor de `secret_key_base` cambia entre entornos al migrar, los `unique_id` existentes se invalidan y los usuarios tendrán que reautorizarse. Planificarlo con el equipo antes del deploy a producción.

---

## Paso 4 — 🔴 Actualizar la vista `authorization_workflows/index.html.erb`

**Fichero:** `app/views/decidim/admin/authorization_workflows/index.html.erb`

Esta vista sobreescribe la del core. Las clases CSS `item_show__header`, `card`, `card-divider`, `card-title`, `card-section`, `table-list` son del sistema de UI de 0.30 y pueden estar eliminadas o renombradas en 0.31.

**Acción:**

1. Localizar la vista original de 0.31 en la gem instalada:
   ```bash
   bundle show decidim-admin
   # Buscar en ese path:
   find $(bundle show decidim-admin) -name "index.html.erb" -path "*authorization_workflows*"
   ```

2. Comparar la original de 0.31 con la nuestra y actualizar clases CSS y estructura HTML.

3. Mantener solo la columna extra de gestión (`census_authorization_handler`) que es lo que añadimos nosotros:
   ```erb
   <td class="!text-left">
     <% if workflow.key == "census_authorization_handler" %>
       <div class="flex gap-2">
         <%= link_to t("decidim.admin.galdakao.streets.title"), decidim_admin.galdakao_index_path, class: "button button__sm button__secondary" %>
         <%= link_to t("decidim.admin.galdakao.zones.index.title"), decidim_admin.galdakao_zones_path, class: "button button__sm button__secondary" %>
       </div>
     <% end %>
   </td>
   ```

4. Verificar que el cell `decidim/verifications/revocations` sigue existiendo en 0.31:
   ```bash
   find $(bundle show decidim-verifications) -name "revocations*" 2>/dev/null
   ```

---

## Paso 5 — 🟡 Corregir `manifest` en `CensusActionAuthorizer`

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

## Paso 6 — 🟡 Simplificar `census_url` en el handler

**Fichero:** `app/services/census_authorization_handler.rb`

```ruby
# ❌ Antes
census_url = ENV["CENSUS_URL"] || Rails.application.secrets.census_url

# ✅ Después
census_url = ENV["CENSUS_URL"]
```

Asegurarse de que `CENSUS_URL` está definida en las variables de entorno de producción.

---

## Paso 7 — 🟡 Verificar assets con Shakapacker 8.3.0

Shakapacker sube de 7.x a 8.3.0. El concern `NeedsMultiselectSnippets` usa:

```ruby
ActionController::Base.helpers.javascript_include_tag("resource_permissions_multiselect")
ActionController::Base.helpers.stylesheet_link_tag("select2.css")
```

**Acciones:**

1. Actualizar `package.json`:
   ```json
   "shakapacker": "~8.3.0"
   ```

2. Tras `bundle update decidim` y `yarn install`, compilar y verificar:
   ```bash
   bin/rails assets:precompile 2>&1 | grep -i "multiselect\|select2\|error"
   cat public/packs/manifest.json | grep -i "multiselect\|select2"
   ```

3. Si `resource_permissions_multiselect` no aparece en el manifiesto, añadirlo como entry point en `config/shakapacker.yml` o en la configuración de webpack.

4. Si `select2.css` no resuelve, mover la importación al pack JS o referenciarla desde el manifiesto de Shakapacker.

---

## Paso 8 — 🟡 Verificar `decidim-file_authorization_handler`

```bash
grep "file_authorization" Gemfile
gem list decidim-file_authorization_handler
```

Si la gema no tiene soporte explícito para 0.31, puede causar un boot error al montar el engine:

```ruby
mount Decidim::FileAuthorizationHandler::AdminEngine => "/admin"
```

Buscar en el repositorio de la gema si hay una versión compatible con 0.31, o valorar comentar el mount temporalmente hasta confirmar compatibilidad.

---

## Paso 9 — Ejecutar las migraciones y tareas de upgrade

```bash
bundle update decidim
bin/rails decidim:upgrade
bin/rails db:migrate

# Tareas específicas de 0.31
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

## Paso 10 — Smoke test del flujo completo

Verificar manualmente en el entorno de staging:

- [ ] El panel admin arranca sin errores
- [ ] La página `/admin/authorization_workflows` carga correctamente con el layout de 0.31
- [ ] Los botones "Calles" y "Zonas" aparecen junto al census handler
- [ ] El formulario de verificación (`CensusAuthorizationHandler`) funciona y llama al SOAP
- [ ] La autorización se graba correctamente en `decidim_authorizations`
- [ ] El `CensusActionAuthorizer` restringe correctamente por zona/calle
- [ ] El multiselect de zonas en los permisos de componente funciona (JS/CSS de select2)
- [ ] `CENSUS_URL` está definida en el entorno y el handler la lee correctamente

---

## Resumen de ficheros a tocar

| Fichero | Tipo de cambio |
|---|---|
| `config/initializers/decidim.rb` | **Eliminar** (después de extraer) |
| `config/initializers/census_authorization.rb` | **Crear** (registro del workflow) |
| `config/initializers/decidim_custom.rb` | **Crear** (config custom sin secrets) |
| `config/secrets.yml` | **Eliminar** |
| `config/application.rb` | Cambiar `load_defaults 6.1` → `7.2` |
| `config/environments/production.rb` | **Reemplazar** con el de 0.31 |
| `config/storage.yml` | **Reemplazar** con el de 0.31 |
| `app/services/census_authorization_handler.rb` | `secrets.secret_key_base` → `secret_key_base`; simplificar `census_url` |
| `app/services/census_action_authorizer.rb` | Corregir método `manifest` |
| `app/views/decidim/admin/authorization_workflows/index.html.erb` | Actualizar clases CSS con la vista original de 0.31 |
| `package.json` | Shakapacker `~8.3.0` |

---

## Referencias

- [Release notes v0.31.0](https://github.com/decidim/decidim/releases/tag/v0.31.0)
- [Upgrading Decidim docs](https://docs.decidim.org/en/develop/install/update.html)
- [Rails 7.2 upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)