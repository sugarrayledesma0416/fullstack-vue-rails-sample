module Enterprise
  class SectionCreator
    def initialize(params, course)
      @course = course

      unless @course.created_from_enterprise? && @course.enterprise_section.present?
        raise(
          ArgumentError,
          "Course id=#{@course.id} must be from enterprise and have an enterprise section."
        )
      end

      @enterprise_template ||= @course.enterprise_section
      @section_data = params
      @new_external_activity_ids = {}
    end

    def create_section
      uncopied_assignment_status = []

      # dup it@template_id
      section = @enterprise_template.dup

      # copy values from course and section_data to section
      copy_values_to_section(section)

      # assign instructor and any additional instructors
      assign_section_instructors_attributes(section)

      dup_time_settings(section)
      # save the new section
      section.save!

      result = copy_assignments(section)

      uncopied_assignment_status << result[:uncopied_assignments]


      { uncopied_assignments: uncopied_assignment_status.any? }
    end

    private def assign_section_instructors_attributes(section)
      # NOTE: There should be only one SI record per section with role = 'Instructor',
      #       and it needs to match the instructor_id value on the section.

      section.section_instructors_attributes = [
        instructor_attributes
      ].concat(
        additional_instructor_attributes
      )
    end

    private def dup_time_settings(section)
      section.days_to_show_assignment_due_date = @section_data[:days_to_show_assignment_due_date]
      section.due_time = @section_data[:due_time]
      section.time_zone = @section_data[:time_zone]
    end

    private def instructor_attributes
      { role: 'Instructor',
        show: @section_data[:show_owner],
        user_id: @course.owner_id,
        hide_from_instructor_dashboard: @course.hide_from_instructor_dashboard }
    end

    private def additional_instructor_attributes
      @section_data.fetch(:additional_instructors, []).map do |addl_inst|
        { role: addl_inst[:role],
          show: addl_inst[:show],
          user_id: addl_inst[:instructor_id] }
      end
    end

    private def copy_values_to_section(section)
      # set the course ID to the given course
      section.course_id = @course.id
      # set the GUID to nil so that a new GUID will be assigned
      section.guid = nil
      # set whether to hide owner name
      section.hide_owner_name = @section_data[:hide_owner_name]
      # set the name
      section.name = @section_data[:name]
      # Ensure we're not creating an enterprise section
      section.is_enterprise = false
      # set the source template
      section.source_template_id = @enterprise_template.id
      # set the instructor_id as course owner's ID
      section.instructor_id = @course.owner_id
    end

    private def copy_assignments(section)
      # Get the section-template assignments as an array of arrays,
      #   where each array contains the values for an assignment record
      #   in database column order.
      #
      # This is to optimize the `Assignment.import`, which runs fastest
      #   given an array of column names and an array of column-value arrays.

      original_assignment_count = Assignment.where(section: @enterprise_template).count
      original_external_assignment_count = GradebookEngine::ExternalAssignment
                                             .where(section_id: @enterprise_template.id)
                                             .count
      original_total_assignment_count = original_assignment_count + original_external_assignment_count

      # get course start, end dates in case of conflict
      start_date = section.course.start_date
      end_date = section.course.end_date

      # Find all assignment templates that fall within course date range.
      #   Order them by ID. This will determine the order of insertion for
      #   assignments in the new section. When we map assignment IDs from the
      #   template to the section so that we can copy assessment details,
      #   we will be able to retrieve the template assignments in this same
      #   order and correctly map them to the section assignments ordered by
      #   ID.
      original_assignments = Assignment
                               .where(section: @enterprise_template)
                               .where('due_date >= ? and due_date <= ?', start_date, end_date)

      assignment_records = original_assignments
                             .order(:id)
                             .pluck(*column_metadata[Assignment][:columns])

      external_assignment_query = GradebookEngine::ExternalAssignment
                                    .where(section_id: @enterprise_template.id)
                                    .where('day_id >= ? and day_id <= ?', start_date, end_date)

      external_assignment_records = external_assignment_query
                                      .pluck(
                                        *column_metadata[GradebookEngine::ExternalAssignment][:columns]
                                      )

      external_activity_records = external_assignment_query
                                    .map(&:external_activity)
                                    .pluck(
                                      *column_metadata[GradebookEngine::ExternalActivity][:columns]
                                    )

      gchat_assignments = get_gchat_assignments(original_assignments)

      external_activity_import_results = GradebookEngine::ExternalActivity.import(
        column_metadata[GradebookEngine::ExternalActivity][:columns],
        external_activity_records,
        validate: false
      )

      @new_external_activity_ids[section.id] = external_activity_import_results.ids

      # Update each column-value array with values for the new section.
      assignment_records.each do |record|
        update_assignment_record(record, section)
      end

      # For external assignments, it's more complicated.
      #   Each external activity has to be copied to a new external activity,
      #   and the external assignment's external_activity_id needs to be updated
      #   with that activity's ID.

      external_assignment_records.each_with_index do |record, index|
        update_external_assignment_record(record, section, index)
      end

      # Reject assignment records with null category ID:
      # the original category from the template either no longer exists in the course,
      # or its name has been changed.
      records_to_copy = assignment_records.reject do |record|
        record[assignment_indices[:category_id]].nil?
      end

      external_records_to_copy = external_assignment_records.reject do |record|
        record[column_metadata[GradebookEngine::ExternalAssignment][:indices][:category_id]].nil?
      end

      records_to_copy_total_count = records_to_copy.size + external_records_to_copy.size

      # Bulk-import the updated arrays to the assignments table.
      #
      # Validations are skipped for optimization. The assignments were validated
      #   when the section template was created, so skipping should be OK.
      #
      # NOTE: for now, I am not adding error handling for any failed insertions.

      Assignment.import(column_metadata[Assignment][:columns],
                        records_to_copy,
                        validate: false)

      copy_assessment_details(section)

      create_gchat_assignment_configs(gchat_assignments, section.id) if gchat_assignments.present?

      # Sync the assignments to the gradebook.
      InstitutionAdminGradebookAssignmentSyncWorker.perform_async(section.id)

      GradebookEngine::ExternalAssignment.import(
        column_metadata[GradebookEngine::ExternalAssignment][:columns],
        external_records_to_copy,
        validate: false
      )

      # Return whether any assignments could not be copied.
      # I'm using a hash in case we need to return any other data
      # about the assignments.

      uncopied_count = original_total_assignment_count - records_to_copy_total_count
      { uncopied_assignments: uncopied_count.positive? }
    end

    private def copy_assessment_details(section)
      # Get records for assigned assessment details.
      assessment_detail_records = AssignedAssessmentDetail
                                    .includes(:assignment)
                                    .where(assignments: { section: @enterprise_template })
                                    .pluck(*column_metadata[AssignedAssessmentDetail][:columns])

      # Update them with new assignment IDs.
      update_assessment_detail_records(assessment_detail_records, section)

      # Import them back into AssignedAssessmentDetails.
      AssignedAssessmentDetail.import(column_metadata[AssignedAssessmentDetail][:columns],
                                      assessment_detail_records,
                                      validate: false)
    end

    private def get_gchat_assignments(original_assignments)
      original_assignments
        .where.not(category_id: nil)
        .select(
          'assignments.*, gcac.group_maximum, gcac.group_minimum'
        ).joins(
        'INNER JOIN group_chat_assignment_configs ' \
          'gcac ON gcac.assignment_id = assignments.id'
      )
    end

    private def create_gchat_assignment_configs(original_gchat_assignments, section_id)
      gchat_assignment_config_creater = BulkGchatAssignmentConfigCreator.new(
        original_gchat_assignments,
        section_id
      )
      gchat_assignment_config_creater.create
    end

    private def column_metadata
      @column_metadata ||= begin
                             tables = [AssignedAssessmentDetail,
                                       Assignment,
                                       GradebookEngine::ExternalActivity,
                                       GradebookEngine::ExternalAssignment]

                             tables.each_with_object({}) do |table, memo|
                               memo[table] = {}

                               # Get the table column names, apart from :id, as symbols.
                               #   We skip :id because, when we import records back into the table,
                               #   the database will assign the value for :id.
                               columns_no_id = table.columns.map(&:name).map(&:to_sym) - [:id]
                               memo[table][:columns] = columns_no_id

                               # Include a column name => index lookup.
                               memo[table][:indices] = columns_no_id
                                                         .each_with_index
                                                         .map { |column, index| [column, index] }
                                                         .to_h
                             end
                           end
    end

    private def update_assignment_record(record, section)
      category_id_index = assignment_indices[:category_id]
      created_at_index = assignment_indices[:created_at]
      section_id_index = assignment_indices[:section_id]
      individually_assignable_index = assignment_indices[:individually_assignable]
      updated_at_index = assignment_indices[:updated_at]

      original_category_id = record[category_id_index]
      record[category_id_index] = category_map[original_category_id]
      record[created_at_index] = section.created_at
      record[section_id_index] = section.id
      record[individually_assignable_index] = false
      record[updated_at_index] = section.updated_at
    end

    private def update_external_assignment_record(record, section, index)
      indices = column_metadata[GradebookEngine::ExternalAssignment][:indices]

      original_category_id = record[indices[:category_id]]
      record[indices[:category_id]] = category_map[original_category_id]
      record[indices[:created_at]] = section.created_at
      record[indices[:external_activity_id]] = @new_external_activity_ids[section.id][index]
      record[indices[:section_id]] = section.id
      record[indices[:updated_at]] = section.updated_at
    end

    private def update_assessment_detail_records(records, section)
      indices = column_metadata[AssignedAssessmentDetail][:indices]
      lookup = assignment_id_lookup(section)

      records.each do |record|
        # Update with assignment ID for new section.
        original_assignment_id = record[indices[:assignment_id]]
        record[indices[:assignment_id]] = lookup[original_assignment_id]

        # Change the timestamp columns to the new section's created_at time.
        record[indices[:created_at]] = section.created_at
        record[indices[:updated_at]] = section.created_at
      end
    end

    private def assignment_id_lookup(section)
      # Get assignment IDs for template.
      #   Order them by ID to guarantee that the order is the same as the
      #   insertion order of the assignments for the section.
      original_assignment_ids = Assignment
                                  .where(section: @enterprise_template)
                                  .order(:id)
                                  .pluck(:id)

      # Get assignment IDs for section.
      #   Order them by ID so that they're in their original insertion order.
      new_assignment_ids = Assignment
                             .where(section: section)
                             .order(:id)
                             .pluck(:id)

      # Create assignment-ID lookup,
      #   where assignment ID from the section template is the key.
      original_assignment_ids
        .zip(new_assignment_ids)
        .to_h
    end

    # Returns a lookup of new-course category IDs by course-template category ID.
    private def category_map
      # TODO: account for changes to category names.

      return @category_map if defined?(@category_map)

      # Create a lookup of the course's category IDs by name.
      category_name_to_id_map = @course.categories.each_with_object({}) do |category, map|
        map[category.name] = category.id
      end

      # Get the categories for the course template.
      category_templates = @course.categories

      # Map the course template's category IDs to the course's category IDs,
      #   using the name-ID lookup.
      @category_map = category_templates.each_with_object({}) do |category, hash|
        hash[category.id] = category_name_to_id_map[category.name]
      end
    end

    private def assignment_indices
      @assignment_indices ||= column_metadata[Assignment][:indices]
    end
  end
end
