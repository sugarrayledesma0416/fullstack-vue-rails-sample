module DemoCourseBuild
  class Course
    ATTRIBUTES_TO_CLONE = [:name, :level, :first_unit_id, :last_unit_id, :allow_audio_transcripts,
                           :access_level, :components, :video_subtitle_languages,
                           :video_transcript_languages, :allow_video_popup_translation].freeze

    attr_reader :owner, :program, :course_attributes, :errors

    def initialize(owner:, program:)
      @errors = ActiveModel::Errors.new(self)
      @owner = owner
      @program = program
      @course_attributes = trial_course_attributes
    end

    def create_demo_course
      if model_data.model_data_exists?
        DemoCourse.create(course_attributes)
      else
        model_data.errors.full_messages.each { |message| errors.add(:base, message) }
        self
      end
    end

    def valid?
      errors.empty?
    end

    private def trial_course_attributes
      # bail if we don't have a model section. validation will take care of setting appropriate errors
      # if this happens
      return unless model_data.model_section.present?

      model_course_attributes.merge(
        end_date: default_end_date,
        is_demo: true,
        owner_id: owner.id,
        program_id: program.id,
        school_id: school.id,
        start_date: default_start_date,
        updated_by: owner.id
      ).tap do |memo|
        memo[:chat_level] = 'disabled' if school.has_chat_support_disabled?
      end
    end

    private def school
      @school ||= owner.schools.last
    end

    private def model_course_attributes
      model_data.model_course.attributes.reject do |key, value|
        !ATTRIBUTES_TO_CLONE.include?(key.to_sym)
      end
    end

    private def model_data
      @model_data ||= ModelData.new(program: program)
    end

    private def default_start_date
      8.days.ago.to_date
    end

    private def default_end_date
      92.days.from_now.to_date
    end
  end
end
