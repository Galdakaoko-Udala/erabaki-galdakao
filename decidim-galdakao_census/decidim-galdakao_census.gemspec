# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/galdakao_census/version"

Gem::Specification.new do |s|
  s.version = Decidim::GaldakaoCensus::VERSION
  s.authors = ["Alabs"]
  s.email = []
  s.license = "AGPL-3.0"
  s.homepage = ""
  s.required_ruby_version = ">= 3.3"

  s.name = "decidim-galdakao_census"
  s.summary = "Galdakao census authorization for Decidim"
  s.description = "Provides census-based authorization and zone management for Decidim in Galdakao. " \
                  "Based on the original work by microstudi (Ivan Vergés) for GetxoUdala " \
                  "(https://github.com/GetxoUdala/decidim-getxo), adapted and extended " \
                  "for Galdakao by Alabs under the Pokecode Decidim distribution."

  s.files = Dir["{app,config,lib}/**/*"]

  s.require_paths = ["lib"]

  s.add_dependency "decidim-admin", Decidim::GaldakaoCensus::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-core", Decidim::GaldakaoCensus::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-verifications", Decidim::GaldakaoCensus::COMPAT_DECIDIM_VERSION
  s.add_dependency "deface", "~> 1.9"
end
