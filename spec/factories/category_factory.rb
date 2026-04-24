FactoryBot.define do
  sequence :category_name do | n |
    names = %w(Practice Homework Lab Projects Quizzes Exams)
    names[n % names.length]
  end

  sequence :category_weighting_percent do | n |
    names = %w(10 15 15 10 50)
    names[n % names.length]
  end

  factory :category do
    course
    name { generate(:category_name) }
    weighting_percent { generate(:category_weighting_percent) }
    accept_late_work { true }
    late_work_penalty { 'percent_per_day' }
    penalty_percent { 5 }
    credit_only { false }
    drop_low_scores { 0 }
    after(:create) do |c|
      create(:scoring_ruleset, :category_id => c.id)
    end
  end

  factory :non_credit_category, parent: :category do
    credit_only { false }
    penalty_percent { 0 }
  end

  factory :credit_only_category, parent: :category do
    credit_only { true }
    penalty_percent { 0 }
  end
end
