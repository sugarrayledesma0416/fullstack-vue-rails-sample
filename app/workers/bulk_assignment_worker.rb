class BulkAssignmentWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include BulkAssignmentWorkerSetup

  sidekiq_options retry: false

  def perform(section_ids, course_id, raw_assignments, category_map, source_section_id, destroy_old = false)
    # do not delete assignments with due dates of today and earlier;
    # they should remain locked and won't be in the list of raw_assignments
    # to be recreated.
    cutoff_date = Date.tomorrow

    # Remove any due date keys that have no assignments
    raw_assignments.reject! { |k, v| v.blank? }

    # in BulkAssignmentWorkerSetup
    # define @category_map, @assignment_calendar_slices, @num_assignments, @total_work
    # lookup @course and @sections
    setup(section_ids, course_id, raw_assignments, category_map, source_section_id)

    # used for progress bar, activated by Sidekiq::Status::Worker
    progress_counter = 1

    ActiveRecord::Base.transaction do
      if destroy_old
        # Unassign all existing activities scheduled in the future
        # before making new assignments.
        @sections.each do |section|
          destroyed_assignments = section.assignments.not_external.where("due_date >= ?", cutoff_date).destroy_all
          logger.info "Destroyed #{destroyed_assignments.count} assignments for section #{section.id} with due date on and after #{cutoff_date}"
        end
      end

      # Create categories from category map even when there are no assignments
      creator = BulkAssignmentCreator.new(@sections, @course, @category_map, @source_section)
      @categories = creator.categories

      logger.info "Creating #{@num_assignments} assignments for course #{course_id} and sections #{section_ids.join(', ')}"

      @assignment_calendar_slices.each do |slice|
        # Calculate progress to nearest percent for progress bar.
        at((progress_counter / @total_work * 100).to_i)
        creator.create(slice)
        progress_counter += 1
      end
    end

    # bulk import the assignments into the gradebook database
    unless @num_assignments == 0
      GradebookEngine::Assignment.transaction do
        gb_creator = BulkGbAssignmentCreator.new(@course, @sections, @categories)

        logger.info "Creating #{@num_assignments} gradebook assignments for course #{course_id} and sections #{section_ids.join(', ')}"

        @assignment_calendar_slices.each do |slice|
          # Calculate progress to nearest percent for progress bar.
          at((progress_counter / @total_work * 100).to_i)
          gb_creator.create(slice)
          progress_counter += 1
        end
      end
    end

    # set progress bar to 100. We're done.
    at 100
  end
end
