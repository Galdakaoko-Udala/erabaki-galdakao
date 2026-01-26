# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_VERSION = { github: "decidim/decidim", branch: "release/0.31-stable" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-conferences", DECIDIM_VERSION
gem "decidim-initiatives", DECIDIM_VERSION

gem "decidim-decidim_awesome", github: "decidim-ice/decidim-module-decidim_awesome", branch: "release/0.31-stable"
gem "decidim-pokecode", github: "openpoke/decidim-module-pokecode", branch: "main"
# gem "decidim-file_authorization_handler", github: "openpoke/decidim-file_authorization_handler", branch: "master"
gem "decidim-term_customizer", github: "openpoke/decidim-module-term_customizer", branch: "release/0.31-stable"

gem "bootsnap", "~> 1.7"
gem "puma", ">= 6.3.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "brakeman", "~> 5.4"
  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web"
  gem "listen"
  gem "web-console"
end
