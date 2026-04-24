require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe AI::GradingSuggestionsController do
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor) }
  let(:section) { create(:section, course:, instructor:) }
  let(:attempt) { create(:attempt_completed, section:) }
end
