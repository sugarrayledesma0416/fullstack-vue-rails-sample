describe Instructor::FocusController do
  describe 'PUT update' do
    let(:program) { build_stubbed(:program) }
    let(:course) { create(:course) }
    let(:section) { create(:section, course:) }
    let(:user) { build_stubbed(:instructor) }
    let(:return_to_path) { '/valid/uri' }

    def put_focus(focus:, **params)
      focus = focus ? CGI.escape(focus) : nil

      put 'update', params: {
        focus: focus,
        program_id: program.id,
        return_to: return_to_path
      }.merge!(params)
    end

    def expect_default_analytics_path
      expect(response).to redirect_to(
        GradebookEngine::Engine.routes.url_helpers.course_path(
          active_subnav: 'analytics',
          course_id: course.id,
          feature: 'analytics',
          program_id: program.id
        )
      )
    end

    before do
      allow(controller).to receive(:current_program).and_return(program)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      allow(user).to receive(:schools).and_return([course.school])
      fake_login(user)
      allow(Program).to receive(:find).and_return(program)
    end

    context 'when given a nil focus' do
      before do
        session[:focus] = { program.id.to_s => 'foo' }
        put_focus(focus: nil)
      end

      it 'stashes the current focus' do
        expect(session[:stashed_focus]).to eq(session[:focus])
      end

      it 'stashes the return_to' do
        expect(session[:stashed_return_to]).to eq(request.params[:return_to])
      end

      it 'clears the focus' do
        expect(session[:focus][program.id.to_s]).to be_nil
      end

      it 'redirects to the return to' do
        expect(response).to redirect_to return_to_path
      end

      it 'receives a json object when response is requested json format' do
        put_focus(focus: nil, format: 'json')

        expect(JSON.parse(response.body)).to eq(
          'section_name' => nil,
          'type_and_id' => 'Course,'
        )
      end
    end

    context 'when given a new focus level' do
      def do_request
        put :update, params: { program_id: '1' }
      end

      it_behaves_like 'an action that requires a logged in instructor'

      it 'sets the new focus level in the session' do
        put_focus(focus: "Course,#{course.id}")

        expect(session[:focus][program.id.to_s]).to eq(
          'course_id' => course.id,
          'section_id' => nil,
          'sort' => nil
        )
      end

      it 'redirects you to the return_to path' do
        put_focus(focus: "Course,#{course.id}")
        expect(response).to redirect_to '/valid/uri'
      end

      it 'stashes old focus into session' do
        old_focus = { program.id.to_s => { 'course_id' => course.id } }
        session[:focus] = old_focus
        put_focus(focus: "Course,#{course.id}")
        expect(session[:stashed_focus]).to eq(old_focus)
      end

      it 'saves new focus into session' do
        old_focus = {
          program.id.to_s => { 'course_id' => course.id }
        }
        new_focus = {
          program.id.to_s => {
            'course_id' => course.id,
            'sort' => nil,
            'section_id' => nil
          }
        }
        session[:focus] = old_focus
        put_focus(focus: "Course,#{course.id}")
        expect(session[:focus]).to eq(new_focus)
        expect(session[:saved_focus]).to eq(new_focus)
      end

      context 'when no section has the focus' do
        it 'redirects you to the unfocus analytics overview path' do
          unfocus_overview_path = "gradebook/#{program.id}/courses/#{course.id}" \
                                  '?active_subnav=analytics&feature=analytics'
          put_focus(focus: "Course,#{course.id}", return_to: unfocus_overview_path)

          expect_default_analytics_path
        end

        it 'redirects you to the unfocus analytics progress path' do
          unfocus_progress_path = "gradebook/#{program.id}/courses/#{course.id}" \
                                  '?active_subnav=analytics&feature=progress'
          put_focus(focus: "Course,#{course.id}", return_to: unfocus_progress_path)

          expect_default_analytics_path
        end

        it 'redirects you to the unfocus standards path' do
          unfocus_standards_path = "gradebook/#{program.id}/courses/#{course.id}" \
                                   '?active_subnav=analytics&feature=standards'
          put_focus(focus: "Course,#{course.id}", return_to: unfocus_standards_path)

          expect_default_analytics_path
        end

        it 'redirects you to the unfocus late work path' do
          unfocus_late_work_path = "gradebook/#{program.id}/courses/#{course.id}" \
                                   '?active_subnav=accept_late_work&feature=late+work'
          put_focus(focus: "Course,#{course.id}", return_to: unfocus_late_work_path)

          expect(response).to redirect_to(
            GradebookEngine::Engine.routes.url_helpers.course_path(
              active_subnav: 'accept_late_work',
              course_id: course.id,
              feature: 'late work',
              program_id: program.id
            )
          )
        end
      end

      context 'when a section has the focus' do
        it 'redirects you to the reports path' do
          report_path = "/gradebook/#{program.id}/courses/#{course.id}/show_reports"
          put_focus(focus: "Section,#{section.id}", return_to: report_path)

          expect(response).to redirect_to(
            # It seems there are problems to use the gradebook_engine object at the controller spec
            # level. As a workaround we use GradebookEngine::Engine.routes.url_helpers
            GradebookEngine::Engine.routes.url_helpers.course_reports_path(
              program_id: program.id, course_id: course.id, section_id: section.id
            )
          )
        end

        it 'redirects you to the late work path' do
          late_work_path = "/gradebook/#{program.id}/courses/#{course.id}" \
                           "/sections/#{section.id}/late_work"
          put_focus(focus: "Section,#{section.id}", return_to: late_work_path)

          expect(response).to redirect_to(
            GradebookEngine::Engine.routes.url_helpers.course_section_show_late_work_path(
              program_id: program.id, course_id: course.id, section_id: section.id
            )
          )
        end

        it 'redirects you to the analytics overview path' do
          overview_path = "/gradebook/#{program.id}/courses/#{course.id}" \
                          "/sections/#{section.id}/analytics/overview"
          put_focus(focus: "Section,#{section.id}", return_to: overview_path)

          expect(response).to redirect_to(
            GradebookEngine::Engine.routes.url_helpers.course_section_analytics_overview_path(
              program_id: program.id, course_id: course.id, section_id: section.id
            )
          )
        end

        it 'redirects you to the analytics progress path' do
          progress_path = "/gradebook/#{program.id}/courses/#{course.id}" \
                          "/sections/#{section.id}/analytics/progress"
          put_focus(focus: "Section,#{section.id}", return_to: progress_path)

          expect(response).to redirect_to(
            GradebookEngine::Engine.routes.url_helpers.course_section_analytics_progress_path(
              program_id: program.id, course_id: course.id, section_id: section.id
            )
          )
        end

        it 'redirects you to the standards path' do
          standards_path = "/gradebook/#{program.id}/courses/#{course.id}" \
                           "/sections/#{section.id}/standards"
          put_focus(focus: "Section,#{section.id}", return_to: standards_path)

          expect(response).to redirect_to(
            gradebook_standards_section_report_index_path(
              program_id: program.id, course_id: course.id, section_id: section.id
            )
          )
        end

        it 'redirects you to the roster path' do
          roster_path = "/#{program.id}/sections/#{section.id}/roster?course_id=#{course.id}"
          put_focus(focus: "Section,#{section.id}", return_to: roster_path)

          expect(response).to redirect_to(
            section_roster_path(
              program_id: program.id, section_id: section.id
            )
          )
        end
      end

      context 'with a new sort value' do
        it 'sets the new sort level in the session' do
          sort_params = {
            'column' => 'cat', 'direction' => 'asc', 'category_id' => '1'
          }

          put_focus(focus: "Course,#{course.id}", sort: sort_params)
          expect(session[:focus][program.id.to_s]).to eq(
            'course_id' => course.id,
            'section_id' => nil,
            'sort' => sort_params
          )
        end
      end
    end
  end

  describe 'get redirect' do
    let(:program) { build_stubbed(:program) }
    let(:user) { build_stubbed(:instructor) }
    let(:course) { build_stubbed(:course) }
    let(:focus) { "Course,#{course.id}" }
    let(:old_focus) do
      {
        program.id.to_s => {
          'course_id' => course.id,
          'sort' => nil,
          'section_id' => nil
        }
      }
    end

    before do
      allow(user).to receive(:has_current_access_to?).and_return(true)
      fake_login(user)
    end

    def do_request
      put 'redirect', params: { program_id: program.id }
    end

    it 'raises error if called without saved focus in session' do
      expect { do_request }.to raise_error('No saved focus to redirect')
    end

    it 'sets focus when saved focus in session exists' do
      session[:saved_focus] = old_focus
      do_request
      expect(session[:focus]).to eq(session[:saved_focus])
    end

    it 'redirects to gradebook show action' do
      session[:saved_focus] = old_focus
      allow(controller).to receive(:render)
      expect(controller).to receive(:redirect_to).with("/gradebook/#{program.id}")
      do_request
    end
  end

  describe 'PUT update_closed_course' do
    let(:program) { build_stubbed(:program) }
    let(:course) { create(:course) }
    let(:user) { build_stubbed(:instructor) }
    let(:return_to_path) { '/valid/uri' }

    before do
      allow(user).to receive(:has_current_access_to?).and_return(true)
      fake_login(user)
    end

    def do_request(selection)
      put(:update_closed_course, params: { program_id: program.id, selected_course_section: selection, return_to: return_to_path })
    end

    it 'redirects with flash error when no search results are found' do
      allow(controller).to receive(:render)
      expect(controller).to receive(:redirect_to).with('/valid/uri')
      do_request("Course,#{course.id}")
    end

    it 'sets closed course section' do
      do_request("Course,#{course.id}")
      expect(session[:closed_course_section]).to eq(
        'course_id' => course.id,
        'section_id' => nil
      )
    end
  end
end
