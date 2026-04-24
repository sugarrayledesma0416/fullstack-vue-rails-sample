namespace :ai_grading_suggestion do
  task generate_grading_suggestions_for_prompt: :environment do |task_name|
    suggestion_prompt_id = ENV['suggestion_prompt_id']

    if suggestion_prompt_id.blank?
      puts "usage: rake #{task_name} suggestion_prompt_id=<id>"
      exit(1)
    end

    suggestion_prompt = AI::GradingSuggestionPrompt.find(suggestion_prompt_id)

    AI::LiveData::GradingSuggestionsForPromptGenerator.new(
      suggestion_prompt
    ).generate
  end

  task generate_overall_comments_for_prompt: :environment do |task_name|
    overall_prompt_id = ENV['overall_prompt_id']

    if overall_prompt_id.blank?
      puts "usage: rake #{task_name} overall_prompt_id=<id>"
      exit(1)
    end

    overall_prompt = AI::OverallCommentPrompt.find(overall_prompt_id)

    AI::LiveData::OverallCommentsForPromptGenerator.new(
      overall_prompt
    ).generate
  end

  task save_student_data: :environment do |task_name|
    dry_run_arg = ENV['dry_run']&.downcase
    activity_ids = ENV['activity_ids'].to_s.split(',').map(&:strip)
    num_submissions = ENV['num_submissions'].to_i
    min_response_size = ENV['min_response_size'].to_i
    max_response_size = ENV['max_response_size'].to_i

    if %w[true false].exclude?(dry_run_arg) ||
       activity_ids.empty? ||
       !num_submissions.positive? ||
       min_response_size.negative? ||
       !max_response_size.positive? ||
       min_response_size > max_response_size
      puts "usage: rake #{task_name} activity_ids=<ids> num_submissions=<number> " \
           'min_response_size=<number> max_response_size=<number> dry_run=<true|false>'
      exit(1)
    end

    dry_run = dry_run_arg == 'true'
    puts 'DRY RUN mode, no record will be saved!' if dry_run

    Activity.find(activity_ids).each do |activity|
      ActivitySubmissionSaver.new(
        activity:,
        dry_run:,
        response_size_range: (min_response_size..max_response_size),
        num_submissions:
      ).save
    end
  end

  class ActivitySubmissionSaver
    attr_reader :activity, :dry_run, :response_size_range, :num_submissions

    def initialize(activity:, dry_run:, response_size_range:, num_submissions:)
      @activity = activity
      @dry_run = dry_run
      @response_size_range = response_size_range
      @num_submissions = num_submissions
    end

    def save
      activity.content_object.questions.each do |question|
        ActivityQuestionSubmissionSaver.new(
          activity:,
          dry_run:,
          question:,
          response_size_range:,
          num_submissions:
        ).save
      end
    end
  end

  class ActivityQuestionSubmissionSaver
    attr_reader :activity, :dry_run, :response_size_range, :num_submissions, :offset, :question

    def initialize(activity:, dry_run:, response_size_range:, num_submissions:, question:)
      @activity = activity
      @dry_run = dry_run
      @response_size_range = response_size_range
      @num_submissions = num_submissions
      @offset = 0
      @question = question
    end

    def save
      puts "Activity #{activity.id}, #{question.label}: " \
           "#{existing_input_attempt_ids.count} existing inputs."

      loop do
        # Break if we have enough submissions
        break if existing_input_attempt_ids.count >= num_submissions

        attempts = find_next_attempts

        # Stop if there is no more attempt to process
        break if attempts.empty?

        attempts.each do |attempt|
          next unless attempt.results.has_response?(question.label)
          next unless response_size_range.include?(attempt.results.response(question.label).size)

          save_suggestion_input(
            attempt:,
            question:,
            student_response: attempt.results.response(question.label)
          )
          existing_input_attempt_ids << attempt.id
          break if existing_input_attempt_ids.count >= num_submissions
        end

        @offset += attempts.count
      end
      puts "-> #{existing_input_attempt_ids.count} total inputs."
    end

    private def existing_input_attempt_ids
      @existing_input_attempt_ids ||= AI::GradingSuggestionInput.where(
        activity_id: activity.id,
        question_label: question.label
      ).pluck(:attempt_id)
    end

    private def find_next_attempts
      Attempt.where.not(
        section_id: 0
      ).where.not(
        id: existing_input_attempt_ids
      ).where(
        status_code: AttemptStatus::CODE_COMPLETED,
        activity_id: activity.id
      ).order(
        updated_at: :desc
      ).offset(
        offset
      ).limit(
        num_submissions
      )
    end

    private def save_suggestion_input(attempt:, question:, student_response:)
      return if dry_run

      input = AI::GradingSuggestionInput.create!(
        program_id: activity.program.id,
        activity_id: activity.id,
        attempt_id: attempt.id,
        question_label: question.label,
        student_response:
      )
      AI::GradingSuggestionGenerators::AsyncQuestionGenerator.new(
        attempt:,
        question_label: question.label,
        grading_suggestion_input: input
      ).generate
      AI::OverallCommentGenerators::AsyncQuestionGenerator.new(
        attempt:,
        question_label: question.label,
        grading_suggestion_input: input
      ).generate
    end
  end

  task generate_student_data: :environment do
    raise 'DO NOT RUN on Live server!!!' if Rails.env.live?

    program_id = 347 # Portales 2.0

    program = Program.find(program_id)

    puts "Generating data for program #{program.title}"

    instructor = Instructor.find_by(username: 'vhl_instructor')
    students = Student.where(
      username: [
        'vhl_1_student',
        'vhl_2_student',
        'vhl_3_student',
        'vhl_4_student',
        'vhl_5_student',
        'vhl_6_student',
        'vhl_7_student',
        'vhl_8_student',
        'vhl_9_student',
        'sl_1_student',
        'sl_2_student',
        'sl_3_student',
        'sl_4_student',
        'sl_5_student',
        'sl_6_student',
        'sl_7_student',
        'sl_8_student',
        'sl_9_student'
      ]
    )
    open_ended_activity = program.activities.where(
      activity_type: 'open_ended'
    ).limit(10)
    composition_activity = program.activities.where(
      activity_type: 'composition'
    ).limit(10)
    activities = open_ended_activity + composition_activity

    activities.each do |activity|
      puts "Using #{activity.activity_type} activity, #{activity.lesson.label} | #{activity.strand.title} | #{activity.title} (id: #{activity.id})"
    end

    Dangerfield::Gatekeeper.instance.disabled = false
    creator = FakeAiGradingSubmissionCreator.new(program:, instructor:)

    creator.enroll_students(students)

    activities.each do |activity|
      creator.assign_activity(activity)
    end

    answers = [
      nil,
      'Respuesta corta',
      'Esta es una respuesta que es mayor que el mínimo esperado.',
      'Esta es un respuesta que es mayor que el mínima esperado.',
      'Y esta es otra respuesta válida.'
    ]

    activities.each do |activity|
      students[0..0].each do |student|
        creator.open_activity(user: student, activity:)
      end

      students[1..1].each do |student|
        creator.submit_activity(user: student, activity:)
      end

      students[2..10].each do |student|
        creator.complete_activity(
          activity:,
          user: student,
          submitted_values: activity.content_object.questions.to_h do |question|
            [question.label, answers.sample]
          end
        )
      end
    end
    Dangerfield::Gatekeeper.instance.disabled = true
  end

  class FakeAiGradingSubmissionCreator
    attr_reader :instructor, :program

    def initialize(program:, instructor:)
      @instructor = instructor
      @program = program
    end

    def course
      @course ||= Course.find_or_create_by!(
        name: 'AI grading suggestion',
        owner: instructor,
        program:
      ) do |record|
        record.school = instructor.schools.first
        record.creator = instructor
        record.start_date = 1.day.ago.to_date
        record.end_date = 6.months.from_now.to_date
        record.first_unit = program.units.first
        record.last_unit = program.units.last
      end.tap do |course|
        # create course licenses
        course_options = CourseOptions.new(instructor, course, program)
        course_package_ids = course_options.levels.pluck('id')
        CourseLicenseCreatorWorker.perform_async(course.guid, course_package_ids)
      end
    end

    def section
      @section ||= Section.find_or_create_by!(
        course:,
        instructor:,
        name: 'Section 1'
      ) do |record|
        record.schedule = 'TH 5:00 PM'
        record.due_time = course.end_date.to_datetime
        record.time_zone = 'Eastern Time (US & Canada)'
      end.tap do |section|
        SectionInstructor.find_or_create_by!(
          instructor:,
          role: 'Instructor',
          section:
        )
      end
    end

    def category
      @category ||= Category.find_or_create_by!(
        course:,
        name: 'Homework'
      ) do |record|
        record.weighting_percent = 100
        record.accept_late_work = true
        record.late_work_penalty = 'percent_per_day'
        record.penalty_percent = 5
        record.credit_only = false
        record.drop_low_scores = 0
      end
    end

    def scoring_ruleset
      @scoring_ruleset ||= ScoringRuleset.find_or_create_by!(
        category:
      ) do |record|
        record.ignore_accents = false
        record.ignore_capitalization = false
        record.ignore_punctuation = false
      end
    end

    def enroll_students(students)
      students.each do |student|
        Enrollment.find_or_create_by!(
          user: student,
          section:
        ) do |record|
          record.state = 'enrolled'
        end
      end
    end

    def assign_activity(activity)
      Assignment.find_or_create_by!(
        assignable: activity,
        section:,
        category:
      ) do |record|
        record.due_date = section.due_time
      end
    end

    def open_activity(activity:, user:)
      Attempt.find_or_create_by(
        activity:,
        section:,
        user:
      ) do |record|
        record.status_code = AttemptStatus::CODE_OPENED
        record.cms_activity_id = activity.cms_activity_id
        record.cms_revision_id = activity.cms_revision_id
        record.time_spent = 0
        record.scoring_ruleset = scoring_ruleset
      end
    end

    def submit_activity(activity:, user:)
      Attempt.find_or_create_by(
        activity:,
        section:,
        user:
      ) do |record|
        record.status_code = AttemptStatus::CODE_SUBMITTED
        record.cms_activity_id = activity.cms_activity_id
        record.cms_revision_id = activity.cms_revision_id
        record.time_spent = 0
        record.scoring_ruleset = scoring_ruleset
      end
    end

    def complete_activity(activity:, user:, submitted_values:)
      attempt = Attempt.find_or_create_by(
        activity:,
        section:,
        user:
      ) do |record|
        record.status_code = AttemptStatus::CODE_COMPLETED
        record.cms_activity_id = activity.cms_activity_id
        record.cms_revision_id = activity.cms_revision_id
        record.time_spent = 0
        record.scoring_ruleset = scoring_ruleset
      end
      results = attempt.validate_responses(
        activity,
        submitted_values,
        request_env
      )
      Attempt.transaction do
        attempt.write_results(results, true)

        submission = Gradebook::Submission.new(user, section, activity)
        submission.submit(results, Time.now.utc, attempt.time_spent, attempt.submission_length)
      end
    end

    private def request_env
      @request_env ||= {
        'HTTP_USER_AGENT' => 'AI rake task'
      }
    end
  end
end
