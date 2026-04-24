require 'requests/login_helper_methods'

describe AI::GradingPromptsController, 'AI Core Integration' do
  let(:user) { create(:user) }
  let(:developer_role) { Role.create!(name: Role::AI_DEVELOPER) }

  before do
    log_in_user(user)
    user.roles << developer_role
  end

  describe 'when AI Core is managing prompts' do
    before do
      allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(true)
      allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(true)
    end

    describe 'POST create' do
      it 'prevents M3 prompts from being set as active for grading suggestions' do
        post ai_grading_prompts_path, params: {
          prompt: {
            model: 'gpt-4o',
            provider: 'openai',
            temperature: 0.5,
            template_body: 'Test template',
            active_for_instructor_grading: true
          }
        }

        new_prompt = AI::GradingSuggestionPrompt.last
        expect(new_prompt).not_to be_active_for_instructor_grading
        expect(flash[:warning]).to include('Cannot set M3 prompt as active while AI Core is managing prompts')
      end

      it 'prevents M3 prompts from being set as active for overall comments' do
        post ai_grading_prompts_path, params: {
          prompt_type: 'overall',
          prompt: {
            model: 'gpt-4o',
            provider: 'openai',
            temperature: 0.5,
            template_body: 'Test template',
            active_for_instructor_grading: true
          }
        }

        new_prompt = AI::OverallCommentPrompt.last
        expect(new_prompt).not_to be_active_for_instructor_grading
      end
    end

    describe 'PUT update' do
      let(:m3_prompt) do
        create(:ai_grading_suggestion_prompt, source: 'm3', active_for_instructor_grading: false)
      end

      it 'prevents M3 prompts from being activated via update' do
        put ai_grading_prompt_path(m3_prompt), params: {
          prompt: { active_for_instructor_grading: true }
        }

        expect(m3_prompt.reload).not_to be_active_for_instructor_grading
        expect(flash[:warning]).to include('Cannot set M3 prompt as active while AI Core is managing prompts')
      end
    end

    describe 'GET edit' do
      let(:ai_core_prompt) { create(:ai_grading_suggestion_prompt, source: 'ai_core') }

      it 'prevents editing AI Core prompts' do
        get edit_ai_grading_prompt_path(ai_core_prompt)

        expect(response).to redirect_to(ai_grading_prompts_path)
        expect(flash[:error]).to include('Cannot edit AI Core prompts')
      end
    end
  end

  describe 'when AI Core is not managing prompts' do
    before do
      allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
    end

    it 'allows M3 prompts to be set as active' do
      post ai_grading_prompts_path, params: {
        prompt: {
          model: 'gpt-4o',
          provider: 'openai',
          temperature: 0.5,
          template_body: 'Test template',
          active_for_instructor_grading: true
        }
      }

      new_prompt = AI::GradingSuggestionPrompt.last
      expect(new_prompt).to be_active_for_instructor_grading
    end
  end
end
