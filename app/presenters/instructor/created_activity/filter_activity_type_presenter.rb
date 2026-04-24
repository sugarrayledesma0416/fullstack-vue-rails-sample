module Instructor::CreatedActivity
  class FilterActivityTypePresenter < ActivityTypePresenter
    def formatted_activity_types
      sorted_displayable_activity_types.to_h.transform_values { |v| v[:label] }
    end

    private def displayable_activity_kind
      :filter
    end
  end
end
