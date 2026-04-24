require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe GradebookEngine::SectionController, new_gb_sync: true do
  # The Section controller inside the GradebookEngine relies on some
  # dependency injection from M3. These tests exercise the connections
  # between the two codebases.
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let!(:analytics_path) do
    gradebook_engine.course_path(
      active_subnav: 'analytics',
      course_id: course.id,
      feature: 'analytics',
      program_id: program.id
    )
  end

  describe 'GET /scores' do
    let(:target_path) do
      gradebook_engine.course_section_scores_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id
      )
    end

    def do_request
      get(target_path)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'when analytics is enabled in rails configuration,' do
        before do
          allow(Rails.application.config).to receive(:enable_analytics)
            .and_return(true)
        end

        it 'allows the instructor to view the Analytics tab' do
          do_request

          expect(response.body).to include('Analytics')
        end

        it 'requires the instructor to focus on just one section' do
          # Create two sections.
          create(:section, course: course, instructor: instructor)
          create(:section, course: course, instructor: instructor)

          # If this is assigned after the `put` call to the focus path,
          # the subsequent `get` fails with
          # ActionController::RoutingError:
          #   uninitialized constant CoursesController
          # See if this is still a problem in Rails 5.1, 5.2
          analytics_path = gradebook_engine.course_path(
            active_subnav: 'analytics',
            course_id: course.id,
            feature: 'analytics',
            program_id: program.id
          )

          # Explicitly set focus on the course, and not either of
          # the two sections.
          put(
            instructor_focus_path(program_id: program.id),
            params: { focus: "Course,#{course.id}", return_to: '' }
          )

          get(analytics_path)

          expect(response.body).to include('Select a section to see its analytics')
        end
      end

      context 'when analytics is disabled in rails configuration,' do
        before do
          allow(Rails.application.config).to receive(:enable_analytics)
            .and_return(false)
        end

        it 'does not allow an instructor without the dev cookie set to ' \
           'view the Analytics tab' do
          do_request

          expect(response.body).not_to include('Analytics')
        end

        it 'allows an instructor with the dev cookie set to view the ' \
           'Analytics tab' do
          get(target_path, headers: { 'HTTP_COOKIE' => 'dev=true' })

          expect(response.body).to include('Analytics')
        end
      end
    end
  end
end
