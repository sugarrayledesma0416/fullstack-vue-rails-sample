describe WorksetsController do
  describe '#show' do
    let(:current_user) { create(:student) }
    let(:current_program) { create(:program, language_code: 'es') }

    before do
      allow(controller).to receive(:current_program).and_return(current_program)
      allow(current_user).to receive(:has_current_access_to?).and_return(true)
      allow(current_program).to receive(:supersite_junior?).and_return(false)
      fake_login(current_user)

      @assignment_day = '2010-03-17'

      @course = build_stubbed(:course)
      @section = build_stubbed(:section, course: @course)
      allow(Section).to receive(:find).and_return(@section)
      allow(@section).to receive(:program).and_return(current_program)

      @concept = build_stubbed(:concept)
      allow(Concept).to receive(:find_by).and_return(nil)
      allow(Concept).to receive(:find_by).with(id: @concept.id.to_s).and_return(@concept)

      @category = build_stubbed(:category)
      allow(Category).to receive(:find_by).and_return(nil)
      allow(Category).to receive(:find_by).with(id: @category.id.to_s).and_return(@category)

      @classwork = double(Classwork, section: @section, user: current_user)
      allow(Classwork).to receive(:new).and_return(@classwork)
      allow(@classwork).to receive(:create_workset).and_return([])
      allow(@classwork).to receive(:new_workset)

      @classwork_filter = double(Classwork, has_assignments?: false)
    end

    it_should_require_a_logged_in_user do
      get(
        :show,
        params: { section_id: @section.id, assignment_day: @assignment_day }
      )
    end

    context 'with a logged in user,' do
      def do_request_with_section(section)
        get :show, params: { section_id: section, assignment_day: @assignment_day }
      end

      def do_request
        do_request_with_section(37)
      end

      it_should_behave_like 'a page that requires program access'

      it 'assigns @section' do
        do_request
        expect(assigns(:section)).to eq(@section)
      end

      it 'assigns @assignment_day' do
        do_request
        expect(assigns(:assignment_day)).to eq(@assignment_day)
      end

      context 'when a concept id is passed,' do
        it 'assigns @concept' do
          get(
            :show,
            params: {
              assignment_day: @assignment_day,
              concept_id: @concept.id,
              section_id: '37'
            }
          )
          expect(assigns(:concept)).to eq(@concept)
        end
      end

      context 'when no assignments exist,' do
        before do
          allow(ClassworkFilter).to receive(:new).and_return(@classwork_filter)
        end

        it 'renders the no_assignments template if the program is not ' \
           'a Supersite Junior program' do
          allow(current_program).to receive(:supersite_junior?).and_return(false)

          get :show, params: { section_id: '37', assignment_day: @assignment_day }

          expect(response).to render_template(:no_assignments)
        end

        it 'renders the supersite_junior_no_assignments template if the ' \
           'program is a Supersite Junior program' do
          allow(current_program).to receive(:supersite_junior?).and_return(true)

          get :show, params: { section_id: '37', assignment_day: @assignment_day }

          expect(response).to render_template(:supersite_junior_no_assignments)
        end
      end

      it 'creates a classwork filter based on the params' do
        expect(ClassworkFilter).to receive(:new).with(
          hash_including(
            assignment_day: @assignment_day,
            category: @category,
            classwork: @classwork,
            concept: @concept
          )
        ).and_return(@classwork_filter)
        get(
          :show,
          params: {
            assignment_day: @assignment_day,
            category_id: @category.id.to_s,
            concept_id: @concept.id,
            full: 'blah',
            section_id: '37'
          }
        )
      end

      context 'when there are assignments' do
        before do
          @classwork_filter_2 = double(Classwork, has_assignments?: true)
          allow(ClassworkFilter).to receive(:new).and_return(@classwork_filter_2)
        end

        it 'creates a workset' do
          activity = build_stubbed(:activity)
          allow(@classwork_filter_2).to receive(:first_activity_for_student)
            .and_return(activity.id)
          expect(@classwork_filter_2).to receive(:create_workset)
          do_request
        end

        it 'redirects to the first activity for the student' do
          activity = build_stubbed(:activity)
          allow(@classwork_filter_2).to receive(:create_workset)
          expect(@classwork_filter_2).to receive(:first_activity_for_student)
            .and_return(activity)
          do_request
          expect(response).to redirect_to(section_activity_path(@section, activity))
        end
      end
    end

    context 'when a range is passed,' do
      let(:range) { '2..10' }

      it 'instantiates a workset filter with the range' do
        mock_classwork_filter = double(ClassworkFilter).as_null_object
        expect(ClassworkFilter).to receive(:new).with(
          hash_including(
            classwork: @classwork,
            concept: @concept,
            rank_range: range
          )
        ).and_return(mock_classwork_filter)
        get(
          :show,
          params: {
            assignment_day: Date.today,
            concept_id: @concept.id,
            rank_range: range,
            section_id: '37'
          }
        )
      end
    end
  end
end
