# frozen_string_literal: true

if ENV.fetch("HEALTHCHECK_ADDITIONAL_CHECKS", nil)
  HealthCheck.setup do |config|
    config.standard_checks += ENV.fetch("HEALTHCHECK_ADDITIONAL_CHECKS", nil).split
  end
end

if ENV.fetch("HEALTHCHECK_EXCLUDE_CHECKS", nil)
  HealthCheck.setup do |config|
    config.standard_checks -= ENV.fetch("HEALTHCHECK_EXCLUDE_CHECKS", nil).split
  end
end
