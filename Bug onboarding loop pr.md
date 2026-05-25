# Bug: Bucle infinito en flujo de onboarding con autorización válida pero sin permiso de zona

---

## Origen

Issue de Decidim core: [#9826 - Organization Census Authorization Redirection Issue](https://github.com/decidim/decidim/issues/9826)

Confirmado en v0.26.2, v0.28.0.dev y v0.30.4. **Sin fix oficial a fecha de mayo 2026.**

---

## Descripción

Cuando un usuario no logueado intenta realizar una acción restringida por `census_authorization_handler` con opciones de zona (`options["zones"]`), el flujo de onboarding de Decidim entra en un bucle infinito si el usuario se autentica correctamente en el padrón pero su domicilio no pertenece a ninguna de las zonas asignadas al permiso.

El caso concreto que lo activa — y que Decidim no contempla — es: **usuario verificado pero sin permiso de zona**. Para Decidim, verificarse con un census authorization siempre implica tener permiso. La introducción de un `action_authorizer` con lógica adicional de zona rompe esa asunción.

---

## Flujo que reproduce el bug

1. Usuario sin sesión ni autorización intenta "Nueva propuesta" (acción restringida por zona)
2. Decidim guarda la URL destino y redirige a login
3. Usuario se loguea → Decidim detecta que no tiene autorización → flujo onboarding → formulario de verificación
4. Usuario introduce datos válidos del padrón → autorización creada correctamente → `AuthorizationsController#create` → redirige a `onboarding_pending`
5. `onboarding_pending` evalúa → `global_code: :unauthorized` → redirige a `finished_redirect_path` (`/proposals/new`)
6. `ProposalsController#new` detecta `:unauthorized` → llama a `AuthorizationStatus#current_path` → devuelve `root_path` del handler → redirige de nuevo a `/authorizations/new`
7. **Bucle**: el usuario vuelve al formulario de verificación indefinidamente

URL característica del bucle:
```
/authorizations/new?handler=census_authorization_handler&redirect_url=%2Fauthorizations%2Fonboarding_pending
```

---

## Causa raíz

Dos problemas encadenados en Decidim core:

### Problema 1 — `AuthorizationStatus#current_path`

```ruby
# decidim-core/app/services/decidim/action_authorizer.rb
def current_path(redirect_url: nil)
  return unless @authorization_handler
  if pending?
    @authorization_handler.resume_authorization_path(redirect_url:)
  else
    @authorization_handler.root_path(redirect_url:)  # ← se ejecuta para :unauthorized
  end
end
```

Para el código `:unauthorized`, `pending?` es `false`, así que llama a `root_path` — el formulario de autorización. La distinción que falta: `:unauthorized` no es lo mismo que `:missing` o `:pending`. El usuario ya tiene una autorización válida, simplemente no cumple los requisitos adicionales del `action_authorizer`.

### Problema 2 — `onboarding_pending`

El método no gestiona explícitamente el caso "autorizado pero sin permiso" antes de llamar a `single_authorization_required?`. Cuando el `action_authorizer` devuelve `:unauthorized`, el flujo pasa a `finished_redirect_path` (correcto) pero el controlador destino rechaza al usuario y llama a `current_path`, cerrando el bucle.

---

## Solución aplicada — monkey patch

**Archivo:** `config/initializers/decidim_patches.rb`  
**Commit:** `8a9af87a`

```ruby
Rails.application.config.after_initialize do
  # Fix 1: current_path no debe redirigir al formulario cuando el código es :unauthorized
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

  # Fix 2: onboarding_pending gestiona explícitamente el caso :unauthorized
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

---

## Propuesta de fix para PR upstream

### Fix 1 — `AuthorizationStatus#current_path`

```ruby
def current_path(redirect_url: nil)
  return nil if unauthorized?  # ← añadir esta línea
  return unless @authorization_handler
  if pending?
    @authorization_handler.resume_authorization_path(redirect_url:)
  else
    @authorization_handler.root_path(redirect_url:)
  end
end
```

### Fix 2 — `onboarding_pending`

```ruby
def onboarding_pending
  return redirect_back(fallback_location: authorizations_path) unless onboarding_manager.valid?

  authorizations = action_authorized_to(onboarding_manager.action, **onboarding_manager.action_authorized_resources)
  authorization_status = authorizations.global_code

  # Caso no contemplado originalmente: usuario verificado pero sin permiso
  # de action_authorizer. Mostrar mensaje y redirigir sin volver al formulario.
  if authorization_status == :unauthorized
    flash[:alert] = t("authorizations.onboarding_pending.unauthorized",
                      scope: "decidim.verifications",
                      action: onboarding_manager.action_text.downcase)
    redirect_path = onboarding_manager.component_path || onboarding_manager.finished_redirect_path
    clear_onboarding_data!(current_user)
    return redirect_to redirect_path
  end

  # ... resto del método original sin cambios
end
```

---

## Versiones afectadas

Confirmado en v0.26.2, v0.28.0.dev, v0.30.4. Presumiblemente todas las versiones que usen `action_authorizer` con lógica que pueda devolver `:unauthorized` teniendo la autorización base ya creada.

---

## Contexto adicional

Este bug solo se manifiesta cuando se usa un `action_authorizer` personalizado que introduce una tercera posibilidad: **verificado pero sin permiso**. El census authorization estándar de Decidim no tiene este caso porque verificarse implica siempre tener permiso. En instalaciones que usan verificación por zona geográfica (portales de una calle), este caso es el más habitual — la mayoría de ciudadanos se verificarán correctamente pero no todos tendrán permiso para participar en todos los procesos.