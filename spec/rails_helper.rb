# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

if ENV['BRANCH_NAME'] == 'release'
  puts 'Skipping the test suite on the release branch.'
  exit(0)
end

require 'simplecov'
SimpleCov.start unless ENV['SKIP_COVERAGE']
if ENV['TEST_ENV_NUMBER'] # parallel specs
  SimpleCov.at_exit do
    result = SimpleCov.result
    result.format! if ParallelTests.number_of_running_processes <= 1
  end
end

# Models that subscribe to rostering notifications will make a
# call to AWS as soon as the class is loaded; these next 2 lines
# are required in order to stub out those calls;
# placement is also important, must be done before File.expand_path
require 'aws-sdk-core'
Aws.config[:stub_responses] = true

# This line prevents any Dangerfieldized models
# referred in rake tasks from publishing and reacting to any callbacks,
# as well as from any networking request attempts.
require 'dangerfield'
Dangerfield::Gatekeeper.instance.disabled = true

require 'gradebook_engine'
GradebookEngine::Config.configure do |config|
  config.auth_controller = 'RequireInstructorController'
end

# aws stub and dangerfield desable should come before this directive
require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'shoulda/matchers'
# require 'rspec/autorun'
require 'webmock/rspec'
require 'sidekiq/testing'
require 'support/activity_test/page_objects'
require 'capybara_config'

# Set to true to see sidekiq errors in STDOUT. Useful when debugging
# GbDataSyncWorker failures.
SHOW_SIDEKIQ_ERRORS = false
Sidekiq::Logging.logger = Logger.new($stdout) if SHOW_SIDEKIQ_ERRORS

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/page_objects/**/*.rb')].sort.each { |f| require f }

# This needs to be defined somewhere for the activity parser to work.  The classes that deal
# with linked media items are different between CMS and M3, and in the parser specs themselves
# we mock the class
def linked_media_class
  MediaLink
end

def fakefs_debugger
  debugger_home = `bundle show byebug`.strip
  current_file = caller.first.scan(/.*\b\.rb/).first.strip
  FakeFS::FileSystem.clone(debugger_home)
  FakeFS::FileSystem.clone(current_file)
  byebug
end

def disable_testunit_autorun
  # `Test::Unit::AutoRunner.need_auto_run=` was introduced to the test-unit
  # gem in version 2.4.9. Previous to this version `Test::Unit.run=` was
  # used. The implementation of test-unit included with Ruby has neither
  # method.
  if defined?(Test::Unit::AutoRunner.need_auto_run = ())
    Test::Unit::AutoRunner.need_auto_run = false
  elsif defined?(Test::Unit.run = ())
    Test::Unit.run = false
  end
end

def enable_dangerfield
  Dangerfield::Gatekeeper.instance.disabled = false
  yield
ensure
  Dangerfield::Gatekeeper.instance.disabled = true
end

require 'fakefs/spec_helpers'

module VhlAwsRecordReset
  def self.all
    [
      Xapi::ActivityState,
      Xapi::BasicAuthCredential,
      Xapi::Statement
    ].each do |klass|
      klass.migrate_down
      klass.migrate_up
    end
  end
end

RSpec.configure do |config|
  disable_testunit_autorun

  # If running rspec --bisect stalls out after running the test suite
  # for the first time, try running with RSPECSHELLBISECT=true at the
  # beginning of the command.
  if ENV['RSPECSHELLBISECT']
    config.bisect_runner = :shell
  end
  config.include WaitForAjax, type: :feature
  config.include WaitForFetch, type: :feature
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry
  config.display_try_failure_messages = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures"

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Set FFaker seed to be the same as RSpec seed so FFaker data is reproducible
  config.before(:all)  { FFaker::Random.seed=config.seed }
  # Reset Random number generator state to prevent test-order interactions
  # (this only matters if we stop using random test order)
  config.before(:each) { FFaker::Random.reset! }

  config.before(:all) { @recycle_bin = [] }

  config.after(:each) do
    @recycle_bin.each { |file| File.unlink(file) if File.exist?(file) }
  end

  def allowing_local_dynamodb_access
    # Allow only connection to the local dynamodb
    WebMock.disable_net_connect!(allow_localhost: true)
    yield
  end

  config.around(:each, use_local_dynamodb: true) do |example|
    Aws.config[:stub_responses] = false
    allowing_local_dynamodb_access do
      VhlAwsRecordReset.all
      example.run
    end
    Aws.config[:stub_responses] = true
  end

  def establish_local_dynamodb_connection
    sleep_interval = 0.1
    seconds_waited = 0.0
    while seconds_waited <= 10.0
      begin
        DynamoConfig.client.list_tables && return
      rescue Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, Seahorse::Client::NetworkingError => e
        puts 'DynamoDB not ready yet (#{e.class}: #{e.message}). Retrying...'
        seconds_waited += sleep(sleep_interval)
      end
    end
    raise 'Could not establish dynamodb-local connection within 10 seconds.'
  end

  config.before(:suite) do
    if DynamoConfig.spawn_local?
      # https://relishapp.com/rspec/rspec-core/v/3-8/docs/hooks/before-and-after-hooks
      # WARNING: Setting instance variables are not supported in before(:suite).
      env_opts = { 'DDB_IN_MEMORY' => 'true', 'DDB_PORT' => DynamoConfig.port.to_s }
      pid = spawn(env_opts, 'dynamodb-local', out: 'log/test.log')
      DynamoConfig.local_pid = pid
      allowing_local_dynamodb_access { establish_local_dynamodb_connection }
    end
  end

  config.after(:suite) do
    if DynamoConfig.spawn_local?
      Process.kill('SIGTERM', DynamoConfig.local_pid)
    end
  end

  ## Using DatabaseCleaner atransaction instead of
  #  use_transactional_fixtures lets us switch to truncation mode
  #  only for capybara js features.
  #  Ref: http://weilu.github.io/blog/2012/11/10/conditionally-switching-off-transactional-fixtures/
  #  Ref: http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    # initialize datafiles dir for test environment
    `rm -rf datafiles/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}/*`
  end

  DatabaseCleaner[:active_record, db: :test].strategy = :transaction
  DatabaseCleaner[:active_record, db: :gradebook_test].strategy = :transaction

  config.before(:each) do
    # @request ||= ActionController::TestRequest.new
    DatabaseCleaner.strategy = :transaction

    # if there are activity xml files, clean out everything
    if File.exist?("datafiles/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}/activities") || File.exist?("datafiles/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}/instructor_activities")
      `rm -rf datafiles/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}/*`
    end
  end

  config.before(:each, js: true) do
    CapybaraDns.validate!
    DatabaseCleaner.strategy = :truncation
    # allow_localhost needed to support requests to chromedriver, like
    # "http://127.0.0.1:43919/__identify__"
    WebMock.disable_net_connect!(allow_localhost: true)

    stub_request(:get, /.*ps.pndsn.com.*/)
      .to_return(status: 200, body: '', headers: {})

    # do not allow to connect to live zopim.
    Kernel::silence_warnings do
      ApplicationHelper::ZOPIM_BASE_SNIPPET = ''
      ApplicationHelper::ZOPIM_BASE_API_CALLS = ''
      ApplicationHelper::ZOPIM_CHAT_WINDOW_API_CALLS = ''
    end
  end

  # Clear local storage to avoid cross-contamination between tests
  config.after(:each, clear_local_storage: true) do
    Capybara.execute_script 'localStorage.clear()'
  end

  # Clear session storage to avoid cross-contamination between tests
  # Needed after any test that manipulates the visibility selector
  # on the ToC (toggling between All Activities / Assigned Only)
  config.after(:each, clear_session_storage: true) do
    Capybara.execute_script 'sessionStorage.clear()'
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com')
  end

  config.after(chrome: true) do
    if ENV['CHROMEVERBOSE']
      if File.exist?(CHROMEDRIVER_LOG)
        puts File.read(CHROMEDRIVER_LOG)
        File.unlink(CHROMEDRIVER_LOG)
      else
        puts "no log found at #{CHROMEDRIVER_LOG}"
      end
    end
  end

  # Displays information about each spec in the rails log before it runs,
  # to help debugging by tailing the test logs.
  # To enable for all test runs:
  #   export LOG_EXAMPLE_INFO=1
  # To disable:
  #   unset LOG_EXAMPLE_INFO
  # You could also set it on your spec command line:
  #   LOG_EXAMPLE_INFO=1 rspec spec/controllers/announcements_controller_spec.rb
  config.before(:each) do |example|
    if ENV["LOG_EXAMPLE_INFO"].present? && ENV["LOG_EXAMPLE_INFO"] == '1'
      Rails.logger.info(
	[
	  "\n-------------------------",
	  "#{example.full_description}",
	  "#{example.location}",
	  "-------------------------\n"
	].join("\n")
      )
    end
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!

  config.raise_errors_for_deprecations!

  config.after(:each, type: :request) do
    # Reset any fake CAS session logins
    fake_user = CASClient::Frameworks::Rails::Filter.fake_user
    CASClient::Frameworks::Rails::Filter.fake(nil) if fake_user
  end

  config.around(:each) do |example|
    new_gb_sync = example.metadata[:new_gb_sync]
    Rails.configuration.update_test_gradebook = new_gb_sync

    if new_gb_sync
      Sidekiq::Testing.inline! do
        example.run
      end
    else
      example.run
    end

    Rails.configuration.update_test_gradebook = false
  end

  config.around(:each) do |example|
    Rails.configuration.stub_js_audio = example.metadata[:stub_js_audio]
    example.run
    Rails.configuration.stub_js_audio = false
  end

  if ENV['CODEBUILD']
    config.after(:each, type: :feature) do |example|
      STDOUT.puts page.html if example.exception
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Put Datadog tracer in testing mode
Datadog.configure do |c|
  c.tracing.transport_options = proc { |t| t.adapter :test }
  c.logger.level = Logger::WARN
end
