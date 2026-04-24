require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe SectionsController do
  describe 'GET /show' do
    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor, program: program) }
    let(:section) { create(:section, course: course, instructor: instructor) }

    before do
      log_in_user_with_access_to_programs(student, [program])
    end

    context 'when the url parameters are guids,' do
      let(:target_path) do
        course_section_path(course_id: course.guid, section_id: section.guid, guids: true)
      end

      def do_request
        get target_path
      end

      context 'with a non-supersite-junior program,' do
        let(:program) { create(:program) }

        it 'redirects to the regular supersite student dashboard, transforming ' \
           'guids to m3 ids' do
          do_request

          expect(response).to redirect_to(
            course_section_url(course_id: course.id, section_id: section.id)
          )
        end
      end

      context 'with a supersite-junior program,' do
        let(:program) { create(:ss_jr_program) }

        it 'redirects to the supersite junior student dashboard, transforming ' \
           'guids to m3 ids' do
          do_request

          expect(response).to redirect_to(
            jr_course_section_url(course_id: course.id, section_id: section.id)
          )
        end
      end
    end
  end
end
