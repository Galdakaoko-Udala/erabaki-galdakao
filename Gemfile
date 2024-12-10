# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", "0.27.5"
gem "decidim-conferences", "0.27.5"
gem "decidim-consultations", "0.27.5"
# gem "decidim-elections", "0.24.3"
gem "decidim-initiatives", "0.27.5"
# gem "decidim-templates", "0.24.3"

# Extra modules old versions 
# gem "decidim-file_authorization_handler", git: "https://github.com/Patuksa/decidim-file_authorization_handler.git"
# gem "decidim-file_authorization_handler", git: "https://github.com/CodiTramuntana/decidim-file_authorization_handler.git", branch: 'release/0.25-stable' # Para Decidim 0.25.x
# gem "decidim-file_authorization_handler", git: "https://github.com/CodiTramuntana/decidim-file_authorization_handler.git", branch: 'release/0.26-stable' # Para Decidim 0.26.x

# Extra modules
gem "decidim-file_authorization_handler", git: "https://github.com/CodiTramuntana/decidim-file_authorization_handler.git", branch: 'master' #Para Decidim 0.27.x

gem "decidim-extra_user_fields", git: "https://github.com/alabs/decidim-module-extra_user_fields", branch: "release/0.27-stable" #Para Decidim 0.27.5+ con traducciones a espanol y euskera

gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer", branch: "release/0.27-stable"

gem "decidim-decidim_awesome"

# Aditional Gems
#gem "bootsnap", "1.4.6"
gem "bootsnap","~> 1.10.3"

gem "puma", ">= 5.0.0"
gem "uglifier", "~> 4.1"

gem "faker", "~> 2.14"
gem "figaro"

gem "wicked_pdf"
gem "webpacker"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", "0.27.5"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :production do
  gem "passenger"
  gem 'delayed_job_active_record'
  gem "daemons"
end
