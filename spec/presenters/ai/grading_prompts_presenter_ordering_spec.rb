require 'rails_helper'

describe AI::GradingPromptsPresenter do
  let(:presenter) { described_class.new }

  describe 'prompt ordering' do
    before do
      # Clean up any existing prompts to ensure clean test
      AI::GradingSuggestionPrompt.delete_all
      
      # Stub AI Core integration to prevent automatic prompt creation/deactivation
      allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
      allow(AI::GradingSuggestionPrompt).to receive(:sync_from_ai_core_if_needed)
      allow(AI::GradingSuggestionPrompt).to receive(:sync_experiment_prompts_if_needed)
    end
    
    let!(:inactive_m3_prompt) do
      create(:ai_grading_suggestion_prompt,
             source: 'm3',
             active_for_instructor_grading: false,
             id: 100)
    end

    let!(:active_ai_core_prompt) do
      create(:ai_grading_suggestion_prompt,
             source: 'ai_core',
             active_for_instructor_grading: true,
             id: 200)
    end

    let!(:experiment_prompt) do
      create(:ai_grading_suggestion_prompt,
             source: 'experiment',
             ai_core_experiment_name: 'test_experiment',
             active_for_instructor_grading: false,
             id: 300)
    end

    let!(:inactive_ai_core_prompt) do
      create(:ai_grading_suggestion_prompt,
             source: 'ai_core',
             active_for_instructor_grading: false,
             id: 400)
    end

    describe '#grading_suggestion_prompts' do
      it 'orders prompts with active first, then by source priority, then by newest' do
        prompts = presenter.grading_suggestion_prompts
        
        # Debug: Print all prompts to understand what's happening
        puts "All prompts:"
        prompts.each_with_index do |p, i|
          puts "#{i}: ID=#{p.id}, Active=#{p.active_for_instructor_grading?}, Source=#{p.source}"
        end
        
        # Find our test prompts among all prompts
        active_ai_core = prompts.find { |p| p.id == active_ai_core_prompt.id }
        experiment = prompts.find { |p| p.id == experiment_prompt.id }
        inactive_ai_core = prompts.find { |p| p.id == inactive_ai_core_prompt.id }
        inactive_m3 = prompts.find { |p| p.id == inactive_m3_prompt.id }
        
        active_ai_core_index = prompts.index(active_ai_core)
        experiment_index = prompts.index(experiment)
        inactive_ai_core_index = prompts.index(inactive_ai_core)
        inactive_m3_index = prompts.index(inactive_m3)

        # Active prompt should come first
        expect(active_ai_core_index).to be < experiment_index
        expect(active_ai_core_index).to be < inactive_ai_core_index
        expect(active_ai_core_index).to be < inactive_m3_index

        # Among inactive prompts, experiments (priority 1) should come before ai_core (priority 2)
        expect(experiment_index).to be < inactive_ai_core_index
        
        # Among inactive prompts, ai_core (priority 2) should come before m3 (priority 3)
        expect(inactive_ai_core_index).to be < inactive_m3_index
      end
    end

    describe '#overall_comment_prompts' do
      before do
        # Clean up any existing prompts to ensure clean test
        AI::OverallCommentPrompt.delete_all
        
        # Stub AI Core integration for overall comment prompts too
        allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        allow(AI::OverallCommentPrompt).to receive(:sync_from_ai_core_if_needed)
        allow(AI::OverallCommentPrompt).to receive(:sync_experiment_prompts_if_needed)
      end

      let!(:inactive_overall_m3) do
        create(:ai_overall_comment_prompt,
               source: 'm3',
               active_for_instructor_grading: false)
      end

      let!(:active_overall_ai_core) do
        create(:ai_overall_comment_prompt,
               source: 'ai_core',
               active_for_instructor_grading: true)
      end

      it 'orders overall comment prompts with same logic' do
        prompts = presenter.overall_comment_prompts

        # Active prompts should come first, regardless of source
        expect(prompts.first.active_for_instructor_grading?).to be_truthy
        expect(prompts.first.source).to eq('ai_core')

        # Inactive prompts should come after
        expect(prompts.last.active_for_instructor_grading?).to be_falsey
        expect(prompts.last.source).to eq('m3')
      end
    end
  end

  describe '#source_priority' do
    it 'returns correct priority values' do
      expect(presenter.send(:source_priority, 'experiment')).to eq(1)
      expect(presenter.send(:source_priority, 'ai_core')).to eq(2)
      expect(presenter.send(:source_priority, 'm3')).to eq(3)
      expect(presenter.send(:source_priority, 'unknown')).to eq(4)
    end
  end
end
