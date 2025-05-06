# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy
Decidim.configure do |config|
  config.content_security_policies_extra = {
    "connect-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "img-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "default-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "script-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "style-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "font-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "frame-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split,
    "media-src" => ENV.fetch("CONTENT_SECURITY_POLICY", "").split
  }
end
