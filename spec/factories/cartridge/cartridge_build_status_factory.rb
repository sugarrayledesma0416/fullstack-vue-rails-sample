FactoryBot.define do
  factory :cartridge_build_status, class: 'Cartridge::CartridgeBuildStatus' do
    cc_version { Cartridge::CartridgeBuildStatus::VERSIONS.sample }
    association :creator, factory: :user
    program
    file_name do |proxy|
      "#{FFaker::Time.between(10.years.ago, Time.now).strftime('%Y%m%d_%H%M%S')}_#{proxy.program.title}_#{proxy.cc_version.gsub(/\W/, '_')}.imscc"
    end
    status { Cartridge::CartridgeBuildStatus::STATUS_SUCCESS }
  end

  factory :cartridge_failed_build_status, parent: :cartridge_build_status do
    error_message { 'an error occured' }
    file_name {}
    status { Cartridge::CartridgeBuildStatus::STATUS_FAILURE }
  end
end
