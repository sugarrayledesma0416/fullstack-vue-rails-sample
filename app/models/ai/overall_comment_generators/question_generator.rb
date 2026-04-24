module AI
  module OverallCommentGenerators
    class QuestionGenerator
      COMMON_STATS_DATA = {
        application: :m3,
        environment: Rails.env,
        vhl_component: :ai
      }.freeze

      USER_PROMPT_TEMPLATE = <<~TEMPLATE.freeze
        <instructions>%<direction_line>s</instructions>
        <question_prompt>%<question_prompt>s</question_prompt>
        <student_answer>%<student_answer>s</student_answer>
      TEMPLATE

      SAMPLE_ANSWERS_TEMPLATE = <<~TEMPLATE.freeze
        <sample_answers>
          %<sample_answers>s
        </sample_answers>
      TEMPLATE

      attr_reader(
        :attempt,
        :grading_suggestion_input,
        :prompt,
        :question_label,
        :student_submission
      )

      def initialize(attempt:, grading_suggestion_input:, prompt:, question_label:, student_submission:)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @prompt = prompt
        @question_label = question_label
        @student_submission = student_submission
      end

      def generate
        overall_comment_response = response_content
        return if overall_comment_response.blank?

        if overall_comment_response.is_a?(VHL::AI::Schemas::OpenAI::Response::OverallCommentSchema)
          overall_comment = overall_comment_response.overall_comment
          explanation = overall_comment_response.explanation
        else
          parsed_response = JSON.parse(overall_comment_response["choices"][0]["message"]["content"])
          overall_comment = parsed_response["overall_comment"]
          explanation = parsed_response["explanation"]
        end

        AI::OverallComment.create!(
          activity:,
          prompt_id: prompt.id,
          attempt:,
          grading_suggestion_input:,
          language_code:,
          program:,
          question_label:,
          overall_comment:,
          explanation:
        )
      end

      private def response_content
        return @response_content if defined?(@response_content)

        begin
          # Use ABTest adapter for language-specific prompt support (no experiment for now)
          response = abtest_adapter.generate_overall_comment(
            prompt: prompt,
            messages: messages,
            experiment_name: nil, # No experiment for now
            template_variables: {
              program_level: program_level,
              language_name: language_name
            },
            span_attributes: {
              VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => attempt&.user&.id,
              VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => attempt&.id,
              VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt&.id
            }
          )
          @response_content = response
        rescue VHL::AI::Core::SchemaError => e
          log_response_failure(e, @response_content)
          nil
        rescue StandardError => e
          log_response_failure(e, @response_content)
          nil
        end
      end

      private def log_response_failure(exception, response_content)
        Rails.logger.error(exception)

        STATS_PROXY.error(
          COMMON_STATS_DATA.merge(
            activity_id: activity.id,
            prompt_id: prompt.id,
            attempt_id: attempt.id,
            error: exception.message,
            grading_suggestion_input_id: grading_suggestion_input&.id,
            language_code:,
            program_id: program.id,
            question_label:,
            response_content: response_content.to_s
          )
        )
      end

      private def messages
        [system_message, user_message]
      end

      private def system_message
        current_prompt = get_prompt_with_language
        wrap_message(
          'system',
          current_prompt.template_body  # Pass raw template, let ABTestAdapter handle expansion
        )
      end

      private def user_message
        user_msg = format(USER_PROMPT_TEMPLATE, student_answer:, direction_line:, question_prompt:)

        if sample_answers.present?
          user_msg += format(SAMPLE_ANSWERS_TEMPLATE, sample_answers:)
        end

        if references_xml.present?
          user_msg += "#{references_xml}"
        end

        wrap_message('user', user_msg)
      end

      private def student_answer
        Nokogiri::HTML(student_submission).text
      end

      private def references_xml
        resources_formatter = AI::ActivityReferencesFormatter.new(activity)
        resources_formatter.format_as_xml
      end

      private def question_prompt
        activity_extractor.question_prompt(question_label)
      end

      private def sample_answers
        activity_extractor.question_sample_answers(question_label).join("\n")
      end

      private def direction_line
        activity_extractor.direction_line
      end

      private def activity_extractor
        @activity_extractor ||= AI::ActivityExtractor.new(activity)
      end

      private def wrap_message(role, content)
        { role:, content: }
      end

      private def client
        @client ||= VHL::AI::Core::Client.new
      end

      private def language_code
        program.language_code
      end

      private def language_name
        MaestroActivityEngine::Languages.language_name(language_code)
      end

      private def activity
        attempt.activity
      end

      private def program
        @program ||= activity.program
      end

      private def program_level
        program.ai_program_level.presence || 'introductory'
      end

      # Get the prompt with language-specific support
      private def get_prompt_with_language
        # If using AI Core, get language-specific prompt
        if defined?(VHL::AI::Prompts) && VHL::AI::Prompts.has_prompt?('overall_comment', language_code)
          ai_core_prompt = VHL::AI::Prompts.get_prompt('overall_comment', language_code)
          # Create a mock prompt object that matches the interface
          OpenStruct.new(
            template_body: ai_core_prompt[:template],
            model: ai_core_prompt[:model],
            temperature: ai_core_prompt[:parameters]&.dig(:temperature) || 0.1,
            id: 'ai_core_language_specific'
          )
        else
          # Fallback to the provided prompt
          prompt
        end
      end

      private def abtest_adapter
        @abtest_adapter ||= AI::AbtestAdapter.new(
          experiment_context: {
            user_id: attempt&.user&.id,
            session_id: attempt&.id,
            program_id: program.id,
            language_code: language_code,
            activity_id: activity.id
          }
        )
      end
    end
  end
end
