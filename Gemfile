source 'https://rubygems.org'

if Gem::Version.new(Bundler::VERSION) < Gem::Version.new('1.10')
  abort 'Bundler version >= 1.10 is required'
end

def vhl_repo(name)
  "https://github.com/vhl/#{name}.git"
end

source 'https://gem.fury.io/vistahigherlearning/' do
  gem 'maestro_core'
  gem 'oj'
end

gem 'vhl-stats', git: vhl_repo('vhl-stats'), tag: '1.0.4'
gem 'pg', '~> 1.0'

gem 'aasm'
gem 'active_model_serializers', '~> 0.8', '< 0.10'
gem 'activerecord-import'
gem 'activerecord-session_store', '>= 2.0.0'
gem 'activeresource', '6.0.0'
gem 'ims-lti', '1.2.4'
gem 'american_date'
gem 'authlogic', '6.4.2'
gem 'autoprefixer-rails', '8.6.5'
gem 'avatar_service', git: vhl_repo('avatar_service'), tag: '2.0.2'
gem 'aws-record'
gem 'aws-sdk-cloudfront', '~> 1'
gem 'aws-sdk-core', '~> 3'
gem 'aws-sdk-dynamodb', '~> 1'
gem 'aws-sdk-sqs', '~> 1'
gem 'bootsnap', '>= 1.9.2'
gem 'bullet', '7.0.7'
gem 'cancancan'
gem 'caxlsx', '3.3.0', require: false
gem 'circuitbox', '~> 1.1.0'
gem 'cloudfront-signer'
gem 'coluche', git: vhl_repo('coluche'), tag: '0.1.3'
gem 'common_cartridge_parser', git: vhl_repo('common_cartridge_parser'), tag: '1.0.11'
gem 'concurrent-ruby', '1.3.4', require: 'concurrent'
gem 'daemons'
gem 'dangerfield', git: vhl_repo('dangerfield'), tag: '0.3.2'
gem 'ddtrace', '~> 1.20.0'
gem 'diller', git: vhl_repo('diller'), tag: '0.2.11'
gem 'dotenv'
gem 'dotenv-rails'
gem 'enrollment_engine', git: vhl_repo('enrollment_engine'), tag: '1.2.8'
gem 'factory_bot_rails'
gem 'fast_blank'
gem 'ffaker', '~> 2.3.0'
gem 'flipper', '~>0.7.0'
gem 'google-apis-classroom_v1', '~> 0.38.0'
gem 'googleauth', '~> 1.9'
gem 'gradebook_engine', git: vhl_repo('gradebook'), tag: '4.7.63'
gem 'hashie'
gem 'hedberg', '0.0.2', git: vhl_repo('hedberg')
gem 'hicks', git: vhl_repo('hicks'), tag: '1.1.0'
gem 'holidays', '~>1.0.0'
gem 'htmlentities', '4.3.4'
gem 'iconv', '~> 1.1.0'
gem 'jquery-rails', '>= 4.4.0'
gem 'json'
gem 'kiba', '~> 4.0'
gem 'light-service'
gem 'lograge', '~> 0.3.1'
gem 'lorem'
gem 'maestro_activity_engine', git: vhl_repo('mae'), tag: '4.13.17'
gem 'maestro_client', git: vhl_repo('maestro_client'), tag: '4.1.38'
gem 'mailgun_rails'
gem 'mini_magick'
gem 'music', git: vhl_repo('music'), tag: '1.6.5'
gem 'multi_version_common_cartridge', git: vhl_repo('multi_version_common_cartridge'), tag: '1.0.4'
gem 'mysql2', '0.5.5'
gem 'net-http-persistent', '~> 4.0.0'
# maestro_activity_engine and common_cartridge_parser both have nokogiri dependencies
gem 'nokogiri', '1.18.8', force_ruby_platform: true
gem 'non-stupid-digest-assets'
gem 'opentok', '~> 4.0.1'
gem 'opensearch-ruby'
gem 'pubnub', '5.3.5'
gem 'rack', '~> 2.2.3'
gem 'rack-cors'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'radner', git: vhl_repo('radner'), tag: '0.1.14'
gem 'rails', '6.1.7.10'
gem 'rake', '~> 12.3.3'
gem 'rake-progressbar'
gem 'rbtrace', '~> 0.5.1'
gem 'redis', '4.8.0'
gem 'retryable'
gem 'rollbar'
gem 'roo'
gem 'unleash', '~> 6.4.0'
gem 'vhl-ai-core', git: vhl_repo('ai_core'), tag: '0.2.3'
gem 'ruby-openai', '~> 7.4.0'
gem 'ruby-progressbar'
gem 'rubycas-client', git: vhl_repo('rubycas-client'), ref: 'fa3467f0579a3b8376f4f75c1404550b726eb9c4'
gem 'rubyzip' # use the version required by maestro_activity_engine
gem 'sassc-rails'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro', '5.5.8'
end
gem 'sidekiq-cron', '1.12.0'
gem 'sidekiq-failures', '1.0.4'
gem 'sidekiq-status', '2.1.3'
gem 'sidekiq-throttled'
gem 'sprockets', '~> 3.7.2'
gem 'sprockets-rails', '3.2.1'
gem 'streamio-ffmpeg'
gem 'strong_migrations', '1.4.2'
gem 'submission_client', git: vhl_repo('submission_client'), tag: '0.1.7'
gem 'syslogger', '~> 1.6.0'
gem 'test-unit', '~> 3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer'
gem 'tzinfo-data'
gem 'uglifier', '>= 1.0.3'
gem 'useragent'
gem 'unicode-emoji'
gem 'uuidtools'
gem 'validates_timeliness', '~> 6.0'
gem 'vhl_secret', git: vhl_repo('vhl_secret'), tag: 'v0.1.6'
gem 'vite_rails'
gem 'webpacker', '~> 5.4.0'
gem 'websocket-driver', '0.7.6' # locking it to 0.7.6 to avoid installing the base64 gem.
gem 'wicked_pdf', '2.6.3'
gem 'will_paginate', '~> 3.3.0'
gem 'wkhtmltopdf', tag: '0.2.1', require: false, git: vhl_repo('wkhtmltopdf')
gem 'zipline', '1.6.0'

group :live do
  # 3.0.0 introduces changes that will break specs
  gem 'cloudflare-rails', '~> 2.3.0' # log true client IP address
end

group :development do
  gem 'awesome_print'
  gem 'meta_request'
  gem 'pry-rails'
  gem 'query_reviewer', git: 'https://github.com/nesquena/query_reviewer.git'
  gem 'rails_view_annotator', git: 'https://github.com/vhl/rails_view_annotator'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-rails', '~> 2.18'
  gem 'rubocop-rspec'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'thin'
  gem 'traceroute'
  gem 'vhl_jsdoc', git: vhl_repo('vhl_jsdoc'), tag: '0.1.1'
end

group :test, :development do
  gem 'byebug'
  gem 'coffee-rails'
  gem 'parallel_tests'
  gem 'pry', '0.14.1'
  gem 'rouge-rails'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'ruby-prof'
  gem 'teaspoon-jasmine'
end

group :test do
  gem 'capybara', '~> 3.0'
  gem 'capybara-angular'
  gem 'ci_reporter'
  gem 'database_cleaner'
  gem 'fakefs', '~>2.6.0', require: 'fakefs/safe'
  gem 'headless', '~>0.2'
  gem 'mocha', '0.9.8', require: false
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'rspec-retry'
  gem 'selenium-devtools', '~> 0.113.0'
  gem 'selenium-webdriver', '~> 4.8.0'
  gem 'shoulda-matchers', '~> 5.1.0', require: false
  gem 'simplecov', require: false
  gem 'timecop', '~> 0.9.6'
  gem 'webmock', '~> 3.6'
  gem 'webrick', '~> 1.8.2'
end
