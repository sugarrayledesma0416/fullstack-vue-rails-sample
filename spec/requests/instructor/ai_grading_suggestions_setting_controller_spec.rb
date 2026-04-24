require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::AIGradingSuggestionsSettingController do
  let(:instructor) { create(:instructor) }

  describe 'PUT /update' do
    let(:target_path) do
      instructor_update_ai_grading_suggestions_setting_path
    end

    def do_request(params = { enable_ai_grading_suggestions: 'true' })
      put(target_path, params: { instructor: params })
    end

    context 'with a valid user,' do
      before do
        log_in_user(instructor)
      end

      it 'updates the enable_ai_grading_suggestions setting to the specified value' do
        do_request

        expect(response).to be_ok
        expect(instructor.reload.enable_ai_grading_suggestions).to eq('true')
      end
    end
  end
end
