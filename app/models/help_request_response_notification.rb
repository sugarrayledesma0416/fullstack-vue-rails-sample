class HelpRequestResponseNotification < Notification::BaseInternalActivityNotification
  include Purgeable

  store(
    :data,
    accessors: %i[
      processed_request_count
    ],
    coder: YAML
  )
  before_create :denormalize_processed_request_count

  # activity.notifications.dispatch('HelpRequestResponse', {:section => section, :user => user})
  def message
    # Could get more fancy someday:
    # E.g Your instructor responded to 1 help request and 5 review requests.
    instructor = audience_label(audience, :instructor)
    if processed_request_count.to_i == 1
      "Your #{instructor} responded to your help request."
    else
      "Your #{instructor} responded to #{processed_request_count} help requests."
    end
  end

  private def denormalize_processed_request_count
    self.processed_request_count = user.help_requests
      .processed_instructor_respondable_by_section_and_activity(
        section.id, activity.id
      ).count
  end
end
