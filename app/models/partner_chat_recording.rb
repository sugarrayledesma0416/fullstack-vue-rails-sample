class PartnerChatRecording < ApplicationRecord
  belongs_to :user
  belongs_to :activity
  belongs_to :partner, class_name: 'User'
end
