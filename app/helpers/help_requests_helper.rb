module HelpRequestsHelper
  def severity_levels_array_for_dropdown
    # in order to return SEVERITY_LEVELS as an array sorted by last element instead of first,
    # since first element is the severity level description
    HelpRequest::SEVERITY_LEVELS.invert.sort_by(&:last)
  end
end
