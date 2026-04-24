require 'assignment_day' unless Object.constants.include?("AssignmentDay")
class AssignmentDay
  def id=(id); end
end

FactoryBot.define do
  factory :assignment_day do
    due_date { 1.days.from_now }
  end
end
