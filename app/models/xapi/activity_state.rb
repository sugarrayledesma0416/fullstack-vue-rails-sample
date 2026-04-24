module Xapi
  class ActivityState
    include VhlAwsRecord

    set_table_name(prefix_table_name('xapi-states'))

    string_attr :id, hash_key: true
    integer_attr :activity_id
    integer_attr :section_id
    integer_attr :user_id
    string_attr :page_location
    integer_attr :milliseconds_spent
    string_attr :payload
  end
end
