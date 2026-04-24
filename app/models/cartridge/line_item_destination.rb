module Cartridge
  class LineItemDestination < ApplicationRecord
    self.table_name = 'cartridge_line_item_destinations'
    belongs_to :user
    belongs_to :section
    belongs_to :activity

    validates :line_item_url, presence: true

    # For CC/LTI 1.3, the line_item_url is used to identify the column in the LMS gradebook
    # for the associated activity. This notably differs from CC 1.1, where lis_result_sourcedid
    # is used to target a specific cell in a column to record a user's score.

    # Determines whether there is an existing line item for this thruple
    # of user/section/activity. If not it adds a new one. If there is one it
    # updates the line_item_url if it changed.
    def self.add_or_update(user:, section:, activity:, line_item_url:)
      line_item_destination = find_by(section: section, user: user, activity: activity)
      if line_item_destination
        line_item_destination.update(line_item_url: line_item_url)
      else
        LineItemDestination.create(
          user: user,
          section: section,
          activity: activity,
          line_item_url: line_item_url
        )
       end
    end

    def self.find_by_user_section_activity(user:, section:, activity:)
      find_by(section: section, user: user, activity: activity)
    end
  end
end
