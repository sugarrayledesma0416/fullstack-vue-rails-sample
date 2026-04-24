class StudyPlanFixer
  def fix
    generate_missing_study_plan_concepts

    return if attempts.nil?

    attempts.find_each(batch_size: 500) do |attempt|
      next if attempt.send(:submission_migration_needed?) # Ignore attempts stored as XML
      next if attempt.user.nil? || attempt.user&.archived?

      results = attempt.results

      next unless results

      activity = attempt.activity.ensure_correct_version(attempt.cms_revision_id)
      activity ||= attempt.activity

      UserReadingsGenerator.new(activity, results, attempt.section, attempt.user).generate
      sleep(0.05)
    end
  end

  def dry_run
    activity_count = activities.count
    attempts_count = (attempts && attempts.count) || 0
    missing_concepts = activities.sum { |activity| activity.content_object.concepts.size }

    puts "Activities with missing study plan concepts #{activity_count}"
    puts "Attempts to be retrieved to create user readings: #{attempts_count}"
    puts "Study plan concepts to be generated #{missing_concepts}"
  end

  private def generate_missing_study_plan_concepts
    activities.each do |activity|
      StudyPlanConceptsCreator.new(activity, activity.program.id).create
    end
  end

  private def activities
    @activities ||= Activity.includes(lesson: { unit: :program })
                            .joins('LEFT JOIN study_plan_concepts ' \
                                   'ON activities.id = study_plan_concepts.activity_id' \
                                   ' AND activities.cms_revision_id = study_plan_concepts.cms_revision_id')
                            .where(activity_type: 'study_plan_practice_test')
                            .where('activities.toc_location is not null')
                            .where('study_plan_concepts.id IS NULL')
  end

  private def attempts
    return @attempts if defined?(@attempts)

    @attempts = unless activities.empty?
                  Attempt.by_activities(*activities)
                         .joins(:activity)
                         .includes(:user, :section, activity: { lesson: :unit })
                         .where(status_code: AttemptStatus::CODE_COMPLETED)
                         .where('user_id IS NOT NULL')
                end
  end
end
