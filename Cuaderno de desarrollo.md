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

**Pendiente menor:**
- [ ] Traducir valores del enum `numbers_constraint` al castellano en las vistas

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

El override del locale `decidim.authorization_modals.content.unauthorized.explanation` en `config/locales/es_zones.yml` personaliza el mensaje del modal para todas las autorizaciones de la instalación (intencionado).

La clave `census_authorization_handler.unauthorized_zone` en `config/locales/es_zones.yml` personaliza el mensaje del flash específico del flujo de onboarding con zona no autorizada.

---

## Notas RGPD

- `street_number` se guarda en `decidim_authorizations.metadata` junto con `street` — dato personal de empadronamiento → misma base legal ya documentada (art. 6.1.e RGPD).
- Las tablas `galdakao_zones` y `galdakao_zone_streets` no contienen datos personales.
- Los metadatos de autorización se borran si el usuario revoca su autorización en Decidim.

---

## Pendientes

- [ ] Traducir valores del enum `numbers_constraint` al castellano en las vistas
- [ ] Auditar todos los textos hardcodeados — moverlos a locales
- [ ] Crear `config/locales/eu.yml` (euskera)
- [ ] Validar texto definitivo del mensaje de zona no autorizada con el técnico de participación
- [ ] Unificar locales de `street-validation` con `zone-verification`
- [ ] Revisar si hay otras claves de `decidim.authorization_modals.content` que convenga sobreescribir
- [ ] Construir PR upstream para Decidim core con el fix del bucle de onboarding