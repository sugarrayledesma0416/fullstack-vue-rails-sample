FactoryBot.define do
  factory :cartridge_score_destination, class: Cartridge::ScoreDestination do |sd|
    sd.association :user
    sd.association :section
    sd.association :activity
    sd.lis_result_sourcedid { SecureRandom.uuid }
  end
end
