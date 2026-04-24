FactoryBot.define do
  factory :role do
    name { 'vtext_creator' }
  end

  factory :support_rep_role, parent: :role do
    name { 'support_rep' }
  end

  factory :common_cartridge_creator_role, parent: :role do
    name { 'common_cartridge_creator' }
  end

  factory :program_config_manager_role, parent: :role do
    name { 'program_config_manager' }
  end

  factory :resource_editor_role, parent: :role do
    name { 'resource_editor' }
  end
end
