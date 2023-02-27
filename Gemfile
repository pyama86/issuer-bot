source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'mysql2'
gem 'recursive-open-struct'
gem 'redis'
gem 'redis-rails'
gem 'sentry-raven'
gem 'sidekiq'
gem 'rails'
gem 'sqlite3', '~> 1.6'
gem 'puma'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'listen', '~> 3.8'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'vcr'
  gem 'webmock'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'octokit'
gem 'slack-ruby-block-kit'
gem 'slack-ruby-client'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
