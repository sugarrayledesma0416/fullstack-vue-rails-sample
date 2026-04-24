require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe VocabTools::WordsController do
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.units.first.lessons.first }
  let(:section) { create(:section) }

  describe 'GET /index' do
    let(:target_path) do
      vocab_tools_words_path(program_id: program.id, section_id: section.id)
    end

    def do_request
      get(target_path)
    end

    include_examples 'require logged in user'

    context 'with a valid user,' do
      before { log_in_user_with_access_to_programs(student, [program]) }

    end
  end
end
