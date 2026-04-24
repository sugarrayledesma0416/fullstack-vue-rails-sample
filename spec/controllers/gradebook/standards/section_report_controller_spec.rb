describe Gradebook::Standards::SectionReportController do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:) }
  let(:lesson) { program.units.first.lessons.first }
  let(:activity) do
    create(:activity, lesson:, title: 'Some Assessment')
  end

  let(:standard_set) do
    StandardSet.create(
      vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2010,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: 'CCSS'
    )
  end

  before do
    initialize_program_access_client_calls_for_user_and_program(instructor, program)
    fake_login(instructor)
  end

  describe 'GET #index' do
    def do_request(params = {})
      default_params = { program_id: program.id, course_id: course.id, section_id: section.id }
      get :index, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'
  end

  describe 'POST #assessments' do
    def do_request(params = {})
      default_params = { program_id: program.id, course_id: course.id, section_id: section.id }
      post :assessments, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    context 'with a lesson that includes a standards test' do
      let!(:standards_exam_1) do
        create(
          :activity,
          activity_type: 'exam',
          lesson:,
          toc_location_rank: 100,
          title: 'End of Unit Exam'
        )
      end

      let!(:standards_exam_2) do
        create(
          :activity,
          activity_type: 'exam',
          lesson:,
          toc_location_rank: 50,
          title: 'Mid Unit Exam'
        )
      end

      let!(:standards_exam_3) do
        create(
          :activity,
          activity_type: 'exam',
          lesson:,
          toc_location_rank: 30,
          title: 'Unit 1 Exam'
        )
      end

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Activity).to receive(:proficiency_assessment?) do |activity|
          activity.in?([standards_exam_1, standards_exam_2])
        end
        allow(standards_exam_3).to receive(:progress_monitoring_assessment?).and_return(true)
      end

      it 'returns JSON content type for proficiency assessments' do
        do_request(selected_lesson_id: lesson.id)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns a JSON object with only proficiency assessments' do
        do_request(selected_lesson_id: lesson.id)
        expect(response.parsed_body).to eq(
          {
            'assessments' =>
              [
                [standards_exam_2.title, standards_exam_2.id],
                [standards_exam_1.title, standards_exam_1.id]
              ],
            'status' => 'ok'
          }
        )
      end

      it 'returns a JSON object without the progress monitoring assessment' do
        do_request(selected_lesson_id: lesson.id)
        result = response.parsed_body
        expect(result['assessments']).not_to include([standards_exam_3.title, standards_exam_3.id])
      end
    end

    context 'with a lesson that does not have any standards tests' do
      it 'returns a JSON object with no assessments' do
        do_request(selected_lesson_id: lesson.id)
        expect(response.parsed_body).to eq({ 'assessments' => [], 'status' => 'ok' })
      end
    end
  end

  describe 'POST #categories with assessment associated' do
    def do_request(params = {})
      default_params = { program_id: program.id, course_id: course.id, section_id: section.id }
      post :categories, params: default_params.merge(params)
    end

    it_behaves_like 'an action that requires a logged in instructor'

    context 'with a lesson that includes progress monitoring assessments' do
      let!(:concept_1) { create(:concept, lesson:, name: 'Progress Monitoring Assessment') }
      let!(:progress_monitoring_exam_1) do
        create(
          :activity,
          concept: concept_1,
          lesson:,
          activity_type: 'exam',
          toc_location_rank: 20,
          title: 'Progress Monitoring Exam 1',
          component_name: 'Quizzes'
        )
      end

      let!(:progress_monitoring_exam_2) do
        create(
          :activity,
          concept: concept_1,
          activity_type: 'exam',
          lesson:,
          toc_location_rank: 30,
          title: 'Progress Monitoring Exam 2',
          component_name: 'Unit Test'
        )
      end

      before do
        allow_any_instance_of(Activity).to receive(:standards_test?).and_return(true)
      end

      it 'returns a JSON object with the unique categories and assessment IDs' do
        do_request(selected_lesson_id: lesson.id)

        expect(response.parsed_body).to eq(
          {
            'categories' => ['Quizzes', 'Unit Test'],
            'assessment_ids' => [progress_monitoring_exam_1.id, progress_monitoring_exam_2.id],
            'status' => 'ok'
          }
        )
      end
    end

    context 'with a lesson that does not have progress monitoring assessments' do
      let(:activity_exam_1) do
        create(
          :activity,
          lesson:,
          activity_type: 'exam',
          toc_location_rank: 20,
          title: 'Activity Exam 1',
          component_name: 'Quizzes'
        )
      end

      before do
        allow_any_instance_of(Activity).to receive(:standards_test?).and_return(true)
      end

      it 'returns a JSON object with empty categories and assessment IDs' do
        do_request(selected_lesson_id: lesson.id)

        expect(response.parsed_body).to eq(
          {
            'categories' => [],
            'assessment_ids' => [],
            'status' => 'ok'
          }
        )
      end
    end
  end
end
