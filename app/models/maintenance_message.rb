class MaintenanceMessage < ApplicationRecord

  def self.current_message
    where("published = ? AND start < ? AND end > ?", true, Time.now.utc, Time.now.utc).first
  end
end
