module StandardsMapping
  class ActivitySet
    include Enumerable

    def initialize(program_id, activity_type = 'Activity')
      @program = Program.find program_id
      @activity_type = activity_type
      @rows = activities_for_program(program_id).map do |row|
        row.attributes.to_hash.compact.values.unshift(@program.id, @program.title)
      end
    end

    def each
      @rows.each { |row| yield row }
    end

    # rubocop:disable Metrics/MethodLength
    private def activities_for_program(program_id)
      # Pull all activities for a program where:
      #  * question banks are null (provided by Activity default scope)
      #  * instructor_id is nil (exclude IGC)
      #  * toc_location is nil (exclude 'deleted' activities), but not if
      #  * component name is 'Unlisted' b/c Unlisted activities
      #  * are supplemental that we want to include
      #
      # Selections:
      #  * Lesson name
      #  * Unit name
      #  * Concept name (call it 'strand' when user facing)
      #  * Component name
      #  * Activity cms id
      #  * Activity title
      #  * Activity type
      #  * Activity link
      #  * Add empty columns to roll into csv for domain, subdomain & standards_id_list

      activities = activity_base
                   .by_program(program_id)
                   .joins(:concept)
                   .select(
                     'units.name as unit_name',
                     'lessons.name as lesson_name',
                     'concepts.name as concept_name',
                     'activities.component_name as component_name',
                     'activities.title as activity_title',
                     'activities.cms_activity_id as cms_activity_id',
                     'activities.activity_type as activity_type',
                     "CONCAT('https://#{VtextDataGenerator::MAESTRO_URL}/sections/0/activities/', activities.id) AS link",
                     '"" as domain', '"" as subdomain', '"" as standards_id_list'
                   )

      filter_by_type(activities)
    end
    # rubocop:enable Metrics/MethodLength

    private def filter_by_type(activities)
      case @activity_type
      when 'Activity'
        activities.where(activities: { instructor_id: nil }, concepts: { assessment: false })
      when 'Assessment'
        activities.where(activities: { instructor_id: nil }, concepts: { assessment: true })
      else
        activities
      end
    end

    private def activity_base
      if @activity_type == 'Activity'
        Activity.has_toc_location_plus_unlisted
      else
        Activity
      end
    end
  end
end
