class ExpressCourseCreator
  include TimeHandler

  DEFAULT_COURSE_ARGS = {
    allow_audio_transcripts: false,
    video_subtitle_languages: 'foreign',
    video_transcript_languages: 'none',
    allow_video_popup_translation: false,
    allows_help_requests: true,
    allows_review_requests: true,
    chat_level: 'partner_chat'
  }

  attr_reader :instructor, :program, :job_id

  DEFAULT_CATEGORY_ARGS = {
    credit_only: false,
    max_attempts: 2,
    enhanced_feedback_disabled: false,
    accept_late_work: true,
    late_work_penalty: 'percent_per_day',
    penalty_percent: 5,
    scoring_rulesets_attributes: [{
      must_match_accents: true,
      must_match_capitalization: false,
      must_match_punctuation: false
    }]
  }

  def initialize(instructor, program, args)
    @instructor = instructor
    @program = program
    @args = args
  end

  def create
    course, sections = ActiveRecord::Base.transaction do
      course = create_course
      sections = create_sections(course)
      [course, sections]
    end
    # both of these enqueue Sidekiq jobs which is
    # why they are outside of the transaction
    create_course_licenses(course)
    create_assignments(course, sections)
    create_external_items(course) if @args[:copy_igc]
    course
  end

  private def school
    School.find(@args[:course][:school_id])
  end

  private def default_course_args
    if school.has_chat_support_enabled?
      DEFAULT_COURSE_ARGS
    else
      DEFAULT_COURSE_ARGS.merge(chat_level: 'disabled')
    end
  end

  private def create_course
    extra_args = {
      course_config_json: {
        setup_method: 'express_setup',
        supersite_jr: program.supersite_junior?,
        express_course_copied: @args[:course][:copy_created_activities_from_previous_course],
        course_copied_id:,
        learning_track: @args[:course][:selected_learning_track],
        streamlined_rostering_setup: ''
      }.to_json,
      owner_id: instructor.id,
      program_id: program.id,
      standard_set_ids: @args[:course][:standard_set_ids]
    }.merge(help_request_extra_args)
    Course.create! @args[:course].except(:selected_learning_track)
                                 .merge(default_course_args)
                                 .merge(extra_args)
  end

  private def help_request_extra_args
    if program&.supersite_junior?
      {
        'allows_help_requests' => false,
        'allows_review_requests' => false
      }
    else
      {}
    end
  end

  def create_course_licenses(course)
    # delegate course license creation to a Sidekiq job
    CourseLicenseCreatorWorker.perform_in(
      3.seconds,
      course.guid,
      @args[:course][:course_package_ids]
    )
  end
  private :create_course_licenses

  def create_sections(course)
    course.sections.build(section_args).each do |section|
      section_instructor_attributes = {
        role: 'Instructor',
        user_id: instructor.id
      }
      section.section_instructors.build(section_instructor_attributes)
      section.save!
    end
  end
  private :create_sections

  private def create_assignments(course, sections)
    @job_id = BulkAssignmentWorker.perform_async(
      sections.map(&:id),
      course.id,
      assignment_args,
      @args[:categories].to_h,
      @args[:src_section_id]
    )
  end

  private def create_external_items(course)
    course.sections.each do |section|
      CopyExternalItemsWorker.perform_async(
        section.id,
        @args[:src_section_id],
        _use_course_categories_map = true,
        @args[:categories].to_h
      )
    end
  end

  private def section_args
    # Future: Use the user's last section's due_time as a default if none is set.
    @section_args ||= @args[:sections].map do |name|
      {
        name: name,
        time_zone: instructor.time_zone || Time.zone.name,
        due_time: set_time_from_params('11', '59', 'PM'),
        instructor_id: instructor.id
      }
    end
  end

  private def assignment_args
    # individual assignments from express course
    # need to be copied as section assignments
    # (individually_assignable = false)
    # as a product requirement
    @assignment_args ||= @args[:assignments].to_h.each do |_date, assignments|
      assignments.each do |assignment|
        assignment[:individually_assignable] = false
      end
    end
  end

  private def course_copied_id
    if @args[:course][:copy_created_activities_from_previous_course]
      @args[:course][:course_library_from]
    else
      ''
    end
  end
end
