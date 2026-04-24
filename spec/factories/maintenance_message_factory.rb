# encoding: utf-8
FactoryBot.define do
  factory :maintenance_message do |maint_msg|
   maint_msg.message { 'Some random message ' }
   maint_msg.start { 2.days.from_now }
   maint_msg.end { 3.days.from_now }
   maint_msg.published { false }
  end
end
