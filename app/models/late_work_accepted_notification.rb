class LateWorkAcceptedNotification < Notification::BaseInternalActivityNotification
  def message
    "Your #{audience_label(audience, :instructor)} accepted your late " \
    'submission as on-time.'
  end
end
