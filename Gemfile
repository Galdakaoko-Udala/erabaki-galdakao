# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_VERSION = { github: "decidim/decidim", branch: "release/0.28-stable" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-conferences", DECIDIM_VERSION
gem "decidim-initiatives", DECIDIM_VERSION

# Extra modules old versions 
# gem "decidim-file_authorization_handler", git: "https://github.com/CodiTramuntana/decidim-file_authorization_handler.git", branch: 'master' #Para Decidim 0.27.x
# gem "decidim-extra_user_fields", git: "https://github.com/alabs/decidim-module-extra_user_fields", branch: "release/0.27-stable" #Para Decidim 0.27.5+ con traducciones a espanol y euskera

gem "decidim-term_customizer", github: "mainio/decidim-module-term_customizer"
gem "decidim-decidim_awesome"

# Aditional Gems
gem "bootsnap","~> 1.10.3"

gem "puma", ">= 6.3.1"
gem "uglifier", "~> 4.1"

gem "figaro"

gem "wicked_pdf"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "faker", "~> 3.2"
  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web"
  gem "listen"
  gem "rubocop-faker"
  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"
end

group :production do
  gem "passenger"
  gem 'delayed_job_active_record'
  gem "daemons"
end
