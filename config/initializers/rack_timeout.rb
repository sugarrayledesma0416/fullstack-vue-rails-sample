# prevent passenger from continuing to process a request after we've timed out on the nginx side
#   service_timeout: 60
# prevent timeout long-running requests, such as a user uploading a large file,
# before Rails has had a chance to start processing them by setting 
#   wait_timeout: false
Rails.configuration.middleware.insert_before(Rack::Runtime,
                                             Rack::Timeout,
                                             service_timeout: 60,
                                             wait_timeout: false)

# Don't write to the rails logs cos the output isn't JSON like the other
# rails logs, and also, if we get an actual timeout, we should get a rollbar
# notification.
Rack::Timeout::Logger.disable
