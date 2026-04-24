feature 'Course owner page', js: true, chrome: true do
  include CapybaraViewHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  class ChangeCourseOwnerPageObject < PageObject
    def programs
      page.all('.test-program').map do |container|
        ProgramPageElement.new(container)
      end
    end

    def program_by_id(id)
      programs.detect do |program|
        program.id == id
      end
    end

    class ProgramPageElement
      attr_reader :container

      def initialize(container)
        @container = container
      end

      def title
        container.find('.test-program_title').text
      end

      def id
        container['data-test-id'].to_i
      end

      def courses
        container.all('.test-course').map do |course_container|
          CoursePageElement.new(course_container)
        end
      end

      def course_by_id(id)
        courses.detect do |course|
          course.id == id
        end
      end

      class CoursePageElement
        attr_reader :container

        def initialize(container)
          @container = container
        end

        def name
          container.find('.test-name').text
        end

        def id
          container['data-test-id'].to_i
        end

        def possible_owners
          container.all('.test-possible_owners option').select do |option|
            option[:value].present?
          end.map(&:text)
        end

        def new_owner=(value)
          container.select(value, from: 'new_owner_id')
        end

        def change_owner
          container.click_on('Change owner')
        end
      end
    end
  end

  def for_change_course_owner_page_object
    yield ChangeCourseOwnerPageObject.new(page)
  end

  let(:support_rep_role) { Role.create!(name: Role::SUPPORT_REP) }
  let(:support_rep) { create(:user).tap { |user| user.roles << support_rep_role } }
  let(:school_1) { create(:clever_school, name: 'VHL School 1') }
  let(:school_2) { create(:clever_school, name: 'VHL School 2') }
  let(:program_1) { create(:program) }
  let(:program_2) { create(:program) }
  let(:instructor) do
    create(:clever_instructor, schools: [school_1, school_2])
  end
  let(:instructor_1) { create(:clever_instructor, schools: [school_1]) }
  let(:instructor_2) { create(:clever_instructor, schools: [school_1]) }
  let(:instructor_3) { create(:clever_instructor, schools: [school_2]) }
  let(:course_1) { create(:course, program: program_1, owner: instructor) }
  let(:course_2) { create(:course, program: program_1, owner: instructor) }
  let(:closed_course) do
    create(:closed_course, program: program_1, owner: instructor)
  end
  let(:archived_course) do
    create(:archived_course, program: program_1, owner: instructor)
  end
  let(:course_with_no_section) do
    create(:course, program: program_2, owner: instructor)
  end
  let(:course_with_section_with_no_co_instructor) do
    create(:course, program: program_2, owner: instructor).tap do |course|
      create(
        :section,
        name: 'section 1',
        course: course,
        instructor: instructor
      )
    end
  end
  let!(:courses) do
    [
      course_1,
      course_2,
      closed_course,
      archived_course,
      course_with_no_section,
      course_with_section_with_no_co_instructor
    ]
  end
  let(:course_1_section_1) do
    create(
      :section,
      name: 'section 1',
      course: course_1,
      instructor: instructor
    )
  end
  let(:course_1_section_2) do
    create(
      :section,
      name: 'section 2',
      course: course_1,
      instructor: instructor
    )
  end
  let(:course_2_section_1) do
    create(
      :section,
      course: course_2,
      name: 'section 1',
      instructor: instructor
    )
  end
  let(:course_2_archived_section) do
    create(
      :section,
      course: course_2,
      name: 'archived section',
      instructor: instructor,
      is_archived: true
    )
  end
  let!(:course_1_section_1_section_instructor_1) do
    create(
      :section_co_instructor,
      section: course_1_section_1,
      instructor: instructor_1
    )
  end
  let!(:course_1_section_1_section_instructor_2) do
    create(
      :section_co_instructor,
      section: course_1_section_1,
      instructor: instructor_2
    )
  end
  let!(:course_1_section_1_section_instructor_3) do
    create(
      :section_co_instructor,
      section: course_1_section_1,
      instructor: instructor_3
    )
  end
  let!(:course_1_section_2_section_instructor_1) do
    create(
      :section_instructor,
      section: course_1_section_2,
      instructor: instructor_1
    )
  end
  let!(:course_1_section_2_section_instructor_2) do
    create(
      :section_instructor,
      section: course_1_section_2,
      instructor: instructor_2
    )
  end
  let!(:course_2_section_1_section_instructor_1) do
    create(
      :section_instructor,
      section: course_2_section_1,
      instructor: instructor_1
    )
  end
  let!(:course_2_archived_section_instructor_2) do
    create(
      :section_instructor,
      section: course_2_archived_section,
      instructor: instructor_2
    )
  end
  let!(:section_instructors) do
    [
      course_1_section_1_section_instructor_1,
      course_1_section_1_section_instructor_2,
      course_1_section_2_section_instructor_1,
      course_2_section_1_section_instructor_1
    ]
  end

  def mock_maestro_user_calls(user)
    allow(Maestro::User).to receive(:accessible_programs)
      .with(user.guid).and_return([program_1, program_2])
  end

  describe 'As a support rep' do
    before do
      allow(Maestro::User).to receive(:redeemed_passcodes).and_return([])
      allow(Maestro::UserLicense).to receive(:all_for_user).and_return([])

      # create an instructor that is not in the same school as the current
      # course owner.
      create(:clever_instructor, schools: [create(:clever_school)])

      log_in_as(support_rep)
    end

    scenario 'I can change the owner of a course owned by a Clever instructor' do
      mock_maestro_user_calls(instructor)

      visit support_course_owner_path(instructor_guid: instructor.guid)

      purpose 'I see details for all the opened courses of the instructor, ' \
              'organized by programs' do
        for_change_course_owner_page_object do |pobject|
          expect(pobject.programs.map(&:title)).to match_array(
            [
              program_1,
              program_2
            ].map(&:title)
          )
          expect(
            pobject.program_by_id(program_1.id).courses.map(&:name)
          ).to match_array(
            [
              course_1,
              course_2
            ].map(&:name)
          )
          expect(
            pobject.program_by_id(program_2.id).courses.map(&:name)
          ).to match_array(
            [
              course_with_no_section,
              course_with_section_with_no_co_instructor
            ].map(&:name)
          )
        end
      end

      purpose 'I can change the owner of a course with sections' do
        step 'I see all instructors that are in the same school as the current ' \
             'owner as possible new owners' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_1.id).course_by_id(course_1.id)
            ) do |course|
              expect(course.possible_owners).to match_array(
                [
                  instructor_1,
                  instructor_2,
                  instructor_3
                ].map(&:full_name)
              )
            end
          end
        end

        step 'I change the owner' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_1.id).course_by_id(course_1.id)
            ) do |course|
              course.new_owner = instructor_1.full_name
              course.change_owner
            end
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, 'Course successfully updated.')
        end

        step 'The course and its sections now belong to the new instructor' do
          expect(course_1.reload.owner).to eq(instructor_1)
          expect(course_1_section_1.reload.instructor).to eq(instructor_1)
          expect(course_1_section_2.reload.instructor).to eq(instructor_1)
          expect(course_1_section_1_section_instructor_1.reload.role).to eq(
            'Instructor'
          )
        end

        step 'I do not see this course anymore' do
          for_change_course_owner_page_object do |pobject|
            expect(
              pobject.program_by_id(program_1.id).courses.map(&:name)
            ).to contain_exactly(course_2.name)
          end
        end
      end

      purpose 'I can change the owner of a course with archived sections' do
        step 'I see all instructors that are in the same school as the current ' \
             'owner as possible new owners' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_1.id).course_by_id(course_2.id)
            ) do |course|
              expect(course.possible_owners).to match_array(
                [
                  instructor_1,
                  instructor_2,
                  instructor_3
                ].map(&:full_name)
              )
            end
          end
        end

        step 'I change the owner' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_1.id).course_by_id(course_2.id)
            ) do |course|
              course.new_owner = instructor_1.full_name
              course.change_owner
            end
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, 'Course successfully updated.')
        end

        step 'The course and its sections now belongs to the new instructor' do
          expect(course_2.reload.owner).to eq(instructor_1)
          expect(course_2_section_1.reload.instructor).to eq(instructor_1)
          expect(course_2_section_1_section_instructor_1.reload.role).to eq(
            'Instructor'
          )
        end

        step 'The owner of archived sections is not changed' do
          expect(course_2_archived_section.reload.instructor).to eq(instructor)
        end

        step 'I do not see this course and its program anymore' do
          for_change_course_owner_page_object do |pobject|
            expect(pobject.programs.map(&:title)).to contain_exactly(
              program_2.title
            )
          end
        end
      end

      purpose 'I can change the owner of a course with no section' do
        step 'I see all instructors that are in the same school as the current ' \
             'owner as possible new owners' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_2.id).course_by_id(
                course_with_no_section.id
              )
            ) do |course|
              expect(course.possible_owners).to match_array(
                [
                  instructor_1,
                  instructor_2,
                  instructor_3
                ].map(&:full_name)
              )
            end
          end
        end

        step 'I change the owner' do
          for_change_course_owner_page_object do |pobject|
            with_element(
              pobject.program_by_id(program_2.id).course_by_id(
                course_with_no_section.id
              )
            ) do |course|
              course.new_owner = instructor_1.full_name
              course.change_owner
            end
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, 'Course successfully updated.')
        end

        step 'The course now belongs to the new instructor' do
          expect(course_with_no_section.reload.owner).to eq(instructor_1)
        end

        step 'I do not see the course anymore' do
          for_change_course_owner_page_object do |pobject|
            expect(
              pobject.program_by_id(program_2.id).courses.map(&:name)
            ).to contain_exactly(
              course_with_section_with_no_co_instructor.name
            )
          end
        end
      end
    end
  end
end
