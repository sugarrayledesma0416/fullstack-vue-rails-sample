FactoryBot.define do
  factory(:xapi_activity_state, class: Xapi::ActivityState) do
    attempt
    user
    section
    activity
  end
end
