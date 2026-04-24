require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::AssignmentWizardController do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) do
    program.units.first.lessons.first.tap do |lesson|
      lesson.toc_entries = [strand]
      lesson.save!
    end
  end
  let(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson: lesson,
      program: program
    )
  end

  let(:activity_1) do
    create(
      :activity_with_assignment_group,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  let(:activity_2) do
    create(
      :activity_with_assignment_group,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  let(:credit_category) do
    create(:category, course: course, name: 'Credit', weighting_percent: 50)
  end

  let(:graded_category) do
    create(:category, course: course, name: 'Graded', weighting_percent: 50)
  end

  let(:category_attrs) do
    {
      Credit: { id: credit_category.id, name: credit_category.name },
      Graded: { id: graded_category.id, name: graded_category.name }
    }
  end

  let(:assignment_attrs) do
    [
      {
        category: credit_category.name,
        due_date: 14.days.from_now.to_date,
        group_id: 1,
        id: activity_1.id
      },
      {
        category: graded_category.name,
        due_date: 15.days.from_now.to_date,
        group_id: 2,
        id: activity_2.id
      }
    ]
  end

  # Params have due dates as keys, with values being an array of
  # activities to be assigned on the day. e.g.
  # {
  #   '10/22/2019' => [
  #     { id: 42217, group_id: 1, category: 'Credit' }
  #   ]
  # }
  let(:raw_assignment_params) do
    assignment_attrs.each_with_object({}) do |attrs, memo|
      due_date = attrs[:due_date].strftime('%m/%d/%Y')
      memo[due_date] = [attrs.except(:due_date)]
      due_date = (attrs[:due_date] + 5.days).strftime('%m/%d/%Y')
      # Add a due date with no assignments.
      memo[due_date] = []
    end
  end

  describe 'POST /create' do
    let(:target_path) do
      instructor_assignment_wizard_index_path(
        course_id: course.id, program_id: program.id, format: :json
      )
    end

    let(:default_params) do
      {
        raw_assignments: raw_assignment_params,
        categories: category_attrs,
        section_id: section.id
      }
    end

    # See https://github.com/rspec/rspec-rails/issues/610
    # Without explicitly converting the params to JSON, for create action,
    # a value of false for the non-attribute parameter copy_external_assignments
    # gets turned into the string "false", which evaluates to true.
    # After Rails 5 upgrade, it should be possible to simplify this to either:
    # post(target_path, params: params_hash, as: :json)
    # or
    # post(target_path, params: params_hash.merge(as: :json))
    def do_post_with_json_params(params_hash)
      post(
        target_path,
        params: JSON.dump(params_hash),
        headers: { 'CONTENT_TYPE' => 'application/json' }
      )
    end

    def do_request(extra_params = {})
      do_post_with_json_params(default_params.merge(extra_params))
    end

    include_examples 'require instructor with program access', :json

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'creates the specified assignments in the specified sections',
         new_gb_sync: true do

        old_assignment = create(
          :assignment,
          assignable: activity_1,
          category_id: credit_category.id,
          due_date: 2.days.from_now.to_date,
          section_id: section.id
        )

        do_request

        expect(response).to be_ok

        # Verify the body is JSON containing the BulkAssignmentCreator job ids.
        expect(JSON.parse(response.body)).to have_key('job_ids')

        # Verify previous assignments are deleted
        expect(Assignment.where(id: old_assignment.id)).not_to exist

        # Verify new assignments are created in the correct category and groups
        assignment_attrs.each do |attrs|
          result = section.assignments.where(assignable_id: attrs[:id]).first
          category = category_attrs[result.category.name.to_sym]
          expect(result.category_id).to eq(category[:id])
          expect(result.due_date).to eq(attrs[:due_date])
        end
      end
    end
  end
end
