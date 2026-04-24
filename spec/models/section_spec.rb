describe Section, :core do
  include TimeHandler
  include CourseBuilder

  before do
    Dangerfield::Gatekeeper.instance.disabled = true
    @program    = build_stubbed(:program, title: 'V3e')
    @school     = build_stubbed(:school)
    @instructor = build_stubbed(:instructor)
    @params = { name: 'valid_name' }
  end

  describe 'complex associations' do
    describe '#current_students_base' do
      let(:section) { create(:section) }
      let(:student) { create(:student) }
      let(:instructor) { create(:instructor) }

      it 'returns only student records' do
        section = create(:section)
        user1 = create(:student)
        create(:enrollment, section: section, user: user1)
        user2 = create(:student)
        create(:enrollment, section: section, user: user2)
        # simulate something bad happening
        user2.account_type = 'Instructor'
        user2.save
        expect(section.current_students_base).to eq([user1])
      end

      context 'when adding instructor records using << operator' do
        it 'raises a type mismatch error' do
          expect do
            expect do
              section.current_students_base << instructor
            end.to raise_error(ActiveRecord::AssociationTypeMismatch)
          end.not_to change(Enrollment, :count)
        end
      end
    end

    describe '#students' do
      let(:section) { create(:section) }
      let(:student) { create(:student) }
      let(:instructor) { create(:instructor) }

      it 'returns only student records' do
        section = create(:section)
        user1 = create(:student)
        create(:enrollment, section: section, user: user1)
        user2 = create(:student)
        create(:enrollment, section: section, user: user2)
        # simulate something bad happening
        user2.account_type = 'Instructor'
        user2.save
        expect(section.students).to eq([user1])
      end

      context 'when adding student records using << operator' do
        it 'appends the student' do
          section.students << student
          expect(section.students).to eq([student])
          expect(Enrollment.find_by_user_id(student.id)).not_to be_nil
        end
      end

      context 'when adding instructor records using << operator' do
        it 'raises a type mismatch error' do
          expect do
            expect do
              section.students << instructor
            end.to raise_error(ActiveRecord::AssociationTypeMismatch)
          end.not_to change(Enrollment, :count)
        end
      end
    end

    describe '#assignments' do
      it 'has an extension that orders by rank' do
        section = create(:section, course: create_course_with_stubs)
        # Inserting in reverse order
        assignment_2 = create(:assignment, section: section, rank: 2)
        assignment_1 = create(:assignment, section: section, rank: 1)
        expect(section.assignments.ranked).to eq([assignment_1, assignment_2])
      end
    end

    describe '#one_roster_linked_section' do
      let(:linked_section_attributes) do
        {
          one_roster_linked_section_attributes: {
            class_external_id: SecureRandom.uuid,
            course_external_id: SecureRandom.uuid
          }
        }
      end

      it 'can create a one roster linked section using nested attributes' do
        section = build(:section)
        section.assign_attributes(linked_section_attributes)
        expect { section.save! }.to change(OneRoster::LinkedSection, :count).by(1)
      end

      context 'when section is deleted' do
        it 'deletes the one roster linked section' do
          section = create(:section, linked_section_attributes)
          expect { section.destroy }.to change(OneRoster::LinkedSection, :count).by(-1)
        end
      end

      context 'when section is archived' do
        it 'deletes the one roster linked section' do
          section = create(:section, linked_section_attributes)
          expect { section.archive }.to change(OneRoster::LinkedSection, :count).by(-1)
        end
      end
    end

    describe '#cartridge_course_context_detail' do
      let(:section) { create(:section) }
      let(:school) { create(:school) }
      let(:course_context_detail_attributes) do
        {
          cartridge_course_context_detail_attributes: {
            lms_context_id: SecureRandom.uuid,
            lis_outcome_service_url: 'MynewUrl',
            course_id: section.course.id,
            school_id: section.instructor.schools.first.id
          }
        }
      end

      before do
        create(:school_user, user: section.instructor, school: school)
      end

      it 'creates a course context detail using nested attributes' do
        section.assign_attributes(course_context_detail_attributes)
        expect { section.save! }.to change(Cartridge::CourseContextDetail, :count).by(1)
        expect(Cartridge::CourseContextDetail.last).to have_attributes(
          course_context_detail_attributes[:cartridge_course_context_detail_attributes]
        )
      end

      context 'when section is deleted' do
        it 'deletes the one course context detail' do
          section = create(:section, course_context_detail_attributes)
          expect { section.destroy }.to change(Cartridge::CourseContextDetail, :count).by(-1)
        end
      end
    end
  end

  describe 'scopes' do
    describe '.by_course' do
      it 'returns all sections led by instructor, joining on section_instructors table' do
        course = create(:course)
        section_1 = create(:section, course: course)
        create(:section) # section in other course
        expect(Section.by_course(course.id)).to eq([section_1])
      end
    end

    describe '.by_instructor' do
      it 'returns all sections led by instructor, joining on section_instructors table' do
        instructor = create(:instructor)
        section_1 = create(:section, instructor: instructor)
        create(:section) # other instructor

        expect(Section.by_instructor(instructor)).to eq([section_1])
      end
    end

    describe '.open' do
      it 'returns sections in courses that end today or later' do
        create(
          :course_with_section,
          end_date: 1.day.ago,
          allow_past_end_date: true
        )
        course_ending_today = create(
          :course_with_section,
          end_date: Time.current
        )
        course_ending_tomorrow = create(
          :course_with_section,
          end_date: 1.day.from_now
        )

        expect(described_class.open).to eq([course_ending_today.sections.first,
                                            course_ending_tomorrow.sections.first])
      end

      it 'returns only non-demo, non-archived courses' do
        course_ending_tomorrow = create(:course_with_section,
                                        end_date: Time.zone.now.to_date + 1.day)
        create(:course_with_section,
               end_date: Time.zone.now.to_date + 1.day,
               is_demo: true)
        archived_course_ending_tomorrow = create(:course,
                                                 end_date: Time.zone.now.to_date + 1.day,
                                                 is_archived: true)
        create(:section, course: archived_course_ending_tomorrow)

        expect(described_class.open).to eq([course_ending_tomorrow.sections.first])
      end
    end

    describe 'enterprise scopes' do
      let!(:enterprise_section) { create(:enterprise_section) }
      let!(:non_enterprise_section) { create(:section) }

      describe '.find' do
        context 'when querying an enterprise section' do
          it 'raises not found exception' do
            expect { described_class.find(enterprise_section.id) }
              .to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when querying a non enterprise section' do
          it 'finds the section successfully' do
            expect(described_class.find(non_enterprise_section.id)).to eq(non_enterprise_section)
          end
        end
      end

      describe '.including_enterprise' do
        it 'gets all sections' do
          expect(described_class.including_enterprise)
            .to include(enterprise_section, non_enterprise_section)
        end
      end

      describe '.enterprise' do
        it 'returns only enterprise sections' do
          result_set = described_class.enterprise

          expect(result_set).to include(enterprise_section)
          expect(result_set).not_to include(non_enterprise_section)
        end
      end
    end
  end

  context 'validate assign_rostering_attrs' do
    before do
      Dangerfield::Gatekeeper.instance.disabled = false
    end

    after do
      Dangerfield::Gatekeeper.instance.disabled = true
    end

    it 'sets guid, request_id' do
      test_section = create(:section_with_course)
      expect(test_section.guid).not_to be_nil
      expect(test_section.request_id).not_to be_nil
    end
  end

  context 'callbacks' do
    let(:section) { create(:section) }

    context 'before_create' do
      describe '#set_shared_false_if_template' do
        it 'sets the shared flag to false if the section is a template' do
          template_course = create(:course_template)
          template_section = create(:section, course: template_course)
          expect(template_section.shared).to be(false)
        end

        it 'does not set the shared flag to false if the section is not a template' do
          expect(section.shared).to be(true)
        end
      end
    end

    context 'after_save' do
      describe '#archive_section_instructors' do
        let(:instructor) { create(:instructor) }

        before do
          section.instance_variable_set(:@processing_rostering_update, true)
        end

        it 'archives related SectionInstructor records if the section is being archived' do
          section_instructor = create(
            :section_instructor,
            section: section,
            instructor: instructor
          )
          expect(section_instructor).not_to be_is_archived
          section.reload
          section.update!(is_archived: true)
          section_instructor.reload
          expect(section_instructor).to be_is_archived
        end

        it 'does not archive the related SectionInstructor records if the section is not being archived' do
          section_instructor = create(
            :section_instructor,
            section: section,
            instructor: instructor
          )
          expect(section_instructor).not_to be_is_archived
          section.update!(name: 'new section name')
          section_instructor.reload
          expect(section_instructor).not_to be_is_archived
        end
      end
    end

    context 'after_destroy' do
      describe '#archive_section_instructors' do
        it 'archives related SectionInstructor records if the section is being destroyed' do
          section_instructor = create(
            :section_instructor,
            section: section,
            instructor: create(:instructor)
          )
          expect(section_instructor).not_to be_is_archived
          section.reload
          section.destroy
          section_instructor.reload
          expect(section_instructor).to be_is_archived
        end
      end
    end

    context 'trigger dangerfield_publish_if call to determine whether or not publish to rostering' do
      let(:test_section) { create(:section_with_course) }

      before do
        Dangerfield::Gatekeeper.instance.disabled = false
      end

      after do
        test_section.run_callbacks(:commit)
        Dangerfield::Gatekeeper.instance.disabled = true
      end

      context 'when common attributes changed and section saved' do
        it 'does trigger dangerfield publishing' do
          test_section.name = 'new section name'
          expect(test_section).to receive(:publish_changes?).and_return(true).at_least(:once)
          test_section.save!
        end
      end

      context 'when M3-only attributes changed and section saved' do
        it 'does not trigger dangerfield publishing' do
          test_section.current_upto = Time.zone.now.to_date
          expect(test_section).to receive(:publish_changes?).and_return(false).at_least(:once)
          test_section.save!
        end
      end
    end

    context 'update_gradebook' do
      context 'after commit' do
        let(:section) { create(:section) }

        it 'triggers update_gradebook in after_commit' do
          section.name = 'New Section Name'
          expect(section).to receive(:update_gradebook)
          section.save
        end

        it 'triggers notify_update when section is created' do
          asection = Section.new
          asection.name = 'Section1'
          asection.course = create(:course)
          asection.instructor = create(:user)
          expect(asection).to receive(:notify_update)
          asection.save
        end

        it 'triggers notify_deletion for an archived section' do
          asection = Section.new
          asection.name = 'Section1'
          asection.course = create(:course)
          asection.instructor = create(:user)
          asection.is_archived = true
          expect(asection).to receive(:notify_deletion)
          asection.save
        end

        it 'triggers notify_deletion for a destroyed section' do
          asection = Section.new
          asection.name = 'Section1'
          asection.course = create(:course)
          asection.instructor = create(:user)
          asection.save
          expect(asection).to receive(:notify_deletion)
          asection.destroy
        end

        it 'does not trigger notify_update for section zero' do
          asection = Section.section_zero
          asection.name = 'Section0'
          asection.course = create(:course)
          asection.instructor = create(:user)
          expect(asection).not_to receive(:notify_update)
          asection.save
        end
      end
    end
  end

  describe '#assignment_by_activity' do
    let(:course) { create_course_with_stubs }
    let(:section) { create(:section, course: course) }
    let(:activity) { create(:activity) }

    it 'returns the assignment for the specified activity in the current section' do
      target_assignment = create(:assignment, section: section, assignable: activity)
      expect(section.assignment_by_activity(activity)).to eq(target_assignment)
    end

    it 'returns nil if no assignment exists for the specified assignment in the specified section' do
      other_section = create(:section, course: course)
      other_activity = create(:activity)
      create(:assignment, section: section, assignable: other_activity)
      create(:assignment, section: other_section, assignable: activity)
      expect(section.assignment_by_activity(activity)).to be_nil
    end
  end

  describe 'validation :owner_name_not_hidden_without_additional_instructors' do
    let(:program) { create(:program) }
    let(:course) { create(:course) }
    let(:owner) { create(:instructor) }
    let(:co_instructor) { create(:instructor) }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course) }
    let(:section) { Section.new(instructor: instructor, course: course) }

    describe 'when hide_owner_name' do
      before do
        section.instance_variable_set(:@processing_rostering_update, true)
      end

      context 'when additional_instructors is empty' do
        it 'adds error to base' do
          section.name = 'Test Section'
          section.instructor = owner
          section.program = program
          section.course = course
          section.hide_owner_name = true
          section.save

          expect(section.errors.full_messages[0]).to include('To hide section owner name, at least a Co-Instructor or Assistant is required')
        end
      end

      context 'when additional_instructors has a Co-Instructor' do
        it 'does not adds error to base' do
          section.name = 'Test Section'
          section.instructor = owner
          section.program = program
          section.course = course
          section.hide_owner_name = true
          section.section_instructors_attributes = { 0 => {
            user_id: co_instructor.id,
            role: 'Co-instructor'
          } }
          section.save

          expect(section.errors.full_messages).to be_empty
        end
      end
    end

    it 'does not return instructors when section instructors record is archived' do
      instructor = create(:instructor)
      section = create(:section, instructor: instructor)
      section.reload
      expect(section.instructors).to eq([instructor])
      lookup = section.section_instructors.where(user_id: section.instructor_id).first
      lookup.update!(is_archived: true)
      section.reload
      expect(section.instructors).to eq([])
    end

    it 'populates the instructor team ids before saving' do
      create(:instructor)
      co_instructor = create(:instructor)
      create(:instructor)
      section_instructors_attrs = {
        0 => { user_id: co_instructor.id, role: 'Co-instructor',
               skip_section_id_validation: true }
      }
      section = Section.new(name: 'test section',
                            section_instructors_attributes: section_instructors_attrs, instructor: instructor, course: course)
      section.save!
      expect(section.instructor_team_ids).to eq(co_instructor.id.to_s)
    end
  end

  describe 'validation of time zones' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course) }
    let(:section) { Section.new(name: 'New Section', instructor: instructor, course: course) }

    it 'is valid when the time zone is nil' do
      section.time_zone = nil
      expect(section).to be_valid
    end

    it 'ensures the time zone is in the list of supported time zones' do
      section.time_zone = 'blah'
      expect(section).not_to be_valid
    end

    it 'is valid when the time zone is in the list of most common time zones' do
      ActiveSupport::TimeZone.all.map(&:name).each do |time_zone|
        section.time_zone = time_zone
        expect(section).to be_valid
      end
    end

    it 'is valid when the time zone is in the list of US time zones' do
      ActiveSupport::TimeZone.us_zones.map(&:name).each do |time_zone|
        section.time_zone = time_zone
        expect(section).to be_valid
      end
    end

    it 'is invalid when the time zone is a less common time zone' do
      valid_time_zones = ActiveSupport::TimeZone.all.map(&:name).concat(
        ActiveSupport::TimeZone.us_zones.map(&:name)
      )
      (TZInfo::Timezone.all_identifiers - valid_time_zones).each do |time_zone|
        section.time_zone = time_zone
        expect(section).not_to be_valid
      end
    end
  end

  describe 'validate class_days' do
    context 'when the course is enterprise' do
      let(:course) { build_stubbed(:enterprise_course) }

      context 'when the section is enterprise' do
        subject(:section) { build_stubbed(:enterprise_section, course:) }

        context 'when class_days is empty' do
          before do
            section.class_days = ''
            section.valid?
          end

          it { expect(section).not_to be_valid }
          it { expect(section.errors[:class_days]).not_to be_empty }
        end

        context 'when class_days is not empty' do
          before { section.class_days = '1, 3, 5' }

          it { expect(section).to be_valid }
        end
      end

      context 'when the section is not enterprise' do
        subject(:section) { build_stubbed(:section, course:) }

        context 'when class_days is empty' do
          before do
            section.class_days = ''
            section.valid?
          end

          it { expect(section).to be_valid }
        end

        context 'when class_days is not empty' do
          before { section.class_days = '1, 3, 5' }

          it { expect(section).to be_valid }
        end
      end
    end

    context 'when the course is not enterprise' do
      subject(:section) { build_stubbed(:section, course:) }

      let(:course) { build_stubbed(:course) }

      context 'when class_days is empty' do
        before { section.class_days = '' }

        it { expect(section).to be_valid }
      end

      context 'when class_days is not empty' do
        before { section.class_days = '1, 3, 5' }

        it { expect(section).to be_valid }
      end
    end
  end

  describe 'validate enterprise_section_consistency' do
    subject(:section) { build(:enterprise_section, course:) }

    context 'when the course is enterprise' do
      let(:course) { build(:enterprise_course) }

      it { expect(section).to be_valid }
    end

    context 'when the course is not enterprise' do
      let(:course) { build(:course) }

      it { expect(section).not_to be_valid }
    end
  end

  describe 'validate single_enterprise_section' do
    context 'when the section is enterprise' do
      subject(:section) { build(:enterprise_section, course:) }

      context 'when course already has an enterprise section' do
        let(:enterprise_section) { build(:enterprise_section, course: nil) }
        let(:course) { build(:enterprise_course, enterprise_section:) }

        it { expect(section).not_to be_valid }
      end

      context 'when the course does not have an enterprise section' do
        let(:course) { build(:enterprise_course) }

        it { expect(section).to be_valid }
      end
    end

    context 'when the section is not enterprise' do
      subject(:section) { build(:section, course:) }

      context 'when course already has a section' do
        let(:enterprise_section) { build(:enterprise_section, course: nil) }
        let(:course) { build(:enterprise_course, enterprise_section:) }

        it { expect(section).to be_valid }
      end

      context 'when the course does not have a section' do
        let(:course) { build(:course) }

        it { expect(section).to be_valid }
      end
    end
  end

  describe '#is_enterprise' do
    it 'sets is_enterprise to false by default' do
      section = described_class.new
      expect(section.is_enterprise).to be false
    end
  end

  context 'with valid attributes' do
    before do
      @course = build_stubbed(:course,
                              program: @program,
                              name: 'my course')
      @section = Section.new(name: 'section 1',
                             course: @course,
                             schedule: 'M T R',
                             instructor_id: 1,
                             class_days: '1,4,5')
      allow(@section).to receive(:program).and_return(@program)
      @instructor = build_stubbed(:instructor)
    end

    it 'exposes name' do
      expect(@section.name).to eq('section 1')
    end

    it 'exposes course id' do
      expect(@section.course_id).to eq(@course.id)
    end

    it 'exposes schedule' do
      expect(@section.schedule).to eq('M T R')
    end

    it 'exposes instructor id' do
      expect(@section.instructor_id).to eq(1)
    end

    it 'exposes program membership' do
      expect(@section.program.id).to eq(@program.id)
    end

    it 'exposes the class days' do
      expect(@section.class_days).to eq('1,4,5')
    end

    describe '#enrollments_without_sufficient_access' do
      let(:section) { create(:section) }

      it 'returns enrollments flagged as not having sufficient access' do
        create(:enrollment, section_id: section.id, sufficient_access: true)
        enroll_2 = create(:enrollment, section_id: section.id, sufficient_access: false)
        expect(section.enrollments_without_sufficient_access).to eq([enroll_2])
      end
    end

    describe '#section_instructors.archive' do
      it 'marks all section_instructors as archived' do
        course = create(:course)
        section = create(:section, course: course)
        other_section = create(:section, course: course)
        instructor = create(:instructor)
        instructor_in_section = create(:section_instructor, section: section,
                                                            instructor: instructor)
        instructor_in_other_section = create(:section_instructor, section: other_section,
                                                                  instructor: instructor)

        section.reload
        section.section_instructors.archive
        instructor_in_section.reload
        instructor_in_other_section.reload

        expect(instructor_in_section.is_archived).to be_truthy
        expect(instructor_in_other_section.is_archived).to be_falsey
      end
    end

    describe '#current_enrollments' do
      before do
        @section = create(:section)
      end

      it 'does not return enrollments that are dropped' do
        enrollment = create(:dropped_enrollment, section: @section,
                                                 user: build_stubbed(:student))
        expect(@section.current_enrollments).not_to include enrollment
      end

      it 'does not return enrollments that are transferred' do
        enrollment = create(:transferred_enrollment, section: @section,
                                                     user: build_stubbed(:student))
        expect(@section.current_enrollments).not_to include enrollment
      end

      it 'returns enrollments that are active' do
        enrollment = create(:active_enrollment, section: @section,
                                                user: build_stubbed(:student))
        expect(@section.current_enrollments).to include enrollment
      end

      it 'returns enrollments that are marked completed' do
        enrollment = create(:completed_enrollment, section: @section,
                                                   user: build_stubbed(:student))
        expect(@section.current_enrollments).to include enrollment
      end
    end

    describe '#current_students' do
      before do
        @section = create(:section)
      end

      it 'does not return students with dropped enrollments' do
        student = create(:student)
        create(:dropped_enrollment, section: @section, user: student)
        expect(@section.current_students).not_to include student
      end

      it 'does not return students with transferred enrollments' do
        student = create(:student)
        create(:transferred_enrollment, section: @section, user: student)
        expect(@section.current_students).not_to include student
      end

      it 'returns students with active enrollments' do
        student = create(:student)
        create(:active_enrollment, section: @section, user: student)
        expect(@section.current_students).to include student
      end

      it 'returns students with enrollments marked as completed' do
        student = create(:student)
        create(:completed_enrollment, section: @section, user: student)
        expect(@section.current_students).to include student
      end
    end

    describe '#current_student_ids' do
      it 'returns an empty array if there are no current students' do
        section = create(:section)
        expect(section.current_student_ids).to eq([])
      end

      it 'returns student ids of users who are enrolled' do
        section = create(:section)
        student = create(:student)
        create(:active_enrollment, section: section, user: student)
        expect(section.current_student_ids).to eq([student.id])
      end

      it 'returns student ids of users whose enrollments are marked completed' do
        section = create(:section)
        student = create(:student)
        create(:completed_enrollment, section: section, user: student)
        expect(section.current_student_ids).to eq([student.id])
      end

      it 'does not return student ids of students who have been dropped or transfered' do
        section = create(:section)
        student_1 = create(:student)
        create(:transferred_enrollment, section: section, user: student_1)
        expect(section.current_student_ids).not_to include student_1.id

        student_2 = create(:student)
        create(:dropped_enrollment, section: section, user: student_2)
        expect(section.current_student_ids).not_to include student_2.id
      end
    end

    describe 'default_scope excludes archived records' do
      it 'does not return archived records' do
        archived_section = create(:section, is_archived: true)
        expect(Section.all).not_to include(archived_section)
      end
    end
  end

  it 'includes Steppable' do
    expect(Section.new).to be_a(Steppable)
  end

  describe '.section_zero' do
    it 'returns a section instance with id of zero' do
      zero_section = Section.section_zero
      expect(zero_section.id).to eq(0)
    end
  end

  describe '#zero?' do
    it 'is true if section id is zero' do
      section = Section.new
      section.id = 0
      expect(section).to be_zero
    end

    it 'is false if section id is not zero' do
      section = Section.new
      section.id = 123
      expect(section).not_to be_zero
    end
  end

  describe '#non_zero?' do
    it 'is false if section id is zero' do
      section = Section.new
      section.id = 0
      expect(section).not_to be_non_zero
    end

    it 'is true if section id is not zero' do
      section = Section.new
      section.id = 123
      expect(section).to be_non_zero
    end
  end

  describe 'a section with id zero' do
    it 'is equal to any other section with id zero' do
      zero_section_1 = Section.section_zero
      zero_section_2 = Section.section_zero

      # these are different instances and thus have different object ids
      expect(zero_section_1.equal?(zero_section_2)).to be_falsey

      # but we want the 2 different instances of section zero to be considered equal
      expect(zero_section_1).to eq(zero_section_2)
      expect(zero_section_1).to be === zero_section_2
    end
  end

  describe '#steps' do
    it 'returns the 2 steps of the section wizard' do
      expect(Section.new.steps).to eq(%w[section_information class_days])
    end
  end

  describe '#weeks_covered' do
    let(:owner) { create(:instructor) }

    it 'returns and empty array if section has no course' do
      section_without_course = create(:section, instructor: owner)
      section_without_course.update_column(:course_id, nil)
      expect(section_without_course.weeks_covered).to eq([])
    end

    it 'returns the lessons covered by the course' do
      week = Week.week_containing(Date.today)

      course = build_stubbed(:course)
      allow(course).to receive(:weeks_covered).and_return([week])

      section = create(:section, course: course, instructor: @instructor)
      expect(section.weeks_covered).to eq([week])
    end
  end

  context 'validation' do
    it 'name should not be blank' do
      expect(Section.new(name: nil)).not_to be_valid
    end
  end

  describe '#closed?' do
    let(:instructor) { create(:instructor) }

    it 'returns true if the section is closed' do
      section = create(:section, instructor: instructor)
      allow(section).to receive(:closed?).and_return(true)
      expect(section).to be_closed
    end

    it 'returns true if the course section has an end date in the past' do
      course = create(:closed_course, school: @school, owner: @instructor,
                                      program: @program, end_date: 10.days.ago.to_date)
      section = create(:section, course: course, instructor: @instructor)
      expect(section).to be_closed
    end

    it 'returns false if the section is not closed and course end date is not in the past' do
      course = create(:course, school: @school, owner: @instructor, program: @program,
                               end_date: 10.days.from_now.to_date)
      section = create(:section, course: course, instructor: @instructor)
      allow(section).to receive(:closed?).and_return(false)
      expect(section).not_to be_closed
    end
  end

  describe '#section_instructors_including_archived' do
    it 'returns the unscoped section instructors ordered by role' do
      instructor_active = create(:instructor)
      instructor_archived = create(:instructor, archived: 1)
      instructor_assistant = create(:instructor)
      course = build_stubbed(:course)
      section = create(:section_without_section_instructor_callback, course: course)
      si_1 = create(:section_instructor, instructor: instructor_active, section: section,
                                         role: 'Instructor')
      si_2 = create(:section_instructor, instructor: instructor_archived, section: section,
                                         is_archived: 1, role: 'Co-instructor')
      si_3 = create(:section_instructor, instructor: instructor_assistant, section: section,
                                         role: 'Assistant')

      expect(section.section_instructors_including_archived).to eq([si_3, si_2, si_1])
    end
  end

  describe '#instructor_last_names' do
    it 'returns the last names of all of the instructors on the team' do
      instructor = build_stubbed(:instructor)
      section = create(:section)
      allow(section).to receive(:instructors).and_return([instructor])
      expect(section.instructor_last_names).to eq([instructor.last_name])
    end
  end

  describe '.find_in_open_courses_for_program' do
    before do
      @program = create(:program)
      @open_course = create(:open_course, school: @school, owner: @instructor,
                                          program: @program)
    end

    it 'returns only sections with specified ids' do
      section_1 = create(:section, course: @open_course, instructor: @instructor)
      section_2 = create(:section, course: create(:open_course, program: @program),
                                   instructor: @instructor)

      sections = Section.find_in_open_courses_for_program([section_1.id], @program.id)
      expect(sections).to include section_1
      expect(sections).not_to include section_2
    end

    it 'excludes courses that are not for the specified program' do
      section_1 = create(:section, course: @open_course, instructor: @instructor)
      other_program_course = create(:open_course, school: @school, owner: @instructor,
                                                  program: create(:program))
      section_2 = create(:section, course: other_program_course, instructor: @instructor)

      sections = Section.find_in_open_courses_for_program([section_1.id, section_2.id], @program.id)
      expect(sections).to include section_1
      expect(sections).not_to include section_2
    end

    it 'excludes courses that have closed' do
      section_1 = create(:section, course: @open_course, instructor: @instructor)
      closed_course = create(:expired_course, school: @school, owner: @instructor,
                                              program: @program)
      section_2 = create(:section, course: closed_course, instructor: @instructor)

      sections = Section.find_in_open_courses_for_program([section_1.id, section_2.id], @program.id)
      expect(sections).to include section_1
      expect(sections).not_to include section_2
    end
  end

  describe '.find_open_by_id' do
    it 'does not return sections in archived courses' do
      valid_course    = create(:course, school: @school, owner: @instructor,
                                        program: @program, is_archived: false)
      invalid_course  = create(:course, school: @school, owner: @instructor,
                                        program: @program, is_archived: true)
      valid_section   = create(:section, course: valid_course, instructor: @instructor)
      invalid_section = create(:section, course: invalid_course, instructor: @instructor)
      expect(Section.find_open_by_id([valid_section.id, invalid_section.id])).to eq([valid_section])
    end

    it 'does not return archived sections' do
      valid_course    = create(:course, school: @school, owner: @instructor,
                                        program: @program, is_archived: false)
      valid_section   = create(:section, course: valid_course, instructor: @instructor,
                                         is_archived: false)
      invalid_section = create(:section, course: valid_course, instructor: @instructor,
                                         is_archived: true)
      expect(Section.find_open_by_id([valid_section.id, invalid_section.id])).to eq([valid_section])
    end

    it 'does not return sections in courses with end dates in the past' do
      valid_course    = create(:course, school: @school, owner: @instructor,
                                        program: @program, end_date: 5.days.from_now)
      invalid_course  = create(:closed_course, school: @school, owner: @instructor,
                                               program: @program, end_date: 1.day.ago)
      valid_section   = create(:section, instructor: @instructor, course: valid_course)
      invalid_section = create(:section, instructor: @instructor, course: invalid_course)
      expect(Section.find_open_by_id([valid_section.id, invalid_section.id])).to eq([valid_section])
    end

    it 'does not return sections in demo courses' do
      valid_course    = create(:course, school: @school, owner: @instructor,
                                        program: @program, is_demo: false)
      invalid_course  = create(:course, school: @school, owner: @instructor,
                                        program: @program, is_demo: true)
      valid_section   = create(:section, instructor: @instructor, course: valid_course)
      invalid_section = create(:section, instructor: @instructor, course: invalid_course)
      expect(Section.find_open_by_id([valid_section.id, invalid_section.id])).to eq([valid_section])
    end
  end

  describe '.assignments_for_sections' do
    let(:course) { create_course_with_stubs(owner_id: @instructor.id) }

    it 'returns a list of assignments for all sections and activities passed' do
      section_1  = create(:section, instructor: @instructor, course: course)
      section_2  = create(:section, instructor: @instructor, course: course)

      assignments = []

      activity_assigned_in_both = create(:activity)
      assignments << create(:assignment, section: section_1,
                                         assignable: activity_assigned_in_both)
      assignments << create(:assignment, section: section_2,
                                         assignable: activity_assigned_in_both)

      activity_assigned_in_1 = create(:activity)
      assignments << create(:assignment, section: section_1,
                                         assignable: activity_assigned_in_1)

      activity_assigned_in_2 = create(:activity)
      assignments << create(:assignment, section: section_2,
                                         assignable: activity_assigned_in_2)

      all_activities = [activity_assigned_in_1, activity_assigned_in_both, activity_assigned_in_2]

      Section.assignments_for_sections([section_1, section_2], all_activities).each do |assignment|
        expect(assignments.include?(assignment)).to be true
      end
    end
  end

  describe '#activity_in_category' do
    before do
      @section = create(:section)
    end

    it 'returns array of uniq activities' do
      activity_1 = build_stubbed(:activity)
      activity_2 = build_stubbed(:activity)
      activity_3 = build_stubbed(:activity)
      activity_4 = build_stubbed(:activity)

      category_1 = build_stubbed(:category)
      category_2 = build_stubbed(:category)

      assignment_1 = build_stubbed(:assignment, category: category_1, assignable: activity_1)
      assignment_2 = build_stubbed(:assignment, category: category_2, assignable: activity_2)
      assignment_3 = build_stubbed(:assignment, category: category_1, assignable: activity_3)
      assignment_4 = build_stubbed(:assignment, category: category_2, assignable: activity_4)

      assignments = [assignment_1, assignment_2, assignment_3, assignment_4]
      allow(@section).to receive(:assignments).and_return(assignments)

      expect(@section.activities_in_category(category_1)).to eq([activity_1, activity_3])
    end
  end

  describe '#archive' do
    let(:school)  { create(:school, district_id: 1000) }
    let(:course)  { create(:course, school: school) }
    let(:section)  { create(:section, course: course) }

    it 'sets error when section not archived' do
      allow(section).to receive(:update).and_return(false)
      section.archive
      expect(section.errors.full_messages).to eql(['Section deletion failed. Please try again in a few minutes. If you continue to see this error, please contact technical support.'])
      expect(section.is_archived).to be_falsey
    end

    it 'sets section to archived' do
      expect(section.enrollments).to receive(:archive)
      expect(section.section_instructors).to receive(:archive)
      allow(section).to receive(:really_archived?).and_return(true)
      section.archive
      expect(section.is_archived).to be_truthy
    end
  end

  describe '#cumulative_grade_for' do
    let(:section) { build_stubbed(:section, course: course) }
    let(:course) { build_stubbed(:course) }
    let(:category) { build_stubbed(:category) }

    it 'calls GradebookAPI#section_average' do
      allow(GradebookEngine::GradebookAPI).to receive(:section_average)
      expect(GradebookEngine::GradebookAPI).to receive(:section_average).with(section: section,
                                                                              category: category)
      section.cumulative_grade_for(category)
    end
  end

  describe '#cumulative_grade' do
    let(:section) { build_stubbed(:section, course: course) }
    let(:course) { build_stubbed(:course) }

    it 'calls GradebookAPI#section_average' do
      allow(GradebookEngine::GradebookAPI).to receive(:section_average)
      expect(GradebookEngine::GradebookAPI).to receive(:section_average)
        .with(section: section)
      section.cumulative_grade
    end
  end

  describe '#activities_for_due_date' do
    it 'returns an array of activities that are due on the specified day' do
      course = create_course_with_stubs
      section = create(:section, course: course)

      activity = create(:activity)
      other_activity = create(:activity)

      assignment = create(:assignment,
                          assignable: activity,
                          section: section,
                          due_date: 1.day.from_now.to_date)

      create(:assignment,
             assignable: other_activity,
             section: section,
             due_date: 2.days.from_now.to_date)

      result = section.activities_for_due_date(assignment.due_date)
      expect(result).to include activity
      expect(result).not_to include other_activity
    end
  end

  describe '#assignments_by_activities' do
    let(:course) { create_course_with_stubs }
    let(:section) { create(:section, course: course) }

    it 'returns an array of assignments for the given activities' do
      activity = create(:activity)
      other_activity = create(:activity)

      assignment = create(:assignment,
                          assignable: activity,
                          section: section)

      other_assignment = create(:assignment,
                                assignable: other_activity,
                                section: section)

      result = section.assignments_by_activities([activity])
      expect(result).to include assignment
      expect(result).not_to include other_assignment
    end

    context 'when activity array is empty' do
      it 'does not raise errors' do
        expect { section.assignments_by_activities([nil]) }.not_to raise_error
      end
    end
  end

  describe '#assignment_past_due_count' do
    it 'returns the count of assignments that are past due' do
      section = create(:section)

      activity = create(:activity)
      other_activity = create(:activity)

      create(:assignment,
             assignable: activity,
             section: section,
             due_date: 1.day.from_now.to_date)

      create(:assignment,
             assignable: other_activity,
             section: section,
             due_date: 1.day.ago.to_date)

      result = section.assignment_past_due_count
      expect(result).to equal 1
    end
  end

  describe '#first_five_students' do
    it 'returns the first five students in a section ordered by last name' do
      section = build_stubbed(:section)
      if section.current_students_base.present?
        expect(section.current_students_base).to receive(:limit).with(5)
        expect(section.current_students_base).to receive(:order).with('last_name ASC')
      else
        expect(section.current_students_base.to_a).to eql([])
      end
      section.first_five_students
    end
  end

  describe '#first_five_active_students' do
    it 'returns the first five active students in a section ordered by last name' do
      section = build_stubbed(:section)
      if section.current_students_base.present?
        expect(section.current_students_base).to receive(:limit).with(5)
        expect(section.current_students_base).to receive(:order).with('last_name ASC')
      else
        expect(section.current_students_base.to_a).to eql([])
      end
      section.first_five_active_students
    end
  end

  describe '#additional_instructors' do
    before do
      @course = build_stubbed(:course)
      @section = build_stubbed(:section, course: @course)
    end

    it 'looks up instructors' do
      allow(@section).to receive(:instructors).and_return([])
      @section.additional_instructors
    end

    it 'exclude course owner' do
      allow(@course).to receive(:owner).and_return('inst_1')
      allow(@section).to receive(:instructors).and_return(['inst_1'])
      expect(@section.additional_instructors).to eq([])
    end
  end

  describe '#prospective_additional_instructors' do
    let(:course_owner) { build_stubbed(:instructor) }
    let(:current_coinstructor) { build_stubbed(:instructor) }
    let(:potential_coinstructor) { build_stubbed(:instructor) }
    let(:potential_instructors) do
      [course_owner,
       current_coinstructor,
       potential_coinstructor]
    end
    let(:course) { build_stubbed(:course, owner: course_owner) }
    let(:section) { build_stubbed(:section, course: course) }

    before do
      # Mock dependencies outside the section class
      allow(course).to receive(:prospective_additional_instructors)
        .and_return(potential_instructors)
      allow(course_owner).to receive(:clever?).and_return(false)
      allow(current_coinstructor).to receive(:clever?).and_return(false)
      allow(potential_coinstructor).to receive(:clever?).and_return(false)

      # Create section instructor records for us to find
      create(:section_instructor, section: section, instructor: course_owner)
      create(:section_instructor, role: 'Co-instructor',
                                  section: section,
                                  instructor: current_coinstructor)
    end

    it 'gets prospective additional instructors from the course' do
      expect(course).to receive(:prospective_additional_instructors)

      section.prospective_additional_instructors
    end

    it 'returns instructors with program access who meet the filter criteria' do
      expect(section.prospective_additional_instructors).to include(potential_coinstructor)
    end

    it 'excludes the course owner' do
      expect(section.prospective_additional_instructors).not_to include(course_owner)
    end

    it 'excludes current co-instructors' do
      expect(section.prospective_additional_instructors).not_to include(current_coinstructor)
    end

    it 'excludes non-clever users if the course owner is from Clever' do
      allow(course_owner).to receive(:clever?).and_return(true)

      expect(section.prospective_additional_instructors).not_to include(potential_coinstructor)
    end
  end

  describe 'editable_by?' do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
    end

    it 'returns false when user is not course owner and section owner' do
      course = build_stubbed(:course)
      allow(course).to receive(:owner).and_return(nil)
      allow(@section).to receive(:instructor).and_return(nil)
      allow(@section).to receive(:course).and_return(course)
      expect(@section.editable_by?(@user)).to be_falsey
    end

    it 'returns true when user is the course owner' do
      course = build_stubbed(:course)
      allow(course).to receive(:owner).and_return(@user)
      allow(@section).to receive(:instructor).and_return(nil)
      allow(@section).to receive(:course).and_return(course)
      expect(@section.editable_by?(@user)).to be_truthy
    end

    it 'returns true when user is the section owner' do
      allow(@section).to receive(:instructor).and_return(@user)
      expect(@section.editable_by?(@user)).to be_truthy
    end

    it 'returns true when user is the co instructor' do
      course = build_stubbed(:course)
      allow(course).to receive(:owner).and_return(nil)
      allow(@section).to receive(:instructor).and_return(nil)
      allow(@section).to receive(:course).and_return(course)
      allow(@section).to receive(:additional_co_instructor?).and_return(true)

      expect(@section.editable_by?(@user)).to be_truthy
    end
  end

  describe '#additional_co_instructor?' do
    let(:instructor) { create(:instructor) }
    let(:section) { create(:section, instructor:) }
    let(:co_instructor) { create(:instructor) }
    let(:assistant) { create(:instructor) }
    let(:section_co_instructor) do
      create(
        :section_instructor,
        section_id: section.id,
        role: 'Co-instructor',
        user_id: co_instructor.id
      )
    end
    let(:section_assistant) do
      create(
        :section_instructor,
        section_id: section.id,
        role: 'Assistant',
        user_id: assistant.id
      )
    end

    before do
      allow(section).to receive(:additional_instructors).and_return(
        [section_co_instructor, section_assistant]
      )
    end

    it 'returns true if the user is a Co-instructor' do
      expect(section).to be_additional_co_instructor(co_instructor)
    end

    it 'returns false if the user is an instructor' do
      expect(section).not_to be_additional_co_instructor(instructor)
    end

    it 'returns false if the user is an assistant' do
      expect(section).not_to be_additional_co_instructor(assistant)
    end
  end

  describe '#sample_student' do
    it 'returns the fake student if it exists' do
      section = create(:section, course: create_course_with_stubs)
      fake_student = create(:student, fake: true)
      section.students << fake_student
      expect(section.sample_student).to eq(fake_student)
    end

    it 'returns nil if there are no fake students' do
      section = create(:section)
      section.students << create(:student, fake: false)
      expect(section.sample_student).to be_nil
    end
  end

  describe '#real_students_base' do
    it 'filters out fake students' do
      students = [double(Student, fake?: false),
                  double(Student, fake?: true)]
      section = build_stubbed(:section)
      allow(section).to receive(:current_students_base).and_return(students)
      expect(section.send(:real_students_base)).to eq([students[0]])
    end
  end

  describe '#date_in_past?' do
    it 'returns false when given due date is in the future' do
      Timecop.travel(Time.local(2014, 2, 8, 12, 5)) do
        in_time_zone('Pacific Time (US & Canada)') do
          section = create(:section,
                           due_time: Time.parse('11:00'),
                           time_zone: 'Central Time (US & Canada)')

          expect(section.date_in_past?(Time.now.tomorrow)).to be_falsey
        end
      end
    end

    it 'returns true when section due time is in the future' do
      Timecop.travel(Time.local(2014, 2, 8, 12, 5)) do
        in_time_zone('Pacific Time (US & Canada)') do
          section = create(:section,
                           due_time: Time.parse('16:00'),
                           time_zone: 'Central Time (US & Canada)')

          expect(section.date_in_past?(Date.today)).to be_falsey
        end
      end
    end

    it 'returns true when section due time is in the past' do
      Timecop.travel(Time.local(2014, 2, 8, 12, 5)) do
        in_time_zone('Eastern Time (US & Canada)') do
          section = create(:section,
                           due_time: Time.parse('06:00'),
                           time_zone: 'Central Time (US & Canada)')

          expect(section.date_in_past?(Date.today)).to be_truthy
        end
      end
    end
  end

  describe '#current_announcement_notifications' do
    let(:section) { create(:section_with_course) }
    let(:student) { create(:student) }

    it 'returns announcement notifications for the given student' do
      Timecop.travel(Time.local(2014, 2, 8, 12, 5)) do
        today = Date.today
        create(:announcement, show_on: today).notifications.dispatch('AnnouncementPosted',
                                                                     { section: section,
                                                                       user: student })
        create(:announcement, show_on: today).notifications.dispatch('AnnouncementPosted',
                                                                     { section: section,
                                                                       user: create(:student) })

        expect(section.current_announcement_notifications(student).count).to eq(1)
        notification = section.current_announcement_notifications(student).first
        expect(notification.user_id).to eq(student.id)
      end
    end

    it 'returns announcement notifications for current day only' do
      Timecop.travel(Time.local(2014, 2, 8, 12, 5)) do
        today = Date.today
        create(:announcement, show_on: today).notifications.dispatch('AnnouncementPosted',
                                                                     { section: section,
                                                                       user: student })
        create(:announcement, show_on: 1.day.ago).notifications.dispatch('AnnouncementPosted',
                                                                         { section: section,
                                                                           user: student })
        create(:announcement, show_on: 1.day.from_now).notifications.dispatch('AnnouncementPosted',
                                                                              { section: section,
                                                                                user: student })

        results = section.current_announcement_notifications(student)
        expect(results.count).to eq(1)
        expect(results.first.announcement.show_on).to eq(today)
      end
    end

    it 'returns the last notification for each announcement only (when it has multiple dismissed notifications)' do
      announcement = create(:announcement, show_on: Date.today)
      create(:announcement_posted_notification, announcement: announcement, dismissed: true,
                                                user: student)
      expected_notification = create(:announcement_posted_notification, announcement: announcement,
                                                                        dismissed: true, user: student)
      expect(announcement.notifications.size).to eq(2)
      results = section.current_announcement_notifications(student)
      expect(results.size).to eq(1)
      expect(results.first.id).to eq(expected_notification.id)
    end
  end

  describe '#activities_in_category' do
    let(:section) { build_stubbed(:section) }
    let(:category) { double('category', id: 1) }
    let(:activity) { double('activity') }
    let(:assignment) { double('assignment', category: category, assignable: activity) }

    it 'returns an empty array when section has no assignments' do
      allow(section).to receive(:assignments).and_return([])
      expect(section.activities_in_category(category)).to be_empty
    end

    context 'when section has assignments' do
      before do
        allow(section).to receive(:assignments).and_return([assignment])
      end

      it 'returns an empty array when there are no category matches within assignments' do
        expect(section.activities_in_category(double('category', id: 2))).to be_empty
      end

      it 'returns an activity array when there are category matches within assignments' do
        expect(section.activities_in_category(category)).to eq([activity])
      end
    end
  end

  describe '#activities_in_week' do
    let(:section) { build_stubbed(:section) }
    let(:weeks_covered) { [] }
    let(:valid_date) { Time.now.to_s }
    let(:assignment) { double('assignment') }

    before do
      allow(section).to receive(:weeks_covered).and_return(weeks_covered)
    end

    it 'returns an empty array when entered date is not included in weeks covered by section' do
      allow(weeks_covered).to receive(:include?).and_return(false)
      expect(section.activities_in_week(valid_date)).to be_empty
    end

    context 'when entered date is included in weeks covered by section' do
      before do
        allow(weeks_covered).to receive(:include?).and_return(true)
      end

      it 'returns an empty array when section has no assignments' do
        allow(section).to receive(:assignments).and_return([])
        expect(section.activities_in_week(valid_date)).to be_empty
      end

      context 'when section has assignments' do
        before do
          allow(section).to receive(:assignments).and_return([assignment])
        end

        it "returns an empty array when entered date not is included in assignment's due date week" do
          allow(assignment).to receive(:in_week).and_return(false)
          expect(section.activities_in_week(valid_date)).to be_empty
        end

        it "returns assignment's activity when entered date is included in assignment's due date week" do
          activity = double('activity')
          allow(assignment).to receive(:in_week).and_return(true)
          allow(assignment).to receive(:assignable).and_return(activity)
          expect(section.activities_in_week(valid_date)).to eq([activity])
        end
      end
    end
  end

  describe '#activities_on_day' do
    let(:section) { build_stubbed(:section) }
    let(:valid_date) { Time.now.to_date }
    let(:activity) { double('activity') }
    let(:assignment) { double('assignment', due_date: valid_date, assignable: activity) }

    it 'returns an empty array when section has no assignments' do
      allow(section).to receive(:assignments).and_return([])
      expect(section.activities_on_day(valid_date)).to be_empty
    end

    context 'when section has assignments' do
      before do
        allow(section).to receive(:assignments).and_return([assignment])
      end

      it "returns an empty array when assignment's due date does not match entered date" do
        expect(section.activities_on_day(valid_date + 1.day)).to be_empty
      end

      it "returns assignment's activity when assignment's due date matches entered date" do
        expect(section.activities_on_day(valid_date)).to eq([activity])
      end
    end
  end

  describe '#activities' do
    let(:section) { build_stubbed(:section) }
    let(:activity_1) { double('activity') }
    let(:assignment_1) { double('assignment', assignable: activity_1) }
    let(:activity_2) { double('activity') }
    let(:assignment_2) { double('assignment', assignable: activity_2) }

    it 'returns an empty array when section has no assignments' do
      allow(section).to receive(:assignments).and_return([])
      expect(section.activities).to be_empty
    end

    it "returns assignments' activities when section has assignments" do
      allow(section).to receive(:assignments).and_return([assignment_1, assignment_2])
      expect(section.activities).to include activity_1
      expect(section.activities).to include activity_2
    end
  end

  describe '#has_instructor?' do
    it 'returns true if the section instructor is the same of the current_user' do
      instructor = create(:instructor)
      section = create(:section)
      section.instructors << instructor
      expect(section.has_instructor?(instructor)).to eq(true)
    end

    it 'returns false if the section instructor is other' do
      instructor_1 = create(:instructor)
      instructor_2 = create(:instructor)
      section = create(:section)
      section.instructors << instructor_1
      expect(section.has_instructor?(instructor_2)).to eq(false)
    end
  end

  describe '#one_roster_linked?' do
    let(:section) { create(:section) }

    it 'returns true if the section has a one_roster_linked_section record' do
      create(:one_roster_linked_section, section: section)
      expect(section.one_roster_linked?).to be(true)
    end

    it 'returns false if the section does not have a one_roster_linked_section record' do
      expect(section.one_roster_linked?).to be(false)
    end
  end

  describe '.find_guid' do
    it 'returns the guid of a section given an id' do
      section = create(:section)
      expect(described_class.find_guid(section.id)).to eql(section.guid)
    end
  end

  describe '.by_guid' do
    it 'returns section that matches specified guid' do
      new_section = create(:section)
      expect(described_class.by_guid(new_section.guid)).to eql(new_section)
    end
  end
end
