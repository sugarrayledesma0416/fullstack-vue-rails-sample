# as_json for objects with time component (Time, DateTime, ActiveSupport::TimeWithZone)
# now (since Rails 4.1) returns millisecond precision by default.
# Following is added to keep old behavior with no millisecond precision.
# For details, refer:
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#json-representation-of-time-objects
ActiveSupport::JSON::Encoding.time_precision = 0

