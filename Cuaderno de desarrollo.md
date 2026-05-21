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
class GaldakaoZoneStreet < ApplicationRecord
  RANGE_REGEXP = /(\A\d+(-(\d+)*)\z)|(\A[\d+(,\d)*]+\z)/.freeze

  belongs_to :zone, class_name: "GaldakaoZone"
  belongs_to :street, class_name: "GaldakaoStreet"

  enum numbers_constraint: { all_numbers: 0, odd_numbers: 1, even_numbers: 2 }

  validates :street, :numbers_constraint, presence: true
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

**Pendiente menor:**
- [ ] Traducir valores del enum `numbers_constraint` al castellano en las vistas (actualmente muestra `all_numbers`, `even_numbers`, `odd_numbers`)

---

### Paso 4 — Authorizer: lógica de verificación

El authorizer debe trabajar sobre `GaldakaoZoneStreet` en lugar de `GaldakaoZone` directamente.

- [ ] Reescribir `belongs_to_zone?` en `CensusActionAuthorizer` para iterar sobre `GaldakaoZoneStreet.where(zone_id: zones_ids)`
- [ ] Adaptar `street_valid?` y `number_valid?` para trabajar sobre `GaldakaoZoneStreet`
- [ ] Verificar que el campo `zones` que llega en `options` sigue siendo lista de IDs de zona (no cambia)

---

### Paso 5 — Tests y verificación del flujo completo

- [ ] Crear zonas de prueba con el nuevo formulario (varias calles por zona, calles repetidas con rangos distintos)
- [ ] Asignar zonas a un permiso de componente
- [ ] Autorizar usuario con padrón y verificar que el authorizer resuelve correctamente
- [ ] Probar caso de calle frontera: misma calle, portales en zonas distintas
- [ ] Probar usuario no empadronado en ninguna zona asignada → debe devolver `:unauthorized`

---

## Cambios en el API SOAP

El endpoint `autenticar` debe pasar a devolver también el número de portal:

```xml
<autenticarResponse>
  <autenticarResult>true</autenticarResult>
  <calle>Calle Mayor</calle>
  <portal>14</portal>
</autenticarResponse>
```

Si usas Spyne (Python), el modelo de respuesta necesita añadir el campo `portal`:

```python
class AutenticarResponse(ComplexModel):
    autenticarResult = Boolean
    calle = Unicode
    portal = Unicode  # se parsea como string y se convierte a Integer en Ruby
```

El método `metadata` del handler pasa de:
```ruby
# ANTES
streets: [response&.xpath("//autenticarResult/calle")&.text&.strip].compact.reject(&:empty?)
```
a:
```ruby
# DESPUÉS — xpath un nivel extra por Spyne, confirmado con curl
street:        response&.xpath("//autenticarResult/calle")&.text&.strip,
street_number: response&.xpath("//autenticarResult/portal")&.text&.strip&.to_i
```

- [x] Actualizar API SOAP para devolver `<portal>`

---

## Notas RGPD

- `street_number` se guarda en `decidim_authorizations.metadata` junto con `street` — dato personal de empadronamiento → misma base legal ya documentada (art. 6.1.e RGPD).
- La tabla `galdakao_zones` y `galdakao_zone_streets` solo contienen nombres de calles y rangos de números, sin datos personales.
- Los metadatos de autorización se borran si el usuario revoca su autorización en Decidim.