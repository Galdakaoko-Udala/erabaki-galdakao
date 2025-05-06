# frozen_string_literal: true

if (additional = ENV.fetch("HEALTHCHECK_ADDITIONAL_CHECKS", nil))
  HealthCheck.setup do |config|
    config.standard_checks += additional.split
  end
end

if (exclude = ENV.fetch("HEALTHCHECK_EXCLUDE_CHECKS", "emailconf"))
  HealthCheck.setup do |config|
    config.standard_checks -= exclude.split
  end
end
