# The table that links roles with users (generally named RoleUser.rb)
class RolesUser < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
