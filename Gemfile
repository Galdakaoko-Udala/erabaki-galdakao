# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", "0.24.3"
# gem "decidim-conferences", "0.24.3"
# gem "decidim-consultations", "0.24.3"
# gem "decidim-elections", "0.24.3"
# gem "decidim-initiatives", "0.24.3"
# gem "decidim-templates", "0.24.3"

gem "bootsnap", "~> 1.3"

gem "puma", ">= 5.0.0"
gem "uglifier", "~> 4.1"

gem "faker", "~> 2.14"
gem "figaro"

gem "wicked_pdf", "~> 1.4"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", "0.24.3"
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
