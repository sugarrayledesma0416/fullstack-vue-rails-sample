class PhantomActivityMigrator < PhantomActivityFixer
  # this class is a special adaptation of the PhantomActivityFixer
  # which handles the particular case where the two activities are not 
  # purely identical. They will have different cms_activity_id's
  # but have nearly identical content. This situation is the result
  # of a publishing bug that was active between 12/14/2019 and 1/6/2020.
  # It is meant to be run on the command line by Tech Dev.
  # Method calls are tracked visually with puts statements before
  # calling the method in the base class.

  # the first activity is archived, the second wins. Choose wisely.
  def initialize(id_first_activity, id_second_activity)
    @errors = []
    @id_first_activity = id_first_activity
    @id_second_activity = id_second_activity
  end

  def process
    @activity_to_archive, @winner_activity = validate_activities

    activity_phantom_duplicate_allocate
    remove_activity_phantom
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, StandardError => e
    errors << e
  end

  private def validate_activities
    # ensure the activities exist
    first_act = Activity.find(@id_first_activity)
    second_act = Activity.find(@id_second_activity)

    # ensure that they "match", same title, type, lesson and concept
    if first_act.title == second_act.title &&
       first_act.activity_type == second_act.activity_type &&
       first_act.toc_location.present? &&
       second_act.toc_location.present? &&
       first_act.toc_location == second_act.toc_location &&
       first_act.concept_id == second_act.concept_id &&
       first_act.lesson_id == second_act.lesson_id
      [first_act.id, second_act.id]
    else
      puts first_act.attributes.slice(*%w[id title activity_type lesson_id toc_location concept_id])
      puts second_act.attributes.slice(*%w[id title activity_type lesson_id toc_location concept_id])
      raise StandardError, 'Activities do not seem to match'
    end
  end

  private def remove_activity_phantom
    puts 'remove_activity_phantom' unless Rails.env.test?
    super
  end

  private def activity_phantom_duplicate_allocate
    puts 'activity_phantom_duplicate_allocate' unless Rails.env.test?
    super
  end

  private def new_allocation_sections
    puts 'new_allocation_sections' unless Rails.env.test?
    super
  end

  private def update_attempts(section, attempts_already_completed)
    puts 'update_attempts' unless Rails.env.test?
    super(section, attempts_already_completed)
  end

  private def update_attempt_duration(section, attempts_already_completed)
    puts 'update_attempt_duration' unless Rails.env.test?
    super(section, attempts_already_completed)
  end

  private def create_score_actions(section)
    puts 'create_score_actions' unless Rails.env.test?
    super(section)
  end

  private def update_assignments(section_id)
    puts 'update_assignments' unless Rails.env.test?
    super(section_id)
  end

  private def destroy_convergent_section
    puts 'destroy_convergent_section' unless Rails.env.test?
    super
  end

  private def section_student_ids(section)
    @section_student_ids ||= {}
    @section_student_ids[section.id] ||= section.current_students_base.pluck(:id)
  end
end
