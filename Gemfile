source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.1.0'

# Propshaft asset pipeline
gem 'propshaft'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '>= 4.0.1'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem 'kredis'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem 'image_processing', '~> 1.2'

# These gems are needed here since they are being removed from Ruby's default gems
# in upcoming releases:
gem 'bigdecimal'
gem 'mutex_m'
gem 'drb'
gem 'fiddle'
gem 'rdoc'
gem 'ostruct'
gem 'logger'
gem 'base64'
gem 'benchmark'

# concurrent-ruby v1.3.5 has removed the dependency on logger
gem 'concurrent-ruby', '1.3.4'

# Use Dart SASS for stylesheets
gem 'dartsass-rails', '~> 0.5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.2.0'
# Use jQuery
gem 'jquery-rails', '~> 4.6'
# Use Bootstrap 5
gem 'bootstrap', '~> 5.3.0'
# bootstrap-datepicker support
gem 'bootstrap-datepicker-rails'
# js-cookie (jQuery plugin) support
gem 'js_cookie_rails'
# Javascript time zone detection
gem 'jsTimezoneDetect-rails'
# Pagination
gem 'will_paginate', '~> 4.0'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Static code analysis, performance testing, and development tools
group :development do
  # Static code analyzer for best coding practices
  gem 'rails_best_practices'

  # Static code analyzer for security issues
  gem 'brakeman'

  gem 'stackprof'

  # Performance profiling using Miniprofiler
  gem 'rack-mini-profiler'
  gem 'flamegraph'

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  gem 'listen'
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.1'

  # Rubocop
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false

  # Solargraph
  gem 'solargraph', require: false
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]

  # Minitest 6 introduces breaking changes with Rails 7.2.3
  gem 'minitest', '<6'

  # Use SQLite as the database for non-production environments
  gem 'sqlite3'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  # Fake data generation with faker
  gem 'faker'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.30'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
  gem 'minitest-reporters'
  gem 'guard'
  gem 'guard-minitest'

  # Check gem versions for known security issues
  gem 'bundler-audit', require: false

  # Check for N+1 queries and other anti-patterns
  gem 'bullet'
end

# Use simplecov for code coverage metrics during testing
gem 'simplecov', require: false, group: :test

group :production do
  # For using MySQL DB in production
  gem 'mysql2'
end
