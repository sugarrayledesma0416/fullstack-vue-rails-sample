class DashboardAnnouncement < ApplicationRecord
  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :link_text
  validates :external_url, presence: true, external_url: true

  def self.remove_previous_announcement(platform)
    DashboardAnnouncement.update_all("#{platform}": false)
  end
end
