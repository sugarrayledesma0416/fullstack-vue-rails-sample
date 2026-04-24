FactoryBot.define do
  factory(:cartridge_consumer, class: Cartridge::Consumer) do |consumer|
    consumer.association :school
    guid { SecureRandom.uuid }
    sequence(:name) { |index| "CartridgeConsumer #{index}" }
    consumer.key { SecureRandom.base64(40) }
    consumer.secret { SecureRandom.base64(40) }
  end
end
