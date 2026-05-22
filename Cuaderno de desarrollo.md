# Cuaderno de desarrollo — Galdakao Decidim
> Rama: `feature/zone-verifications`

---

## Infraestructura Docker — entorno de desarrollo

### Comandos habituales

**Rebuild completo** (cambios en Ruby, modelos, migraciones, assets compilados):
```bash
docker build . -t erabaki-galdakao:local && docker compose up -d && docker image prune -f && docker builder prune -f
```

**Cambios en volúmenes** (vistas ERB, JS packs — no requieren rebuild):
```bash
docker compose restart app
```

**Monitorizar espacio antes de buildear:**
```bash
docker system df
```
Si hay poco margen, limpiar primero con `docker image prune -f && docker builder prune -f`.

**⚠️ No usar nunca** `docker image prune -a` ni `docker system prune` — hay imágenes en uso que no deben eliminarse (`postgres:14`, `redis`, `traefik`, `tiredofit/db-backup`, `node:18`). El `prune -f` sin `-a` solo elimina imágenes dangling (la versión anterior de `erabaki-galdakao:local`), que es lo único que sobra tras cada build.

---

Git push habitual:
```
git push alabs feature/zone-verifications
```

---

### docker-compose.override.yml

Docker Compose carga automáticamente `docker-compose.override.yml` si existe, fusionándolo con el compose principal. Se usa para adaptar el compose de producción al entorno local sin tocar el archivo original (que es compartido con otros municipios).

**El archivo NO está en git** (está en `.gitignore`). Si se pierde, recrearlo con:

```bash
cat > /opt/decidim_production/docker-compose.override.yml << 'EOF'
services:
  traefik:
    image: traefik:v2.11
    command:
      - --log.level=DEBUG
      - --api=true
      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.web.forwardedHeaders.insecure=true
    ports:
      - "3015:80"
      - "0.0.0.0:8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=PathPrefix(`/traefik`)"
      - "traefik.http.routers.traefik.entrypoints=web"
      - "traefik.http.routers.traefik.service=api@internal"

  app:
    image: erabaki-galdakao:local
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`galdakaocenso.demo.participa.cloud`) && PathPrefix(`/`)"
      - "traefik.http.routers.app.entrypoints=web"
      - "traefik.http.routers.app.tls=false"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
EOF

echo "docker-compose.override.yml" >> /opt/decidim_production/.gitignore
docker compose up -d
```

**Por qué existe:** el `docker-compose.yml` original apunta a `ghcr.io/galdakaoko-udala/erabaki-galdakao:main` (registry privado) y usa `traefik:v3.3` con SSL. Este override lo adapta para usar la imagen buildeada localmente y traefik sin SSL en el puerto 3015.

**Nota importante:** las labels en el override **reemplazan completamente** las del servicio original — por eso hay que incluir `tls=false` explícitamente para neutralizar el `tls=true` del compose principal. Si no, Traefik espera TLS y devuelve 404 en HTTP.

**Nota sobre copiar archivos al contenedor:** el contenedor no monta el host en ejecución. Para propagar cambios en archivos que no son vistas ni packs JS:
```bash
# Método general
docker compose cp /opt/decidim_production/ruta/al/archivo app:/app/ruta/al/archivo
docker compose restart app

# Para routes.rb (device busy con cp directo)
docker compose cp /opt/decidim_production/config/routes.rb app:/tmp/routes.rb
docker compose exec app cp /tmp/routes.rb /app/config/routes.rb
```

---

## Referencia: renombrado Getxo → Galdakao

| Getxo (original 0.23) | Galdakao (este repo) |
|---|---|
| `GetxoZone` | `GaldakaoZone` |
| `GetxoStreet` | `GaldakaoStreet` |
| `getxo_zone` | `galdakao_zone` |
| `admin_getxo_zones_path` | `decidim_admin.galdakao_zones_path` |
| `Rectify::Command` | `Decidim::Command` |
| `layout "decidim/admin/getxo"` | `layout "decidim/admin/application"` |

---

## Referencia: diferencias 0.23 → 0.30 específicas de esta rama

| Problema | Solución |
|---|---|
| `Rectify::Command` no existe en 0.30 | Usar `Decidim::Command` |
| `before_action :logged_and_admin?` con redirect manual | `enforce_permission_to :read, :admin_user` |
| `layout "decidim/admin/getxo"` | `layout "decidim/admin/application"` |
| `link_to` con `method: :delete` | `button_to` con `method: :delete` |
| Helper `admin_getxo_zones_path` | `decidim_admin.galdakao_zones_path` |
| `authenticate_admin!` | No existe — usar `enforce_permission_to` |
| Shakapacker: dos llamadas a `javascript_pack_tag` | Lanza excepción 500 — solo una llamada permitida |

---

## Bug resuelto: campo `streets` en lugar de `zones` en formulario de permisos ✅

### Síntoma

El formulario de permisos del componente mostraba el campo "Streets" en lugar de "Zones". El select2 no se inicializaba porque el JS buscaba `[census_authorization_handler][zones]` en el DOM pero el HTML generado contenía `[census_authorization_handler][streets]`.

### Causa raíz

En `config/initializers/decidim.rb`, el workflow del handler tenía:

```ruby
workflow.options do |options|
  options.attribute :streets, type: :string, required: false
end
```

Decidim usa ese atributo para generar el campo del formulario de permisos. Como se llamaba `:streets`, generaba `<div class="streets_container">` con un input `[census_authorization_handler][streets]`.

### Cadena completa de Decidim

```
register_workflow options
  → PermissionForm#options_attributes
    → _options_form.html.erb
      → settings_attribute_input
        → genera div con clase {nombre}_container
        → genera input con name [census_authorization_handler][{nombre}]
```

### Solución

Cambiar `:streets` por `:zones` en `config/initializers/decidim.rb`:

```ruby
workflow.options do |options|
  options.attribute :zones, type: :string, required: false
end
```

---

## Bug resuelto: JS roto — `window.Decidim.currentDialogs` undefined ✅

### Síntoma

El modal de confirmación de Decidim (`data: { confirm: }`) no funcionaba en ninguna vista del admin. Error en consola: `Cannot read properties of undefined (reading 'confirm-modal')`.

### Causa raíz

El entrypoint `decidim_admin_select2.js` hacía:
```js
import $ from "jquery";
window.jQuery = $;
window.$ = $;
```
Esto sobreescribía el jQuery que ya había inicializado Decidim core, antes de que `window.Decidim.currentDialogs` se populase. Al sobreescribir `window.$`, los listeners de Foundation y el sistema de diálogos quedaban rotos.

### Solución

Usar el hook oficial de Decidim para el admin. Crear `app/packs/src/decidim/admin/decidim_application.js`:
```js
import "select2";
import "../../../../stylesheets/select2.css";
import "../../resource_permissions_multiselect";
```

Este archivo se hookea automáticamente dentro del pack `decidim_admin`, con acceso al jQuery ya inicializado por Decidim. No hace falta exponer jQuery globalmente.

El header del admin queda igual que el original de Decidim:
```erb
<%= stylesheet_pack_tag "decidim_core", "decidim_admin", media: "all" %>
<%= javascript_pack_tag "decidim_core", "decidim_admin", defer: false %>
```

El entrypoint `decidim_admin_select2.js` fue eliminado — no tenía referencias en vistas ni config, y el manifest no lo registraba.

---

## Migración select2 → tom-select ✅

### Contexto

El componente de permisos de recursos usaba `select2 4.1.0-beta.1` para el multiselect de zonas en `census_authorization_handler`. Esta versión estaba rota con webpack/webpacker y causaba errores en el build.

`tom-select ^2.2.2` ya estaba en `package.json` — no requirió instalar nada nuevo. Es compatible con webpack, no depende de jQuery y tiene paridad funcional con select2 para este caso de uso.

### Archivos modificados

- `app/packs/src/resource_permissions_multiselect.js` — reescrito completo
- `app/packs/src/decidim/admin/application.js` — cambio de import CSS
- `package.json` — eliminado select2

### Cambios concretos

**`application.js`:**
```js
// Antes:
import "../../../stylesheets/select2.css";
// Después:
import "tom-select/dist/css/tom-select.default.css";
```

**`package.json`:** eliminada la línea `"select2": "4.1.0-beta.1"` de dependencies.

**`resource_permissions_multiselect.js`:** reescrito sin jQuery. Lógica principal:

- Selector: `input[id*='authorization_handlers_options'][id*='zones']` — Rails genera un `input type="text"`, no un `<select>`
- El JS crea un `<select multiple>` dinámico, convierte el input original a `hidden` y sincroniza los valores via `onChange`
- `preload: true` — carga la lista completa de zonas al abrir, igual que hacía select2 con query vacía
- Endpoint `/admin/galdakao/zones` sin parámetros devuelve todas las zonas; con `?q=` filtra; con `?ids=` carga valores iniciales
- Guard de doble inicialización via `input.dataset.tsInitialized` **y** `input.closest(".ts-wrapper")` — este segundo guard es crítico (ver bug resuelto abajo)
- Al marcar el checkbox `census_authorization_handler` se llama `initAllSelects(true)` que abre el dropdown automáticamente tras inicializar

### Bug resuelto: doble inicialización de tom-select ✅

**Síntoma:** el dropdown aparecía anidado dentro de sí mismo — un `.ts-wrapper` dentro de otro `.ts-wrapper`, con dos instancias activas y el dropdown interior visualmente recortado.

**Causa raíz:** tom-select genera internamente un `<input type="hidden">` dentro del `.ts-control`. El selector `input[id*='authorization_handlers_options'][id*='zones']` lo encontraba en la segunda pasada de `initAllSelects` (disparada por el evento `change` del checkbox) e inicializaba tom-select sobre él de nuevo. El guard `input.dataset.tsInitialized` no era suficiente porque ese atributo no estaba presente en el input interno generado por tom-select.

**Estructura DOM errónea (antes del fix):**
```
.ts-wrapper                      ← instancia exterior
  .ts-control
    input[interno de tom-select]  ← era seleccionado por el SELECTOR
    .ts-wrapper                   ← instancia interior (segunda init)
      .ts-control
        ...items...
      .ts-dropdown                ← dropdown interior, recortado
  .ts-dropdown                    ← dropdown exterior (display:none)
```

**Fix aplicado — dos cambios en `resource_permissions_multiselect.js`:**

1. En `initAllSelects`, añadir como primera guarda:
```js
if (input.closest(".ts-wrapper")) return;
```

2. En `initCensusZonesSelect`, eliminar:
```js
// ← línea eliminada:
select.dataset.tsInitialized = "1";
```

### Estado final — `app/packs/src/resource_permissions_multiselect.js`

```javascript
import TomSelect from "tom-select";

const URL_ZONES = "/admin/galdakao/zones";

const SELECTOR = "input[id*='authorization_handlers_options'][id*='zones']";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

const initCensusZonesSelect = (input) => {
  if (input.dataset.tsInitialized) return;
  input.dataset.tsInitialized = "1";

  const existingValues = input.value ? input.value.split(",").filter(Boolean) : [];

  const select = document.createElement("select");
  select.multiple = true;
  select.name = input.name;
  select.id = input.id + "_ts";

  input.type = "hidden";
  input.parentNode.insertBefore(select, input.nextSibling);

  const ts = new TomSelect(select, {
    plugins: ["remove_button", "clear_button"],
    valueField: "id",
    labelField: "text",
    searchField: "text",
    preload: true,
    maxOptions: 200,
    load(query, callback) {
      fetch(`${URL_ZONES}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => callback(json.results || json))
        .catch(() => callback());
    },
    render: {
      option: (data, escape) => `<div>${escape(data.text)}</div>`,
      item:   (data, escape) => `<div>${escape(data.text)}</div>`,
      no_results: () => `<div class="no-results">No se han encontrado resultados</div>`
    },
    onInitialize() {
      if (existingValues.length === 0) return;
      fetch(`${URL_ZONES}?ids=${existingValues.join(",")}`, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => {
          const items = json.results || json;
          items.forEach((item) => {
            this.addOption({ id: String(item.id), text: item.text });
            this.addItem(String(item.id), true);
          });
          this.refreshItems();
        })
        .catch(() => {});
    },
    onChange(values) {
      input.value = values.join(",");
    }
  });

  return ts;
};

const initAllSelects = (openAfter = false) => {
  document.querySelectorAll(SELECTOR).forEach((input) => {
    if (input.closest(".ts-wrapper")) return;
    if (input.dataset.tsInitialized) return;

    const ts = initCensusZonesSelect(input);
    if (openAfter && ts) {
      setTimeout(() => ts.open(), 100);
    }
  });
};

document.addEventListener("DOMContentLoaded", () => {
  initAllSelects(false);

  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      setTimeout(() => initAllSelects(true), 50);
    }
  });
});
```

---

## Hoja de ruta: rediseño del modelo de zonas

### Contexto

El modelo inicial (`galdakao_zones`) solo soportaba una calle con un rango por zona. Galdakao necesita zonas con múltiples calles, donde una misma calle puede pertenecer a varias zonas con rangos de portales distintos (calles frontera entre zonas).

### Diseño de datos final

```
galdakao_zones
  id, name, decidim_organization_id

galdakao_zone_streets
  id, zone_id, street_id, numbers_constraint, numbers_range
```

Una zona tiene N entradas calle+rango. La misma calle puede aparecer en varias zonas con rangos distintos.

---

### Paso 1 — Migración de base de datos ✅

**Proceso ejecutado:**

1. Bajar la migración original:
```bash
docker compose exec app rails db:migrate:down VERSION=20260428000002
```

2. Reescribir `db/migrate/20260428000002_create_galdakao_zones.rb`:
```ruby
class CreateGaldakaoZones < ActiveRecord::Migration[7.0]
  def change
    create_table :galdakao_zones do |t|
      t.references :decidim_organization, null: false, index: true
      t.string     :name, null: false
      t.timestamps
    end

    create_table :galdakao_zone_streets do |t|
      t.references :zone,   null: false, foreign_key: { to_table: :galdakao_zones }, index: true
      t.references :street, null: false, index: true
      t.integer    :numbers_constraint, default: 0, null: false
      t.string     :numbers_range
      t.timestamps
    end
  end
end
```

3. Copiar al contenedor y migrar. El migrate falló en bucle porque el registro quedó marcado como ejecutado tras crear solo la primera tabla. Solución:
```bash
docker compose exec app rails runner "ActiveRecord::Base.connection.execute(\"DELETE FROM schema_migrations WHERE version = '20260428000002'\")"
docker compose exec app rails db:migrate
```

**Resultado:** Tres tablas activas en BD:
- `galdakao_streets` — calles del municipio (preexistente)
- `galdakao_zones` — zonas (id, nombre, organización)
- `galdakao_zone_streets` — relación zona↔calle con constraint y rango de portales

---

### Paso 2 — Modelos Ruby ✅

**`app/models/galdakao_zone.rb`:**
```ruby
class GaldakaoZone < ApplicationRecord
  belongs_to :organization,
             foreign_key: "decidim_organization_id",
             class_name: "Decidim::Organization"
  has_many :zone_streets,
           class_name: "GaldakaoZoneStreet",
           foreign_key: :zone_id,
           dependent: :destroy
  has_many :streets, through: :zone_streets, class_name: "GaldakaoStreet"

  validates :name, presence: true
end
```

**`app/models/galdakao_zone_street.rb`:**
```ruby
# frozen_string_literal: true
class GaldakaoZoneStreet < ApplicationRecord
  RANGE_REGEXP = /\A\d+(-\d+)?(,\d+(-\d+)?)*\z/.freeze

  belongs_to :zone, class_name: "GaldakaoZone"
  belongs_to :street, class_name: "GaldakaoStreet"

  enum numbers_constraint: {
    all_numbers:  0,
    odd_numbers:  1,
    even_numbers: 2,
    only_range:   3,
    except_range: 4
  }

  RANGE_REQUIRED = %w[only_range except_range].freeze

  validates :street, :numbers_constraint, presence: true
  validates :numbers_range,
            presence: true,
            if: ->(zs) { zs.numbers_constraint.in?(RANGE_REQUIRED) }
  validates :numbers_range,
            format: { with: GaldakaoZoneStreet::RANGE_REGEXP },
            if: ->(zs) { zs.numbers_range.present? }
end
```

---

### Paso 3 — Admin: CRUD de zonas y calles ✅

Flujo en dos niveles: primero se crea la zona con nombre, luego desde su detalle se gestionan las calles una a una.

**Archivos creados/modificados:**

- `app/forms/decidim/admin/galdakao_zone_form.rb` — solo atributo `name`
- `app/forms/decidim/admin/galdakao_zone_street_form.rb` — `street_id`, `numbers_constraint`, `numbers_range`
- `app/commands/decidim/admin/create_galdakao_zone.rb` — crea zona con nombre
- `app/commands/decidim/admin/update_galdakao_zone.rb` — actualiza nombre, recibe zona como parámetro
- `app/commands/decidim/admin/create_galdakao_zone_street.rb` — crea entrada calle+rango en una zona
- `app/commands/decidim/admin/update_galdakao_zone_street.rb` — actualiza entrada calle+rango
- `app/controllers/decidim/admin/zones_controller.rb` — CRUD de zonas + acción `show`
- `app/controllers/decidim/admin/zone_streets_controller.rb` — CRUD de calles de una zona
- `app/views/decidim/admin/zones/` — index, show, new, edit, _form
- `app/views/decidim/admin/zone_streets/` — new, edit, _form
- `config/routes.rb` — `zone_streets` anidado dentro de `zones`

**`app/forms/decidim/admin/galdakao_zone_street_form.rb`:**
```ruby
# frozen_string_literal: true
module Decidim
  module Admin
    class GaldakaoZoneStreetForm < Form
      mimic :galdakao_zone_street

      attribute :street_id,           Integer
      attribute :numbers_constraint,  String, default: "all_numbers"
      attribute :numbers_range,       String

      validates :street_id, :numbers_constraint, presence: true
      validates :numbers_range,
                presence: true,
                if: ->(form) { form.numbers_constraint.in?(GaldakaoZoneStreet::RANGE_REQUIRED) }
      validates :numbers_range,
                format: { with: GaldakaoZoneStreet::RANGE_REGEXP },
                if: ->(form) { form.numbers_range.present? }

      def numbers_constraint_options
        {
          "Todos los números"          => "all_numbers",
          "Números pares"              => "even_numbers",
          "Números impares"            => "odd_numbers",
          "Solo estos portales"        => "only_range",
          "Todos menos estos portales" => "except_range"
        }
      end
    end
  end
end
```

**`app/views/decidim/admin/zone_streets/_form.html.erb`:** el campo `numbers_range` se muestra u oculta via JS según el constraint — solo visible cuando es `only_range` o `except_range`, y en esos casos es obligatorio.

**Pendiente menor:**
- [ ] Traducir valores del enum `numbers_constraint` al castellano en las vistas (actualmente muestra `all_numbers`, `even_numbers`, `odd_numbers`)

---

### Paso 3b — Refactor constraints de portales ✅

El modelo inicial solo soportaba tres constraints. Se añadieron `only_range` y `except_range` y se amplió el formato de rango para aceptar combinaciones mixtas.

**Diseño final de constraints:**

| Valor | Integer en BD | Descripción | ¿Requiere rango? |
|---|---|---|---|
| `all_numbers`  | 0 | Todos los portales | No |
| `odd_numbers`  | 1 | Solo impares | No |
| `even_numbers` | 2 | Solo pares | No |
| `only_range`   | 3 | Solo estos portales | Sí |
| `except_range` | 4 | Todos menos estos | Sí |

No requiere migración — el enum es un integer en BD y los nuevos valores (3 y 4) se añaden sin tocar los existentes.

**Formato de rango flexible** — acepta cualquier combinación de números sueltos y rangos:
```
1          → portal suelto
1-50       → rango continuo
2,4,6,8    → lista de sueltos
1,5-9,11,13 → mezcla
3,5-8,12,24 → mezcla
```

**Caso de uso típico — calle frontera:** una calle cuyos portales `3,5-8,12,24` pertenecen a Zona 1 y el resto a Zona 2:
- Zona 1 → constraint `only_range`, rango `3,5-8,12,24`
- Zona 2 → constraint `except_range`, rango `3,5-8,12,24`

La calle queda cubierta al 100% entre las dos zonas sin solapamiento ni huecos.

---

### Paso 4 — Authorizer: lógica de verificación ✅

**`app/services/census_action_authorizer.rb`:**
```ruby
class CensusActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
  def authorize
    return [:missing, { action: :authorize }] if authorization.blank?
    return [:ok, {}] if zones.blank?
    return [:unauthorized, {}] if authorization_street.blank? || authorization_number.blank?
    @fields = { street: authorization_street, street_number: authorization_number }
    return [:ok, {}] if belongs_to_zone?
    [:unauthorized, { fields: @fields }]
  end

  private

  def zones
    options["zones"]
  end

  def authorization_street
    authorization.metadata["street"]
  end

  def authorization_number
    authorization.metadata["street_number"]
  end

  def belongs_to_zone?
    GaldakaoZoneStreet
      .joins(:street)
      .where(zone_id: zones.split(","))
      .find_each do |zone_street|
        if street_valid?(zone_street)
          @fields.except!(:street)
          return true if number_valid?(zone_street)
        end
      end
    false
  end

  def street_valid?(zone_street)
    authorization_street == zone_street.street&.name
  end

  def parse_range(numbers_range)
    numbers_range.split(",").flat_map do |segment|
      if segment.include?("-")
        a, b = segment.split("-")
        (a.to_i..b.to_i).to_a
      else
        segment.to_i
      end
    end
  end

  def number_valid?(zone_street)
    passes_constraint = case zone_street.numbers_constraint
                        when "even_numbers" then authorization_number.even?
                        when "odd_numbers"  then authorization_number.odd?
                        else true
                        end
    return false unless passes_constraint
    return true if zone_street.numbers_range.blank?

    portal_list = parse_range(zone_street.numbers_range)

    case zone_street.numbers_constraint
    when "except_range" then !portal_list.include?(authorization_number)
    else                     portal_list.include?(authorization_number)
    end
  end

  def manifest
    Decidim.authorization_handlers.find { |m| m.name == "census_authorization_handler" }
  end
end
```

---

### Paso 5 — Tests y verificación del flujo completo

- [ ] Crear zonas de prueba con el nuevo formulario (varias calles por zona, calles repetidas con rangos distintos)
- [ ] Asignar zonas a un permiso de componente
- [ ] Autorizar usuario con padrón y verificar que el authorizer resuelve correctamente
- [ ] Probar caso de calle frontera: misma calle, portales en zonas distintas
- [ ] Probar usuario no empadronado en ninguna zona asignada → debe devolver `:unauthorized`

---

## API SOAP y handler de autorización

### API SOAP ✅

El endpoint `autenticar` devuelve calle y portal del ciudadano:

```xml
<autenticarResponse>
  <autenticarResult>true</autenticarResult>
  <calle>Calle Mayor</calle>
  <portal>14</portal>
</autenticarResponse>
```

Modelo de respuesta en Spyne (Python):
```python
class AutenticarResult(ComplexModel):
    autenticarResult = Boolean
    calle = Unicode
    portal = Unicode  # se convierte a Integer en Ruby con .to_i
```

- [x] Actualizar API SOAP para devolver `<portal>`
- [x] Actualizar handler para leer `street` y `street_number` de la respuesta

## Mensajes de autorización — limpieza ✅

### Problema

El mensaje de no autorizado mostraba los datos del usuario (`street_number: 6`) exponiendo información personal y dando pistas sobre los criterios de verificación.

### Solución

El `CensusActionAuthorizer` dejó de devolver `fields` con valores del usuario. El return de no autorizado queda como:

```ruby
[:unauthorized, {}]
```

Decidim muestra su mensaje genérico "Lo sentimos, no puedes realizar esta acción porque algunos de tus datos de autorización no coinciden." sin exponer ningún dato del usuario.

### Intentos fallidos

- `extra_explanation` con string via `I18n.t` → `TypeError: no implicit conversion of Symbol into Integer` en `authorization_modal_cell.rb` — la cell espera un hash, no un string.
- `extra_explanation` con hash `{ key:, params: }` → muestra la key en crudo (`Not In Zone`) sin resolver el locale.

### Pendiente para fase de traducciones

- [ ] Investigar la estructura exacta que espera `authorization_modal_cell` para `extra_explanation` y añadir mensaje personalizado con locale
- [ ] El texto genérico de Decidim "algunos de tus datos de autorización no coinciden" viene de core — requiere override de la cell para cambiarlo
- [ ] Auditar todos los textos hardcodeados en vistas ERB, helpers, commands y authorizers
- [ ] Mover todos los textos al locale `config/locales/es.yml` bajo la estructura `decidim.admin.galdakao`
- [ ] Crear `config/locales/eu.yml` (euskera) con las mismas claves
- [ ] Verificar que los textos del enum `numbers_constraint` en vistas usan I18n y no el valor Ruby en crudo
- [ ] Revisar mensajes de error de formularios (create/update de zonas y zone_streets)

### CensusAuthorizationHandler — metadata ✅

El método `metadata` pasó del formato antiguo (campo `streets` como array) al nuevo con `street` y `street_number`:

```ruby
# ANTES
streets: [response&.xpath("//autenticarResult/calle")&.text&.strip].compact.reject(&:empty?)

# DESPUÉS
street:        response&.xpath("//autenticarResult/calle")&.text&.strip,
street_number: response&.xpath("//autenticarResult/portal")&.text&.strip&.to_i
```

Los registros existentes con formato antiguo no se migran — requieren revocar y volver a pasar el flujo de verificación.

---

## Notas RGPD

- `street_number` se guarda en `decidim_authorizations.metadata` junto con `street` — dato personal de empadronamiento → misma base legal ya documentada (art. 6.1.e RGPD).
- La tabla `galdakao_zones` y `galdakao_zone_streets` solo contienen nombres de calles y rangos de números, sin datos personales.
- Los metadatos de autorización se borran si el usuario revoca su autorización en Decidim.

---

## Mensajes de autorización — limpieza y locale ✅

### Problema

El mensaje de no autorizado mostraba los datos del usuario (`street_number: 6`) exponiendo información personal y dando pistas sobre los criterios de verificación.

### Solución

El `CensusActionAuthorizer` dejó de devolver `fields` con valores del usuario y pasó a usar `extra_explanation` con clave de traducción:

```ruby
[:unauthorized, { extra_explanation: { key: "not_in_zone", params: { scope: "census_authorization_handler" } } }]
```

La clave se añadió al locale `config/locales/es.yml`:

```yaml
es:
  decidim:
    authorization_handlers:
      census_authorization_handler:
        not_in_zone: "No cumples los requisitos de participación para este proceso."
```

El usuario ve únicamente el mensaje genérico, sin datos propios ni pistas sobre los criterios.

---

## Pendiente: revisión completa de textos y multiidioma

- [ ] Auditar todos los textos hardcodeados en vistas ERB, helpers, commands y authorizers
- [ ] Mover todos los textos al locale `config/locales/es.yml` bajo la estructura `decidim.admin.galdakao`
- [ ] Crear `config/locales/eu.yml` (euskera) con las mismas claves
- [ ] Verificar que los textos del enum `numbers_constraint` en vistas usan I18n y no el valor Ruby en crudo
- [ ] Revisar mensajes de error de formularios (create/update de zonas y zone_streets)
- [ ] Revisar mensajes del authorizer y handler para que ningún texto vaya hardcodeado