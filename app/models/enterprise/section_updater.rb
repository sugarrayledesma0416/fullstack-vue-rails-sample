module Enterprise
  class SectionUpdater
    def initialize(params, section)
      @section_params = params
      @section = section

      raise 'At least one instructor must be shown in section preview.' if no_instructors_shown
    end

    def update_section
      ActiveRecord::Base.transaction do
        update_section_instructors
        @section.update!(filtered_section_params)
      end
    end

    private def update_section_instructors
      # Find current list of section instructors
      current_additional_instructor_ids = @section.additional_instructors.map(&:user_id)
      new_additional_instructor_ids = @section_params[:additional_instructors].map { |ai| ai[:instructor_id] }
      new_additional_instructor_lookup = @section_params[:additional_instructors].each_with_object({}) do |ai, h|
        h[ai[:instructor_id]] = ai
      end

      # Delete any section instructors not in additional-instructors list
      instructors_to_delete = current_additional_instructor_ids - new_additional_instructor_ids
      SectionInstructor.where(section: @section, user_id: instructors_to_delete).destroy_all

      # Add any section instructors not in current list
      instructors_to_add = new_additional_instructor_ids - current_additional_instructor_ids
      instructors_to_add.each do |id|
        instructor_data = new_additional_instructor_lookup[id]
        SectionInstructor.create(
          section: @section,
          user_id: id,
          role: instructor_data[:role],
          show: instructor_data[:show]
        )
      end

      # Update any section instructors in both current and additional-instructors list
      instructors_to_update = current_additional_instructor_ids & new_additional_instructor_ids
      instructors_to_update.each do |id|
        instructor_data = new_additional_instructor_lookup[id]
        SectionInstructor.where(section: @section, user_id: id).update(
          role: instructor_data[:role],
          show: instructor_data[:show]
        )
      end

      # Set instructor team IDs:
      #   - reload object so that it gets updated section instructors
      #   - save object to invoke the set_instructor_team_ids before_save
      @section.reload
      @section.save!
    end

    private def no_instructors_shown
      @section_params[:hide_owner_name] && @section_params[:additional_instructors].map { |ai| ai[:show] }.none?
    end

    private def filtered_section_params
      @section_params.slice(:name, :hide_owner_name, :open_to_students, :days_to_show_assignment_due_date, :due_time, :time_zone)
    end
  end
end
