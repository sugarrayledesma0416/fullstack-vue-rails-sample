class StudentSectionConfig < ApplicationRecord
  belongs_to :section
  belongs_to :user
end
