# frozen_string_literal: true

class GaldakaoStreet < ApplicationRecord
  belongs_to :organization,
             foreign_key: "decidim_organization_id",
             class_name: "Decidim::Organization"

  # Sincroniza las calles desde tu API SOAP a la BD interna de Decidim.
  # Llama a la acción "ListadoCalles" de tu API.
  # Tu API debe devolver XML con la estructura:
  #   <calles><calle>Nombre Calle</calle>...</calles>
  def self.import_streets!(organization)
    import_streets.each do |street_name|
      s = GaldakaoStreet.find_or_initialize_by(name: street_name, organization: organization)
      # rubocop:disable Rails/SkipsModelValidations
      s.touch if s.persisted?
      # rubocop:enable Rails/SkipsModelValidations
      s.save!
    end
  end

  def self.import_streets
    service = GaldakaoWebservice.new("ListadoCalles")
    service.response

    service.response.search("calles").children.map { |node| node.text.strip }.compact_blank
  end
end
