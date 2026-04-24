require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe GradebookEngine::LateWorkController, new_gb_sync: true do
  let(:owner) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: owner, program: program) }
  let(:section) { create(:section, course: course, instructor: owner) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:concept) { create(:concept, lesson: lesson, id: strand.location) }
  let(:category) { create(:category, course: course) }
  let(:activity) do
    create(
      :activity,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  describe 'GET /index' do
    let(:url_params) do
      {
        activities_strand_or_day: 'activity',
        activity_id: activity.id,
        all_lesson_or_week: lesson.id,
        category_id: '',
        course_id: course.id,
        lesson_or_due_date: 'lesson',
        program_id: program.id,
        section_id: section.id
      }
    end

    before do
      create(
        :assignment,
        assignable: activity,
        category: category,
        due_date: 2.days.ago.to_date,
        section: section
      )
      create(:enrollment, section: section, user: student)
      GradebookEngine::GradebookAPI.submit(
        student.id,
        section.id,
        activity.id,
        section.school_id,
        points_earned: 10,
        submitted_at: Time.now
      )
    end

    it 'does not throw "unable to convert unpermitted parameters to hash"' do
      log_in_user_with_access_to_programs(owner, [program])

      expect do
        get gradebook_engine.course_section_activity_late_work_index_path(url_params)
      end.not_to raise_error
    end
  end
end
