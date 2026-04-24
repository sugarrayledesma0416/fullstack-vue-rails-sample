require 'rails_helper'

describe InstitutionAdminDashboardPresenter do
  include RspecJsContentHelpers

  let(:presenter) do
    described_class.new(institution_admin, school.id, program.id, year, course_id)
  end

  let(:year) { nil }
  let(:course_id) { nil }
  let(:district) { create(:district, name: 'VHL District 1') }
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }
  let(:institution_admin) do
    create(:institution_admin, first_name: 'Jane', last_name: 'Doe')
  end
  let(:other_institution_admin) do
    create(:institution_admin, first_name: 'Cookie', last_name: 'Doe')
  end
  let(:instructor) { build_stubbed(:instructor) }
  let(:program) { create(:program_with_lessons) }
  let(:other_program) { create(:program_with_lessons) }
  let(:program_one) { create(:program) }
  let!(:course) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id,
      created_at: Time.zone.now - 10.minutes,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:course_2) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:closed_course) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      end_date: Time.zone.today - 1.day,
      allow_past_end_date: true,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:course_previous_year_1) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id,
      start_date: Date.new(Time.zone.today.year - 2, 12, 15),
      end_date: Date.new(Time.zone.today.year - 1, 4, 15),
      allow_past_end_date: true,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:course_previous_year_2) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id,
      start_date: Date.new(Time.zone.today.year - 1, 1, 15),
      end_date: Date.new(Time.zone.today.year - 1, 4, 15),
      allow_past_end_date: true,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:course_next_year) do
    create(
      :course_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id,
      start_date: Date.new(Time.zone.today.year + 1, 1, 1),
      end_date: Date.new(Time.zone.today.year + 1, 6, 1),
      is_enterprise: true,
      enterprise_section: create(:enterprise_section, instructor: institution_admin)
    )
  end
  let!(:template) do
    create(
      :course_template_with_section,
      owner: institution_admin,
      school:,
      program_id: program.id
    )
  end
  let(:course_one) do
    create(
      :course_with_section,
      school:,
      program_id: program_one.id,
      is_enterprise: true,
      enterprise_section: create(:enterprise_section)
    )
  end
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, unit: program.units.first, toc_entries: [strand], label: 'label') }
  let!(:concept) do
    create(
      :concept,
      lesson:,
      id: strand.location,
      program:
    )
  end
  let(:igc_activity) do
    create(
      :instructor_created_activity,
      concept:,
      toc_location: strand.location,
      title: 'Test activity No 1',
      lesson:
    )
  end
  let(:activity_copy) do
    create(
      :instructor_created_activity,
      instructor_id: institution_admin.id,
      lesson:,
      title: 'Test activity No 1',
      concept:,
      toc_location: strand.location
    )
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    allow(Maestro::User).to receive(:accessible_programs)
      .with(institution_admin.guid)
      .and_return([program])

    create(:school_program_admin_user,
           user: institution_admin,
           school:,
           program:,
           account_type: institution_admin.account_type)

    create(:school_program_admin_user,
           user: institution_admin,
           school:,
           program: other_program,
           account_type: institution_admin.account_type)

    5.times do
      enrollment_1 = create(:active_enrollment, section: course.sections.first)
      create(:attempt,
             section: course.sections.first,
             user: enrollment_1.user,
             updated_at: Time.zone.today - 15)
      enrollment_2 = create(:active_enrollment, section: course_2.sections.first)
      create(:attempt, section: course_2.sections.first, user: enrollment_2.user)
      create(:completed_enrollment, section: course.sections.first)
      create(:completed_enrollment, section: course_2.sections.first)
    end

    create_list(:shared_library_activity,
                5,
                source_activity: igc_activity,
                school:)
    create_list(:shared_library_activity,
                3,
                activity: activity_copy,
                source_activity: igc_activity,
                school:,
                is_shared: true)
  end

  describe '#initialize' do
    it { expect(presenter.current_user).to eq(institution_admin) }
    it { expect(presenter.institution_admin).to eq(institution_admin) }
    it { expect(presenter.school).to eq(school) }
    it { expect(presenter.program).to eq(program) }
    it { expect(presenter.year).to eq(Time.zone.today.year) }

    context 'when the year is provided' do
      let(:year) { 2020 }

      it { expect(presenter.year).to eq(year) }
    end

    context 'when the course is enterprise' do
      let(:enterprise_course) { create(:enterprise_course) }
      let(:course_id) { enterprise_course.id }

      it 'sets the course if it is enterprise' do
        expect(presenter.course).to eq(enterprise_course)
      end
    end

    context 'when the course is not enterprise' do
      let(:non_enterprise_course) { create(:course) }
      let(:course_id) { non_enterprise_course.id }

      it 'does not set the course' do
        expect(presenter.course).to be_nil
      end
    end
  end

  describe '#courses_by_school_program' do
    it 'returns the list of open, non-demo courses associated to the selected program/school' do
      presenter.assign_school(school.id)

      expect(presenter.courses_by_school_program[program.id])
        .to match_array([course_2, course, course_next_year])
    end

    it 'returns the full list of courses even if admin has chosen to hide some' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_2.id)

      expect(presenter.courses_by_school_program[program.id])
        .to match_array([course_2, course, course_next_year])
    end

    it 'ignores hidden-course records for other admins' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_2.id)
      InstitutionAdminHiddenCourse.create!(user_id: other_institution_admin.id, course_id: course_2.id)

      expect(presenter.courses_by_school_program[program.id])
        .to match_array([course_2, course, course_next_year])
    end
  end

  describe '#displayed_courses_by_school_program' do
    it 'returns same list as #courses_by_school_program, excluding courses that are hidden for the admin' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_2.id)

      expect(presenter.displayed_courses_by_school_program[program.id])
        .to match_array([course, course_next_year])
    end

    it 'returns courses that are not hidden for the admin but hidden for other admins' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: other_institution_admin.id, course_id: course_2.id)

      expect(presenter.displayed_courses_by_school_program[program.id])
        .to match_array([course_2, course, course_next_year])
    end
  end

  describe '#all_courses_grouped_by_program' do
    it 'returns the full list of courses even if admin has chosen to hide some' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_2.id)

      expect(presenter.all_courses_grouped_by_program[program.id])
        .to match_array([course_2, course, course_next_year])
    end
  end

  describe "#hidden_courses" do
    it 'returns courses that are hidden for the admin' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_2.id)

      expect(presenter.hidden_courses(program.id))
        .to match_array([course_2])
    end

    it 'does not return courses that are hidden for other admin' do
      presenter.assign_school(school.id)
      InstitutionAdminHiddenCourse.create!(user_id: other_institution_admin.id, course_id: course_2.id)

      expect(presenter.hidden_courses(program.id))
        .to match_array([])
    end

    it 'includes non enterprise courses in the results' do
      presenter.assign_school(school.id)
      course_3 = create(:course_with_section,
                        owner: institution_admin,
                        school:,
                        program_id: program.id,
                        is_enterprise: false)
      InstitutionAdminHiddenCourse.create!(user_id: institution_admin.id, course_id: course_3.id)

      expect(presenter.hidden_courses(program.id))
        .to include(course_3)
    end
  end

  describe '#count_enrollments_by_course' do
    it 'returns the number of enrollments of a course' do
      presenter.assign_school(school.id)

      expect(presenter.count_enrollments_by_course(course.id)).to be 5
      expect(presenter.count_enrollments_by_course(course_2.id)).to be 5
    end
  end

  describe '#section_owners' do
    let(:section) { create(:section, course:, instructor: institution_admin) }

    context 'when the section has multiple instructors' do
      let(:other_instructor) { create(:instructor) }
      let!(:section_instructor) do
        create(:section_instructor, instructor: other_instructor, section:, role: 'Instructor')
      end

      it 'returns all owners of the section' do
        owners = presenter.section_owners(section)

        expect(owners).to match_array([
          {
            instructor: institution_admin,
            role: 'Instructor'
          },
          {
            instructor: other_instructor,
            role: 'Instructor'
          }
        ])
      end
    end

    context 'when the section has only the main instructor' do
      it 'returns the main instructor as the sole owner' do
        owners = presenter.section_owners(section)

        expect(owners).to match_array([
          {
           instructor: institution_admin,
           role: 'Instructor'
          }
        ])
      end
    end
  end

  describe '#count_enrollments_by_section' do
    it 'returns the number of active enrollments by section' do
      presenter.assign_school(school.id)
      create(:section, course: course)
      course.reload
      create_list(:active_enrollment, 10, section: course.sections[1])
      enrollment_counts = course.sections.map do |section|
        presenter.count_enrollments_by_section(section.id)
      end
      expect(enrollment_counts).to eq([5, 10])
    end
  end

  describe '#sections' do
    it 'returns the list of open sections for the selected program/school' do
      presenter.assign_school(school.id)
      expect(presenter.sections(course.id)).to eq course.sections.all
      expect(presenter.sections(closed_course.id)).to eq []
    end
  end

  describe '#templates' do
    it 'returns the list of templates associated to the selected program/school' do
      presenter.assign_school(school.id)
      expect(presenter.templates(program)).to eq [template]
    end

    it 'returns nil if there are no templates associated to the selected program/school' do
      school_no_templates = create(:school)
      presenter.assign_school(school_no_templates.id)
      expect(presenter.templates(program)).to be_nil
    end
  end

  describe '#count_enrollments_by_school_and_program' do
    let(:course_same_program_other_school) do
      create(
        :course_with_section,
        school: other_school,
        program_id: program.id,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end
    let(:course_expired) do
      create(
        :course_with_section,
        school:,
        program_id: program.id,
        end_date: Date.yesterday,
        allow_past_end_date: true,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end

    before do
      create(
        :school_program_admin_user,
        user: institution_admin,
        school: other_school,
        program:,
        account_type: institution_admin.account_type
      )
      create_list(:active_enrollment, 3, section: course_one.sections.first)
      create_list(:active_enrollment, 4, section: course_same_program_other_school.sections.first)
      create_list(:active_enrollment, 2, section: course_expired.sections.first)
    end

    it 'returns the count of active enrollments by program/school' do
      expect(presenter.count_enrollments_by_school_and_program(school.id, program.id)).to be 10
      expect(presenter.count_enrollments_by_school_and_program(school.id, program_one.id)).to be 3
      expect(presenter.count_enrollments_by_school_and_program(other_school.id, program.id)).to be 4
    end
  end

  describe '#enterprise_enrollment_count_with_link' do
    let(:section) { create(:section, course:) }
    let(:enrollment_count) { 5 }

    before do
      allow(presenter).to receive(:count_enrollments_by_section).with(section.id)
                                                                .and_return(enrollment_count)
    end
    it 'returns a link to roster path for the section' do
      roster_path = "/institution_admin/roster/#{section.id}/courses_past"
      result = presenter.enterprise_enrollment_count_with_link(section.id)
      expect(result).to eq("<a class=\"u-txt-black  u-txt-under\" href=\"#{roster_path}\">#{enrollment_count}</a>" )
    end
  end

  describe '#count_enrollments_by_district_and_program' do
    it 'returns the count of active enrollments by district/programs/schools' do
      district.schools << school
      expect(presenter.count_enrollments_by_district_and_program(district.id, program.id)).to be 10
    end
  end

  describe '#count_insufficient_access_by_program' do
    let(:course_expired) do
      create(
        :course_with_section,
        school:,
        program_id: program.id,
        end_date: Date.yesterday,
        allow_past_end_date: true,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end

    before do
      create_list(:enrollment, 3, section_id: course.sections.first.id, sufficient_access: false)
      create_list(:enrollment, 2, section_id: course_one.sections.first.id, sufficient_access: false)
      create_list(:enrollment, 2, section: course_expired.sections.first, sufficient_access: false)
    end

    it 'returns the count of students without access by program/school' do
      expect(presenter.count_insufficient_access_by_program(school.id, program.id)).to be 3
      expect(presenter.count_insufficient_access_by_program(school.id, program_one.id)).to be 2
    end
  end

  describe '#count_insufficient_access_by_section' do
    it 'returns the count of students without access by section' do
     presenter.assign_school(school.id)
     section_id = course.sections.first.id
     other_section_id = create(:section, course: course).id
     create_list(:enrollment, 3, section_id: section_id, sufficient_access: false)
     create_list(:enrollment, 5, section_id: other_section_id, sufficient_access: false)
     expect(presenter.count_insufficient_access_by_section(section_id)).to be 3
     expect(presenter.count_insufficient_access_by_section(other_section_id)).to be 5
    end
  end

  describe '#section_insufficient_access' do
    let(:section) { create(:section, course:) }

    context 'when section insufficient access count is greater than 0' do
      let(:insufficient_access_count) { 5 }

      before do
        allow(presenter).to receive(:count_insufficient_access_by_section)
          .with(section.id).and_return(insufficient_access_count)
      end

      it 'returns insufficient access count with a link to roster path for the section' do
        roster_path = "/institution_admin/roster/#{section.id}/courses_past"
        result = presenter.section_insufficient_access(section.id)
        expect(result).to eq("<a class=\"u-txt-black  u-txt-under\" href=\"#{roster_path}\">#{insufficient_access_count}</a>")
      end
    end

    context 'when section insufficient access count is 0' do
      let(:insufficient_access_count) { 0 }

      before do
        allow(presenter).to receive(:count_insufficient_access_by_section)
          .with(section.id).and_return(insufficient_access_count)
      end

      it 'returns insufficient access count by section' do
        result = presenter.section_insufficient_access(section.id)
        expect(result).to eq(insufficient_access_count)
      end
    end
  end

  describe '#count_courses_by_program' do
    it { expect(presenter.count_courses_by_program(school.id, program.id)).to be 3 }
  end

  describe '#count_section_by_program' do
    it 'returns the count of sections by program/school' do
      expect(presenter.count_section_by_program(school.id, program.id)).to be 3
    end
  end

  describe '#count_section_by_district_and_program' do
    it 'returns the count of sections by district and programs' do
      district.schools << school
      expect(presenter.count_section_by_district_and_program(district.id, program.id)).to be 3
    end
  end

  describe '#count_section_by_course' do
    it 'returns the count of sections by section' do
      presenter.assign_school(school.id)
      expect(presenter.count_section_by_course(course.id)).to be 1
    end
  end

  describe '#section_needs_grading' do
    it 'returns the number of task with needs_grading task type by section' do
      section = course.sections.first
      student_ids = section.students.pluck(:id)
      expected_grading_number = rand(5..100)
      expected_task_list = { 'needs_grading_section' => expected_grading_number }
      grading_presenter = instance_double(InstructorGradingTasksPresenter,
                                          tasklist_count: expected_task_list)
      expect(InstructorGradingTasksPresenter).to receive(:new).with(current_task: 'needs_grading_section',
                                                                          section_ids: section.id,
                                                                          student_ids: student_ids)
                                                              .and_return(grading_presenter)
      result = presenter.section_needs_grading(section)
      expect(result['needs_grading_section']).to eql(expected_grading_number)
    end
  end

  describe '#section_average' do
    it 'returns the section average' do
      average = rand(0.0..0.1).round(1)
      formatted_average = "#{average*100}%"
      allow(GradebookEngine::GradebookAPI).to receive(:section_average).and_return(average)
      expect(presenter.section_average(course.sections.first)).to eql(formatted_average)
    end
  end

  describe '#count_idle_students_by_program' do
    let(:course_expired) do
      create(
        :course_with_section,
        school:,
        program_id: program.id,
        end_date: Date.yesterday,
        allow_past_end_date: true,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end

    before do
      2.times do
        enrollment_1 = create(:active_enrollment, section: course_expired.sections.first)
        create(
          :attempt,
          section: course_expired.sections.first,
          user: enrollment_1.user,
          updated_at: Time.zone.today - 15
        )
      end
    end

    it 'returns the count of students by program whose last submission was more than 10 days ago' do
      expect(presenter.count_idle_students_by_program(program.id, school.id)).to be 5
    end
  end

  describe '#count_idle_students_by_district_and_program' do
    let(:course_expired) do
      create(
        :course_with_section,
        school:,
        program_id: program.id,
        end_date: Date.yesterday,
        allow_past_end_date: true,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end
    let(:course_expired_two) do
      create(
        :course_with_section,
        school: other_school,
        program_id: other_program.id,
        end_date: Date.yesterday,
        allow_past_end_date: true,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section)
      )
    end

    before do
      district.schools << school
      district.schools << other_school

      3.times do
        enrollment_1 = create(:active_enrollment, section: course_expired.sections.first)
        create(
          :attempt,
          section: course_expired.sections.first,
          user: enrollment_1.user,
          updated_at: Time.zone.today - 15
        )
      end

      3.times do
        enrollment_2 = create(:active_enrollment, section: course_expired_two.sections.first)
        create(
          :attempt,
          section: course_expired_two.sections.first,
          user: enrollment_2.user,
          updated_at: Time.zone.today - 15
        )
      end
    end

    it 'returns the count of students by school and program whose last submission was more than 10 days ago' do
      expect(presenter.count_idle_students_by_district_and_program(district.id, program.id)).to be 5
    end
  end

  describe '#count_idle_students_by_section' do
    it 'returns the count of students by section whose last submission was more than 10 days ago' do
      expect(presenter.count_idle_students_by_section(course.sections.first)).to be 5
    end
  end

  describe '#count_pending_share_requests' do
    it 'returns the count of IGC share requests by program' do
      expect(presenter.count_pending_share_requests(school.id, program.id)).to be 5
    end
  end

  describe '#total_assignments_count' do
    it 'returns the count of both regular and external assignments for the section' do
      gb_section = create(:gb_section, id: course.sections.first.id)
      gb_lesson = create(:gb_lesson, id: lesson.id)

      5.times do |n|
        FactoryBot.create(:assignment,
                           section: course.sections.first,
                           due_date: Time.zone.today + (n % 3))
      end


      5.times do |n|
        FactoryBot.create(:gb_external_assignment,
                           lesson: gb_lesson,
                           section: gb_section,
                           day_id: Time.zone.today + (2 + n % 3))
      end

      expect(presenter.total_assignments_count(course.sections.first)).to be(10)
    end
  end

  describe '#due_dates_count' do
    it 'returns the count of due dates for the section' do
      gb_section = create(:gb_section, id: course.sections.first.id)
      gb_lesson = create(:gb_lesson, id: lesson.id)

      5.times do |n|
        FactoryBot.create(:assignment,
                           section: course.sections.first,
                           due_date: Time.zone.today + (n % 3))
      end


      5.times do |n|
        FactoryBot.create(:gb_external_assignment,
                           lesson: gb_lesson,
                           section: gb_section,
                           day_id: Time.zone.today + (2 + n % 3))
      end

      expect(presenter.due_dates_count(course.sections.first)).to be(5)
    end
  end

  describe '#duration_in_weeks_and_days' do
    describe 'returns the duration in weeks and days format' do
      it 'when the duration is weeks exact returns only weeks format' do
        beginning_of_next_month = (Time.zone.now.end_of_month + 1.day)
        course = create(
          :course,
          start_date: beginning_of_next_month,
          end_date: beginning_of_next_month + (14.days)
        )
        expect(presenter.duration_in_weeks_and_days(course)).to eq({ weeks: 2, days: 0 })
      end

      it 'when the duration is not weeks exact returns weeks days format' do
        beginning_of_next_month = (Time.zone.now.end_of_month + 1.day)
        course = create(
          :course,
          start_date: beginning_of_next_month,
          end_date: beginning_of_next_month + 16.days
        )
        expect(presenter.duration_in_weeks_and_days(course)).to eq({ weeks: 2, days: 2 })
      end
    end
  end

  describe '#students_by_section' do
    it 'returns an array of user ids for enrolled students with a state of "enrolled"' do
      presenter.assign_school(school.id)
      result = Enrollment.where(section_id: course.sections.first.id, state: 'enrolled').pluck(:user_id)
      expect(presenter.students_by_section(course.sections.first)).to eql(result)
    end
  end

  describe '#avg_time_spent_per_student' do
    it 'returns average time spent per student per section' do
      section = course.sections.first
      cumulative = { cumulative: { time_spent: rand(5..10) } }
      params = { level: 'week',
                 summary_level: 'section',
                 summary_level_id: section.id,
                 section_id: section.id }
      analytics_presenter = instance_double('GradebookEngine::AnalyticsPresenter', overview_stats: cumulative)
      expect(GradebookEngine::AnalyticsPresenter).to receive(:new).with(params).and_return(analytics_presenter)
      result = presenter.avg_time_spent_per_student(section.id)
      expect(result).to eq cumulative[:cumulative][:time_spent]
    end
  end

  describe '#instructor_full_name' do
    it 'returns the full name of an instructor' do
      expect(presenter.instructor_full_name(course.owner.id)).to eql('Jane Doe')
    end
  end

  describe '#strands' do
    let(:strand_1) { create(:toc_entry) }
    let(:substrand) { create(:toc_entry) }

    before do
      strand_1.children = [substrand]
      strand_1.background_color = '#999'
      display_lesson = double(:display_lesson, strands: [strand_1])
      allow(presenter).to receive(:display_lesson).and_return(display_lesson)
    end

    it 'return lesson strands if toc_entry is nil' do
      expect(presenter.strands).to eq([strand_1])
    end

    it 'return strands from assessment' do
      expect(presenter.display_lesson).to receive(:strands).with(true)
      presenter.strands
    end

    it 'return substrands with same parent background if toc_entry is defined' do
      expected_substrand = substrand
      expected_substrand.background_color = strand_1.background_color
      expect(presenter.strands(strand_1)).to eq([expected_substrand])
    end
  end

  describe '#activities_by_toc_entry' do
    it 'returns an empty array when passed toc_entry does not match to any activity' do
      new_toc_entry = TocEntry.new

      # result should be the same regardless if the activity is shared or not
      expect(presenter.activities_by_toc_entry(true, new_toc_entry)).to eq([])
      expect(presenter.activities_by_toc_entry(false, new_toc_entry)).to eq([])
    end

    it 'returns an array of activities which belongs to that toc_entry' do
      expect(presenter.activities_by_toc_entry(false, strand)).to eq([SharedLibraryActivity.where(is_shared: false).first])
      expect(presenter.activities_by_toc_entry(true, strand)).to eq([SharedLibraryActivity.where(is_shared: true).first])
    end
  end

  # TODO: need specs for
  # course_owner_options
  # section_data

  describe '#course_template_options' do
    it 'returns only templates for given program and school with future end dates' do
      # course for program and school: should not be included
      create(:course, program: program, school: school)

      # template for school, other program: should not be included
      create(:course_template, program: other_program, school: school)

      # template for program, other school: should not be included
      create(:course_template, program: program, school: other_school)

      # template with past end date: should not be included
      create(:course_template, end_date: Time.zone.today - 1, allow_past_end_date: true, program:, school:)

      # template with end date = today: should not be included
      create(:course_template, end_date: Time.zone.today, program: program, school: school)

      # template with end date = tomorrow: should be included
      template_end_date_tomorrow = create(:course_template,
                                          end_date: Time.zone.today + 1,
                                          program: program,
                                          school: school)

      expect(presenter.course_template_options(program)).to eq(
        [[template.name, template.id],
         [template_end_date_tomorrow.name, template_end_date_tomorrow.id]]
      )
    end
  end

  describe '#section_template_options' do
    let(:course_from_template) do
      create(:course, source_template_id: template.id)
    end

    let(:course_not_from_template) do
      create(:course)
    end

    it "returns an array of section template name/id pairs for the course's course template" do
      section_template = template.sections.first

      expect(presenter.section_template_options(course_from_template)).to eq(
        [[section_template.name, section_template.id]]
      )
    end

    it 'returns an empty array if there is no template associated with the course' do
      expect(presenter.section_template_options(course_not_from_template)).to eq([])
    end

    it 'returns an empty array if the template associated with the course has been deleted' do
      template.delete
      expect(presenter.section_template_options(course_from_template)).to eq([])
    end

    it 'returns only shared section templates associated with the course' do
      section_template_shared_one = template.sections.first
      section_template_shared_two = create(:section, course: template)
      section_template_shared_two.update(shared: true)
      section_template_unshared = create(:section, course: template)
      expect(presenter.section_template_options(course_from_template)).to eq(
        [[section_template_shared_one.name, section_template_shared_one.id],
         [section_template_shared_two.name, section_template_shared_two.id]]
      )
    end
  end

  describe '#csv_filename' do
    it 'returns a filename with the school and program names' do
      filename = "#{school.name.downcase.gsub(/\s/, '-')}-#{program.title.downcase.gsub(/\s/, '-')}-metrics.csv"
      expect(presenter.csv_filename).to eq(filename)
    end
  end

  describe '#admin_program_options' do
    it 'returns a list of unique program options with their details' do
      result = presenter.admin_program_options

      expect(result).to match_array([
        { program_id: program.id, school_id: school.id, program_title: program.title },
        { program_id: other_program.id, school_id: school.id, program_title: other_program.title }
      ])
    end

    it 'returns an empty list if there are no accessible programs' do
      allow(institution_admin).to receive(:admin_school_programs).and_return([])

      result = presenter.admin_program_options

      expect(result).to eq([])
    end
  end

  describe '#courses' do
    context 'when the year is the current year' do

      it 'returns current and upcoming courses' do
        expect(presenter.courses).to match_array([course, course_2, course_next_year])
      end
    end

    context 'when the year is the previous year' do
      let(:year) { Time.zone.today.year - 1 }

      it 'returns courses for the given year' do
        expect(presenter.courses).to match_array([course_previous_year_1, course_previous_year_2])
      end
    end
  end

  describe '#open_courses' do
    it 'returns courses that have already ended' do
      expect(presenter.open_courses).to match_array([course, course_2, course_next_year])
    end
  end

  describe '#closed_courses' do
    let!(:closed_course_for_closed_courses) do
      create(
        :course_with_section,
        owner: institution_admin,
        school:,
        end_date: Time.zone.today - 1.day,
        allow_past_end_date: true,
        program_id: program.id,
        is_enterprise: true,
        enterprise_section: create(:enterprise_section, instructor: institution_admin)
      )
    end

    it 'returns courses that have yet to end' do
      expect(presenter.closed_courses).to match_array([closed_course_for_closed_courses])
    end
  end

  describe '#past_years_list' do
    let(:current_year) { Time.zone.today.year }
    let(:expected_result) { [current_year, current_year - 1, current_year - 2] }

    it { expect(presenter.past_years_list).to eq(expected_result) }
  end

  describe '#current_year_selected?' do
    context 'when the year is the current year' do
      it { expect(presenter.current_year_selected?).to be true }
    end

    context 'when the year is a previous year' do
      let(:year) { Time.zone.today.year - 1 }

      it { expect(presenter.current_year_selected?).to be false }
    end
  end

  describe '#selected_year_label' do
    context 'when the year is the current year' do
      it { expect(presenter.selected_year_label).to eq('Current') }
    end

    context 'when the year is a previous year' do
      let(:year) { Time.zone.today.year - 1 }

      it { expect(presenter.selected_year_label).to eq(year) }
    end
  end

  describe '#current_past_select_options' do
    let(:current_year) { Time.zone.today.year }
    let(:expected_result) do
      [
        [current_year, 'Current', program.id, school.id],
        [current_year - 1, current_year - 1, program.id, school.id],
        [current_year - 2, current_year - 2, program.id, school.id]
      ]
    end

    it 'returns expected block definition' do
      result = presenter.current_past_select_options do |year, year_label, program_id, school_id|
        [year, year_label, program_id, school_id]
      end

      expect(result).to eq(expected_result)
    end
  end

  describe '#timezones_for_select' do
    it 'returns an array of timezones including US timezones' do
      timezone_options = presenter.timezone_options_for_select.pluck(1)
      us_timezones = ActiveSupport::TimeZone.us_zones.map(&:name)

      expect(timezone_options).to include(*us_timezones)
    end

    it 'presents every option as an array of two elements' do
      timezone_option = presenter.timezone_options_for_select.last

      expect(timezone_option.length).to eq(2)
    end

    it 'contains the GMT offset and the timezone element as the first element of the option' do
      tz_offset_and_name = presenter.timezone_options_for_select.last[0]

      expect(tz_offset_and_name).to eq('(GMT+13:00) Tokelau Is.')
    end

    it 'contains the timezone name as the second element of the option' do
      tz_name = presenter.timezone_options_for_select.last[1]

      expect(tz_name).to eq('Tokelau Is.')
    end
  end

  describe '#school_time_zone' do
    context 'when school has a time_zone' do
      it 'returns the school time_zone' do
        expect(presenter.school_time_zone).to eq('Pacific Time (US & Canada)')
      end
    end
  end

  describe '#parse_due_time' do
    it 'converts due hour to a hash containing hour, minutes and ampm' do
      due_time_hash = presenter.parse_due_time(Time.zone.parse('11:00:00'))

      expect(due_time_hash).to eq({ hours: 11, minutes: '00', ampm: 'AM' })
    end

    it 'transforms time from 24Hr format to AM/PM' do
      due_time_hash = presenter.parse_due_time(Time.zone.parse('23:59:00'))

      expect(due_time_hash).to eq({ hours: 11, minutes: '59', ampm: 'PM' })
    end
  end

  describe '#additional_instructor_options' do
    let(:prospective_instructor_1) { create(:instructor) }
    let(:prospective_instructor_2) { create(:instructor, email: '') }

    before do
      allow(school).to receive(:active_instructors_with_program_access)
                   .with(program)
                   .and_return([prospective_instructor_1,
                                prospective_instructor_2,
                                course.owner])
      allow(presenter).to receive(:school).and_return(school)
    end

    it 'includes instructors in school, other than owner, with access to program' do
      expect(presenter.additional_instructor_options(course)).to eq(
        [{ id: prospective_instructor_1.id,
           full_name: prospective_instructor_1.full_name,
           email: prospective_instructor_1.email },
         { id: prospective_instructor_2.id,
           full_name: prospective_instructor_2.full_name,
           email: '' }]
      )
    end
  end
end
