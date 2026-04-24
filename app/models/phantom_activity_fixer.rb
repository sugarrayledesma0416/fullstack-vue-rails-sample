class PhantomActivityFixer
  attr_accessor :winner_activity,
                :activity_to_archive,
                :section_ids_to_move,
                :score_actions_to_remove,
                :errors

  # Define winner activity, the one with most assignments is the winner.
  def initialize(id_first_activity, id_second_activity)
    @errors = []
    @id_first_activity = id_first_activity
    @id_second_activity = id_second_activity
  end

  def process
    begin
      if @id_second_activity.positive?
        #sanity check on ids passed
        validate_activities

        # Sort activities by ascending assignment count,
        #   and mark the one with the lower count for archiving.
        @activity_to_archive, @winner_activity = [
          @id_first_activity,
          @id_second_activity
        ].sort do |a, b|
          Activity.find(a).assignments.size <=> Activity.find(b).assignments.size
        end

        activity_phantom_duplicate_allocate
      else
        @activity_to_archive = @id_first_activity
      end

      remove_activity_phantom
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, StandardError => e
      errors << e.message
    end
  end

  private def validate_activities
    # ensure the activities exist
    first_act = Activity.find(@id_first_activity)
    second_act = Activity.find(@id_second_activity)

    # ensure that they "match", same cms id, type, lesson and concept
    errors = []
    %w[cms_activity_id activity_type lesson_id toc_location concept_id].each do |attr|
      if first_act.send(attr) != second_act.send(attr)
        errors << "#{attr} does not match"
      end
    end

    unless errors.empty?
      raise StandardError, "Activities are not phantoms: #{errors.join(', ')}"
    end
  end

  private def remove_activity_phantom
    activity = Activity.find(@activity_to_archive)

    # ensure there are no assignments in open sections
    if activity.assignments.none? { |a| a.section&.open? }
      activity.update!(toc_location: nil, toc_location_rank: nil)
    else
      raise StandardError, "Activity ##{activity.id} has been assigned and cannot be removed."
    end
  end

  # Activity is assigned to a Student and duplicated
  private def activity_phantom_duplicate_allocate
    section_ids = Section
                  .open
                  .joins(:assignments)
                  .where(assignments: { assignable_id: @activity_to_archive,
                                        assignable_type: 'Activity' })
                  .group('sections.id')
                  .pluck('sections.id')
    @convergent_section_ids = Assignment.where(assignable_id: @winner_activity,
                                               assignable_type: 'Activity',
                                               section_id: section_ids)
                                        .pluck(:section_id)
    @section_ids_to_move = section_ids - @convergent_section_ids
    new_allocation_sections
  end

  private def new_allocation_sections
    @section_ids_to_move.each do |section_id|
      attempts_already_completed = Attempt.where(
        section_id: section_id,
        activity_id: @winner_activity,
        status_code: AttemptStatus::CODE_COMPLETED
      ).to_a # set this value to an array so the results will not
             # change after update_attempts() is run

      section = Section.find(section_id)
      update_attempts(section, attempts_already_completed)
      update_attempt_duration(section, attempts_already_completed)
      create_score_actions(section)
      update_assignments(section_id)
    end
    destroy_convergent_section
  end

  private def update_attempts(section, attempts_already_completed)
    student_ids = section_student_ids(section) - attempts_already_completed.pluck(:user_id)

    attempts =
      Attempt.where(section_id: section.id,
                    activity_id: @activity_to_archive,
                    user_id: student_ids,
                    status_code: AttemptStatus::CODE_COMPLETED)

    attempts.each do |act|
      act.activity_id = @winner_activity
      act.save!
    end
  end

  private def update_attempt_duration(section, attempts_already_completed)
    student_ids = section_student_ids(section) - attempts_already_completed.pluck(:user_id)

    GradebookEngine::AttemptDuration
      .where(section_id: section.id,
             user_id: student_ids,
             activity_id: @activity_to_archive)
      .update_all(activity_id: @winner_activity)
  end

  private def create_score_actions(section)
    GradebookEngine::ScoreAction.transaction do
      section_student_ids(section).each do |student_id|
        scores_to_move = GradebookEngine::ScoreAction.where(
          user_id: student_id,
          section_id: section.id,
          activity_id: @activity_to_archive
        ).order('id ASC')

        scores_to_move.each do |old_action|
          GradebookEngine::ScoreAction.create!(
            old_action.attributes.except('id', 'activity_id')
                                 .merge('activity_id' => @winner_activity)
          )
        end

        if scores_to_move.any?
          GradebookEngine::CurrentScoreAction.find_by(
            user_id: student_id,
            section_id: section.id,
            activity_id: @activity_to_archive
          ).destroy
        end
      end
    end
  end

  private def update_assignments(section_id)
    assignments = Assignment.where(assignable_id: @activity_to_archive,
                                   assignable_type: 'Activity',
                                   section_id: section_id)
    assignments.each do |assigment|
      assigment.assignable_id = @winner_activity
      assigment.save!
    end
  end

  private def destroy_convergent_section
    @convergent_section_ids.each do |section_id|
      assignments = Assignment.where(assignable_id: @activity_to_archive,
                                     assignable_type: 'Activity',
                                     section_id: section_id)
      assignments.each { |assigment| assigment.destroy }
    end
  end

  private def section_student_ids(section)
    @section_student_ids ||= {}
    @section_student_ids[section.id] ||= section.current_students_base.pluck(:id)
  end
end
