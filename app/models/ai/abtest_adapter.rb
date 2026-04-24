module AI
  # ABTest adapter that bridges M3's current AI patterns with the new A/B testing system
  # This allows gradual adoption of A/B testing while maintaining existing interfaces
  class ABTestAdapter
    def initialize(experiment_context: {})
      @experiment_context = experiment_context
      @client = VHL::AI::ABTestClient.new(experiment_context: experiment_context)
    end

    # Generate grading suggestions with optional A/B testing
    # Maintains M3's current interface while adding A/B testing capabilities
    def generate_grading_suggestions(prompt:, messages:, experiment_name: nil, span_attributes: {},
                                     template_variables: {})
      # Map M3's prompt object to prompt name for the unified system
      prompt_name = map_prompt_to_name(prompt)
      language_code = @experiment_context[:language_code]

      # Determine the actual prompt name to use in tracing
      actual_prompt_name = determine_actual_prompt_name(prompt_name, language_code)

      # Check if experiment should be disabled due to language mismatch
      final_experiment_name = if should_disable_experiment_for_language_mismatch?(
        experiment_name, actual_prompt_name, language_code
      )
                                nil
                              else
                                experiment_name
                              end

      @client.chat(
        parameters: { messages: messages },
        prompt_name: actual_prompt_name,
        language_code: language_code,
        experiment_name: final_experiment_name,
        response_schema_type: VHL::AI::Constants::ResponseSchemas::GRADING_SUGGESTION,
        template_variables: template_variables,
        span_attributes: build_span_attributes(span_attributes,
                                               actual_prompt_name: actual_prompt_name)
      )
    end

    # Generate overall comments with optional A/B testing
    def generate_overall_comment(prompt:, messages:, experiment_name: nil, span_attributes: {},
                                 template_variables: {})
      prompt_name = map_prompt_to_name(prompt)
      language_code = @experiment_context[:language_code]

      # Determine the actual prompt name to use in tracing
      actual_prompt_name = determine_actual_prompt_name(prompt_name, language_code)

      # Check if experiment should be disabled due to language mismatch
      final_experiment_name = if should_disable_experiment_for_language_mismatch?(
        experiment_name, actual_prompt_name, language_code
      )
                                nil
                              else
                                experiment_name
                              end

      @client.chat(
        parameters: { messages: messages },
        prompt_name: actual_prompt_name,
        language_code: language_code,
        experiment_name: final_experiment_name,
        response_schema_type: VHL::AI::Constants::ResponseSchemas::OVERALL_COMMENT,
        template_variables: template_variables,
        span_attributes: build_span_attributes(span_attributes,
                                               actual_prompt_name: actual_prompt_name)
      )
    end

    # Check which variant was assigned for an experiment
    def assigned_variant(experiment_name)
      variant = @client.get_assigned_variants[experiment_name]
      variant&.name
    end

    # Check if assigned to a specific variant
    delegate :assigned_to_variant?, to: :@client

    # Update experiment context (useful for adding user info after initialization)
    def update_experiment_context(new_context)
      @experiment_context.merge!(new_context)
      @client.update_experiment_context(new_context)
    end

    private

    def map_prompt_to_name(prompt)
      # Map M3's prompt objects to prompt names in prompts.yml
      case prompt.class.name
      when 'AI::GradingSuggestionPrompt'
        'grading_suggestion'
      when 'AI::OverallCommentPrompt'
        'overall_comment'
      when 'AI::VirtualChatPrompt'
        'ai_virtual_chat'
      else
        raise "Unknown prompt type: #{prompt.class.name}. Please add mapping to ABTestAdapter."
      end
    end

    def determine_actual_prompt_name(prompt_name, language_code)
      # Check if a language-specific prompt exists
      if language_code && defined?(VHL::AI::Prompts)
        language_specific_name = "#{prompt_name}_#{language_code}"
        # Only use language-specific name if it actually exists as a separate prompt
        if VHL::AI::Prompts.configuration.prompts.key?(language_specific_name)
          language_specific_name
        else
          prompt_name
        end
      else
        prompt_name
      end
    end

    def build_span_attributes(additional_attributes = {}, actual_prompt_name: nil)
      base_attributes = {
        VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => @experiment_context[:user_id],
        VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => @experiment_context[:session_id],
        VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => @experiment_context[:program_id],
        VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => @experiment_context[:language_code],
        VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => @experiment_context[:activity_id]
      }

      # Add the actual prompt name to the span attributes if available
      if actual_prompt_name
        base_attributes[VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME] =
          actual_prompt_name
      end

      base_attributes.merge(additional_attributes).compact
    end

    # Check if experiment should be disabled due to language/prompt mismatch
    # Returns true if the experiment should be disabled
    def should_disable_experiment_for_language_mismatch?(experiment_name, actual_prompt_name,
                                                         language_code)
      return false unless experiment_name && language_code

      # Get the variant that would be assigned for this experiment
      begin
        variant = @client.get_or_assign_variant(experiment_name)
        return false unless variant&.prompt_reference

        # Check if we're using a language-specific prompt but variant references base prompt
        # This would cause the variant to override the language-specific prompt with base prompt
        is_language_specific_prompt = actual_prompt_name.to_s.match?(/_[a-z]{2}$/)
        variant_base_prompt = variant.prompt_reference
        actual_base_prompt = extract_base_prompt_name(actual_prompt_name)

        # If we're using a language-specific prompt but variant would override with base prompt,
        # disable the experiment to preserve language-specific behavior
        if is_language_specific_prompt && variant_base_prompt == actual_base_prompt
          Rails.logger.info(
            "[ABTestAdapter] Disabling experiment '#{experiment_name}' due to language-specific prompt: " \
            "using '#{actual_prompt_name}' but variant would override with base '#{variant_base_prompt}'"
          )
          return true
        end

        # Also disable if base prompts don't match at all
        if variant_base_prompt != actual_base_prompt
          Rails.logger.info(
            "[ABTestAdapter] Disabling experiment '#{experiment_name}' due to prompt mismatch: " \
            "variant references '#{variant_base_prompt}' but using '#{actual_base_prompt}'"
          )
          return true
        end

        false
      rescue StandardError => e
        Rails.logger.warn(
          "[ABTestAdapter] Error checking experiment language compatibility: #{e.message}"
        )
        # On error, disable experiment to be safe
        true
      end
    end

    # Extract base prompt name from language-specific or regular prompt name
    def extract_base_prompt_name(prompt_name)
      # Remove language suffix if present (e.g., "grading_suggestion_en" -> "grading_suggestion")
      prompt_name.to_s.gsub(/_[a-z]{2}$/, '')
    end
  end

  # Alias to handle Rails auto-loading conventions
  AbtestAdapter = ABTestAdapter
end
