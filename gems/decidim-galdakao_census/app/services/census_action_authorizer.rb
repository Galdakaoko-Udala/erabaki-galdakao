class CensusActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
  def authorize
    return [:missing, { action: :authorize }] if authorization.blank?
    return [:ok, {}] if zones.blank?
    return [:unauthorized, {}] if authorization_street.blank? || authorization_number.blank?
    return [:ok, {}] if belongs_to_zone?
    [:unauthorized, {}]
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
    Decidim::Verifications.find_workflow_manifest("census_authorization_handler")
  end
end