require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe AI::GradingPromptsController do
  describe 'GET index' do
    def do_request
      get(ai_grading_prompts_path)
    end

    it_behaves_like 'require logged in user'

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'redirects a user who is not an ai developer' do
        other_role = Role.create!(name: Role::AI_GRADING_EDITOR)
        user.roles << other_role

        do_request

        expect(response).to redirect_to '/403'
      end

      context 'with a user who is an ai developer' do
        before do
          developer_role = Role.create!(name: Role::AI_DEVELOPER)
          user.roles << developer_role
          # Allow M3 prompts to be activated in tests
          allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
          allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        end

        it 'renders a list of the current prompts' do
          do_request

          expect(response).to render_template(:index)
          expect(assigns(:presenter).grading_suggestion_prompts).to contain_exactly(
            AI::GradingSuggestionPrompt.current
          )
        end
      end
    end
  end

  describe 'GET new' do
    def do_request(prompt_type = nil)
      get(new_ai_grading_prompt_path(prompt_type: prompt_type))
    end

    it_behaves_like 'require logged in user'

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'redirects a user who is not an ai developer' do
        other_role = Role.create!(name: Role::AI_GRADING_EDITOR)
        user.roles << other_role

        do_request

        expect(response).to redirect_to '/403'
      end

      context 'with a user who is an ai developer' do
        before do
          developer_role = Role.create!(name: Role::AI_DEVELOPER)
          user.roles << developer_role
          # Allow M3 prompts to be activated in tests
          allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
          allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        end

        it 'renders a form populated with data from the current grading ' \
           'suggestion prompt if prompt_type param is not "overall"' do
          do_request

          expect(response).to render_template(:new)
          current_prompt = AI::GradingSuggestionPrompt.current
          expect(assigns(:prompt)).not_to be_persisted

          expect(assigns(:prompt)).to have_attributes(
            model: current_prompt.model,
            temperature: current_prompt.temperature,
            template_body: current_prompt.template_body
          )
        end

        it 'renders a form populated with data from the current overall ' \
           'comment prompt if prompt_type param is "overall"' do
          do_request('overall')

          expect(response).to render_template(:new)
          current_prompt = AI::OverallCommentPrompt.current
          expect(assigns(:prompt)).not_to be_persisted

          expect(assigns(:prompt)).to have_attributes(
            model: current_prompt.model,
            temperature: current_prompt.temperature,
            template_body: current_prompt.template_body
          )
        end
      end
    end
  end

  describe 'POST create' do
    let(:new_attrs) do
      {
        model: 'gpt-5',
        provider: 'openai',
        temperature: 0.7,
        template_body: 'new body'
      }
    end

    def do_request(prompt_type = nil, override_attrs = {})
      post(
        ai_grading_prompts_path,
        params: { prompt_type:, prompt: new_attrs.merge(override_attrs) }
      )
    end

    it_behaves_like 'require logged in user'

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'redirects a user who is not an ai developer' do
        other_role = Role.create!(name: Role::AI_GRADING_EDITOR)
        user.roles << other_role

        do_request

        expect(response).to redirect_to '/403'
      end

      context 'with a user who is an ai developer' do
        before do
          developer_role = Role.create!(name: Role::AI_DEVELOPER)
          user.roles << developer_role
          # Allow M3 prompts to be activated in tests
          allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
          allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        end

        context 'when prompt type parameter is not set to "overall"' do
          it 'does not save a new prompt when invalid attributes are specified' do
            expect do
              do_request(nil, { temperature: -1, template_body: '' })
            end.not_to change(AI::GradingSuggestionPrompt, :count)

            expect(response).to be_unprocessable
            expect(response).to render_template(:new)

            prompt = assigns(:prompt)

            expect(prompt).not_to be_persisted

            expect(prompt.errors.full_messages).to contain_exactly(
              'Temperature must be greater than or equal to 0.0',
              'Template body is required'
            )

            expect(prompt).to have_attributes(
              temperature: -1,
              template_body: ''
            )
          end

          it 'saves a new prompt when valid attributes are specified' do
            do_request

            expect(response).to redirect_to(ai_grading_prompts_path)

            new_prompt = AI::GradingSuggestionPrompt.last
            expect(new_prompt).to have_attributes(new_attrs.except(:provider))
            expect(new_prompt.provider).to eq('openai')
          end

          it 'saves provider parameter in the parameters JSON' do
            do_request(nil, { provider: 'anthropic' })

            new_prompt = AI::GradingSuggestionPrompt.last
            expect(new_prompt.parameters['provider']).to eq('anthropic')
          end

          it 'defaults to openai provider when none specified' do
            do_request(nil, new_attrs.except(:provider))

            new_prompt = AI::GradingSuggestionPrompt.last
            expect(new_prompt.provider).to eq('openai')
          end
        end

        context 'when prompt type parameter is set to "overall"' do
          it 'does not save a new prompt when invalid attributes are specified' do
            expect do
              do_request('overall', { temperature: -1, template_body: '' })
            end.not_to change(AI::OverallCommentPrompt, :count)

            expect(response).to be_unprocessable
            expect(response).to render_template(:new)

            prompt = assigns(:prompt)

            expect(prompt).not_to be_persisted

            expect(prompt.errors.full_messages).to contain_exactly(
              'Temperature must be greater than or equal to 0.0',
              'Template body is required'
            )

            expect(prompt).to have_attributes(
              temperature: -1,
              template_body: ''
            )
          end

          it 'saves a new prompt when valid attributes are specified' do
            do_request('overall')

            expect(response).to redirect_to(ai_grading_prompts_path)

            new_prompt = AI::OverallCommentPrompt.last
            expect(new_prompt).to have_attributes(new_attrs)
          end
        end
      end
    end
  end

  describe 'GET edit' do
    let(:grading_suggestion_prompt) { create(:ai_grading_suggestion_prompt) }
    let(:overall_comment_prompt) { create(:ai_overall_comment_prompt) }

    def do_request(prompt_type = nil)
      id = if prompt_type == 'overall'
             overall_comment_prompt.id
           else
             grading_suggestion_prompt.id
           end

      get(edit_ai_grading_prompt_path(id:, prompt_type:))
    end

    it_behaves_like 'require logged in user'

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'redirects a user who is not an ai developer' do
        other_role = Role.create!(name: Role::AI_GRADING_EDITOR)
        user.roles << other_role

        do_request

        expect(response).to redirect_to '/403'
      end

      context 'with a user who is an ai developer' do
        before do
          developer_role = Role.create!(name: Role::AI_DEVELOPER)
          user.roles << developer_role
          # Allow M3 prompts to be activated in tests
          allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
          allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        end

        it 'renders a form populated with data from specified grading ' \
           'suggestion prompt if prompt_type param is not "overall"' do
          do_request

          expect(response).to render_template(:edit)

          expect(assigns(:prompt)).to eq(grading_suggestion_prompt)
        end

        it 'renders a form populated with data from the specified overall ' \
           'comment prompt if prompt_type param is "overall"' do
          do_request('overall')

          expect(response).to render_template(:edit)

          expect(assigns(:prompt)).to eq(overall_comment_prompt)
        end
      end
    end
  end

  describe 'PUT update' do
    let(:prompt) do
      create(:ai_grading_suggestion_prompt)
    end

    def do_request(prompt_type = nil, new_attrs = {})
      put(
        ai_grading_prompt_path(id: prompt.id),
        params: { prompt_type:, prompt: new_attrs }
      )
    end

    it_behaves_like 'require logged in user'

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      it 'redirects a user who is not an ai developer' do
        other_role = Role.create!(name: Role::AI_GRADING_EDITOR)
        user.roles << other_role

        do_request

        expect(response).to redirect_to '/403'
      end

      context 'with a user who is an ai developer' do
        before do
          developer_role = Role.create!(name: Role::AI_DEVELOPER)
          user.roles << developer_role
          # Allow M3 prompts to be activated in tests
          allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
          allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
        end

        context 'when prompt_type is not "overall"' do
          let!(:old_active_prompt) do
            create(
              :ai_grading_suggestion_prompt,
              active_for_instructor_grading: true
            )
          end

          it 'does not make the old active prompt inactive if the ' \
             'active_for_instructor_grading parameter is false' do
            do_request(
              nil,
              active_for_instructor_grading: false
            )

            expect(old_active_prompt.reload).to have_attributes(
              active_for_instructor_grading: true
            )

            expect(response).to redirect_to(ai_grading_prompts_path)
          end

          it 'makes the old active prompt inactive if the ' \
             'active_for_instructor_grading parameter is true' do
            do_request(
              nil,
              active_for_instructor_grading: true
            )

            expect(old_active_prompt.reload).to have_attributes(
              active_for_instructor_grading: false
            )

            expect(prompt.reload).to have_attributes(
              active_for_instructor_grading: true
            )

            expect(response).to redirect_to(ai_grading_prompts_path)
          end
        end

        context 'when prompt_type is "overall"' do
          let(:prompt) do
            create(:ai_overall_comment_prompt)
          end

          let!(:old_active_prompt) do
            create(
              :ai_overall_comment_prompt,
              active_for_instructor_grading: true
            )
          end

          it 'does not make the old active prompt inactive if the ' \
             'active_for_instructor_grading parameter is false' do
            do_request(
              'overall',
              active_for_instructor_grading: false
            )

            expect(old_active_prompt.reload).to have_attributes(
              active_for_instructor_grading: true
            )

            expect(response).to redirect_to(ai_grading_prompts_path)
          end

          it 'makes the old active prompt inactive if the ' \
             'active_for_instructor_grading parameter is true' do
            do_request(
              'overall',
              active_for_instructor_grading: true
            )

            expect(old_active_prompt.reload).to have_attributes(
              active_for_instructor_grading: false
            )

            expect(prompt.reload).to have_attributes(
              active_for_instructor_grading: true
            )

            expect(response).to redirect_to(ai_grading_prompts_path)
          end
        end
      end
    end
  end
end
