require 'timecop'
require 'uri'

describe InstructorDashboardPresenter do
  let(:instructor) { create(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:school) { create(:school) }
  let(:course) { create(:course, program: program, school: school, owner: instructor) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:other_section) { build_stubbed(:section) }
  let(:current_focus) do
    instance_double(Focus, course: course, sections: [], course_open?: true)
  end
  let(:clever_warning_class) { described_class::CleverSchoolWarning }
  let(:section_data_class) { described_class::SectionData }
  let(:gradebook_api) { GradebookEngine::GradebookAPI }
  let(:clever_endpoint) { "/api/clever/section_link/search" }

  let(:presenter) do
    described_class.new(instructor, current_focus, program_id: program.id)
  end

  before do
    allow(Program).to receive(:find).and_return(program)
    allow(instructor).to receive(:editable_courses_by_program)
      .and_return([course])
    allow(gradebook_api).to receive(:pending_grading_results)
      .and_return([])
    allow(gradebook_api).to receive(:find_submitted).and_return([])
  end

  describe '#sections_data' do
    let(:section_data) { instance_double(section_data_class) }

    before do
      allow(section_data_class).to receive(:new)
        .and_return(section_data)
      allow(course).to receive(:sections_by_instructor)
        .and_return([section])
    end

    context 'when the instructor has no sections in the focused course' do
      it 'creates a SectionData instance with an empty array of scores' do
        allow(course).to receive(:sections_by_instructor)
          .and_return([])

        presenter.sections_data(section)
        expect(section_data_class).to have_received(:new)
          .with(section, [])
      end
    end

    context 'when there are no students in focus,' do
      it 'creates a SectionData instance with an empty array of scores' do
        presenter.sections_data(section)
        expect(section_data_class).to have_received(:new)
          .with(section, [])
      end
    end

    context 'when the instructor has sections in the focused course and ' \
            'there are students in focus, ' do
      let(:student) { create(:student) }

      before do
        create(:active_enrollment, section: section, user: student)
      end

      it 'queries the gradebook api for pending scores' do
        presenter.sections_data(section)

        expect(gradebook_api).to have_received(:pending_grading_results)
          .with(section_ids: [section.id], user_ids: [student.id])
      end

      context 'when there are no scores for the specified section,' do
        it 'creates a SectionData instance with an empty array of scores' do
          presenter.sections_data(section)

          expect(section_data_class).to have_received(:new)
            .with(section, [])
        end
      end

      context 'when there are scores for the specified section' do
        it 'returns a SectionData instance instantiated with the specified ' \
           'section and the scores for that section' do
          score = instance_double(
            GradebookEngine::ScoreAction, section_id: section.id
          )
          other_section_score = instance_double(
            GradebookEngine::ScoreAction, section_id: other_section.id
          )
          allow(gradebook_api).to receive(:pending_grading_results)
            .and_return([score, other_section_score])

          presenter.sections_data(section)

          expect(section_data_class).to have_received(:new)
            .with(section, [score])
        end
      end
    end
  end

  describe '#instructor_schools' do
    let(:old_school) { build_stubbed(:school) }
    let(:other_program) { build_stubbed(:program) }
    let(:other_program_school) { build_stubbed(:school) }
    let(:other_program_course) do
      build_stubbed(
        :course,
        owner: instructor,
        program: other_program,
        school: other_program_school
      )
    end
    let(:old_school_course) do
      build_stubbed(
        :course,
        owner: instructor,
        program: program,
        school: old_school
      )
    end

    before do
      allow(instructor).to receive(:schools).and_return([school])
      allow(instructor).to receive(:editable_courses_by_program)
        .with(program).and_return([course, old_school_course])
      allow(instructor).to receive(:editable_courses_by_program)
        .with(other_program).and_return([other_program_course])
    end

    it "includes all the instructor's current schools" do
      expect(presenter.instructor_schools).to include(school)
    end

    it 'includes schools the instructor has left but in which they still ' \
       'have an active course for the current program' do
      expect(presenter.instructor_schools).to include(old_school)
    end

    it 'does not includes schools the instructor has left but in which they ' \
       'still have an active course for a different program' do
      expect(presenter.instructor_schools).not_to include(other_program_school)
    end

    it 'does not return duplicate schools' do
      allow(instructor).to receive(:schools).and_return([school, school])
      expect(presenter.instructor_schools.count(school)).to eq 1
    end
  end

  describe '#enrollment_warning' do
    let(:license_with_seats) do
      instance_double(Maestro::SiteLicense, hard_cap_reached: false, response: true)
    end
    let(:license_with_no_seats) do
      instance_double(Maestro::SiteLicense, hard_cap_reached: true, response: true)
    end
    let(:no_license) { instance_double(Maestro::SiteLicense, response: nil) }

    before do
      allow(instructor).to receive(:schools).and_return([school])
    end

    it 'returns a warning message with school names when the site license is exhausted' do
      allow(Maestro::SiteLicense).to receive(:find_by_program_and_school_or_district)
        .and_return(license_with_no_seats)

      expect(presenter.enrollment_warning.strip_tags).to match(
        %r{Your site license has no available seats.*#{school.name}}
      )
    end

    it 'returns nil when the site license has seats available' do
      allow(Maestro::SiteLicense).to receive(:find_by_program_and_school_or_district)
        .and_return(license_with_seats)

      expect(presenter.enrollment_warning).to be_nil
    end

    it 'returns nil when there is no site lisense' do
      allow(Maestro::SiteLicense).to receive(:find_by_program_and_school_or_district)
        .and_return(no_license)

      expect(presenter.enrollment_warning).to be_nil
    end
  end

  describe '#open_courses_by_program' do
    it 'returns open courses_by_program' do
      allow(instructor).to receive(:open_courses_for_program).and_return([])
      presenter.open_courses_by_program
      expect(instructor).to have_received(:open_courses_for_program)
        .with(program)
    end
  end

  describe '#closed_courses_by_program' do
    it 'returns closed courses by program' do
      allow(instructor).to receive(:closed_courses_for_program).and_return([])
      presenter.closed_courses_by_program
      expect(instructor).to have_received(:closed_courses_for_program)
        .with(program)
    end
  end

  describe 'open_courses_by_school' do
    it 'returns open courses by school and program' do
      allow(instructor).to receive(:open_courses_by_school_and_program)
        .and_return([])
      presenter.open_courses_by_school(school)
      expect(instructor).to have_received(:open_courses_by_school_and_program)
        .with(school, program)
    end
  end

  describe '#closed_courses_by_school' do
    it 'returns closed courses by school and program' do
      allow(instructor).to receive(:closed_courses_by_school_and_program)
        .and_return([])
      presenter.closed_courses_by_school(school)
      expect(instructor).to have_received(:closed_courses_by_school_and_program)
        .with(school, program)
    end
  end

  describe '#editable_courses_and_sections_by_school' do
    it 'returns a hash with course keys and section values' do
      allow(instructor).to receive(:courses_and_sections_for_dashboard)
        .and_return([])
      presenter.editable_courses_and_sections_by_school(school)
      expect(instructor).to have_received(:courses_and_sections_for_dashboard)
        .with(school, program)
    end
  end

  describe '#assignment_wizard_enabled?' do
    let(:activity) { build_stubbed(:activity) }
    let(:category) { build_stubbed(:category) }
    let(:course) { create(:course, program: program, school: school) }
    let(:gradebook_api_class) { GradebookEngine::GradebookAPI }
    let(:section) { create(:section, course: course, instructor: instructor) }

    def create_assignment(target_section)
      create(
        :assignment,
        assignable: activity,
        category: category,
        section: target_section
      )
    end

    context 'with a non-vista-online-learning program,' do
      before do
        allow(section).to receive(:program).and_return(program)
        allow(program).to receive(:vista_online_learning?).and_return(false)
      end

      it 'returns false when there are no assignments in any section' do
        expect(presenter).not_to be_assignment_wizard_enabled(course)
      end

      it 'returns false when there are assignments only in sections the ' \
         'instructor has in other programs' do
        other_program = build_stubbed(:program)
        other_program_course = create(
          :course,
          program: other_program,
          school: school
        )
        other_program_section = create(
          :section,
          course: other_program_course
        )
        create_assignment(other_program_section)
        expect(presenter).not_to be_assignment_wizard_enabled(course)
      end

      it 'returns false when there are assignments only in sections the ' \
         'instructor has at other schools' do
        other_school = build_stubbed(:school)
        other_school_course = create(
          :course,
          program: program,
          school: other_school
        )
        other_school_section = create(
          :section,
          course: other_school_course
        )
        create_assignment(other_school_section)
        expect(presenter).not_to be_assignment_wizard_enabled(course)
      end

      it 'returns true if there are assignments in sections the instructor' \
         'has at the same school and in the same program' do
        create_assignment(section)
        expect(presenter).to be_assignment_wizard_enabled(course)
      end
    end

    it 'returns true for a vista-online-learning program' do
      allow(program).to receive(:vista_online_learning?).and_return(true)
      expect(presenter).to be_assignment_wizard_enabled(course)
    end

    it 'returns false when there are no external assignments in any section' do
      allow(gradebook_api_class).to receive(:has_external_assignments?).and_return(false)
      expect(presenter).not_to be_assignment_wizard_enabled(course)
    end

    it 'returns true if there is at least one external assignments in sections the instructor' do
      allow(gradebook_api_class).to receive(:has_external_assignments?).and_return(true)
      expect(presenter).to be_assignment_wizard_enabled(course)
    end
  end

  describe '#first_course_as_focus' do
    it "returns a string containing the id of the first of the instructor's " \
       'open courses when the instructor has open courses' do
      other_course = build_stubbed(:course)
      allow(instructor).to receive(:open_courses_for_program)
        .and_return([course, other_course])
      expect(presenter.first_course_as_focus).to eq("Course,#{course.id}")
    end

    it 'returns nil when the instructor has no open courses' do
      allow(instructor).to receive(:open_courses_for_program)
        .and_return([])
      expect(presenter.first_course_as_focus).to be_nil
    end
  end

  describe '#student_access_problem_count' do
    it 'returns 0 when no students in the specified section have access problems' do
      allow(section).to receive(:enrollments_without_sufficient_access)
        .and_return([])
      expect(presenter.student_access_problem_count(section)).to be 0
    end

    it 'returns the number of students in the specified section who have ' \
       'access problems' do
      student = create(:student)
      enrollment_with_problem = build_stubbed(
        :enrollment,
        section_id: section.id,
        user_id: student.id
      )
      allow(section).to receive(:enrollments_without_sufficient_access)
        .and_return([enrollment_with_problem])
      expect(presenter.student_access_problem_count(section)).to be 1
    end
  end

  describe '#first_five_active_students' do
    context 'with a mix of active students with and without access problems,' do
      let(:no_access_problem_student) { create(:student) }
      let(:access_problem_student) { create(:student) }
      let(:enrollment_with_problem) do
        build_stubbed(
          :enrollment,
          section_id: section.id,
          user_id: access_problem_student.id
        )
      end

      before do
        allow(section).to receive(:enrollments_without_sufficient_access)
          .and_return([enrollment_with_problem])
        allow(section).to receive(:first_five_active_students)
          .and_return([no_access_problem_student, access_problem_student])
      end

      it 'returns any students with access problems first' do
        expect(presenter.first_five_active_students(section)).to eq(
          [access_problem_student, no_access_problem_student]
        )
      end

      it 'extends students with a StudentDecorator module' do
        expect(presenter.first_five_active_students(section)).to all(
          be_a_kind_of(described_class::StudentDecorator)
        )
      end

      it 'stores the information about where the student has access problems ' \
         'in an accessor provided by the StudentDecorator module' do
        results = presenter.first_five_active_students(section)
        expect(results.map(&:access_problems?)).to eq([true, false])
      end
    end

    it 'sorts students with access problems by last name' do
      student_1 = create(:student, last_name: 'B', first_name: 'A')
      student_2 = create(:student, last_name: 'A', first_name: 'B')
      student_3 = create(:student, last_name: 'A', first_name: 'A')
      enrollment_1 = build_stubbed(:enrollment, section: section, user: student_1)
      enrollment_2 = build_stubbed(:enrollment, section: section, user: student_2)
      enrollment_3 = build_stubbed(:enrollment, section: section, user: student_3)

      allow(section).to receive(:enrollments_without_sufficient_access)
        .and_return([enrollment_1, enrollment_2, enrollment_3])
      allow(section).to receive(:first_five_active_students)
        .and_return([])

      expect(presenter.first_five_active_students(section)).to eq(
        [student_3, student_2, student_1]
      )
    end

    context 'when there are fewer than 5 students with access problems' do
      it 'returns enough students without access problems to get 5 students' do
        students = Array.new(6) { create(:student) }
        enrollment = build_stubbed(
          :enrollment,
          section_id: section.id,
          user_id: students.first.id
        )
        allow(section).to receive(:enrollments_without_sufficient_access)
          .and_return([enrollment])
        allow(section).to receive(:first_five_active_students)
          .and_return(students[1..5])

        expect(presenter.first_five_active_students(section)).to eq(students[0..4])
      end

      it 'ensures no student appears twice' do
        student = create(:student)
        enrollment = build_stubbed(
          :enrollment,
          section_id: section.id,
          user_id: student.id
        )
        allow(section).to receive(:enrollments_without_sufficient_access)
          .and_return([enrollment])
        allow(section).to receive(:first_five_active_students)
          .and_return([student])

        expect(presenter.first_five_active_students(section)).to eq([student])
      end
    end
  end

  describe 'methods that forward to SectionData instances' do
    let(:section_data) { instance_double(section_data_class) }
    let(:other_section_data) { instance_double(section_data_class) }

    before do
      allow(course).to receive(:sections_by_instructor).and_return([])

      allow(section_data_class).to receive(:new)
        .with(section, anything)
        .and_return(section_data)
      allow(section_data_class).to receive(:new)
        .with(other_section, anything)
        .and_return(other_section_data)
      # Ensure other section data instance is in sections_data hash
      presenter.sections_data(other_section)
    end

    describe '#activity_count_by_section' do
      it 'returns the activity count from the SectionData instance for the ' \
         'specified section' do
        allow(section_data).to receive(:activity_count).and_return(9)
        allow(other_section_data).to receive(:activity_count).and_return(8)

        expect(presenter.activity_count_by_section(section)).to eq(9)
      end
    end

    describe '#score_count_by_section_and_activity_id' do
      it 'returns score course by activity from section data' do
        activity = build_stubbed(:activity)
        other_activity = build_stubbed(:activity)

        allow(section_data).to receive(:score_count_by_activity_id)
          .with(activity.id).and_return(7)
        allow(section_data).to receive(:score_count_by_activity_id)
          .with(other_activity.id).and_return(6)
        allow(other_section_data).to receive(:score_count_by_activity_id)
          .with(activity.id).and_return(5)

        result = presenter.score_count_by_section_and_activity_id(section, activity.id)
        expect(result).to eq(7)
      end
    end

    describe '#first_three_activity_scores' do
      it 'returns the first three activities for a section' do
        allow(section_data).to receive(:unique_activity_scores)
          .and_return([1, 2, 3, 4, 5])
        allow(other_section_data).to receive(:unique_activity_scores)
          .and_return([6, 7, 8, 9, 10])

        result = presenter.first_three_activity_scores(section)
        expect(result).to eq([1, 2, 3])
      end
    end
  end

  describe 'methods that make use of StudentAssignmentMap data' do
    let(:activity) { create(:activity) }
    let(:category) { build_stubbed(:category) }
    let(:student) { create(:student) }
    let(:section) { create(:section, course: course, instructor: instructor) }

    def create_assignment(target_activity)
      create(
        :assignment,
        assignable: target_activity,
        due_date: Date.tomorrow,
        category: category,
        section: section
      )
    end

    def create_score(student, activity_id)
      GradebookEngine::ScoreAction.new(
        activity_id: activity_id,
        user_id: student.id
      )
    end

    before do
      allow(course).to receive(:sections_by_instructor).and_return([section])
      create(:active_enrollment, section: section, user: student)
    end

    describe '#unfinished_upcoming_assignments_by_section' do
      it 'returns a count of students who have not submitted any of the next ' \
         "day's assignments" do
        allow(gradebook_api).to receive(:find_submitted).and_return([])
        create_assignment(activity)
        expect(
          presenter.unfinished_upcoming_assignments_by_section(section)
        ).to eq(1)
      end

      it "returns zero if all students have submitted the next day's assignments" do
        create_assignment(activity)
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.unfinished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end

      it 'returns zero if there are no upcoming assignments' do
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.unfinished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end
    end

    describe '#finished_upcoming_assignments_by_section' do
      it 'returns a count of students who submitted all of the next ' \
         "day's assignments" do
        create_assignment(activity)
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.finished_upcoming_assignments_by_section(section)
        ).to eq(1)
      end

      it "returns zero if no students have submitted the next day's assignments" do
        create_assignment(activity)
        allow(gradebook_api).to receive(:find_submitted).and_return([])
        expect(
          presenter.finished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end

      it 'returns zero if there are no upcoming assignments' do
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.finished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end
    end

    describe '#partially_finished_upcoming_assignments_by_section' do
      let(:other_activity) { create(:activity) }

      it 'returns a count of students who have completed some of the next ' \
         "day's assigments" do
        create_assignment(activity)
        create_assignment(other_activity)
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.partially_finished_upcoming_assignments_by_section(section)
        ).to eq(1)
      end

      it 'returns zero if all students have submitted all of the next ' \
         "day's assignments" do
        create_assignment(activity)
        create_assignment(other_activity)
        allow(gradebook_api).to receive(:find_submitted).and_return(
          [
            create_score(student, activity.id),
            create_score(student, other_activity.id)
          ]
        )
        expect(
          presenter.partially_finished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end

      it 'returns zero if no student has submitted any of the next ' \
         "day's assignments" do
        create_assignment(activity)
        allow(gradebook_api).to receive(:find_submitted).and_return([])
        expect(
          presenter.partially_finished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end

      it 'returns zero if there are no upcoming assignments' do
        score = create_score(student, activity.id)
        allow(gradebook_api).to receive(:find_submitted).and_return([score])
        expect(
          presenter.partially_finished_upcoming_assignments_by_section(section)
        ).to eq(0)
      end
    end
  end

  describe '#clever_warning?' do
    let(:warning) { instance_double(clever_warning_class, required?: true) }

    before do
      allow(instructor).to receive(:schools).and_return([school])
      allow(clever_warning_class).to receive(:new).and_return(warning)
    end

    it "creates a CleverSchoolWarning instance, specifying the presenter's " \
       'instructor and their schools' do
      presenter.clever_warning?
      expect(clever_warning_class).to have_received(:new)
        .with(instructor, [school])
    end

    it 'returns true if the warning is required' do
      allow(warning).to receive(:required?).and_return(true)
      expect(presenter.clever_warning?).to be true
    end

    it 'returns false if the warning is not required' do
      allow(warning).to receive(:required?).and_return(false)
      expect(presenter.clever_warning?).to be false
    end
  end

  describe '#clever_warning_message' do
    let(:warning) { instance_double(clever_warning_class, message: 'blah') }

    before do
      allow(instructor).to receive(:schools).and_return([school])
      allow(clever_warning_class).to receive(:new).and_return(warning)
    end

    it "creates a CleverSchoolWarning instance, specifying the presenter's " \
       'instructor and their schools' do
      presenter.clever_warning_message
      expect(clever_warning_class).to have_received(:new)
        .with(instructor, [school])
    end

    it 'returns the message from the warning' do
      message = 'some message'
      allow(warning).to receive(:message).and_return(message)
      expect(presenter.clever_warning_message).to eq(message)
    end
  end

  describe '#course_creation_path' do
    it 'returns the one roster instructor courses index path '\
       'when the instructor is a rostering user' do
      allow(instructor).to receive(:one_roster_rostering?).and_return(true)
      expected_path = Rails.application.routes.url_helpers
                           .one_roster_instructor_courses_path(program)
      expect(presenter.course_creation_path(school)).to eq expected_path
    end

    it 'returns the course new path for the given school '\
       'when the instructor is a regular user' do
      expected_path = Rails.application.routes.url_helpers
                           .instructor_new_course_path(program, school)
      expect(presenter.course_creation_path(school)).to eq expected_path
    end
  end

  # Specs for CleverSectionLinks module,
  # which fetches data from a Clever endpoint via UA.
  describe '#clever_section_links' do
    # Custom matcher to check for expected get request query params,
    #  independent of the order in which they appear.
    RSpec::Matchers.define :expected_endpoint_query do |expected_query_params|
      match do |actual|
        actual_uri = URI(actual)
        actual_query = actual_uri.query

        return false unless actual_uri.to_s.start_with?(clever_endpoint)

        # Split query up by params and split into an array.
        # example:
        # [
        #  "section_guids[]=811e0f3d-aeb8-4e90-a4d3-d5a060f8ff3c",
        #  "section_guids[]=2a913e1c-eb41-4474-a488-b1250aa47de8"
        # ]
        param_parts = actual_query.to_s.split('&')

        # Compare via array intersection, which is item order agnostic
        param_parts & expected_query_params == param_parts
      end
    end

    context 'with a non clever instructor' do
      let(:non_clever_instructor) do
        create(:instructor)
      end

      let(:focus) do
        instance_double(Focus)
      end

      let(:non_clever_instructor_presenter) do
        described_class.new(non_clever_instructor, focus, program_id: program.id)
      end

      it 'returns section defaults' do
        course = create(:course)
        section = create(:section, course:, instructor: non_clever_instructor)
        allow(focus).to receive(:course).and_return(course)
        expected = { section.guid => { 'linked' => false } }
        expect(non_clever_instructor_presenter.clever_section_links).to eq expected
      end
    end

    context 'with a clever instructor' do
      let(:clever_instructor) { create(:clever_instructor) }
      let(:rostering_school) { create(:clever_rostering_school) }

      let(:rostering_course) do
        create(:course, program: program, school: rostering_school, owner: clever_instructor)
      end

      context 'with a focused course with a single rostering section' do
        let(:rostering_section) do
          create(:section, course: rostering_course, instructor: clever_instructor)
        end

        let(:focus) do
          instance_double(Focus, course: rostering_course)
        end

        let(:clever_instructor_presenter) do
          described_class.new(clever_instructor, focus, program_id: program.id)
        end

        it 'queries UA, sending the section guid with the parameters' do
          ua_payload =
            {
              rostering_section.guid => {
                'error' => false,
                'linked' => false
              }
            }
          connection = instance_double(Faraday::Connection)
          ua_response = instance_double(Faraday::Response)

          expected_request_param = "section_guids[]=#{rostering_section.guid}"
          allow(ua_response).to receive(:body).and_return(ua_payload)
          allow(ConnectionHandler).to(
            receive(:connection)
              .with(
                basic_auth: [
                  Rails.configuration.ua_api_username,
                  Rails.configuration.ua_api_password
                ],
                request_type: :json,
                uri: UA_URL
              )
              .and_return(connection)
          )

          expect(connection).to(
            receive(:get).with(
              expected_endpoint_query(
                [expected_request_param]
              )
            ).and_return(ua_response)
          )
          clever_instructor_presenter.clever_section_links
        end
      end

      context 'with a focused course with multiple rostering sections' do
        let(:rostering_section_a) do
          create(:section, course: rostering_course, instructor: clever_instructor)
        end
        let(:rostering_section_b) do
          create(:section, course: rostering_course, instructor: clever_instructor)
        end

        let(:focus) do
          instance_double(Focus, course: rostering_course, course_open?: true)
        end

        let(:multi_section_instructor_presenter) do
          described_class.new(clever_instructor, focus, program_id: program.id)
        end

        it 'queries UA, sending all focused section guids as the parameters' do
          ua_payload =
            {
              rostering_section_a.guid => {
                'error' => false,
                'linked' => false
              },
              rostering_section_b.guid => {
                'error' => false,
                'linked' => false
              }
            }
          connection = instance_double(Faraday::Connection)
          ua_response = instance_double(Faraday::Response)

          # These query params may appear in any order, the order is based
          # on the original db query for instructor courses via the Focus.
          expected_param_a = "section_guids[]=#{rostering_section_a.guid}"
          expected_param_b = "section_guids[]=#{rostering_section_b.guid}"
          allow(ua_response).to receive(:body).and_return(ua_payload)
          allow(ConnectionHandler).to(
            receive(:connection)
              .with(
                basic_auth: [
                  Rails.configuration.ua_api_username,
                  Rails.configuration.ua_api_password
                ],
                request_type: :json,
                uri: UA_URL
              )
              .and_return(connection)
          )

          expect(connection).to(
            receive(:get).with(
              expected_endpoint_query(
                [expected_param_a, expected_param_b]
              )
            ).and_return(ua_response)
          )

          multi_section_instructor_presenter.clever_section_links
        end
      end
    end
  end

  describe '#clever_section_for' do
    let(:clever_section) { build_stubbed(:section) }
    let(:non_clever_section) { build_stubbed(:section) }

    let(:clever_section_links_hash) do
      {
        clever_section.guid => {
          'clever_section_name' => 'expected clever name',
          'linked' => true
        },
        non_clever_section.guid => {
          'linked' => false
        }
      }
    end

    let(:presenter) do
      described_class.new(build_stubbed(:instructor), instance_double(Focus),
                          program_id: program.id)
    end

    before do
      allow(presenter).to receive(:clever_section_links).and_return(clever_section_links_hash)
    end

    context 'when the passed section guid is present in clever_section_links' do
      it 'returns the clever_section_name if it has been returned in the results' do
        expect(presenter.clever_section_for(clever_section)).to eq('expected clever name')
      end

      it 'returns nil if clever_section_name has not been returned in the results' do
        expect(presenter.clever_section_for(non_clever_section)).to be_nil
      end
    end

    context 'when the passed section guid is not present in clever_section_links' do
      it 'returns nil' do
        expect(presenter.clever_section_for(build_stubbed(:section))).to be_nil
      end
    end
  end

  describe '#clever_section_linked?' do
    let(:clever_section) { build_stubbed(:section) }
    let(:non_clever_section) { build_stubbed(:section) }

    let(:clever_section_links_hash) do
      {
        clever_section.guid => {
          'linked' => true
        },
        non_clever_section.guid => {
          'linked' => false
        }
      }
    end

    before do
      allow(presenter).to receive(:clever_section_links).and_return(clever_section_links_hash)
    end

    context 'when the passed section guid is present in clever_section_links' do
      it 'returns true when the linked key has been set to true' do
        expect(presenter).to be_clever_section_linked(clever_section)
      end

      it 'returns true when the linked key has been set to false' do
        expect(presenter).not_to be_clever_section_linked(non_clever_section)
      end
    end

    context 'when the section guid is not present in clever_section_links' do
      it 'returns nil' do
        expect(presenter).not_to be_clever_section_linked(build_stubbed(:section))
      end
    end
  end

  describe '#clever_section_error?' do
    let(:clever_section_a) { build_stubbed(:section) }
    let(:clever_section_b) { build_stubbed(:section) }

    let(:clever_section_links_hash) do
      {
        clever_section_a.guid => {
          'error' => true
        },
        clever_section_b.guid => {
          'error' => false
        }
      }
    end

    before do
      allow(presenter).to receive(:clever_section_links).and_return(clever_section_links_hash)
    end

    context 'when the passed section guid is present in clever_section_links' do
      it 'returns true when the error key has been set to true' do
        expect(presenter).to be_clever_section_error(clever_section_a)
      end

      it 'returns true when the linked key has been set to false' do
        expect(presenter).not_to be_clever_section_error(clever_section_b)
      end
    end

    context 'when the section guid is not present in clever_section_links' do
      it 'returns nil' do
        expect(presenter).not_to be_clever_section_error(build_stubbed(:section))
      end
    end
  end

  describe 'methods that forward to an UnprocessedRequestCounter instance' do
    let(:student_1) { build_stubbed(:student) }
    let(:section_students) { [student_1] }
    let(:request_counter) do
      instance_double(
        UnprocessedRequestCounter,
        help_request_count: 1,
        needy_student_count: 3,
        review_request_count: 2
      )
    end

    before do
      allow(course).to receive(:sections_by_instructor).and_return([section])

      allow(UnprocessedRequestCounter).to receive(:new).and_return(request_counter)
      allow(request_counter).to receive(:populate).and_return(request_counter)
      allow(Student).to receive(:enrolled_in_sections_user_ids_only).and_return(section_students)
    end

    it 're-uses the created UnprocessedRequestCounter on subsequent calls' do
      presenter.review_request_count(section.id)
      presenter.review_request_count(section.id)
      presenter.help_request_count(section.id)
      presenter.needy_student_count(section.id)
      expect(UnprocessedRequestCounter).to have_received(:new)
        .with([section.id], section_students)
        .once
    end

    describe '#help_request_count' do
      it 'instantiates and populates a new UnprocessedRequestCounter, ' \
         'passing in current sections' do
        presenter.help_request_count(section.id)
        expect(UnprocessedRequestCounter).to have_received(:new)
          .with([section.id], section_students)
        expect(request_counter).to have_received(:populate)
      end

      it 'delegates calls to the UnprocessedRequestCounter' do
        expect(presenter.help_request_count(section.id)).to eq(1)
        expect(request_counter).to have_received(:help_request_count)
          .with(section.id)
      end
    end

    describe '#review_request_count' do
      it 'instantiates and populates a new UnprocessedRequestCounter, ' \
         'passing in current sections' do
        presenter.review_request_count(section.id)
        expect(UnprocessedRequestCounter).to have_received(:new)
          .with([section.id], section_students)
        expect(request_counter).to have_received(:populate)
      end

      it 'delegates calls to the UnprocessedRequestCounter' do
        expect(presenter.review_request_count(section.id)).to eq(2)
        expect(request_counter).to have_received(:review_request_count)
          .with(section.id)
      end
    end

    describe '#needy_student_count' do
      it 'instantiates and populates a new UnprocessedRequestCounter, ' \
         'passing in current sections' do
        presenter.needy_student_count(section.id)
        expect(UnprocessedRequestCounter).to have_received(:new)
          .with([section.id], section_students)
        expect(request_counter).to have_received(:populate)
      end

      it 'delegates calls to the UnprocessedRequestCounter' do
        expect(presenter.needy_student_count(section.id)).to eq(3)
        expect(request_counter).to have_received(:needy_student_count)
          .with(section.id)
      end
    end
  end

  context 'with methods that use one roster tables' do
    describe '#has_one_roster_linked_user?' do
      it 'returns true if the user is in the linked users table' do
        create(:one_roster_linked_user, school: school, user: instructor)
        expect(presenter).to have_one_roster_linked_user
      end

      it 'returs false if the user is not in the linked users table' do
        expect(presenter).not_to have_one_roster_linked_user
      end
    end
  end
end # end describe InstructorDashboardPresenter

# This class simulates the row format retrieved from the
# GradebookEngine::GradebookAPI query. The results include extra
# attributes that aren't found in a regular ScoreAction, so an instance
# double would raise errors trying to use those results. Instantiating
# real ScoreAction instances would have the same problem. This test record
# class exposes the same methods as the records returned by the query, so
# it should allow the maximum amount of presenter code to be exercised
# without having to stub methods on individual instances.
class FakeGradebookEnginePendingScoreRecord
  attr_accessor :args

  def initialize(args)
    @args = args
  end

  %i[activity_id title].each do |method|
    define_method method do
      args[method]
    end
  end
end

describe InstructorDashboardPresenter::SectionData do
  let(:section) { create(:section) }
  let(:section_data) { described_class.new(section) }
  let(:activity_1) { build_stubbed(:activity) }
  let(:activity_2) { build_stubbed(:activity) }
  let(:user_id) { create(:user).id }
  let(:score_class) { FakeGradebookEnginePendingScoreRecord }

  def create_assignment(due_date:)
    create(
      :assignment,
      assignable: build_stubbed(:activity),
      due_date: due_date,
      section: section
    )
  end

  def create_individual_assignment(activity, section)
    IndividualAssignment.create!(
      activity_id: activity.id,
      section_id: section.id,
      user_id: user_id
    )
  end

  describe '#when the activity is an individual assignment' do
    it 'returns false if not individual assignment' do
      expect(
        section_data.activity_has_individual_assignments?(activity_1.id, section.id)
      ).to be(false)
    end

    it 'returns true if is individual assignment' do
      create_individual_assignment(activity_1, section)
      expect(
        section_data.activity_has_individual_assignments?(activity_1.id, section.id)
      ).to be(true)
    end

    it 'returns a list of users ids individually assigned' do
      create_individual_assignment(activity_1, section)
      expect(
        section_data.individual_assignment_user_ids(activity_1.id, section.id)
      ).to eq([user_id])
    end

    it 'return an empty list of users ids if not individually assigned' do
      expect(
        section_data.individual_assignment_user_ids(activity_1.id, section.id)
      ).to eq([])
    end
  end

  describe '#unique_activity_scores' do
    it 'returns one score for each unique activity' do
      score_1 = score_class.new(activity_id: activity_1.id)
      score_2 = score_class.new(activity_id: activity_1.id)
      score_3 = score_class.new(activity_id: activity_2.id)
      section_data = described_class.new(section, [score_1, score_2, score_3])
      expect(section_data.unique_activity_scores.map(&:activity_id)).to eq(
        [activity_1.id, activity_2.id]
      )
    end
  end

  describe '#score_count_by_activity_id' do
    it 'returns the number of times the activity appears' do
      score_1 = score_class.new(activity_id: activity_1.id)
      score_2 = score_class.new(activity_id: activity_1.id)
      score_3 = score_class.new(activity_id: activity_2.id)
      section_data = described_class.new(section, [score_1, score_2, score_3])
      results = [activity_1, activity_2].map do |activity|
        section_data.score_count_by_activity_id(activity.id)
      end
      expect(results).to eq([2, 1])
    end
  end

  describe '#next_assignment_due' do
    let(:section) { create(:section) }

    it 'returns the next assignment due' do
      create_assignment(due_date: Date.yesterday)
      assignment_2 = create_assignment(due_date: Date.tomorrow)
      create_assignment(due_date: 5.days.from_now.to_date)

      section_data = described_class.new(section)
      result = section_data.next_assignment_due
      expect(result).to eq(assignment_2)
    end

    it 'returns an empty array when there are no assignments due after today' do
      create_assignment(due_date: 5.days.ago.to_date)
      section_data = described_class.new(section)
      expect(section_data.next_assignment_due).to be_nil
    end

    it 'excludes assignment in the past, includes future dates' do
      assignment_1 = create_assignment(due_date: 2.days.from_now.to_date)
      create_assignment(due_date: 5.days.ago.to_date)
      section_data = described_class.new(section)
      expect(section_data.next_assignment_due).to eql(assignment_1)
    end

    context 'when the next due date is today,' do
      it 'returns nil when the section due time is in the past' do
        Timecop.freeze(Time.new(2017, 12, 27, 12, 0, 0)) do
          due_time_past_section = create(
            :section,
            due_time: 10.minutes.ago.in_time_zone('Eastern Time (US & Canada)')
              .strftime('%H:%M:%S')
          )
          create(:assignment,
                 due_date: Time.zone.today,
                 section: due_time_past_section)
          section_data = described_class.new(due_time_past_section)
          expect(section_data.next_assignment_due).to be_nil
        end
      end

      it "returns today's assignment when the section due time is in the future" do
        Timecop.freeze(Time.utc(2017, 1, 2, 13, 40, 55)) do
          due_time_future_section = create(
            :section,
            due_time: Time.parse(5.minutes.from_now.strftime('%H:%M:%S'))
          )

          assignment_1 = create(:assignment,
                                due_date: Time.zone.today,
                                section: due_time_future_section)
          section_data = described_class.new(due_time_future_section)
          expect(section_data.next_assignment_due.id).to eql(assignment_1.id)
        end
      end

      context 'when custom due time is set on assignment, ' do
        it 'returns nil when custom due time is past ' do
          past_due_time = 10.minutes.ago.in_time_zone('Eastern Time (US & Canada)')
                            .strftime('%H:%M:%S')
          due_time_past_section = create(:section, due_time: past_due_time)
          create(:assignment,
                 custom_due_time: past_due_time,
                 due_date: Time.zone.today,
                 section: due_time_past_section)
          section_data = described_class.new(due_time_past_section)
          expect(section_data.next_assignment_due).to be_nil
        end

        it 'returns the assignment when when custom due time is in the future' do
          # DateTime values are stored relative to UTC. So we need to create the
          # future due time relative to UTC. That's why we parse the time in the UTC
          # time zone.
          future_due_time = ActiveSupport::TimeZone.new('UTC')
            .parse(5.minutes.from_now.strftime('%H:%M:%S'))
          due_time_future_section = create(:section, due_time: future_due_time)
          assignment_1 = create(
            :assignment,
            custom_due_time: future_due_time,
            due_date: Time.zone.today,
            section: due_time_future_section
          )
          section_data = described_class.new(due_time_future_section)
          expect(section_data.next_assignment_due.id).to eql(assignment_1.id)
        end

        context 'when there are mulitple assignment due today' do
          it 'returns the first assignment due in the future, choosing custom ' \
             'due time over section due time' do
            due_time_future_section = create(
              :section,
              due_time: 5.minutes.from_now.strftime('%H:%M:%S')
            )
            due_time_past_section = create(
              :section,
              due_time: 5.minutes.ago.strftime('%H:%M:%S')
            )
            create(
              :assignment,
              custom_due_time: 10.minutes.from_now.in_time_zone('Eastern Time (US & Canada)')
              .strftime('%H:%M:%S'),
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            assignment_1 = create(
              :assignment,
              custom_due_time: 3.minutes.from_now.in_time_zone('Eastern Time (US & Canada)')
              .strftime('%H:%M:%S'),
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            create(
              :assignment,
              due_date: Time.zone.today,
              section: due_time_past_section
            )
            create(
              :assignment,
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            section_data = described_class.new(due_time_future_section)
            expect(section_data.next_assignment_due.id).to eql(assignment_1.id)
          end

          it 'returns the first assignment due in the future', test_debt: true do
            # fails intermittently and non-reproducibly. Presumably a date bug.
            due_time_future_section = create(
              :section,
              due_time: 5.minutes.from_now.strftime('%H:%M:%S')
            )
            due_time_past_section = create(
              :section,
              due_time: 5.minutes.ago.strftime('%H:%M:%S')
            )
            create(
              :assignment,
              custom_due_time: 9.minutes.from_now.in_time_zone('Eastern Time (US & Canada)')
              .strftime('%H:%M:%S'),
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            create(
              :assignment,
              custom_due_time: 10.minutes.from_now.in_time_zone('Eastern Time (US & Canada)')
              .strftime('%H:%M:%S'),
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            create(
              :assignment,
              due_date: Time.zone.today,
              section: due_time_past_section
            )
            assignment_1 = create(
              :assignment,
              due_date: Time.zone.today,
              section: due_time_future_section
            )
            section_data = described_class.new(due_time_future_section)
            expect(section_data.next_assignment_due.id).to eql(assignment_1.id)
          end
        end
      end
    end
  end

  describe '#next_due_date_assignments' do
    let(:section) { create(:section) }
    let(:section_data) { described_class.new(section) }

    it 'returns only assignments on the next upcoming due date' do
      create_assignment(due_date: Date.yesterday)
      assignment_2 = create_assignment(due_date: Date.tomorrow)
      assignment_3 = create_assignment(due_date: Date.tomorrow)
      create_assignment(due_date: 5.days.from_now.to_date)

      result = section_data.next_due_date_assignments
      expect(result).to match_array([assignment_2, assignment_3])
    end
  end

  describe '#due_date_sheduled?' do
    let(:section_1) { create(:section, days_to_show_assignment_due_date: 7) }
    let(:section_2) { create(:section) }
    let(:section_data_1) { described_class.new(section_1) }
    let(:section_data_2) { described_class.new(section_2) }

    it 'is true if due date release has been scheduled' do
      expect(section_data_1.due_date_scheduled?).to be true
    end

    it 'is false if due date release has not been scheduled' do
      expect(section_data_2.due_date_scheduled?).to be false
    end
  end
end

describe InstructorDashboardPresenter::CleverSchoolWarning do
  let(:non_clever_instructor) { build_stubbed(:instructor) }
  let(:clever_instructor) { build_stubbed(:instructor) }
  let(:non_clever_school) { build_stubbed(:school) }
  let(:clever_school_1) { build_stubbed(:clever_school) }
  let(:clever_school_2) { build_stubbed(:clever_school) }
  let(:all_schools) { [clever_school_1, clever_school_2, non_clever_school] }

  let(:no_warning) do
    described_class.new(non_clever_instructor, [non_clever_school])
  end
  let(:multi_school_warning) do
    described_class.new(non_clever_instructor, all_schools)
  end

  before do
    allow(clever_instructor).to receive(:clever?).and_return(true)
  end

  describe '#required?' do
    # Non-Clever instructor cases
    context 'when the user is a non-Clever instructor' do
      it 'is true when the instructor affiliated with a Clever school' do
        expect(multi_school_warning).to be_required
      end

      it 'is false when the instructor is not affiliated with any Clever schools' do
        expect(no_warning).not_to be_required
      end

      context 'when the user is an LTI rostering user transition from Clever' do
        it 'is false' do
          allow(non_clever_instructor).to receive(:lti_rostering_transitioned_from_clever?)
            .and_return(true)

          expect(multi_school_warning).not_to be_required
        end
      end
    end

    # Clever instructor cases
    it 'is false for a Clever instructor affiliated with a Clever school' do
      clever_no_warning = described_class.new(clever_instructor, all_schools)
      expect(clever_no_warning).not_to be_required
    end

    # The case of a Clever instructor associated with non-Clever school
    # should be prevented from occurring by other application code, but
    # the test should still be written.
    it 'is false for a Clever instructor affiliated with only non-Clever schools' do
      warning = described_class.new(clever_instructor, [non_clever_school])
      expect(warning).not_to be_required
    end
  end

  describe '#message' do
    it 'returns an empty string if the instructor has no Clever schools' do
      expect(no_warning.message).to eq('')
    end

    it "lists the Clever school if there's only one" do
      one_school_warning = described_class.new(non_clever_instructor, [clever_school_1])
      expect(one_school_warning.message).to include(
        clever_school_1.name, 'is'
      )
    end

    it "lists all Clever schools if there's more than one" do
      expect(multi_school_warning.message).to include(
        clever_school_1.name, clever_school_2.name, 'are'
      )
    end

    it "doesn't mention non-Clever schools" do
      expect(multi_school_warning.message).to include(non_clever_school.name)
    end
  end
end
