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

El entrypoint `decidim_admin_select2.js` fue eliminado.

---

## Migración select2 → tom-select ✅

### Contexto

El componente de permisos de recursos usaba `select2 4.1.0-beta.1` para el multiselect de zonas en `census_authorization_handler`. Esta versión estaba rota con webpack/webpacker y causaba errores en el build.

`tom-select ^2.2.2` ya estaba en `package.json` — no requirió instalar nada nuevo.

### Archivos modificados

- `app/packs/src/resource_permissions_multiselect.js` — reescrito completo
- `app/packs/src/decidim/admin/application.js` — cambio de import CSS
- `package.json` — eliminado select2

### Bug resuelto: doble inicialización de tom-select ✅

**Síntoma:** el dropdown aparecía anidado dentro de sí mismo.

**Fix:** añadir como primera guarda en `initAllSelects`:
```js
if (input.closest(".ts-wrapper")) return;
```

### Bug resuelto: onChange no sincronizaba múltiples valores ✅

**Síntoma:** al guardar con varias zonas seleccionadas, el servidor recibía solo un ID.

**Solución:** usar `this.items` directamente:
```js
onChange() {
  input.value = this.items.join(",");
}
```

**Commit:** `0dc4b92c Fix OnChange for multiselect`

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
          input.value = this.items.join(",");
        })
        .catch(() => {});
    },
    onChange() {
      input.value = this.items.join(",");
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

### Diseño de datos final

```
galdakao_zones
  id, name, decidim_organization_id

galdakao_zone_streets
  id, zone_id, street_id, numbers_constraint, numbers_range
```

### Paso 1 — Migración de base de datos ✅

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

### Paso 2 — Modelos Ruby ✅

`GaldakaoZone` y `GaldakaoZoneStreet` con enum `numbers_constraint` (all_numbers, odd_numbers, even_numbers, only_range, except_range) y validaciones de rango.

### Paso 3 — Admin: CRUD de zonas y calles ✅

Flujo en dos niveles: zona con nombre → gestión de calles desde su detalle.

### Paso 3b — Refactor constraints de portales ✅

| Valor | Descripción | ¿Requiere rango? |
|---|---|---|
| `all_numbers`  | Todos los portales | No |
| `odd_numbers`  | Solo impares | No |
| `even_numbers` | Solo pares | No |
| `only_range`   | Solo estos portales | Sí |
| `except_range` | Todos menos estos | Sí |

Formato de rango acepta combinaciones: `1`, `1-50`, `2,4,6`, `1,5-9,11`.

### Paso 4 — Authorizer: lógica de verificación ✅

`app/services/census_action_authorizer.rb` — verifica que el domicilio del ciudadano pertenece a alguna de las zonas asignadas al permiso del componente.

### Paso 5 — Tests y verificación del flujo completo ✅

- [x] Crear zonas de prueba con el nuevo formulario
- [x] Asignar zonas a un permiso de componente
- [x] Autorizar usuario con padrón y verificar que el authorizer resuelve correctamente
- [x] Probar caso de calle frontera
- [x] Probar usuario no empadronado en ninguna zona asignada → `:unauthorized`

---

## Bug resuelto: bucle infinito en flujo de onboarding con zona no autorizada ✅

### Síntoma

Cuando un usuario sin sesión intenta una acción restringida por zona, se loguea y se verifica correctamente en el padrón pero su domicilio no pertenece a la zona asignada, Decidim entra en un bucle infinito mostrándole el formulario de verificación indefinidamente.

### Causa raíz

Dos problemas encadenados en Decidim core (sin fix oficial a mayo 2026, confirmado en v0.26.2, v0.28.0.dev y v0.30.4):

**Problema 1 — `AuthorizationStatus#current_path`:** para el código `:unauthorized`, `pending?` es `false`, así que llama a `root_path` del handler — que es el formulario de autorización. Debería devolver `nil`.

**Problema 2 — `onboarding_pending`:** no gestiona explícitamente el caso "autorizado pero sin permiso de zona" antes de evaluar `single_authorization_required?`, causando que el flujo redirija al componente destino que a su vez rechaza al usuario y lo manda de vuelta al formulario.

### Solución — monkey patch en `config/initializers/decidim_patches.rb`

```ruby
Rails.application.config.after_initialize do
  Decidim::ActionAuthorizer::AuthorizationStatus.class_eval do
    def current_path(redirect_url: nil)
      return nil if unauthorized?
      return unless @authorization_handler
      if pending?
        @authorization_handler.resume_authorization_path(redirect_url:)
      else
        @authorization_handler.root_path(redirect_url:)
      end
    end
  end

  Decidim::Verifications::AuthorizationsController.class_eval do
    def onboarding_pending
      return redirect_back(fallback_location: decidim_verifications.authorizations_path) unless onboarding_manager.valid?

      authorizations = action_authorized_to(onboarding_manager.action, **onboarding_manager.action_authorized_resources)
      authorization_status = authorizations.global_code

      if authorization_status == :unauthorized
        flash[:alert] = t("census_authorization_handler.unauthorized_zone", scope: "decidim.authorization_handlers")
        redirect_path = onboarding_manager.component_path || onboarding_manager.finished_redirect_path || decidim.root_path
        clear_onboarding_data!(current_user)
        return redirect_to redirect_path
      end

      if authorizations.single_authorization_required?
        flash.keep
        return redirect_to(authorizations.statuses.first.current_path(redirect_url: decidim_verifications.onboarding_pending_authorizations_path))
      end

      return unless onboarding_manager.finished_verifications?(active_authorization_methods) || authorization_status == :unauthorized

      clear_onboarding_data!(current_user)
      redirect_to onboarding_manager.finished_redirect_path
    end

    private

    def active_authorization_methods
      Decidim::Verifications::Authorizations.new(organization: current_organization, user: current_user, granted: true).query.pluck(:name)
    end
  end
end
```

### Resultado

El usuario es redirigido a la lista del componente con el mensaje "Tu domicilio no está incluido en las zonas habilitadas para participar en este proceso." (texto provisional — pendiente de validar con el técnico de participación).

**Commit:** `8a9af87a Fix onboarding loop unauthorized zone + locale message + decidim patches initializer`

**Issue upstream:** https://github.com/decidim/decidim/issues/9826

---

## API SOAP y handler de autorización ✅

El endpoint `autenticar` devuelve calle y portal del ciudadano. El handler guarda `street` y `street_number` en los metadatos de la autorización.

---

## Mensajes de autorización ✅

La clave `decidim.authorization_modals.content.unauthorized.explanation` en `es_census_authorizer_galdakao.yml` personaliza el mensaje del modal para todas las autorizaciones de la instalación (intencionado).

La clave `decidim.authorization_handlers.census_authorization_handler.unauthorized_zone` personaliza el mensaje del flash específico del flujo de onboarding con zona no autorizada.

---

## Notas RGPD

- `street_number` se guarda en `decidim_authorizations.metadata` junto con `street` — dato personal de empadronamiento → misma base legal ya documentada (art. 6.1.e RGPD).
- Las tablas `galdakao_zones` y `galdakao_zone_streets` no contienen datos personales.
- Los metadatos de autorización se borran si el usuario revoca su autorización en Decidim.

---

## Paso 6 — Accesos a gestión de calles y zonas en el panel de autorizaciones ✅

### Objetivo

Añadir accesos directos a las secciones de gestión de **calles** (`/admin/galdakao`) y **zonas** (`/admin/galdakao/zones`) desde el panel de métodos de verificación (`/admin/authorization_workflows`), evitando que el administrador tenga que conocer las URLs de memoria.

### Contexto y discovery

La vista que renderiza la tabla de métodos de verificación **no está en `decidim-verifications`** sino en **`decidim-admin`**:

```
/usr/local/bundle/bundler/gems/decidim-8b1b21b88b86/decidim-admin/
  app/views/decidim/admin/authorization_workflows/index.html.erb
```

Los `view_paths` de Rails en este entorno son:

```
/app/app/views          ← volumen montado desde /opt/decidim_production/app/views
/usr/local/bundle/...   ← gems
```

> **Importante:** Cualquier sobreescritura de vistas debe ir en `/app/app/views`, no en `/app/views`. Las copias a `/app/views` son ignoradas por Rails.

### Helpers de ruta relevantes

| Enlace | Helper | Ruta |
|--------|--------|------|
| Calles (sincronización) | `decidim_admin.galdakao_index_path` | `/admin/galdakao` |
| Zonas (gestión) | `decidim_admin.galdakao_zones_path` | `/admin/galdakao/zones` |

> Las dos secciones son independientes: **Calles** gestiona la sincronización del listado desde la API SOAP; **Zonas** gestiona el modelo de zonas y sus calles asociadas (CRUD completo). No son la misma cosa aunque las zonas tengan calles anidadas.

### Solución

Sobreescritura de la vista original del gem, añadiendo una tercera columna **"Gestión"** con los dos enlaces, condicionada al handler `census_authorization_handler`.

### Procedimiento de despliegue

Las vistas ERB se sirven desde el volumen montado — **no requieren rebuild de imagen**. Sin embargo, con `cache_template_loading: true` (producción), Rails cachea las vistas en memoria al arrancar. Cualquier cambio en una vista requiere restart:

```bash
docker compose restart app
```

### Lecciones aprendidas

- **No presuponer, comprobar primero.** Antes de escribir cualquier archivo, verificar `view_paths` y la estructura real del contenedor.
- **No presuponer las rutas.** Las calles y las zonas son secciones independientes con rutas propias.
- Confirmar `cache_template_loading` antes de asumir que un cambio de vista se sirve sin restart.

**Commit:** `e30d5875 Add Calles and Zonas management links to authorization workflows admin panel`

---

## Paso 7 — Auditoría i18n y unificación de locales ✅

### Objetivo

- Inventariar todos los textos hardcodeados en controladores, vistas y servicios del módulo Galdakao.
- Sustituirlos por llamadas `t()` con claves i18n.
- Unificar todos los archivos de locale dispersos en un único archivo por idioma, específico del módulo.

### Estado inicial — archivos de locale existentes

| Archivo | Acción |
|---------|--------|
| `es.yml` | No se toca — ver tarea futura |
| `eu.yml` | No se toca |
| `en.yml` | No se toca |
| `es_streets.yml` | Eliminado — absorbido en el nuevo yml |
| `es_zones.yml` | Eliminado — absorbido en el nuevo yml |
| `eu_streets.yml` | Eliminado — absorbido en el nuevo yml |
| `census-soap-es.yml` | Eliminado — absorbido en el nuevo yml |

#### Por qué `census-soap-es.yml` pertenece aquí

El handler `census_authorization_handler.rb` llama directamente a esas claves con `I18n.t("census_authorization_handler.service_unavailable")` etc. El repo de la API SOAP devuelve XML y no necesita locales. Las claves pertenecen al autorizador de este proyecto.

#### Por qué no se tocan `es.yml`, `eu.yml` ni `en.yml`

Rails fusiona todos los YML del mismo idioma al arrancar. Si la misma clave aparece en dos archivos, el último que carga gana sin dar ningún error — comportamiento silencioso e impredecible. La limpieza de los yml base es una operación atómica separada (ver tarea futura).

### Resultado — archivos de locale tras la unificación

```
config/locales/
  es.yml                              ← no tocado
  eu.yml                              ← no tocado
  en.yml                              ← no tocado
  es_census_authorizer_galdakao.yml   ← nuevo, absorbe todo el ES
  eu_census_authorizer_galdakao.yml   ← nuevo, absorbe todo el EU
  en_census_authorizer_galdakao.yml   ← nuevo, derivado del ES
```

### Criterio de nombrado

`<idioma>_census_authorizer_galdakao.yml` — quien trabaja las traducciones del módulo va directo a su archivo, sin interferir con el `es.yml` general de Decidim.

### Inventario completo de textos hardcodeados resueltos

#### Controladores

| Archivo | Texto | Clave |
|---------|-------|-------|
| `galdakao_controller.rb` | `"Calles sincronizadas correctamente."` | `decidim.admin.galdakao.sync.success` |
| `zones_controller.rb` | `"Nueva zona creada correctamente"` | `decidim.admin.galdakao.zones.create.success` |
| `zones_controller.rb` | `"Error al crear la zona: #{error}"` | `decidim.admin.galdakao.zones.create.error` (con `%{error}`) |
| `zones_controller.rb` | `"Zona actualizada correctamente"` | `decidim.admin.galdakao.zones.update.success` |
| `zones_controller.rb` | `"Error al actualizar la zona: #{error}"` | `decidim.admin.galdakao.zones.update.error` (con `%{error}`) |
| `zones_controller.rb` | `"Zona eliminada correctamente"` | `decidim.admin.galdakao.zones.destroy.success` |

#### Vistas

| Vista | Textos | Claves |
|-------|--------|--------|
| `authorization_workflows/index.html.erb` | "Gestión", "Calles", "Zonas" | `authorization_workflows.management`, `streets.title`, `zones.index.title` |
| `zone_streets/_form.html.erb` | labels, select blank, help, submit, cancel | `decidim.admin.galdakao.zone_streets.form.*` |
| `zones/_form.html.erb` | label nombre, submit, cancel | `decidim.admin.galdakao.zones_form.*` |
| `zones/index.html.erb` | título, botones, columnas, confirm | `decidim.admin.galdakao.zones_index.*` |
| `zones/show.html.erb` | botones, cabeceras tabla, "Todos" | `decidim.admin.galdakao.zones_show.*` |

#### Verificación final

```bash
grep -rn --include="*.erb" /opt/decidim_production/app/views/decidim/admin/ | \
  grep -v 't("' | grep -v "t('" | \
  grep -E '(["'"'"'][A-ZÁÉÍÓÚÑ][a-záéíóúñ ]{3,}["'"'"'])' | \
  grep -v "confirm:" | grep -v "class:" | grep -v "placeholder:" | grep -v "data-"
# → LIMPIO ✅
```

### Commits

```
58ac6a95  i18n: sustituir hardcodes por t() en vistas zones y zone_streets
          (yml es/eu/en nuevos + zones_controller + 7 vistas)
```

Push confirmado: `83b63e24..58ac6a95 → alabs/feature/zone-verifications`

---
## Paso 8 — Rediseño visual y coherencia de vistas del módulo Galdakao ✅

### Objetivo

Unificar la estructura visual de todas las vistas del módulo (cabeceras, títulos, botones, labels, selectores, iconos de tabla) siguiendo los patrones nativos de Decidim, y mover a i18n todos los textos hardcodeados restantes en las vistas.

---

### Patrón visual adoptado

#### Cabecera de vista

Todas las vistas siguen el patrón nativo de Decidim descubierto en `decidim-admin/app/views/decidim/admin/users/index.html.erb`:

```erb
<div class="card">
  <div class="item_show__header">
    <h1 class="item_show__header-title">
      <%= t("...titulo") %>
      <%= link_to "...", ruta, class: "button button__sm button__secondary" %>
      <%= link_to ruta_atras, style: "..." do %>
        <%= icon "arrow-left-line", class: "fill-current" %>
        <span><%= t("...nav_button") %></span>
      <% end %>
    </h1>
  </div>
```

#### Antetítulo + título (vistas de formulario)

Las vistas con formulario añaden un antetítulo fijo encima del título dinámico:

```erb
<div style="display:flex;flex-direction:column;flex:1;">
  <span style="font-size:0.85rem;color:#666;font-weight:500;margin-bottom:0.25rem;">
    <%= t("decidim.admin.galdakao.zones_index.title") %>  <%# "Zonas de verificación" %>
  </span>
  <h1 class="item_show__header-title" style="margin:0;">
    <%= título dinámico %>
  </h1>
</div>
```

| Vista | Antetítulo | Título |
|-------|-----------|--------|
| `zones/index` | — | "Listado de zonas" |
| `zones/new` | "Zonas de verificación" | "Crear nueva zona" |
| `zones/edit` | "Zonas de verificación" | "Editando zona: \<nombre\>" |
| `zones/show` | — | nombre de la zona |
| `zone_streets/new` | "Zonas de verificación" | "Añadir calle a la zona: \<nombre\>" |
| `zone_streets/edit` | "Zonas de verificación" | "Editar calle de la zona: \<nombre\>" |

Los `h2` hardcodeados de `new.html.erb` y `edit.html.erb` (en `zones/` y `zone_streets/`) fueron eliminados — la cabecera se genera íntegramente desde el partial `_form`.

#### Tablas

Todas las tablas usan `class="table-list"` dentro de `<div class="table-scroll">`, con acciones en `<td class="table-list__actions">`.

#### Formularios

`decidim_form_for` con `html: { class: "form form-defaults" }`, botones en `item__edit-sticky > item__edit-sticky-container`.

---

### Botón de navegación jerárquica ("volver / cancelar")

Se investigó el paginador nativo de Decidim (`kaminari/decidim/_prev_page.html.erb`) para encontrar un estilo de botón secundario que se diferenciara visualmente de los botones de acción. Se determinó que Decidim no tiene clase `button__outline` ni similar.

**Solución adoptada:** style inline con `var(--secondary)` para adaptarse automáticamente al tema de la instancia, con hover JavaScript:

```erb
<%= link_to ruta,
    style: "display:inline-flex;align-items:center;gap:0.5rem;border:2px solid var(--secondary);color:var(--secondary);border-radius:4px;font-weight:600;padding:1.375px 10px;font-size:0.875rem;text-decoration:none;background:transparent;",
    onmouseover: "this.style.background='var(--secondary)';this.style.color='white'",
    onmouseout: "this.style.background='transparent';this.style.color='var(--secondary)'" do %>
  <%= icon "arrow-left-line", class: "fill-current" %>
  <span><%= t("...nav_button") %></span>
<% end %>
```

El padding `1.375px 10px` iguala el tamaño visual al de `button__sm` de Decidim (verificado con DevTools).

**Jerarquía de navegación y destino de cada botón:**

```
/admin/authorization_workflows  (Métodos de verificación)
    └── /admin/galdakao              → nav_button: "Volver a Métodos de verificación"
            ├── /admin/galdakao/streets  → nav_button: "Volver a Gestión del catálogo"
            └── /admin/galdakao/zones    → nav_button: "Volver a Métodos de verificación"
                    ├── zones/new        → cancel: volver a zones
                    ├── zones/show       → back: volver a zones
                    ├── zones/edit       → cancel: volver a zones
                    └── zone_streets/new|edit → cancel: volver a zones/:id
```

---

### Acciones en tabla — iconos sin texto

Se sustituyeron los botones de texto "Editar" / "Eliminar" de las tablas por `icon_link_to` siguiendo el patrón de `decidim-admin/app/views/decidim/admin/users/index.html.erb`:

```erb
<%= icon_link_to "edit-line", ruta_editar, t("...edit"), class: "action-icon" %>
<%= icon_link_to "delete-bin-line", ruta_borrar, t("...destroy"),
    class: "action-icon--remove",
    method: :delete,
    data: { confirm: t("...destroy_confirm") } %>
```

El icono lápiz en `zones/index` apunta a `zones/show` (no a `zones/edit`) porque el nombre se puede editar desde dentro de la vista de detalle.

---

### Labels de formulario — problema del doble label

`decidim_form_for` genera su propio `<label>` con el nombre del atributo en inglés (`Name`, `Street`, `Numbers constraint`). Al añadir `f.label` en el ERB se generaban dos labels superpuestos.

**Solución:** sustituir `f.label` por un `<label>` HTML manual con `for` explícito apuntando al mismo `id`, y pasar `label: false` al helper del campo (o simplemente omitir `f.label`).

---

### Selectores — padding y separación

Los `<select>` reciben style inline para separar el texto de la flecha nativa del navegador y del asterisco de campo obligatorio:

```
padding:3px 35px 3px 3px;margin-left:5px;
```

El padding derecho de 35px fue ajustado empíricamente hasta que la flecha del selector no tapara el texto en las opciones más largas.

Los `<div class="field">` llevan `margin-bottom:1rem` para separar los campos verticalmente.

---

### Opciones del selector `numbers_constraint` — traducción

Las opciones estaban hardcodeadas en castellano dentro del form object (`GaldakaoZoneStreetForm`). Se movieron a i18n:

```ruby
def numbers_constraint_options
  base = "decidim.admin.galdakao.zone_streets.form.numbers_constraint_options"
  {
    I18n.t("#{base}.all_numbers")  => "all_numbers",
    I18n.t("#{base}.even_numbers") => "even_numbers",
    I18n.t("#{base}.odd_numbers")  => "odd_numbers",
    I18n.t("#{base}.only_range")   => "only_range",
    I18n.t("#{base}.except_range") => "except_range"
  }
end
```

---

### Correcciones funcionales asociadas

- `CreateGaldakaoZoneStreet` y `UpdateGaldakaoZoneStreet` limpian `numbers_range` a `nil` cuando el tipo de restricción no lo requiere (`all_numbers`, `even_numbers`, `odd_numbers`), evitando basura en base de datos al cambiar de tipo.
- La columna "Restricción" en `zones/show` muestra el valor traducido (`t("...numbers_constraint_options.#{zs.numbers_constraint}")`) en lugar del nombre del enum Ruby.
- El placeholder del campo `numbers_range` se movió a i18n (`numbers_range_placeholder`).
- Los flash messages de `zone_streets_controller.rb` (create/update/destroy) se movieron a i18n.

---

### Claves i18n añadidas en esta fase

Bajo `decidim.admin.galdakao` en los tres yml (`es`, `eu`, `en`):

- `zones_index.list_title`, `zones_index.nav_button`
- `zones_form.title_new`, `zones_form.title_edit`, `zones_form.name_label`
- `zones_show.edit_zone` (→ "Editar nombre"), `zones_show.back`
- `zone_streets.form.title_new`, `zone_streets.form.title_edit`
- `zone_streets.form.numbers_constraint_options.*` (5 valores)
- `zone_streets.form.numbers_range_placeholder`
- `zone_streets.create.*`, `zone_streets.update.*`, `zone_streets.destroy.*`
- `index.nav_button`, `streets.nav_button` (en EU y EN, que faltaban)
- `index.section_sync.subtitle`, `index.section_catalog.subtitle` (en EU y EN)

---

### Archivos modificados

- `app/views/decidim/admin/galdakao/{index,streets}.html.erb`
- `app/views/decidim/admin/zones/{_form,index,show,new,edit}.html.erb`
- `app/views/decidim/admin/zone_streets/{_form,new,edit}.html.erb`
- `app/forms/decidim/admin/galdakao_zone_street_form.rb`
- `app/controllers/decidim/admin/zone_streets_controller.rb`
- `app/commands/decidim/admin/create_galdakao_zone_street.rb`
- `app/commands/decidim/admin/update_galdakao_zone_street.rb`
- `config/locales/{es,eu,en}_census_authorizer_galdakao.yml`


### Commits
Push confirmado: `8188ce2d..126471d7 → alabs/feature/zone-verifications`

---

## Pendientes técnicos


- [ ] Construir PR upstream para Decidim core con el fix del bucle de onboarding (issue #9826)

---


### Pendiente externo

- [ ] Validar traducciones al euskera con técnico del ayuntamiento

---

## ~~Tarea futura~~ Tarea completada — limpiar `es.yml`

Cuando se aborde, el commit debe ser atómico: eliminar la clave del yml base y confirmar que ya existe en `es_census_authorizer_galdakao.yml`, todo en el mismo commit. Las claves afectadas son:

```yaml
# Actualmente en es.yml — a mover en su momento
decidim:
  authorization_handlers:
    census_authorization_handler:
      name: Censo municipal soap        # desactualizado además
      explanation: Verifica tu cuenta con el censo municipal   # desactualizado
census_authorization:
  form:
    date_select:                        # residuo, ya no se usa — simplemente eliminar
```

> **Nota:** `name` y `explanation` ya están actualizados en `es_census_authorizer_galdakao.yml`. Como Rails carga los archivos de módulo después del yml base, las claves del módulo tienen precedencia actualmente. La limpieza del yml base es cosmética hasta que se haga el commit atómico.