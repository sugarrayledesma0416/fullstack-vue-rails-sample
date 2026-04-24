class AssignmentBuilder
  DEFAULT_CATEGORY_ARGS = {
    'credit_only' => false,
    'max_attempts' => 2,
    'enhanced_feedback_disabled' => false,
    'accept_late_work' => true,
    'late_work_penalty' => 'percent_per_day',
    'penalty_percent' => 5,
    'scoring_rulesets_attributes' => [{
      'must_match_accents' => true,
      'must_match_capitalization' => false,
      'must_match_punctuation' => false
    }]
  }

  # extract activity ids from the raw_asssignments hash
  def activity_ids_from(raw_assignments)
    raw_assignments.flat_map do |due_date, assignment_data|
      assignment_data.map { |a| a[:id] } if assignment_data.present?
    end.uniq
  end

  def find_or_create_categories(course, category_map)
    category_map.inject({}) do |memo, (group_name, attributes)|
      memo[group_name.downcase] = find_category(course, attributes['name']) ||
        create_category(course, attributes)
      memo
    end
  end

  private def find_category(course, name)
    course.categories.where(name: name).first
  end

  private def create_category(course, attributes)
    course.categories.create!(category_attributes(attributes))
  end

  private def category_attributes(attributes)
    DEFAULT_CATEGORY_ARGS.merge(attributes)
  end

  def build_assignments(categories, raw_assignments)
    # create a lookup hash of activity objects
    activities = Activity.where(id: activity_ids_from(raw_assignments)).group_by(&:id)

    # Make a new assignments hash for the bulk assignment creator
    # setting category based on Activity#assignment_group or activity_info category
    raw_assignments.to_a.map do |date, assignments|
      rank = 0
      assignments.to_a.map do |activity_info|
        activity = activities[activity_info[:id]].first
        rank = rank + 1
        {
          activity_id: activity_info[:id],
          due_date: date,
          category: set_category(categories, activity_info, activity),
          individually_assignable: activity_info[:individually_assignable] || false,
          is_igc: activity&.instructor_id.present? || false,
          rank: rank
        }
      end
    end.flatten
  end

  # set_category(): returns the intended Category db record for an activity
  # categories: Hash mapping string to AR Category
  #   {"explore"=>#<Category id: 46, course_id: 37, ...>, "learn"=>#<Category...>}
  # assignment_activity: Hash containing activity info
  #   {id: 1234, category: 'Practice'}
  # activity: Activity db record
  private def set_category(categories, assignment_activity, activity)
    # check the category from the raw assignment data first
    categories.fetch(assignment_activity[:category].downcase.strip) do
      # if a matching category is not found, check assignment_group mapping to category
      # for non-VOL programs, assignment_group is always nil
      categories.fetch(activity.assignment_group&.downcase&.strip) do
        raise "Category #{assignment_activity[:category]} not found in category mapping."
      end
    end
  end
end
