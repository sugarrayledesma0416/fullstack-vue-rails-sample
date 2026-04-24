module AI
  module GradingSuggestionGenerators
    class QuestionGenerator
      COMMON_STATS_DATA = {
        application: :m3,
        environment: Rails.env,
        vhl_component: :ai
      }.freeze

      attr_reader(
        :attempt,
        :grading_suggestion_input,
        :prompt,
        :question_label,
        :student_submission
      )

      attr_accessor :job_id

      def initialize(attempt:, grading_suggestion_input:, job_id:, prompt:, question_label:, student_submission:)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        @prompt = prompt
        @question_label = question_label
        @student_submission = student_submission
        self.job_id = job_id
      end

      def generate
        offsets = {}
        doc = Nokogiri::HTML(student_submission)
        body = doc.css('//body')
        suggestions.each do |suggestion|
          last_occurence = offsets[suggestion.incorrect_text]
          start_offset = if last_occurence
                           last_occurence.incorrect_text_end_offset
                         else
                           0
                         end
          result = find_text_in_node(
            node: body.first,
            start_offset:,
            target_text: suggestion.incorrect_text
          )
          if result[:begin_offset]
            # The text has been found
            suggestion.incorrect_text_begin_offset = result[:begin_offset]
            offsets[suggestion.incorrect_text] = suggestion
          elsif last_occurence
            # the text has not been found but has been found before: use that last offset
            suggestion.incorrect_text_begin_offset = last_occurence.incorrect_text_begin_offset
          else
            # The text has not been found
            suggestion.incorrect_text_begin_offset = -1
          end
        end
        suggestions.each(&:save!)
        complete_job
      rescue StandardError => e
        fail_job(e)
      end

      private def complete_job
        # Edge case here: a JSON parse error could be received for any
        # suggestion, but some suggestions could parse successfully. Should
        # the whole job be logged as failed if any suggestion fails to parse?
        job.update!(status: 'completed', error: nil) unless job.status == 'failed'
      end

      private def fail_job(error)
        job.update!(status: 'failed', error: error.message)
      end

      private def find_text_in_node(node:, start_offset: 0, target_text:, full_text: '')
        if node.text?
          full_text += node.text
          regexp = /.*?\b(#{target_text})(?:\W|\b|$).*/
          if (match = regexp.match(full_text, start_offset))
            # The text has been found. Return the offset the text has been found at.
            return {
              node:,
              begin_offset: match.begin(1)
            }
          end
        else
          node.children.each do |child|
            result = find_text_in_node(node: child, start_offset:, full_text:, target_text:)
            return result if result[:begin_offset]

            full_text = result[:text]
          end
        end

        {
          text: full_text
        }
      end

      private def job
        @job ||= GradingSuggestionJob.find(job_id)
      end

      private def suggestions
        @suggestions ||=
          Array(raw_suggestions_attributes.dig('errors')).filter_map do |raw_suggestion|
            suggestion = AI::GradingSuggestion.new(
              activity:,
              ai_grading_suggestion_job_id: job_id,
              prompt_id: prompt.id,
              attempt:,
              grading_suggestion_input:,
              language_code:,
              program:,
              question_label:,
              incorrect_text: raw_suggestion['incorrect_text'],
              error_explanation: raw_suggestion['error_explanation']
            )

            suggestion.valid? ? suggestion : nil
          end
      end

      private def raw_suggestions_attributes
        if response_content.blank?
          {}
        else
          content = if response_content.respond_to?(:errors)
                     response_content.errors
                   else
                     JSON.parse(response_content["choices"][0]["message"]["content"])["errors"]
                   end
          { 'errors' => content }
        end
      end

      private def response_content
        return @response_content if defined?(@response_content)

        begin
          # Use ABTest adapter for A/B testing
          response = abtest_adapter.generate_grading_suggestions(
            prompt: prompt,
            messages: messages,
            experiment_name: 'gpt4o_version_upgrade',
            template_variables: {
              program_level: program_level,
              language_name: language_name
            },
            span_attributes: {
              VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'ai_grading_suggestion',
              VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt&.id
            }
          )
          @response_content = response
        rescue VHL::AI::Core::SchemaError => e
          log_response_failure("Schema error: #{e.message}")
          nil
        rescue StandardError => e
          log_response_failure("Standard error: #{e.message}")
          nil
        end
      end

      private def log_response_failure(error)
        VHLMonitor.notify(error)
      end

      private def messages
        [system_message, user_message]
      end

      private def system_message
        current_prompt = get_prompt_with_language
        wrap_message(
          'system',
          current_prompt.template_body
        )
      end

      private def user_message
        wrap_message(
          'user',
          student_submission
        )
      end

      private def wrap_message(role, content)
        { role:, content: }
      end

      # Use ABTest adapter instead of direct client
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

      # Keep the old client method for backward compatibility during transition
      # This can be removed once we're confident the adapter is working
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
        if defined?(VHL::AI::Prompts) && VHL::AI::Prompts.has_prompt?('grading_suggestion', language_code)
          ai_core_prompt = VHL::AI::Prompts.get_prompt('grading_suggestion', language_code)
          # Create a mock prompt object that matches the interface
          OpenStruct.new(
            template_body: ai_core_prompt[:template],
            model: ai_core_prompt[:model],
            temperature: ai_core_prompt[:parameters]&.dig(:temperature) || 0.2,
            id: 'ai_core_language_specific'
          )
        else
          # Fallback to the provided prompt
          prompt
        end
      end
    end
  end
end
