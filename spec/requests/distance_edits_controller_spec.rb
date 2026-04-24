require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe DistanceEditsController do
  describe 'POST #create' do
    let(:student) { create(:student) }
    let(:target) { 'cafe' }
    let(:student_response) { 'cafe' }
    let(:invalid_spelling) { 'Correct your spelling' }
    let(:response_tokens) do
      { 'distance_edits' => [
        { 'tokens' => [
          { 'student_text' => 'cafe',
            'correct_text' => 'cafe',
            'token_type' => 'word',
            'edit_type' => 'none' }
        ] }
      ] }
    end

    def do_request(target, student_response)
      post distance_edits_path, params: { target:, student_response: }, as: :json
    end

    context 'with a logged in user,' do
      before do
        log_in_user(student)
      end

      it 'returns a JSON array of response tokens' do
        do_request(target, student_response)

        expect(response).to be_ok
        expect(response.parsed_body).to eq(response_tokens)
      end
    end
  end
end
