FactoryBot.define do
  factory :cartridge_resource_link, class: Cartridge::ResourceLink do |rl|
    rl.resource_id { SecureRandom.random_number(100000..900000) }
    rl.resource_type { 'activity' }
    rl.resource_link_id { SecureRandom.uuid }
    program
  end
end
