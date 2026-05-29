# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "decidim-galdakao_census"
  s.version     = "0.1.0"
  s.authors     = ["Alabs"]
  s.email       = []
  s.summary     = "Galdakao census authorization for Decidim"
  s.description = "Provides census-based authorization and zone management for Decidim in Galdakao. " \
                  "Based on the original work by microstudi (Ivan Vergés) for GetxoUdala " \
                  "(https://github.com/GetxoUdala/decidim-getxo), adapted and extended " \
                  "for Galdakao by Alabs under the Pokecode Decidim distribution."
  s.homepage    = ""
  s.license     = "AGPL-3.0"

  s.files = Dir[
    "app/**/*",
    "config/**/*",
    "lib/**/*"
  ]

  s.require_paths = ["lib"]

  s.add_dependency "decidim-core", "~> 0.31"
  s.add_dependency "decidim-admin", "~> 0.31"
  s.add_dependency "decidim-verifications", "~> 0.31"
end
