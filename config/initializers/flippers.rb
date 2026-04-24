require 'flipper'
require 'flipper/adapters/memory'

$flipper = Flipper.new(Flipper::Adapters::Memory.new)
$api_attempt_read_store = $flipper[:api_attempt_read_store]
$api_attempt_write_store = $flipper[:api_attempt_write_store]

Rails.configuration.flipper = Flipper.new(Flipper::Adapters::Memory.new)
Flipper.register :gradebook_analytics_schools do |school|
  GradebookAnalyticsSchool.where(school_id: school.id).present?
end

Rails.configuration.flipper[:gradebook_analytics].enable_group :gradebook_analytics_schools
