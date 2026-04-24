module Instructor::CreatedActivity
  class ActivityTypePresenter
    ACTIVITY_TYPES = {
      audio_composition: { label: 'Student Recording', display_kinds: %i[activity assessmnet] },
      composition: { label: 'Composition', display_kinds: %i[activity assessment filter] },
      drop_down: { label: 'Drop-down', display_kinds: %i[activity filter] },
      exam: { label: 'Assessment', display_kinds: %i[assessment filter] },
      external_link: { label: 'External Link', display_kinds: %i[activity filter] },
      external_video: { label: 'Video', display_kinds: %i[activity filter] },
      fill_in_the_blanks: { label: 'Fill In The Blanks', display_kinds: %i[activity filter] },
      multiple_answer: { label: 'Multiple Answer', display_kinds: %i[activity filter] },
      multiple_choice: {
        label: 'Multiple Choice',
        display_kinds: %i[activity filter],
        variants: [
          { choice_count: 2 },
          { choice_count: 3 },
          { choice_count: 4 }
        ]
      },
      multiple_choice_same: { label: 'True or False', display_kinds: %i[activity filter] },
      open_ended: { label: 'Free Response', display_kinds: %i[activity filter] },
      partner_chat: {
        label: 'Partner Chat',
        display_kinds: %i[activity assessment filter],
        conditional: :not_supersite_junior?
      },
      recording_v2: { label: 'Audio Recording', display_kinds: %i[activity filter] },
      solo_video_recording: { label: 'Video Recording', display_kinds: %i[activity filter] },
      upload_file_activity: { label: 'Upload File', display_kinds: %i[activity filter] }
    }.freeze

    def initialize(view)
      @view = view
    end

    def activity_label(activity_type, activity_params = {})
      config = ACTIVITY_TYPES[activity_type]
      label = config[:label]

      if activity_type == :multiple_choice && activity_params[:choice_count]
        label = "#{label} (#{activity_params[:choice_count]} options)"
      end

      label
    end

    def formatted_activity_types
      sorted_displayable_activity_types.flat_map do |activity_type, config|
        if config[:variants]
          config[:variants].map { |variant| [activity_type, variant] }
        else
          [[activity_type, config.except(:conditional, :label, :display_kinds)]]
        end
      end
    end

    def displayable_activity_types
      ACTIVITY_TYPES.select { |activity_type, _| should_display?(activity_type) }
    end

    def sorted_displayable_activity_types
      displayable_activity_types.sort_by { |_, config| config[:label] }
    end

    private def should_display?(activity_type)
      config = ACTIVITY_TYPES[activity_type]
      is_displayable_activity = displayable_activity_type?(config)

      if config[:conditional]
        is_displayable_activity && send(config[:conditional])
      else
        is_displayable_activity
      end
    end

    private def displayable_activity_type?(config)
      displayable_activity_kind == :all || config[:display_kinds].include?(displayable_activity_kind)
    end

    private def displayable_activity_kind
      :all
    end

    private def not_supersite_junior?
      !@view.supersite_junior?
    end
  end
end
