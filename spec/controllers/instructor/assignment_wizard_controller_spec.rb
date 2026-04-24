# encoding: utf-8

describe Instructor::AssignmentWizardController do
  let(:program) { build_stubbed(:program, unit_label: 'Unit Label') }
  let(:course) { create(:course, name: 'Foo Course') }
  let(:section) { create(:section, course: course, assignments: []) }
  let(:assignment_1) { create(:assignment) }
  let(:previous_course) { create(:course) }
  let!(:section_with_assignments) { create(:section, course: previous_course, assignments: [assignment_1]) }
  let(:instructor) { build_stubbed(:instructor) }

  before do
    allow(Program).to receive(:find_by_id).and_return(program)
    allow(Course).to receive(:find).and_return(course)
    allow(instructor).to receive(:has_current_access_to?).and_return(true)
    fake_login(instructor)
  end

  describe '#course_info' do
    it 'returns a json payload with course info' do
      category = build_stubbed(:category)
      allow(course).to receive(:categories).and_return([category])
      allow(course).to receive('start_date').and_return('2014-01-01');
      allow(course).to receive('end_date').and_return('2014-12-31');

      course_options = double(
        'CourseOptions',
        previous_courses_with_assignments: [previous_course],
        setup_descriptions: ''
      )
      expect(course_options)
        .to receive(:previous_course_and_section_data)
        .and_return(
          [{
            id: previous_course.id,
            name: previous_course.name,
            sections: [{
              id: section_with_assignments.id,
              name: section_with_assignments.name
            }]
          }]
        )

      expect(CourseOptions).to receive(:new).with(instructor, course, program).
        and_return(course_options)
      allow(Course).to receive(:find).and_return(course)
      course_data = {
        'current_course' => course.id,
        'name' => 'Foo Course',
        'start_date' => '2014-01-01',
        'end_date' => '2014-12-31',
        'has_assignments' => false,
        'setup_descriptions' => '',
        'categories' => [
          {
            'id' => category.id,
            'name' => category.name
          }
        ],
        'previous_courses' => [{
          'id' => previous_course.id,
          'name' => previous_course.name,
          'sections' => [{
            'id' => section_with_assignments.id,
            'name' => section_with_assignments.name
          }]
        }],
        'unit_label' => 'Unit Label'
      }
      params = {
        program_id: program.id,
        course_id: course.id,
        format: 'json'
      }

      get :course_info, params: params
      expect(JSON.parse(response.body)).to eq(course_data)
    end
  end
end
