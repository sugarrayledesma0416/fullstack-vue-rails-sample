class ParentInstitution < ApplicationRecord
  self.table_name = 'schools'
  default_scope -> { joins(:schools) }
  has_many :schools
  has_many :shared_library_activities
  has_many :institution_admins,
           through: :school_users,
           class_name: 'InstitutionAdmin',
           foreign_key: 'user_id',
           source: :user
end
