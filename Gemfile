source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0'
# Use Puma as the app server
gem 'puma', '~> 4.1.1'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use jQuery
gem 'jquery-rails', '~> 4.3.5'

# Use Bootstrap 4
gem 'bootstrap', '~> 4.3.1'

# bootstrap-datepicker support
gem 'bootstrap-datepicker-rails'

# js-cookie (jQuery plugin) support
gem 'js_cookie_rails'

# Javascript time zone detection
gem 'jsTimezoneDetect-rails'

# Pagination
gem 'will_paginate', '~> 3.1.8'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0.0'
# Turbolinks makes navigating your web application faster. Read more:
# https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.13'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.5', require: false

# Payment processing with Stripe
gem 'stripe'

# Static code analysis and performance testing tools
group :development do
  # Static code analyzer for best coding practices
  gem 'rails_best_practices'

  # Static code analyzer for security issues
  gem 'brakeman'

  # Use derailed_benchmarks for memory usage stats
  gem 'derailed_benchmarks'
  gem 'stackprof'

  # Performance profiling using Miniprofiler
  gem 'rack-mini-profiler'
  gem 'flamegraph'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere
  # in the code.
  gem 'web-console', '>= 4.0.1'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.1'
end

group :development, :test do
  # Use SQLite as the database for non-production environments
  gem 'sqlite3', '~> 1.4.1'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  # Fake data generation with faker
  gem 'faker'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.29'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
  gem 'minitest-reporters'
  gem 'guard'
  gem 'guard-minitest'
  gem 'stripe-ruby-mock', require: 'stripe_mock'
end

# Use simplecov for code coverage metrics during testing
gem 'simplecov', require: false, group: :test

group :production do
  # For using MySQL DB in production
  #gem 'mysql2'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
