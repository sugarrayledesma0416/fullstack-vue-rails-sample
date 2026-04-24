module Cartridge
  class ScoreDestination < ApplicationRecord
    self.table_name = 'cartridge_score_destinations'
    belongs_to :user
    belongs_to :section
    belongs_to :activity

    validates :lis_result_sourcedid, presence: true

    # row and cell in the LMS gradebook is identified by lis_result_sourcedid for CC 1.1;
    # that is the target in the LMS gradebook for this user's score for
    # this activity in this section.

    # Determines whether there is an existing score destination for this thruple
    # of user/section/activity. If not it adds a new one. If there is one it
    # updates the lis_result_sourced_id if it changed.
    def self.add_or_update(user:, section:, activity:, lis_result_sourcedid:)
      score_destination = find_by(section: section, user: user, activity: activity)
      if score_destination
        score_destination.update(lis_result_sourcedid: lis_result_sourcedid)
      else
        ScoreDestination.create(
          user: user,
          section: section,
          activity: activity,
          lis_result_sourcedid: lis_result_sourcedid
        )
       end
    end

    def self.find_by_user_section_activity(user:, section:, activity:)
      find_by(section: section, user: user, activity: activity)
    end
  end
end
