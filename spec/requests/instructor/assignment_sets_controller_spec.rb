require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::AssignmentSetsController do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:due_date) { course.start_date + 7.days }
  let(:activity) { create(:activity) }

  describe 'POST #create' do
    let(:create_attrs) do
      { due_date: due_date, section_id: section.id }
    end

    def do_request(extra_attrs = {})
      post(
        instructor_assignment_sets_path(program_id: program.id, format: :json),
        params: { assignment_set: create_attrs.merge(extra_attrs) }
      )
    end

    include_examples 'require instructor with program access', :json

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'creates a new AssignmentSet record with valid params' do
        expect { do_request }.to change(AssignmentSet, :count).by(1)

        expect(response).to be_ok

        expect(AssignmentSet.last).to have_attributes(create_attrs)
      end

      it 'renders JSON with error messages with invalid assignmentSet params' do
        expect { do_request(due_date: '') }.not_to change(AssignmentSet, :count)

        expect(response).to be_unprocessable

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          errors: ['Due date is required']
        )
      end

      it 'renders JSON with error messages with invalid activity params' do
        expect do
          do_request(
            activities: [
              { activity_id: activity.id, assignment_set_rank: '' }
            ]
          )
        end.not_to change(AssignmentSet, :count)

        expect(response).to be_unprocessable

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          errors: [
            'Activities assignment set rank is required',
            'Activities assignment set rank must be a number'
          ]
        )
      end
    end
  end

  describe 'PUT #update' do
    let(:assignment_set) do
      create(
        :assignment_set,
        due_date: due_date,
        section_id: section.id
      )
    end

    let(:update_attrs) do
      {
        activities: [
          { activity_id: activity.id, assignment_set_rank: 3 }
        ]
      }
    end

    def do_request
      put(
        instructor_assignment_set_path(id: assignment_set.id, program_id: program.id),
        params: { assignment_set: update_attrs }
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'updates the specified assignment sets with the specified ' \
         'activities and renders no errors if all attrs pass validation' do
        do_request

        expect(response).to be_ok

        expect(assignment_set.activities).to contain_exactly(
          have_attributes(activity_id: activity.id, assignment_set_rank: 3)
        )
      end

      it 'does not update any assignment set if and sets errors for each ' \
         'failed set if any assignment set fails validation' do
        update_attrs[:activities][0][:assignment_set_rank] = ''

        do_request

        expect(response).to be_unprocessable

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          errors: [
            'Activities could not be updated because one or more records ' \
            'failed validation'
          ]
        )
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:assignment_set) do
      create(
        :assignment_set,
        due_date: due_date,
        section_id: section.id
      )
    end

    def do_request
      delete instructor_assignment_set_path(id: assignment_set.id, program_id: program.id)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      # it 'fails with a 404 error if the specified assignment set is not ' \
      #    'owned by the current user' do
      #   expect { do_request }.to raise_error(ActiveRecord::RecordNotFound)
      # end

      it 'deletes the specified assignment set and associated ' \
         'assignment_set_activity records if it is owned by the ' \
         'current user' do
        assignment_set.activities.create!(
          activity_id: activity.id, assignment_set_rank: 3
        )

        do_request

        expect(response).to be_ok

        expect(AssignmentSet).not_to exist(assignment_set.id)
        expect(AssignmentSetActivity.count).to eq(0)
      end
    end
  end

  describe 'GET /export' do
    let(:unit) { create(:unit, program: program) }
    let(:lesson) do
      create(
        :lesson,
        name: 'Lesson 1 long',
        label: 'Lesson 1<br >short <b>title</b>',
        unit: unit
      )
    end

    let(:concept) do
      create(
        :concept,
        background_color: '#FFF',
        lesson: lesson,
        program: program,
        name: 'Strand<br>1 <b>title</b>'
      )
    end

    let(:due_date_1) { 7.days.from_now.to_date }

    let(:due_date_2) { 5.days.from_now.to_date }

    let(:activity_1) do
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        title: 'Activity<br />1 <b>title</b>'
      )
    end

    let(:activity_2) do
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        title: 'Activity 2 title'
      )
    end

    def do_request
      get export_instructor_assignment_sets_path(
        format: 'csv',
        program_id: program.id
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])

        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date_1,
          section: section,
          rank: 22
        )

        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date_2,
          section: section,
          rank: 33
        )

        assignment_set = create(
          :assignment_set,
          due_date: due_date_2,
          section: section
        )

        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set,
          assignment_set_rank: 11
        )
      end

      it 'renders a csv' do
        do_request

        expect(response).to be_ok

        csv = response.body
        parsed_data = CSV.parse(csv.encode('windows-1252').encode('utf-8'))

        expect(parsed_data[0]).to eq(
          AssignmentSetList::CsvData::HEADER_ROW
        )

        expect(parsed_data[1]).to eq(
          [
            due_date_2.strftime('%-m/%d'),
            'Yes',
            '11',
            'Lesson 1 short title',
            'Strand 1 title',
            'Activity 2 title'
          ]
        )

        expect(parsed_data[2]).to eq(
          [
            due_date_1.strftime('%-m/%d'),
            'No',
            '22',
            'Lesson 1 short title',
            'Strand 1 title',
            'Activity 1 title'
          ]
        )
      end
    end
  end
end
