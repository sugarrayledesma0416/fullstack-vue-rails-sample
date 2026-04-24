describe SectionOptions do
  let(:section) { build_stubbed(:section, course: build_stubbed(:course)) }
  let(:course) { build_stubbed(:course) }
  let(:user) { build_stubbed(:user) }
  let(:latest_section) { build_stubbed(:section, course: course) }
  let(:another_section) { build_stubbed(:section, course: course) }
  let(:previous_sections) { [latest_section, another_section] }
  let(:options) { described_class.new(user, section, previous_sections) }
  let(:enrollment_lock_policy) { double(Policy::Section::BlockEnrollment) }
  # Create gradebook counterparts for sections so that we can check for external assignments.
  let!(:gb_latest_section) { create(:gb_section, id: latest_section.id) }
  let!(:gb_another_section) { create(:gb_section, id: another_section.id) }

  before do
    allow(latest_section).to receive(:created_at).and_return(Time.now)
    allow(another_section).to receive(:created_at).and_return(Time.now - 1.day)
    allow(Policy::Section::BlockEnrollment).to receive(:new) { enrollment_lock_policy }
  end

  describe '#latest_section_id' do
    it 'includes the id of the latest section created in the resopnse' do
      expect(options.latest_section_id).to eq(latest_section.id)
    end
  end

  describe '#instructor' do
    it 'includes the section creator (taken from section.instructor)' do
      expect(options.instructor).to eq({ id: section.instructor.id })
    end
  end

  describe '#allow_enrollment_lock' do
    context 'when user can lock enrollments' do
      it 'returns true' do
        allow(enrollment_lock_policy).to receive(:can?) { true }
        expect(options.allow_enrollment_lock).to be_truthy
      end
    end

    context 'when user cannot lock enrollments' do
      it 'returns false' do
        allow(enrollment_lock_policy).to receive(:can?) { false }
        expect(options.allow_enrollment_lock).to be_falsy
      end
    end
  end

  describe '#section_instructors' do
    it 'includes the section instructor records' do
      section = create(:section, course: build_stubbed(:course))
      current_user = section.instructor
      another_user = create(:instructor)
      section.section_instructors.build(
        [
          {
            allowed_to_edit_content: true,
            role: 'Instructor',
            user_id: current_user.id
          },
          {
            allowed_to_edit_content: false,
            role: 'Assistant',
            user_id: another_user.id
          }
        ]
      )
      options = SectionOptions.new(user, section, [latest_section, another_section])
      expect(options.section_instructors).to match_array(
        [
          {
            allowed_to_edit_content: true,
            first_name: current_user.first_name,
            full_name: current_user.full_name,
            last_name: current_user.last_name,
            email: current_user.email,
            role: 'Instructor',
            user_id: current_user.id
          },
          {
            allowed_to_edit_content: false,
            first_name: another_user.first_name,
            full_name: another_user.full_name,
            last_name: another_user.last_name,
            email: another_user.email,
            role: 'Assistant',
            user_id: another_user.id
          }
        ]
      )
    end
  end

  describe '#instructor_creator_roles' do
    it 'includes the instructor creator roles' do
      expect(options.instructor_creator_roles).to eq(SectionInstructor::INSTRUCTOR_CREATOR_ROLES.values.sort)
    end
  end

  describe '#instructor_roles' do
    it 'includes the instructor roles' do
      expect(options.instructor_roles).to eq(SectionInstructor::INSTRUCTOR_ROLES.values)
    end
  end

  describe '#course' do
    it 'includes the course id and name and owner id and program id' do
      options =  SectionOptions.new(user, section, previous_sections)
      expect(options.course).to eq({ id: section.course.id, name: section.course.name, owner_id: section.course.owner_id, program_id: section.course.program_id })
    end
  end

  context 'when serializing a new section' do
    it "includes the section's id as nil" do
      section.id = nil
      options =  SectionOptions.new(user, section, previous_sections)
      expect(options.id).to eq(nil)
    end

    it 'includes Time.zone.now', test_debt: true do
      expect(options.time_zone).to eq(Time.zone.name)
    end

    context 'when there are previous sections' do
      before do
        section.due_time = nil
        @options = SectionOptions.new(user, section, previous_sections)
      end

      it 'includes relevant section copy information (previous sections)' do
        instructor = build_stubbed(:instructor)
        section_instructor = SectionInstructor.new(user_id: instructor.id, role: 'Instructor')
        allow(section_instructor).to receive(:instructor).and_return(instructor)
        allow(latest_section).to receive(:section_instructors).and_return([section_instructor])
        allow(latest_section).to receive(:class_days).and_return('1,2')
        allow(another_section).to receive(:class_days).and_return('3,4,5')
        previous_sections = [latest_section, another_section]
        options = SectionOptions.new(user, section, previous_sections)
        expect(options.previous_sections_info).to match_array [
          {
            additional_info: latest_section.additional_info,
            assignment_past_due_count: latest_section.assignment_past_due_count,
            assignments_present: false,
            class_days: { '1' => true, '2' => true },
            course: {
              id: latest_section.course.id,
              name: latest_section.course.name
            },
            due_time_ampm: 'PM',
            due_time_hour: '12',
            due_time_min: '00',
            has_external_assignments: false,
            hide_owner_name: false,
            id: latest_section.id,
            name: latest_section.name,
            section_instructors: [
              allowed_to_edit_content: true,
              first_name: instructor.first_name,
              full_name: instructor.full_name,
              last_name: instructor.last_name,
              email: instructor.email,
              role: 'Instructor',
              user_id: instructor.id
            ],
            time_zone: latest_section.time_zone
          },
          {
            additional_info: another_section.additional_info,
            assignment_past_due_count: another_section.assignment_past_due_count,
            assignments_present: false,
            class_days: { '3' => true, '4' => true, '5' => true },
            course: {
              id: another_section.course.id,
              name: another_section.course.name
            },
            due_time_ampm: 'PM',
            due_time_hour: '12',
            due_time_min: '00',
            has_external_assignments: false,
            hide_owner_name: false,
            id: another_section.id,
            name: another_section.name,
            section_instructors: [],
            time_zone: another_section.time_zone
          }
        ]
      end
    end

    context 'when there are no previous sections' do
      before do
        section.due_time = nil
        @options = SectionOptions.new(user, section)
      end

      it 'includes 11:59 PM at the default due time' do
        expect(@options.due_time_hour).to eq('11')
        expect(@options.due_time_min).to eq('59')
        expect(@options.due_time_ampm).to eq('PM')
      end

      it 'defaults to a blank string for the sections additional info' do
        expect(@options.additional_info).to eq('')
      end

      it 'sets the latest section id to 0' do
        expect(@options.latest_section_id).to eq(0)
      end
    end
  end

  context 'when serializing an existing section' do
    it "includes the section's id" do
      options =  SectionOptions.new(user, section, previous_sections)
      expect(options.id).to eq(section.id)
    end

    it 'includes the sections due time' do
      section.due_time = '10:11AM'
      options = SectionOptions.new(user, section, previous_sections)
      expect(options.due_time_hour).to eq('10')
      expect(options.due_time_min).to eq('11')
      expect(options.due_time_ampm).to eq('AM')
    end

    it 'includes the section name' do
      options = SectionOptions.new(user, section, previous_sections)
      expect(options.name).to eq(section.name)
    end

    it "includes the section's time zone" do
      allow(section).to receive(:time_zone).and_return('my_zone')
      options = SectionOptions.new(user, section, previous_sections)
      expect(options.time_zone).to eq('my_zone')
    end

    it "includes the section instructor's ids for existing section instructors" do
      section = create(:section)
      allow(section).to receive(:course).and_return(build_stubbed(:course))
      section.reload
      section_instructor = section.section_instructors.first
      section.section_instructors << SectionInstructor.new(user_id: section_instructor.user_id, role: 'Assistant', section_id: section.id)
      options = SectionOptions.new(user, section, previous_sections)
      expect(options.section_instructors).to eq(
        [
          {
            allowed_to_edit_content: true,
            first_name: section_instructor.instructor.first_name,
            full_name: section_instructor.instructor.full_name,
            id: section_instructor.id,
            last_name: section_instructor.instructor.last_name,
            email: section_instructor.instructor.email,
            role: 'Instructor',
            user_id: section_instructor.user_id
          },
          {
            allowed_to_edit_content: true,
            first_name: section_instructor.instructor.first_name,
            full_name: section_instructor.instructor.full_name,
            last_name: section_instructor.instructor.last_name,
            email: section_instructor.instructor.email,
            role: 'Assistant',
            user_id: section_instructor.user_id
          }
        ]
      )
    end
  end

  describe '#additional_info' do
    before do
      allow(latest_section).to receive(:created_at).and_return(Time.now)
      allow(another_section).to receive(:created_at).and_return(Time.now - 1.day)
    end
    describe 'when section has additional info' do
      it 'returns it' do
        section.additional_info = 'Foo'
        expect(options.additional_info).to eq('Foo')
      end
    end

    describe 'when section does not have additional info' do
      it 'returns the empty string' do
        section.additional_info = nil
        expect(options.additional_info).to eq('')
      end
    end
  end

  describe '#hide_owner_name' do
    it "returns section's value for hiding owner's name" do
      section.hide_owner_name = true
      expect(options.hide_owner_name).to be_truthy
    end
  end
end
