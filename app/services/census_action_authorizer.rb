# frozen_string_literal: true

class CensusActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
  def authorize
    # Sin autorización previa → redirige a verificarse
    return [:missing, { action: :authorize }] if authorization.blank?

    # Si el componente no tiene calles configuradas → cualquier usuario autorizado puede pasar
    return [:ok, {}] if streets_empty?

    # Si el usuario no tiene calles en sus metadatos → no autorizado
    return [:unauthorized, {}] if authorization_streets.blank?

    # Si alguna de las calles del usuario coincide con las permitidas → ok
    return [:ok, {}] if belongs_to_street?

    # No coincide → no autorizado, informamos de las calles requeridas
    [:unauthorized, { fields: { "streets": authorization_streets.join("; ") } }]
  end

  private

  def streets_empty?
    options["streets"].blank?
  end

  # Calles guardadas en los metadatos de la autorización del usuario
  def authorization_streets
    authorization.metadata["streets"] || []
  end

  # Comprueba si alguna calle permitida (configurada en el componente) coincide
  # con las calles del usuario (guardadas al verificarse)
  def belongs_to_street?
    allowed_streets = GaldakaoStreet.where(id: options["streets"].split(","))&.pluck(:name)
    allowed_streets&.detect { |street| authorization_streets.include?(street) }
  end

  def manifest
    @manifest ||= Decidim::Verifications.find_workflow_manifest(authorization&.name)
  end
end