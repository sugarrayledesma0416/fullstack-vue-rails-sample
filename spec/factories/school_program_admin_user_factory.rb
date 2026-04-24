FactoryBot.define do
  factory :school_program_admin_user do
    user
    school
    program
    account_type { 'Institution_Admin' }
  end
end
