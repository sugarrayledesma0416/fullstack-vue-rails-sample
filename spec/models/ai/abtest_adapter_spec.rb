require 'rails_helper'

describe AI::AbtestAdapter do
  let(:experiment_context) do
    {
      user_id: 123,
      session_id: 456,
      program_id: 789,
      language_code: 'es',
      activity_id: 101
    }
  end

  let(:adapter) { described_class.new(experiment_context: experiment_context) }
  let(:abtest_client) { instance_double(VHL::AI::ABTestClient) }

  before do
    allow(VHL::AI::ABTestClient).to receive(:new).and_return(abtest_client)
    # Mock get_or_assign_variant for language mismatch checking
    allow(abtest_client).to receive(:get_or_assign_variant).and_return(nil)
  end

  describe '#initialize' do
    it 'creates an ABTestClient with experiment context' do
      described_class.new(experiment_context: experiment_context)
      expect(VHL::AI::ABTestClient).to have_received(:new).with(experiment_context: experiment_context)
    end

    it 'can be initialized with empty context' do
      expect { described_class.new(experiment_context: {}) }.not_to raise_error
    end
  end

  describe '#generate_grading_suggestions' do
    let(:grading_prompt) { instance_double(AI::GradingSuggestionPrompt) }
    let(:messages) { [{ role: 'system', content: 'test' }] }
    let(:response) { { 'errors' => [] } }

    before do
      allow(grading_prompt).to receive(:class).and_return(AI::GradingSuggestionPrompt)
      allow(abtest_client).to receive(:chat).and_return(response)
    end

    it 'calls ABTestClient with correct parameters' do
      adapter.generate_grading_suggestions(prompt: grading_prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        parameters: { messages: messages },
        prompt_name: 'grading_suggestion',
        experiment_name: nil,
        language_code: 'es',
        response_schema_type: VHL::AI::Constants::ResponseSchemas::GRADING_SUGGESTION,
        template_variables: {},
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => 456,
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'es',
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => 101,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'grading_suggestion'
        }
      )
    end

    it 'works without experiment name' do
      adapter.generate_grading_suggestions(prompt: grading_prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(experiment_name: nil)
      )
    end

    it 'works without span attributes' do
      adapter.generate_grading_suggestions(prompt: grading_prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: hash_including(
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123
          )
        )
      )
    end

    it 'returns the response from ABTestClient' do
      result = adapter.generate_grading_suggestions(prompt: grading_prompt, messages: messages)

      expect(result).to eq(response)
    end

    it 'passes template variables to ABTestClient' do
      template_vars = {
        program_level: 'intermediate',
        language_name: 'Spanish'
      }

      adapter.generate_grading_suggestions(
        prompt: grading_prompt,
        messages: messages,
        template_variables: template_vars
      )

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: template_vars)
      )
    end

    it 'works with empty template variables' do
      adapter.generate_grading_suggestions(
        prompt: grading_prompt,
        messages: messages,
        template_variables: {}
      )

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: {})
      )
    end

    it 'works without template variables parameter' do
      adapter.generate_grading_suggestions(prompt: grading_prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: {})
      )
    end
  end

  describe '#generate_overall_comment' do
    let(:overall_comment_prompt) { instance_double(AI::OverallCommentPrompt) }
    let(:messages) { [{ role: 'system', content: 'test' }] }
    let(:response) { { 'overall_comment' => 'Great work!', 'explanation' => 'Well done' } }

    before do
      allow(overall_comment_prompt).to receive(:class).and_return(AI::OverallCommentPrompt)
      allow(abtest_client).to receive(:chat).and_return(response)
    end

    it 'calls ABTestClient with overall comment parameters' do
      # Mock VHL::AI::Prompts to NOT have a Spanish-specific prompt (so base prompt is used)
      allow(VHL::AI::Prompts).to receive(:configuration).and_return(
        double('configuration', prompts: { 'overall_comment' => {} })
      )
      # Mock variant to match the prompt for this test
      matching_variant = double('variant', prompt_reference: 'overall_comment')
      allow(abtest_client).to receive(:get_or_assign_variant).with('comment_experiment').and_return(matching_variant)
      
      adapter.generate_overall_comment(
        prompt: overall_comment_prompt,
        messages: messages,
        experiment_name: 'comment_experiment'
      )

      expect(abtest_client).to have_received(:chat).with(
        parameters: { messages: messages },
        prompt_name: 'overall_comment',
        experiment_name: 'comment_experiment',
        language_code: 'es',
        response_schema_type: VHL::AI::Constants::ResponseSchemas::OVERALL_COMMENT,
        template_variables: {},
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => 456,
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'es',
          VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => 101,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'overall_comment'
        }
      )
    end

    it 'returns the response from ABTestClient' do
      result = adapter.generate_overall_comment(prompt: overall_comment_prompt, messages: messages)

      expect(result).to eq(response)
    end

    it 'passes template variables to ABTestClient' do
      template_vars = {
        program_level: 'advanced',
        language_name: 'French'
      }

      adapter.generate_overall_comment(
        prompt: overall_comment_prompt,
        messages: messages,
        template_variables: template_vars
      )

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: template_vars)
      )
    end

    it 'works with empty template variables' do
      adapter.generate_overall_comment(
        prompt: overall_comment_prompt,
        messages: messages,
        template_variables: {}
      )

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: {})
      )
    end

    it 'works without template variables parameter' do
      adapter.generate_overall_comment(prompt: overall_comment_prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(template_variables: {})
      )
    end
  end

  describe '#assigned_variant' do
    let(:variant) { double(name: 'variant_a') }

    before do
      allow(abtest_client).to receive(:get_assigned_variants).and_return(
        'test_experiment' => variant
      )
    end

    it 'returns the assigned variant name' do
      result = adapter.assigned_variant('test_experiment')
      expect(result).to eq('variant_a')
    end

    it 'returns nil for non-existent experiment' do
      result = adapter.assigned_variant('non_existent_experiment')

      expect(result).to be_nil
    end
  end

  describe '#assigned_to_variant?' do
    before do
      allow(abtest_client).to receive(:assigned_to_variant?).and_return(true)
    end

    it 'delegates to ABTestClient' do
      result = adapter.assigned_to_variant?('test_experiment', 'variant_a')

      expect(abtest_client).to have_received(:assigned_to_variant?).with('test_experiment', 'variant_a')
      expect(result).to be true
    end
  end

  describe '#update_experiment_context' do
    before do
      allow(abtest_client).to receive(:update_experiment_context)
    end

    it 'updates the experiment context' do
      new_context = { user_id: 999, additional_field: 'value' }
      adapter.update_experiment_context(new_context)

      expect(abtest_client).to have_received(:update_experiment_context).with(new_context)
    end
  end

  describe 'prompt mapping' do
    let(:messages) { [{ role: 'system', content: 'test' }] }

    before do
      allow(abtest_client).to receive(:chat).and_return({})
    end

    context 'with GradingSuggestionPrompt' do
      let(:prompt) { instance_double(AI::GradingSuggestionPrompt) }

      before do
        allow(prompt).to receive(:class).and_return(AI::GradingSuggestionPrompt)
      end

      it 'maps to grading_suggestion prompt name' do
        adapter.generate_grading_suggestions(prompt: prompt, messages: messages)

        expect(abtest_client).to have_received(:chat).with(
          hash_including(prompt_name: 'grading_suggestion')
        )
      end
    end

    context 'with OverallCommentPrompt' do
      let(:prompt) { instance_double(AI::OverallCommentPrompt) }

      before do
        allow(prompt).to receive(:class).and_return(AI::OverallCommentPrompt)
      end

      it 'maps to overall_comment prompt name' do
        adapter.generate_overall_comment(prompt: prompt, messages: messages)

        expect(abtest_client).to have_received(:chat).with(
          hash_including(prompt_name: 'overall_comment')
        )
      end
    end

    context 'with VirtualChatPrompt' do
      let(:prompt) { double('VirtualChatPrompt') }
      let(:virtual_chat_class) { double('AI::VirtualChatPrompt') }

      before do
        allow(prompt).to receive(:class).and_return(virtual_chat_class)
        allow(virtual_chat_class).to receive(:name).and_return('AI::VirtualChatPrompt')
      end

      it 'maps to ai_virtual_chat prompt name' do
        # Test that VirtualChatPrompt would map to ai_virtual_chat
        # Since there's no generate_virtual_chat method, we'll test the mapping indirectly
        # by calling generate_grading_suggestions which uses the same mapping logic
        adapter.generate_grading_suggestions(prompt: prompt, messages: messages)

        expect(abtest_client).to have_received(:chat).with(
          hash_including(prompt_name: 'ai_virtual_chat')
        )
      end
    end

    context 'with unknown prompt type' do
      let(:unknown_prompt) { instance_double('UnknownPrompt') }

      before do
        allow(unknown_prompt).to receive(:class).and_return(Class.new)
        allow(unknown_prompt.class).to receive(:name).and_return('UnknownPrompt')
      end

      it 'raises an error for unknown prompt types' do
        expect do
          adapter.generate_grading_suggestions(prompt: unknown_prompt, messages: messages)
        end.to raise_error(RuntimeError, /Unknown prompt type: UnknownPrompt/)
      end
    end
  end

  describe 'span attributes building' do
    let(:prompt) { instance_double(AI::GradingSuggestionPrompt) }
    let(:messages) { [{ role: 'system', content: 'test' }] }

    before do
      allow(prompt).to receive(:class).and_return(AI::GradingSuggestionPrompt)
      allow(abtest_client).to receive(:chat).and_return({})
    end

    it 'includes all experiment context attributes' do
      adapter.generate_grading_suggestions(prompt: prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => 456,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'es',
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => 101,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'grading_suggestion'
          }
        )
      )
    end

    it 'merges additional span attributes' do
      additional_attrs = {
        'custom_attr' => 'value',
        'another_attr' => 42
      }

      adapter.generate_grading_suggestions(
        prompt: prompt,
        messages: messages,
        span_attributes: additional_attrs
      )

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: hash_including(additional_attrs)
        )
      )
    end

    it 'filters out nil values from context' do
      adapter_with_nils = described_class.new(
        experiment_context: {
          user_id: 123,
          session_id: nil,
          program_id: 789,
          language_code: 'es',
          activity_id: nil
        }
      )

      adapter_with_nils.generate_grading_suggestions(prompt: prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'es',
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'grading_suggestion'
          }
        )
      )
    end

    it 'uses language-specific prompt name when English prompt exists' do
      # Mock VHL::AI::Prompts to have an English-specific prompt
      allow(VHL::AI::Prompts).to receive(:configuration).and_return(
        double('configuration', prompts: { 'grading_suggestion_en' => {} })
      )

      adapter_with_english = described_class.new(
        experiment_context: {
          user_id: 123,
          session_id: 456,
          program_id: 789,
          language_code: 'en',
          activity_id: 101
        }
      )

      adapter_with_english.generate_grading_suggestions(prompt: prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => 456,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'en',
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => 101,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'grading_suggestion_en'
          }
        )
      )
    end

    it 'falls back to default prompt name when English-specific prompt does not exist' do
      # Mock VHL::AI::Prompts to NOT have an English-specific prompt
      allow(VHL::AI::Prompts).to receive(:configuration).and_return(
        double('configuration', prompts: { 'grading_suggestion' => {} })
      )

      adapter_with_english = described_class.new(
        experiment_context: {
          user_id: 123,
          session_id: 456,
          program_id: 789,
          language_code: 'en',
          activity_id: 101
        }
      )

      adapter_with_english.generate_grading_suggestions(prompt: prompt, messages: messages)

      expect(abtest_client).to have_received(:chat).with(
        hash_including(
          span_attributes: {
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => 123,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => 456,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_PROGRAM_ID => 789,
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_LANGUAGE_CODE => 'en',
            VHL::AI::ABTesting::SpanAttributes::EXPERIMENT_CONTEXT_ACTIVITY_ID => 101,
            VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'grading_suggestion'
          }
        )
      )
    end
  end

  describe 'language mismatch handling' do
    let(:grading_prompt) { instance_double(AI::GradingSuggestionPrompt) }
    let(:messages) { [{ role: 'system', content: 'test' }] }
    let(:mock_variant) { double('variant', prompt_reference: 'grading_suggestion') }

    before do
      allow(grading_prompt).to receive(:class).and_return(AI::GradingSuggestionPrompt)
      allow(abtest_client).to receive(:chat).and_return({})
      allow(abtest_client).to receive(:get_or_assign_variant).and_return(mock_variant)
    end

    context 'when using language-specific prompt with matching base variant' do
      it 'disables experiment to preserve language-specific behavior' do
        # Mock VHL::AI::Prompts to have an English-specific prompt
        allow(VHL::AI::Prompts).to receive(:configuration).and_return(
          double('configuration', prompts: { 'grading_suggestion_en' => {} })
        )

        adapter_with_english = described_class.new(
          experiment_context: { language_code: 'en' }
        )

        adapter_with_english.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).to have_received(:chat).with(
          hash_including(experiment_name: nil)
        )
      end

      it 'logs the language-specific prompt reason' do
        allow(VHL::AI::Prompts).to receive(:configuration).and_return(
          double('configuration', prompts: { 'grading_suggestion_en' => {} })
        )
        allow(Rails.logger).to receive(:info)

        adapter_with_english = described_class.new(
          experiment_context: { language_code: 'en' }
        )

        adapter_with_english.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(Rails.logger).to have_received(:info).with(
          match(/Disabling experiment 'test_experiment' due to language-specific prompt/)
        )
      end
    end

    context 'when using base prompt (no language suffix)' do
      it 'allows experiment to run normally' do
        # Mock VHL::AI::Prompts to NOT have a language-specific prompt
        allow(VHL::AI::Prompts).to receive(:configuration).and_return(
          double('configuration', prompts: { 'grading_suggestion' => {} })
        )

        adapter.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).to have_received(:chat).with(
          hash_including(experiment_name: 'test_experiment')
        )
      end
    end

    context 'when variant prompt does not match language-specific prompt base' do
      let(:different_variant) { double('variant', prompt_reference: 'different_prompt') }

      before do
        allow(abtest_client).to receive(:get_or_assign_variant).and_return(different_variant)
      end

      it 'disables the experiment' do
        # Mock VHL::AI::Prompts to have an English-specific prompt
        allow(VHL::AI::Prompts).to receive(:configuration).and_return(
          double('configuration', prompts: { 'grading_suggestion_en' => {} })
        )

        adapter_with_english = described_class.new(
          experiment_context: { language_code: 'en' }
        )

        adapter_with_english.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).to have_received(:chat).with(
          hash_including(experiment_name: nil)
        )
      end

      it 'logs the mismatch reason' do
        allow(VHL::AI::Prompts).to receive(:configuration).and_return(
          double('configuration', prompts: { 'grading_suggestion_en' => {} })
        )
        allow(Rails.logger).to receive(:info)

        adapter_with_english = described_class.new(
          experiment_context: { language_code: 'en' }
        )

        adapter_with_english.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(Rails.logger).to have_received(:info).with(
          match(/Disabling experiment 'test_experiment' due to prompt mismatch/)
        )
      end
    end

    context 'when variant has no prompt_reference' do
      let(:no_reference_variant) { double('variant', prompt_reference: nil) }

      before do
        allow(abtest_client).to receive(:get_or_assign_variant).and_return(no_reference_variant)
      end

      it 'allows experiment to run normally' do
        adapter.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).to have_received(:chat).with(
          hash_including(experiment_name: 'test_experiment')
        )
      end
    end

    context 'when experiment assignment fails' do
      before do
        allow(abtest_client).to receive(:get_or_assign_variant).and_raise(StandardError.new('Assignment failed'))
        allow(Rails.logger).to receive(:warn)
      end

      it 'disables the experiment and logs warning' do
        adapter.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).to have_received(:chat).with(
          hash_including(experiment_name: nil)
        )

        expect(Rails.logger).to have_received(:warn).with(
          match(/Error checking experiment language compatibility/)
        )
      end
    end

    context 'when no experiment_name is provided' do
      it 'skips language mismatch check' do
        allow(abtest_client).to receive(:get_or_assign_variant)

        adapter.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: nil
        )

        expect(abtest_client).not_to have_received(:get_or_assign_variant)
      end
    end

    context 'when no language_code is provided' do
      let(:no_language_adapter) { described_class.new(experiment_context: {}) }

      it 'skips language mismatch check' do
        allow(abtest_client).to receive(:get_or_assign_variant)

        no_language_adapter.generate_grading_suggestions(
          prompt: grading_prompt,
          messages: messages,
          experiment_name: 'test_experiment'
        )

        expect(abtest_client).not_to have_received(:get_or_assign_variant)
      end
    end
  end

  describe '#extract_base_prompt_name' do
    let(:adapter) { described_class.new(experiment_context: {}) }

    it 'removes language suffix from prompt names' do
      result = adapter.send(:extract_base_prompt_name, 'grading_suggestion_en')
      expect(result).to eq('grading_suggestion')
    end

    it 'removes language suffix for other languages' do
      result = adapter.send(:extract_base_prompt_name, 'overall_comment_es')
      expect(result).to eq('overall_comment')
    end

    it 'leaves base prompt names unchanged' do
      result = adapter.send(:extract_base_prompt_name, 'grading_suggestion')
      expect(result).to eq('grading_suggestion')
    end

    it 'handles symbol input' do
      result = adapter.send(:extract_base_prompt_name, :grading_suggestion_fr)
      expect(result).to eq('grading_suggestion')
    end

    it 'handles nil input' do
      result = adapter.send(:extract_base_prompt_name, nil)
      expect(result).to eq('')
    end
  end
end
