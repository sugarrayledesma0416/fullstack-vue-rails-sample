module AI
  class OverallCommentPrompt < ApplicationRecord
    self.table_name = 'ai_overall_comment_prompts'

    DEFAULT_SYSTEM_MESSAGE_TEMPLATE = VHL::AI::Prompts::OVERALL_COMMENT_PROMPT

    has_many(
      :overall_comments,
      class_name: 'AI::OverallComment',
      dependent: :nullify,
      foreign_key: :prompt_id,
      inverse_of: :prompt
    )

    validates(
      :temperature,
      numericality: { less_than_or_equal_to: 1.0, greater_than_or_equal_to: 0.0 }
    )

    validates(:template_body, presence: true)

    def self.current(language_code = nil)
      # Check if AI Core has a prompt available
      if using_ai_core_source?(language_code)
        # AI Core takes precedence - use its prompt content but return active M3 record
        sync_from_ai_core_if_needed(language_code)
      end

      # Return active prompt or create default
      find_by(active_for_instructor_grading: true) || create_default_prompt
    end

    def self.using_ai_core_source?(language_code = nil)
      defined?(VHL::AI::Prompts) && VHL::AI::Prompts.has_prompt?('overall_comment', language_code)
    end

    def self.sync_from_ai_core_if_needed(language_code = nil)
      return unless using_ai_core_source?(language_code)

      ai_core_prompt = VHL::AI::Prompts.get_prompt('overall_comment', language_code)
      return unless ai_core_prompt

      # Check if active prompt already matches AI Core content
      active_prompt = find_by(active_for_instructor_grading: true)
      ai_core_template = ai_core_prompt[:template] || ai_core_prompt['template']

      if active_prompt&.template_body == ai_core_template
        return # Already in sync
      end

      # Deactivate current active prompt
      where(active_for_instructor_grading: true).update_all(active_for_instructor_grading: false)

      # Create new prompt with AI Core content
      create!(
        template_body: ai_core_template,
        model: ai_core_prompt[:model] || ai_core_prompt['model'] || VHL::AI::Constants::Models::OpenAI::GPT_4O,
        temperature: ai_core_prompt[:temperature] || ai_core_prompt['temperature'] || VHL::AI::Constants::Parameters::Temperature::CONSERVATIVE,
        active_for_instructor_grading: true
      )
    end

    def self.create_default_prompt
      create!(
        active_for_instructor_grading: true,
        model: VHL::AI::Constants::Models::OpenAI::GPT_4O,
        temperature: VHL::AI::Constants::Parameters::Temperature::CONSERVATIVE,
        template_body: DEFAULT_SYSTEM_MESSAGE_TEMPLATE
      )
    end

    def self.sync_experiment_prompts_if_needed
      # Only ai_core manages real A/B test experiments
      # M3 experimental prompts are just user-created non-active prompts
    end

    # Method for identifying if a prompt came from an experiment
    def from_experiment?
      false # Only ai_core manages real experiments
    end

    # Return source for compatibility with views
    def source
      # Check if source is encoded in model field for testing
      raw_model = self[:model]
      if raw_model.to_s.include?('|source:')
        raw_model.split('|source:').last.split('|').first
      elsif self.class.using_ai_core_source? && active_for_instructor_grading?
        'ai_core'
      else
        'manual'
      end
    end

    # Setter for source to support testing - encodes in model field
    def source=(value)
      current_model = self[:model] || ''
      # Remove existing source encoding
      clean_model = current_model.gsub(/\|source:[^|]*/, '')
      # Add new source encoding
      self.model = "#{clean_model}|source:#{value}"
    end

    # Method for view compatibility - simplified implementation
    def ai_core_experiment_name
      # Extract experiment name from model field if encoded there
      raw_model = self[:model]
      if raw_model.to_s.include?('|experiment:')
        raw_model.split('|experiment:').last.split('|').first
      else
        nil # Only ai_core manages real experiments
      end
    end

    # Setter for ai_core_experiment_name to support testing - encodes in model field
    def ai_core_experiment_name=(value)
      current_model = self[:model] || ''
      # Remove existing experiment encoding
      clean_model = current_model.gsub(/\|experiment:[^|]*/, '')
      # Add new experiment encoding if value provided
      if value.present?
        self.model = "#{clean_model}|experiment:#{value}"
      else
        self.model = clean_model
      end
    end

    # Method for view compatibility - simplified implementation
    def is_experimental
      false # Only ai_core manages real experiments
    end

    # Method for view compatibility - simplified implementation
    def parameters
      result = {}
      # Extract provider from model field if encoded there
      raw_model = self[:model]
      result['provider'] = provider if raw_model.to_s.include?('|provider:')
      result
    end

    # Method for view compatibility - simplified implementation
    def provider
      # Extract provider from model field if encoded there
      raw_model = self[:model]
      if raw_model.to_s.include?('|provider:')
        raw_model.split('|provider:').last
      else
        'openai' # Default provider
      end
    end

    # Override model to return just the model part without provider/source encoding
    def model
      model_value = super
      if model_value.to_s.include?('|')
        # Extract just the model part, removing any encoding
        model_value.split('|').first
      else
        model_value
      end
    end

    # Method for view compatibility - simplified implementation
    def content_hash
      Digest::SHA256.hexdigest(template_body.to_s)
    end
  end
end
