require 'rails_helper'

describe 'AI Experiment Sync' do
  let(:mock_experiment) do
    double('experiment',
           name: 'gpt4o_version_upgrade',
           variants: [
             double('variant1',
                    name: 'current_version',
                    configuration: { '_prompt_reference' => 'grading_suggestion',
                                     'model' => 'gpt-4o-2024-08-06' }),
             double('variant2',
                    name: 'upgraded_version',
                    configuration: { '_prompt_reference' => 'grading_suggestion',
                                     'model' => 'gpt-4o-2024-11-20' })
           ])
  end

  let(:mock_manager) do
    double('manager', active_experiments: [mock_experiment])
  end

  before do
    allow(VHL::AI::ABTesting).to receive(:manager).and_return(mock_manager)
    allow(VHL::AI::Prompts).to receive(:get_prompt).with('grading_suggestion').and_return({
                                                                                            template: 'Test grading template',
                                                                                            model: 'gpt-4o-2024-08-06',
                                                                                            provider: 'openai',
                                                                                            parameters: { temperature: 0.2 }
                                                                                          })
  end

  describe AI::GradingSuggestionPrompt do
    describe '.sync_experiment_prompts_if_needed' do
      it 'does not create prompts since only ai_core manages experiments' do
        expect do
          AI::GradingSuggestionPrompt.sync_experiment_prompts_if_needed
        end.not_to change(AI::GradingSuggestionPrompt, :count)
      end
    end
  end

  describe AI::OverallCommentPrompt do
    describe '.sync_experiment_prompts_if_needed' do
      it 'does not create prompts since only ai_core manages experiments' do
        expect do
          AI::OverallCommentPrompt.sync_experiment_prompts_if_needed
        end.not_to change(AI::OverallCommentPrompt, :count)
      end
    end
  end
end
