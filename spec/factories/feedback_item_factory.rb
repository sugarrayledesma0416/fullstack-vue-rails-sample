# encoding: utf-8
FactoryBot.define do
  sequence(:attempt_id) { |id| id + 1 }

  sequence :label do |seq|
    "question_#{sprintf("%02d", seq + 1)}"
  end

  factory :feedback_item do
    attempt
    section
    user
    question_label { generate(:label) }
  end
end
