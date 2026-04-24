require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::AssignmentFiltersController do
  describe 'PUT /update' do
    let(:program) { create(:program) }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor, program: program) }
    let(:lesson) { create(:lesson, unit: course.first_unit) }
    let(:new_lesson) { create(:lesson, unit: course.last_unit) }
    let(:category) { create(:category, course: course) }
    let(:non_focused_course) do
      create(:course, owner: instructor, program: program)
    end
    let(:previous_section) do
      create(:section, course: non_focused_course, instructor: instructor)
    end

    let(:filter) do
      AssignmentFilter.new(course: course, lesson: lesson, user: instructor)
    end
    let(:target_path) do
      instructor_assignment_filter_path(program_id: program.id)
    end

    let(:new_attrs) do
      {
        activity_type: 'composition',
        category_id: category.id,
        content_type: 'activities',
        day: 3.days.ago.to_date.to_s,
        grading_method: 'instructor',
        lesson_id: new_lesson.id,
        previous_section_id: previous_section.id,
        toc_entry_location: 123,
        week: 1.week.ago.to_date.to_s
      }
    end

    let(:update_params) { { assignment_filter: new_attrs } }

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        filter.save!
        log_in_user_with_access_to_programs(instructor, [program])
        # explicitly set focused course
        put(
          instructor_focus_path(program_id: program.id),
          params: {
            focus: "Course,#{course.id}",
            return_to: ''
          }
        )
      end

      it 'requires a root key :assignment_filter in the params' do
        expect { put(target_path, params: {}) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: assignment_filter/
        )
      end

      it 'updates only the AssignmentFilter for the logged-in user and ' \
         'currently focused course' do
        other_instructor_filter = AssignmentFilter.create!(
          course: course, lesson: lesson, user: create(:instructor)
        )

        non_focused_course_filter = AssignmentFilter.create!(
          course: non_focused_course, lesson: lesson, user: instructor
        )

        do_request

        expect(response).to redirect_to(
          instructor_new_assignments_path(program.id)
        )

        other_instructor_filter.reload
        expect(other_instructor_filter.lesson_id).not_to eq(new_lesson.id)

        non_focused_course_filter.reload
        expect(non_focused_course_filter.lesson_id).not_to eq(new_lesson.id)

        filter.reload
        expect(filter).to have_attributes(
          # day param is specified as a string, but converted to a date type
          # when saved.
          new_attrs.merge(day: Date.parse(new_attrs[:day]))
        )
      end

      it 'ignores a specified day param if no previous section is specified' do
        attrs_without_section = new_attrs.except(:previous_section_id)
        put(target_path, params: { assignment_filter: attrs_without_section })

        expect(response).to redirect_to(
          instructor_new_assignments_path(program.id)
        )

        filter.reload
        expect(filter).to have_attributes(
          attrs_without_section.merge(day: nil)
        )
      end
    end
  end
end
