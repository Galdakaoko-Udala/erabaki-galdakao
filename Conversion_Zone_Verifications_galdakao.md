# zone-verifications — Guía de aplicación para Galdakao

> **Rama base:** `feature/street-validation` (ya en producción)
> **Rama nueva:** `feature/zone-verifications`
> **Entorno:** LXC + Docker, código en `/opt/decidim_production`
> **Rebuild:** `docker build . -t erabaki-galdakao:local && docker compose up -d`
> **Cambios en volúmenes (vistas, JS packs):** `docker compose restart decidim_production`

---

## Qué hace esta rama

Añade una capa de verificación más fina sobre las calles: ya no basta con vivir en una calle determinada, el usuario debe vivir en un **rango de números** de esa calle. Introduce el concepto de **zona** = calle + restricción de paridad + rango opcional de portales.

El API SOAP también pasa a devolver el número de portal además de la calle.

---

## Tabla de renombrado Getxo → Galdakao

| Getxo (original 0.23) | Galdakao (este repo) |
|---|---|
| `GetxoZone` | `GaldakaoZone` |
| `GetxoStreet` | `GaldakaoStreet` |
| `getxo_zone` | `galdakao_zone` |
| `admin_getxo_zones_path` | `decidim_admin.galdakao_zones_path` |
| `Rectify::Command` | `Decidim::Command` |
| `layout "decidim/admin/getxo"` | `layout "decidim/admin/application"` |

---

## Diferencias 0.23 → 0.30 específicas de esta rama

| Problema | Solución |
|---|---|
| `Rectify::Command` no existe en 0.30 | Usar `Decidim::Command` |
| `before_action :logged_and_admin?` con redirect manual | `enforce_permission_to :read, :admin_user` |
| `layout "decidim/admin/getxo"` | `layout "decidim/admin/application"` |
| `link_to` con `method: :delete` | `button_to` con `method: :delete` |
| Helper `admin_getxo_zones_path` | `decidim_admin.galdakao_zones_path` |
| `authenticate_admin!` | No existe — usar `enforce_permission_to` |

---

## Orden de ejecución

```bash
# 1. Crear rama
git checkout feature/street-validation
git checkout -b feature/zone-verifications

# 2. Copiar archivos nuevos (ver secciones siguientes)

# 3. Aplicar patches en archivos existentes

# 4. Build y migración
docker build . -t erabaki-galdakao:local
docker compose up -d
docker compose exec app bundle exec rails db:migrate

# 5. Verificar: /admin/galdakao/zones → crear zonas de prueba
# 6. Probar autorización con datos de empadronamiento reales
```

---

## Archivos nuevos

### `app/models/galdakao_zone.rb`

```ruby
# frozen_string_literal: true

class GaldakaoZone < ApplicationRecord
  RANGE_REGEXP = /(\A\d+(-(\d+)*)\z)|(\A[\d+(,\d)*]+\z)/.freeze

  belongs_to :organization,
             foreign_key: "decidim_organization_id",
             class_name: "Decidim::Organization"
  belongs_to :street,
             class_name: "GaldakaoStreet"
  enum numbers_constraint: { all_numbers: 0, odd_numbers: 1, even_numbers: 2 }

  validates :street_id, :numbers_constraint, presence: true
  validates :numbers_range,
            format: { with: GaldakaoZone::RANGE_REGEXP },
            if: ->(z) { z.numbers_range.present? }
  validate :unique_combination

  private

  def unique_combination
    return unless GaldakaoZone.exists?(
      street_id: street_id,
      organization: organization,
      numbers_constraint: numbers_constraint,
      numbers_range: numbers_range
    )
    errors.add(:name, :invalid)
  end
end
```

---

### `db/migrate/20260428000002_create_galdakao_zones.rb`

```ruby
class CreateGaldakaoZones < ActiveRecord::Migration[7.0]
  def change
    create_table :galdakao_zones do |t|
      t.references :decidim_organization, null: false, index: true
      t.references :street,              null: false, index: true
      t.integer    :numbers_constraint,  default: 0,  null: false
      t.string     :numbers_range
      t.string     :name

      t.timestamps
    end
  end
end
```

---

### `app/forms/decidim/admin/galdakao_zone_form.rb`

```ruby
# frozen_string_literal: true

module Decidim
  module Admin
    class GaldakaoZoneForm < Form
      mimic :galdakao_zone

      attribute :street_id,           Integer
      attribute :numbers_constraint,  String, default: "all_numbers"
      attribute :numbers_range,       String

      validates :street_id, :numbers_constraint, presence: true
      validates :numbers_range,
                format: { with: GaldakaoZone::RANGE_REGEXP },
                if: ->(form) { form.numbers_range.present? }

      def numbers_constraint_options
        {
          "Todos los números" => "all_numbers",
          "Números pares"     => "even_numbers",
          "Números impares"   => "odd_numbers"
        }
      end

      def name
        t = "#{street.name} | #{numbers_constraint_options.invert[numbers_constraint]}"
        t = "#{t} | #{numbers_range}" if numbers_range.present?
        t
      end

      private

      def street
        GaldakaoStreet.find_by(id: street_id, organization: current_organization)
      end
    end
  end
end
```

---

### `app/commands/decidim/admin/create_galdakao_zone.rb`

> ⚠️ **0.30:** `Rectify::Command` → `Decidim::Command`

```ruby
# frozen_string_literal: true

module Decidim
  module Admin
    class CreateGaldakaoZone < Decidim::Command
      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless form.valid?

        begin
          create_zone!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, zone)
      end

      private

      attr_reader :form, :zone

      def create_zone!
        @zone = GaldakaoZone.create!(
          organization:        form.current_organization,
          street_id:           form.street_id,
          numbers_constraint:  form.numbers_constraint,
          numbers_range:       form.numbers_range,
          name:                form.name
        )
      end
    end
  end
end
```

---

### `app/commands/decidim/admin/update_galdakao_zone.rb`

```ruby
# frozen_string_literal: true

module Decidim
  module Admin
    class UpdateGaldakaoZone < Decidim::Command
      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless form.valid?

        begin
          update_zone!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, zone)
      end

      private

      attr_reader :form, :zone

      def update_zone!
        @zone = GaldakaoZone.find(form.id)
        @zone.street_id          = form.street_id
        @zone.numbers_constraint = form.numbers_constraint
        @zone.numbers_range      = form.numbers_range
        @zone.name               = form.name
        @zone.save!
      end
    end
  end
end
```

---

### `app/controllers/decidim/admin/zones_controller.rb`

> ⚠️ **0.30:** layout `"decidim/admin/application"`, no `"decidim/admin/getxo"`
> ⚠️ **0.30:** `enforce_permission_to` en lugar de `logged_and_admin?`
> ⚠️ **0.30:** helpers con prefijo `decidim_admin.`

```ruby
# frozen_string_literal: true

module Decidim
  module Admin
    class ZonesController < GaldakaoApplicationController
      include Paginable
      layout "decidim/admin/application"

      helper_method :zone_list, :streets, :zone

      before_action -> { enforce_permission_to :read, :admin_user }

      def index
        respond_to do |format|
          format.html
          format.json { render json: json_zones }
        end
      end

      def new
        @form = form(GaldakaoZoneForm).instance
      end

      def edit
        @form = form(GaldakaoZoneForm).from_model(zone)
      end

      def create
        @form = form(GaldakaoZoneForm).from_params(params)
        CreateGaldakaoZone.call(@form) do
          on(:ok) do
            flash[:notice] = "Nueva zona creada correctamente"
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = "Error al crear la zona: #{error}"
            render :new
          end
        end
      end

      def update
        @form = form(GaldakaoZoneForm).from_params(params)
        UpdateGaldakaoZone.call(@form) do
          on(:ok) do
            flash[:notice] = "Zona actualizada correctamente"
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = "Error al actualizar la zona: #{error}"
            render :edit
          end
        end
      end

      def destroy
        zone.destroy!
        flash[:notice] = "Zona eliminada correctamente"
        redirect_to decidim_admin.galdakao_zones_path
      end

      private

      def zone
        @zone ||= GaldakaoZone.find(params[:id])
      end

      def streets
        GaldakaoStreet.where(organization: current_organization).order(name: :asc)
      end

      def json_zones
        query = zone_list
        query = if params[:ids]
                  query.where(id: params[:ids].split(","))
                else
                  query.where("name ILIKE ?", "%#{params[:q]}%")
                end
        query.map { |z| { id: z.id, text: z.name } }
      end

      def zone_list
        paginate(GaldakaoZone.where(organization: current_organization).order(name: :asc))
      end

      def per_page
        50
      end
    end
  end
end
```

---

## Archivos existentes a modificar

### PATCH: `config/routes.rb`

Añadir `resources :zones` dentro del bloque `Decidim::Admin::Engine.routes.draw`, al mismo nivel que `resources :galdakao`. El archivo completo queda:

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
  mount Decidim::FileAuthorizationHandler::AdminEngine => "/admin"
end

Decidim::Admin::Engine.routes.draw do
  resources :galdakao, only: [:index] do
    collection do
      get  :streets
      post :sync
      post :check
    end
  end

  resources :zones
end
```

Los helpers resultantes serán:
- `decidim_admin.galdakao_zones_path`
- `decidim_admin.new_galdakao_zone_path`
- `decidim_admin.edit_galdakao_zone_path(zone)`
- `decidim_admin.galdakao_zone_path(zone)` (para update/destroy)

---

### PATCH: `app/services/census_authorization_handler.rb`

Solo cambia el método `metadata`. Todo lo demás del archivo no se toca.

**Antes:**
```ruby
def metadata
  super.merge(
    date_of_birth: date_of_birth&.strftime("%Y-%m-%d"),
    streets: [response&.xpath("//autenticarResult/calle")&.text&.strip].compact.reject(&:empty?)
  )
end
```

**Después:**
```ruby
# Se guarda en decidim_authorizations.metadata (JSON)
# RGPD: contiene fecha de nacimiento, calle y número de portal (datos personales de empadronamiento)
def metadata
  super.merge(
    date_of_birth: date_of_birth&.strftime("%Y-%m-%d"),
    street:        response&.xpath("//autenticarResult/calle")&.text&.strip,
    street_number: response&.xpath("//autenticarResult/portal")&.text&.strip&.to_i
  )
end
```

Cambios:
- `streets` (array) → `street` (string singular) + `street_number` (entero)
- xpath mantiene el nivel `//autenticarResult/calle` — Spyne anida la respuesta un nivel extra, confirmado con curl
- `super.merge` se mantiene

---

### PATCH: `app/services/census_action_authorizer.rb`

Reemplazar toda la lógica actual (que comparaba streets) por la nueva (que compara zonas con restricciones de número):

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
    GaldakaoZone.where(id: zones.split(",")).find_each do |zone|
      if street_valid?(zone)
        @fields.except!(:street)
        return true if number_valid?(zone)
      end
    end
    false
  end

  def street_valid?(zone)
    authorization_street == zone.street&.name
  end

  def number_valid?(zone)
    passes_constraint = case zone.numbers_constraint
                        when "even_numbers" then authorization_number.even?
                        when "odd_numbers"  then authorization_number.odd?
                        else true
                        end
    return false unless passes_constraint
    return true if zone.numbers_range.blank?

    valids = if zone.numbers_range.include?(",")
               zone.numbers_range.split(",").map(&:to_i)
             else
               a, b = zone.numbers_range.split("-")
               (a.to_i..b.to_i).to_a
             end
    valids.include?(authorization_number)
  end

  def manifest
    Decidim.authorization_handlers.find { |m| m.name == "census_authorization_handler" }
  end
end
```

---

### PATCH: `app/packs/src/resource_permissions_multiselect.js`

Tres cambios: URL, selector de input y llamada AJAX. Cambiar `streets` por `zones` en:

```js
// ANTES:
const url_streets = "/admin/galdakao/streets";
// DESPUÉS:
const url_zones = "/admin/galdakao/zones";

// ANTES:
$("input[name$='[authorization_handlers_options][census_authorization_handler][streets]'").each(...)
// DESPUÉS:
$("input[name$='[authorization_handlers_options][census_authorization_handler][zones]'").each(...)

// ANTES (dentro del $.get y en el ajax url):
$.get(url_streets, ...)
url: url_streets,
// DESPUÉS:
$.get(url_zones, ...)
url: url_zones,
```

---

## Vistas nuevas

### Estructura de directorios

```
app/views/decidim/admin/zones/
  index.html.erb
  new.html.erb
  edit.html.erb
  _form.html.erb
```

### `index.html.erb`

```erb
<div class="container">
  <div class="row">
    <div class="columns">
      <h2>Zonas de verificación</h2>

      <%= link_to "Nueva zona", decidim_admin.new_galdakao_zone_path, class: "button" %>

      <table class="table">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Calle</th>
            <th>Restricción</th>
            <th>Rango</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% zone_list.each do |zone| %>
            <tr>
              <td><%= zone.name %></td>
              <td><%= zone.street&.name %></td>
              <td><%= zone.numbers_constraint %></td>
              <td><%= zone.numbers_range %></td>
              <td>
                <%= link_to "Editar", decidim_admin.edit_galdakao_zone_path(zone), class: "button small" %>
                <%= button_to "Eliminar",
                    decidim_admin.galdakao_zone_path(zone),
                    method: :delete,
                    data: { confirm: "¿Seguro que quieres eliminar esta zona?" },
                    class: "button small alert" %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

> ⚠️ **0.30:** `button_to` con `method: :delete`, no `link_to method: :delete`.

### `new.html.erb`

```erb
<h2>Nueva zona</h2>
<%= render "form", form: @form %>
```

### `edit.html.erb`

```erb
<h2>Editar zona</h2>
<%= render "form", form: @form %>
```

### `_form.html.erb`

```erb
<%= decidim_form_for @form, url: (@form.id ? decidim_admin.galdakao_zone_path(@form.id) : decidim_admin.galdakao_zones_path) do |f| %>
  <div class="field">
    <%= f.label :street_id, "Calle" %>
    <%= f.select :street_id,
        streets.map { |s| [s.name, s.id] },
        { include_blank: "Selecciona una calle" },
        class: "form-control" %>
  </div>

  <div class="field">
    <%= f.label :numbers_constraint, "Restricción de números" %>
    <%= f.select :numbers_constraint,
        @form.numbers_constraint_options.to_a,
        {},
        class: "form-control" %>
  </div>

  <div class="field">
    <%= f.label :numbers_range, "Rango de portales (opcional)" %>
    <%= f.text_field :numbers_range,
        class: "form-control",
        placeholder: "Ej: 1-50  o  2,4,6,8" %>
    <p class="help-text">Dejar vacío para incluir todos los números de la restricción seleccionada.</p>
  </div>

  <%= f.submit "Guardar", class: "button" %>
  <%= link_to "Cancelar", decidim_admin.galdakao_zones_path, class: "button hollow" %>
<% end %>
```

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
    portal = Unicode  # o Integer — se parsea como string y se convierte en Ruby
```

---

## Locales

Añadir a `config/locales/es.yml` (fusionar con el existente):

```yaml
es:
  decidim:
    admin:
      galdakao:
        zones:
          index:
            title: "Zonas de verificación"
          new:
            title: "Nueva zona"
          edit:
            title: "Editar zona"
          destroy:
            success: "Zona eliminada correctamente"
          create:
            success: "Nueva zona creada correctamente"
            error: "Error al crear la zona"
          update:
            success: "Zona actualizada correctamente"
            error: "Error al actualizar la zona"
```

---

## Notas RGPD

- `street_number` se guarda en `decidim_authorizations.metadata` junto con `street` — dato personal de empadronamiento → misma base legal ya documentada (art. 6.1.e RGPD).
- La tabla `galdakao_zones` solo contiene nombres de calles y rangos de números, sin datos personales.
- Los metadatos de autorización se borran si el usuario revoca su autorización en Decidim.

---

## Checklist de aplicación

- [ x] Crear rama `feature/zone-verifications` desde `feature/street-validation`
- [x ] Crear `app/models/galdakao_zone.rb`
- [x ] Crear migración `create_galdakao_zones`
- [ x] Crear `app/forms/decidim/admin/galdakao_zone_form.rb`
- [ x] Crear `app/commands/decidim/admin/create_galdakao_zone.rb`
- [x ] Crear `app/commands/decidim/admin/update_galdakao_zone.rb`
- [x ] Crear `app/controllers/decidim/admin/zones_controller.rb`
- [ x] Crear vistas `app/views/decidim/admin/zones/`
- [x ] PATCH `config/routes.rb` — añadir `resources :zones`
- [ x] PATCH `census_authorization_handler.rb` — `streets` array → `street` + `street_number`
- [ x] PATCH `census_action_authorizer.rb` — lógica por zona
- [ x] PATCH `resource_permissions_multiselect.js` — `streets` → `zones`
- [x ] Añadir locales
- [ ] Build imagen Docker
- [ ] Ejecutar migración
- [ ] Actualizar API SOAP para devolver `<portal>`
- [ ] Probar flujo completo: sync calles → crear zona → autorizar usuario
