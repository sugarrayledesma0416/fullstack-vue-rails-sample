describe "an enrollment", :core => true do
  before do
    Dangerfield::Gatekeeper.instance.disabled = true
  end

  describe '.by_program' do
    it 'returns all enrollments by program' do
      program_1 = create(:program)
      program_2 = create(:program)
      course_1 = create(:course, :program => program_1)
      course_2 = create(:course, :program => program_2)
      section_1 = create(:section, :course => course_1)
      section_2 = create(:section, :course => course_2)
      enrollment_1 = create(:enrollment, :section => section_1)
      enrollment_2 = create(:enrollment, :section => section_2)

      expect(Enrollment.by_program(program_1)).to eq([enrollment_1])
    end
  end

  describe '.by_section' do
    it 'returns all enrollments by section' do
      section_1 = create(:section)
      section_2 = create(:section)
      enrollment_1 = create(:enrollment, :section => section_1)
      enrollment_2 = create(:enrollment, :section => section_2)
      expect(Enrollment.by_section(section_1)).to eq([enrollment_1])
    end
  end

  describe '.by_section_transferred_to' do
    it 'returns all enrollments by section transferred to' do
      section_1 = create(:section)
      section_2 = create(:section)
      enrollment_1 = create(:enrollment, :section_transferred_to => section_1.id)
      enrollment_2 = create(:enrollment, :section_transferred_to => section_2.id)
      expect(Enrollment.by_section_transferred_to(section_1)).to eq([enrollment_1])
    end
  end

  describe '.by_student' do
    it 'returns all enrollments by student' do
      student = create(:student)
      section_1 = create(:section)
      section_2 = create(:section)
      enrollment_1 = create(:enrollment, :section => section_1)
      enrollment_2 = create(:enrollment, :section => section_2, :user => student)
      expect(Enrollment.by_student(student)).to eq([enrollment_2])
    end
  end

  describe '.transferred_or_dropped' do
    it 'returns all transferred or dropped enrollments' do
      e_1 = create(:enrollment, :state => 'transferred')
      e_2 = create(:enrollment, :state => 'dropped')
      e_3 = create(:enrollment, :state => 'enrolled')
      expect(Enrollment.transferred_or_dropped).to eq([e_1, e_2])
    end
  end

  describe '.sufficient_access' do
    it 'returns enrollments with access level true' do
      enrollment = create(:enrollment, :sufficient_access => true)
      expect(Enrollment.sufficient_access).to eq([enrollment ])
    end

    it 'does not return enrollments with access level false' do
      enrollment = create(:enrollment, :sufficient_access => false)
      expect(Enrollment.sufficient_access).to eq([])
    end
  end

  describe '.active' do
    it 'returns all active enrollments' do
      transferred_enrollment = create(:enrollment, :state => 'transferred')
      completed_enrollment = create(:enrollment, :state => 'marked_complete')
      dropped_enrollment = create(:enrollment, :state => 'dropped')
      active_enrollment = create(:enrollment, :state => 'enrolled')
      expect(Enrollment.active).to eq([active_enrollment])
    end
  end

  describe '.active_or_completed' do
    it 'returns all active or completed enrollments' do
      transferred_enrollment = create(:enrollment, :state => 'transferred')
      completed_enrollment = create(:enrollment, :state => 'marked_complete')
      dropped_enrollment = create(:enrollment, :state => 'dropped')
      active_enrollment = create(:enrollment, :state => 'enrolled')
      expect(Enrollment.active_or_completed).to match_array([active_enrollment, completed_enrollment])
    end
  end

  describe '.in_open_course' do
    let (:user) { create(:student) }
    let (:school) { build_stubbed(:school) }
    let (:owner) { build_stubbed(:instructor) }
    let (:program) { build_stubbed(:program) }

    it 'returns enrollments in unarchived sections and courses with end dates after today' do
      course = create(:open_course, :school => school, :owner => owner, :program => program)
      open_course_section = create(:section, :course => course)
      open_enrollment = create(:enrollment, :user => user, :section => open_course_section)
      expect(Enrollment.in_open_course).to eq([open_enrollment])
    end

    it 'returns enrollments in courses that end today' do
      course = create(:course, :school => school, :owner => owner, :program => program, :end_date => Date.today)
      open_course_section = create(:section, :course => course)
      open_enrollment = create(:enrollment, :user => user, :section => open_course_section)
      expect(Enrollment.in_open_course).to eq([open_enrollment])
    end

    it 'does not return enrollments in sections in courses with end dates of yesterday or earlier' do
      course = create(:closed_course, :school => school, :owner => owner, :program => program, :end_date => Date.yesterday)
      closed_course_section = create(:section, :course => course)
      closed_course_enrollment = create(:enrollment, :user => user, :section => closed_course_section)
      expect(Enrollment.in_open_course).not_to include [closed_course_enrollment]
    end

    it 'does not return enrollments in sections in archived courses' do
      course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)
      expect(Enrollment.in_open_course).not_to include [archived_course_enrollment]
    end

    it 'does not return enrollments in archived sections' do
      course = create(:open_course, :school => school, :owner => owner, :program => program)
      archived_section = create(:section, :course => course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)
      expect(Enrollment.in_open_course).not_to include [archived_section_enrollment]
    end

    it 'returns enrollments in courses on the ending date in terms of the user time zone' do
      # Use Time.now - 1.day to set end date regardless of time zone (Date.yesterday considers time zone)
      # this test has an expectation that the base time zone is Eastern
      # we'll specify it here so the test will pass when run in say, Brazil
      Time.use_zone('Eastern Time (US & Canada)') do
        Timecop.travel(Time.zone.now.change(hour: 4, min: 0, sec: 0)) do
          course_1 = create(
            :course,
            school:,
            owner:,
            program:,
            end_date: 1.day.ago,
            allow_past_end_date: true
          )
          open_course_section = create(:section, course: course_1)
          open_enrollment = create(:enrollment, user:, section: open_course_section)
          course_2 = create(
            :course,
            school:,
            owner:,
            program:,
            end_date: 2.days.ago,
            allow_past_end_date: true
          )
          closed_course_section = create(:section, course: course_2)
          closed_enrollment = create(:enrollment, user:, section: closed_course_section)

          Time.use_zone('Alaska') do
            # Alaska - courses just ended at midnight
            expect(Enrollment.in_open_course.to_a).to eq([])
          end
          Time.use_zone(5.hours) do
            expect(Enrollment.in_open_course.to_a).to eq([])
          end
          Time.use_zone(-11.hours) do
            expect(Enrollment.in_open_course.to_a).to eq([open_enrollment])
          end
        end
      end
    end
  end

  describe '.in_editable_course' do
    let (:user) { create(:student) }
    let (:school) { build_stubbed(:school) }
    let (:owner) { build_stubbed(:instructor) }
    let (:program) { build_stubbed(:program) }

    it 'returns enrollments in unarchived sections and courses with end dates up to a month ago' do
      course = create(:editable_course, :school => school, :owner => owner, :program => program)
      editable_course_section = create(:section, :course => course)
      editable_enrollment = create(:enrollment, :user => user, :section => editable_course_section)
      expect(Enrollment.in_editable_course).to eq([editable_enrollment])
    end

    it 'does not return enrollments in sections in courses with end dates greater than a month ago' do
      course = create(:closed_course, :school => school, :owner => owner, :program => program, :end_date => Date.yesterday)
      closed_course_section = create(:section, :course => course)
      closed_course_enrollment = create(:enrollment, :user => user, :section => closed_course_section)
      expect(Enrollment.in_editable_course).not_to include [closed_course_enrollment]
    end

    it 'does not return enrollments in sections in archived courses' do
      course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)
      expect(Enrollment.in_editable_course).not_to include [archived_course_enrollment]
    end

    it 'does not return enrollments in archived sections' do
      course = create(:editable_course, :school => school, :owner => owner, :program => program)
      archived_section = create(:section, :course => course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)
      expect(Enrollment.in_editable_course).not_to include [archived_section_enrollment]
    end
  end


  describe '.active_in_open_course' do
    it 'returns only active enrollments in unarchived sections and courses with end dates in the future' do
      user = create(:student)
      school = build_stubbed(:school)
      owner = build_stubbed(:instructor)
      program = build_stubbed(:program)

      open_course = create(:open_course, :school => school, :owner => owner, :program => program)
      open_course_section = create(:section, :course => open_course)
      open_active_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'enrolled')

      closed_course = create(:closed_course, :school => school, :owner => owner, :program => program)
      closed_course_section = create(:section, :course => closed_course)
      closed_course_enrollment = create(:enrollment, :user => user, :section => closed_course_section)

      archived_course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => archived_course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)

      archived_section = create(:section, :course => open_course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)

      open_transferred_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'transferred')
      open_completed_enrollment = create(:enrollment, :section => open_course_section, :state => 'marked_complete')
      open_dropped_enrollment = create(:enrollment, :section => open_course_section, :state => 'dropped')

      expect(Enrollment.active_in_open_course).to eq([open_active_enrollment])
    end
  end

  describe '.active_in_editable_course' do
    let(:editable_course) { create(:editable_course) }
    let(:editable_section) { create(:section, :course => editable_course) }
    let(:closed_course) { create(:closed_course) }
    let(:closed_section) { create(:section, :course => closed_course) }
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:student_3) { create(:student) }

    it 'returns enrollments in courses that have closed up to a month ago' do
      enrollment_1 = create(:enrollment, :section => editable_section, :user => student_1)
      enrollment_2 = create(:dropped_enrollment, :section => editable_section, :user => student_2)
      enrollment_3 = create(:enrollment, :section => closed_section, :user => student_3)
      expect(Enrollment.active_in_editable_course).to eq([enrollment_1])
    end

    it 'returns active and complete enrollments' do
      enrollment_1 = create(:enrollment, :section => editable_section, :user => student_1)
      enrollment_2 = create(:dropped_enrollment, :section => editable_section, :user => student_2)
      enrollment_3 = create(:completed_enrollment, :section => editable_section, :user => student_3)
      expect(Enrollment.active_in_editable_course).to eq([enrollment_1, enrollment_3])
    end
  end

  describe '.active_or_completed_in_open_course' do
    it 'returns only active or completed enrollments in unarchived sections and courses with end dates in the future' do
      user = create(:student)
      school = build_stubbed(:school)
      owner = build_stubbed(:instructor)
      program = build_stubbed(:program)

      open_course = create(:open_course, :school => school, :owner => owner, :program => program)
      open_course_section = create(:section, :course => open_course)
      open_active_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'enrolled')

      closed_course = create(:closed_course, :school => school, :owner => owner, :program => program)
      closed_course_section = create(:section, :course => closed_course)
      closed_course_enrollment = create(:enrollment, :user => user, :section => closed_course_section)

      archived_course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => archived_course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)

      archived_section = create(:section, :course => open_course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)

      open_transferred_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'transferred')
      open_completed_enrollment = create(:enrollment, :section => open_course_section, :state => 'marked_complete')
      open_dropped_enrollment = create(:enrollment, :section => open_course_section, :state => 'dropped')

      expect(Enrollment.active_or_completed_in_open_course).to match_array([open_active_enrollment, open_completed_enrollment])
    end
  end

  describe '.active_or_completed_in_open_course_by_section' do
    it 'returns only the active and completed enrollments in the sections specified' do
      user = create(:student)
      school = build_stubbed(:school)
      owner = build_stubbed(:instructor)
      program = build_stubbed(:program)

      open_course = create(:open_course, :school => school, :owner => owner, :program => program)
      open_course_section = create(:section, :course => open_course)
      open_active_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'enrolled')

      closed_course = create(:closed_course, :school => school, :owner => owner, :program => program)
      closed_course_section = create(:section, :course => closed_course)
      closed_course_enrollment = create(:enrollment, :user => user, :section => closed_course_section)

      archived_course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => archived_course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)

      archived_section = create(:section, :course => open_course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)

      open_transferred_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'transferred')
      open_completed_enrollment = create(:enrollment, :section => open_course_section, :state => 'marked_complete')
      open_dropped_enrollment = create(:enrollment, :section => open_course_section, :state => 'dropped')

      other_section = create(:section, :course => open_course)
      other_section_active_enrollment = create(:enrollment, :user => user, :section => other_section, :state => 'enrolled')
      other_section_completed_enrollment = create(:enrollment, :user => user, :section => other_section, :state => 'marked_complete')

      results = Enrollment.active_or_completed_in_open_course_by_section([open_course_section])
      expect(results).to match_array([open_active_enrollment, open_completed_enrollment])
    end
  end

  describe '.active_or_completed_in_editable_course_by_section' do
    it 'returns only the active and completed enrollments in the sections specified' do
      user = create(:student)
      school = build_stubbed(:school)
      owner = build_stubbed(:instructor)
      program = build_stubbed(:program)

      open_course = create(:open_course, :school => school, :owner => owner, :program => program)
      open_course_section = create(:section, :course => open_course)
      open_active_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'enrolled')

      editable_course = create(:editable_course, :school => school, :owner => owner, :program => program)
      editable_course_section = create(:section, :course => editable_course)
      editable_course_enrollment = create(:enrollment, :user => user, :section => editable_course_section)

      archived_course = create(:archived_course, :school => school, :owner => owner, :program => program)
      archived_course_section = create(:section, :course => archived_course)
      archived_course_enrollment = create(:enrollment, :user => user, :section => archived_course_section)

      archived_section = create(:section, :course => open_course, :is_archived => true)
      archived_section_enrollment = create(:enrollment, :user => user, :section => archived_section)

      open_transferred_enrollment = create(:enrollment, :user => user, :section => open_course_section, :state => 'transferred')
      open_completed_enrollment = create(:enrollment, :section => open_course_section, :state => 'marked_complete')
      open_dropped_enrollment = create(:enrollment, :section => open_course_section, :state => 'dropped')

      other_section = create(:section, :course => open_course)
      other_section_active_enrollment = create(:enrollment, :user => user, :section => other_section, :state => 'enrolled')
      other_section_completed_enrollment = create(:enrollment, :user => user, :section => other_section, :state => 'marked_complete')

      results = Enrollment.active_or_completed_in_editable_course_by_section([open_course_section, editable_course_section])
      expect(results).to match_array([open_active_enrollment, open_completed_enrollment, editable_course_enrollment])
    end
  end

  it_behaves_like 'a model with enterprise section validation' do
    subject(:model) { build_stubbed(:enrollment, section:) }
  end

  it "should expose its inactive attribute" do
    enrollment = create(:enrollment, :section =>
                                  create(:section , :course => create(:course)))
    allow(enrollment.section.course).to receive(:program_id).and_return(1)
    enrollment.inactive = true
    expect(enrollment.inactive).to be_truthy
  end

  it "validates the the user is a student" do
    expect(build(:enrollment, :user => build_stubbed(:student))).to be_valid
    expect(build(:enrollment, :user => build_stubbed(:instructor))).not_to be_valid
  end

  it "should validate that state is set to an accepted value" do
    expect(build(:enrollment, :state => 'enrolled')).to be_valid
    expect(build(:enrollment, :state => 'marked_complete')).to be_valid
    expect(build(:enrollment, :state => 'dropped')).to be_valid
    expect(build(:enrollment, :state => 'transferred')).to be_valid
    expect(build(:enrollment, :state => 'bad_value')).not_to be_valid
  end

  describe "#active?" do
    it "should be false if section is in an archived course" do
      school = build_stubbed(:school)
      program = build_stubbed(:program)
      instructor = build_stubbed(:instructor)
      course = create(:course, :is_archived => true, :school => school, :program => program, :owner => instructor)
      section = create(:section, :course => course )
      enrollment = build(:enrollment, :state => 'enrolled', :section => section)
      expect(enrollment).not_to be_active
    end

    it "should be false if section is archived" do
      section = create(:section_with_course, :is_archived => true)
      enrollment = build(:enrollment, :state => 'enrolled', :section => section)
      expect(enrollment).not_to be_active
    end

    context "when state is enrolled," do
      it "should be false if section is closed" do
        section = create(:section_in_closed_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).not_to be_active
      end

      it "should be true if section is not closed" do
        section = create(:section_in_open_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).to be_active
      end
    end

    it "should be false if state is dropped, marked_complete, or transferred" do
      expect(create(:transferred_enrollment)).not_to be_active
      expect(create(:completed_enrollment)).not_to be_active
      expect(create(:dropped_enrollment)).not_to be_active
    end
  end

  describe "#inactive?" do
    it "should be true if section is in an archived course" do
      section = create(:section, :course => create(:course, :is_archived => true) )
      enrollment = build(:enrollment, :state => 'enrolled', :section => section)
      expect(enrollment).to be_inactive
    end

    it "should be true if section is archived" do
      section = create(:section_with_course, :is_archived => true)
      enrollment = build(:enrollment, :state => 'enrolled', :section => section)
      expect(enrollment).to be_inactive
    end

    context "when state is enrolled," do
      it "should be true if section is closed" do
        section = create(:section_in_closed_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).to be_inactive
      end

      it "should be false if section is not closed" do
        section = create(:section_in_open_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).not_to be_inactive
      end
    end

    it "should be true if state is dropped, marked_complete, or transferred" do
      expect(create(:transferred_enrollment)).to be_inactive
      expect(create(:completed_enrollment)).to be_inactive
      expect(create(:dropped_enrollment)).to be_inactive
    end

  end

  describe "#complete?" do
    it "should be true if state is marked_complete" do
      expect(build(:completed_enrollment)).to be_complete
    end

    it "should be false if state is transferred or dropped" do
      expect(build(:transferred_enrollment)).not_to be_complete
      expect(build(:dropped_enrollment)).not_to be_complete
    end

    context "when state is enrolled," do
      it "should be true when section is closed" do
        section = create(:section_in_closed_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).to be_complete
      end
    end

    it "should be false when section is not closed" do
      section = create(:section_in_open_course)
      enrollment = build(:enrollment, :state => 'enrolled', :section => section)
      expect(enrollment).not_to be_complete
    end
  end

  describe "#dropped?" do
    it "should be true if state is dropped" do
      expect(build(:dropped_enrollment)).to be_dropped
    end

    it "should be false if state is not dropped" do
      expect(build(:active_enrollment)).not_to be_dropped
      expect(build(:completed_enrollment)).not_to be_dropped
      expect(build(:transferred_enrollment)).not_to be_dropped
    end
  end

  describe "#enrolled?" do
    it "should be true if state is enrolled" do
      expect(build(:active_enrollment)).to be_enrolled
    end

    it "should be false if state is not enrolled" do
      expect(build(:dropped_enrollment)).not_to be_enrolled
      expect(build(:completed_enrollment)).not_to be_enrolled
      expect(build(:transferred_enrollment)).not_to be_enrolled
    end
  end

  describe "#transferred?" do
    it "should be true if state is transferred" do
      expect(build(:transferred_enrollment)).to be_transferred
    end

    it "should be false if state is not transferred" do
      expect(build(:active_enrollment)).not_to be_transferred
      expect(build(:completed_enrollment)).not_to be_transferred
      expect(build(:dropped_enrollment)).not_to be_transferred
    end
  end

  describe "#undrop_student" do
    let(:student) { create(:student) }
    let(:section) { create(:section) }

    context 'when enrollment exists' do
      it "sets enrollment's state to enrolled" do
        create(:dropped_enrollment, user: student, section: section)
        enrollment = Enrollment.undrop_student(student.id, section)
        expect(enrollment.section_id).to eq section.id
        expect(enrollment.user_id).to eq student.id
        expect(enrollment).to be_enrolled
      end
    end

    context 'when enrollment does not exist' do
      it "returns nil" do
        expect(Enrollment.undrop_student(student.id, section)).to be_nil
      end
    end
  end

  describe "#drop_student" do
    let(:student) { create(:student) }
    let(:section) { create(:section) }

    context 'when enrollment exists' do
      it "sets enrollment's state to dropped" do
        create(:active_enrollment, user_id: student.id, section_id: section.id)
        enrollment = Enrollment.drop_student(student.id, section)
        expect(enrollment.section_id).to eq section.id
        expect(enrollment.user_id).to eq student.id
        expect(enrollment).to be_dropped
      end
    end

    context 'when enrollment does not exist' do
      it "returns nil" do
        expect(Enrollment.drop_student(student.id, section)).to be_nil
      end
    end

    context 'when there is a dropped enrollment that is newer than an undropped enrollment' do
      it 'drops the undropped enrollment' do
        create(:active_enrollment, user: student, section_id: section.id)
        create(:dropped_enrollment, user: student, section_id: section.id)
        Enrollment.drop_student(student.id, section)
        expect(Enrollment.where(state: 'dropped').size).to eq 2
      end
    end
  end

  describe  "#find_active_or_completed_by_user_id_and_section" do
    it "finds the lastest active or completed enrollment record for the student and section" do
      @section_1 = create(:section)
      @user_1 = create(:student)
      @enrollment_1 = create(:dropped_enrollment,:user => @user_1, :section => @section_1)
      @enrollment_2 = create(:active_enrollment,:user => @user_1, :section => @section_1)
      expect(Enrollment.find_active_or_completed_by_user_id_and_section(@user_1.id, [@section_1])).to eql(@enrollment_2)
    end
  end

  describe  "#find_by_user_id_and_section" do
    it "finds the lastest enrollment record for the student and section" do
      @section_1 = create(:section)
      @user_1 = create(:student)
      @enrollment_1 = create(:dropped_enrollment,:user => @user_1, :section => @section_1)
      @enrollment_2 = create(:active_enrollment,:user => @user_1, :section => @section_1)
      expect(Enrollment.find_by_user_id_and_section(@user_1.id, [@section_1])).to eq(@enrollment_2)
    end
  end

  describe  "#find_all_enrolled_by_users_and_sections" do
    it "should find enrollments for the users given" do
      @section_1 = create(:section)
      @section_2 = create(:section)
      @user_1 = create(:student)
      @user_2 = create(:student)
      @enrollment_1 = create(:dropped_enrollment, :user => @user_1, :section => @section_1)
      @enrollment_2 = create(:enrollment, :user => @user_1, :section => @section_2)
      @enrollment_3 = create(:transferred_enrollment, :user => @user_2, :section => @section_1)
      @enrollment_4 = create(:enrollment, :user => @user_2, :section => @section_2)
      expect(Enrollment.find_all_enrolled_by_users_and_sections([@user_1, @user_2], [@section_2])).to eq([@enrollment_2, @enrollment_4])
    end
  end

  describe  "#find_all_active_or_completed_by_users_and_sections" do
    it "should find enrollments for the users given" do
      section_1 = create(:section)
      section_2 = create(:section)
      user_1 = create(:student)
      user_2 = create(:student)
      user_3 = create(:student)
      enrollment_1 = create(:dropped_enrollment, :user => user_1, :section => section_1)
      enrollment_2 = create(:enrollment, :user => user_1, :section => section_2)
      enrollment_3 = create(:transferred_enrollment, :user => user_2, :section => section_1)
      enrollment_4 = create(:enrollment, :user => user_2, :section => section_2)
      enrollment_5 = create(:completed_enrollment, :user => user_3, :section => section_2)
      expect(Enrollment.find_all_active_or_completed_by_users_and_sections([user_1, user_2, user_3], [section_2])).to eq([enrollment_5, enrollment_4, enrollment_2])
    end
  end

  describe "#transfer" do
    it "should set the state to transferred" do
      enrollment = create(:enrollment)
      section_to = create(:section)
      expect(enrollment.state).not_to eq('transferred')
      enrollment.transfer(section_to)
      expect(enrollment.state).to eq('transferred')
    end
  end

  describe "#mark_complete" do
    it "should set the state to marked_complete" do
      enrollment = create(:enrollment)
      expect(enrollment.state).not_to eq('marked_complete')
      enrollment.mark_complete
      expect(enrollment.state).to eq('marked_complete')
    end
  end

  describe "#active?" do
    context "when state is enrolled," do
      it "should be false if section is closed" do
        section = create(:section_in_closed_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).not_to be_active
      end

      it "should be true if section is not closed" do
        section = create(:section_in_open_course)
        enrollment = build(:enrollment, :state => 'enrolled', :section => section)
        expect(enrollment).to be_active
      end
    end

    it "should be false if state is dropped, marked_complete, or transferred" do
      expect(build(:transferred_enrollment)).not_to be_active
      expect(build(:completed_enrollment)).not_to be_active
      expect(build(:dropped_enrollment)).not_to be_active
    end
  end

  describe "when creating enrollment" do
    it "should rebuild user programs for the user of that enrollment" do
      user = build_stubbed(:student)
      section = create(:section)
      create(:enrollment, :section => section, :user => user)
    end
  end

  describe "#program" do
    it "should return the program of the course for the enrolled section" do
      program = create(:program)
      course = create(:course , :program => program)
      section = create(:section , :course => course)
      enrollment = create(:enrollment, :section => section)
      expect(enrollment.program).to eq(program)
    end

    it "should return nil if course for the enrolled section is archived" do
      program = create(:program)
      course = create(:course , :program => program, :is_archived => true)
      section = create(:section , :course => course)
      allow(section).to receive(:program).and_return(nil)
      enrollment = create(:enrollment, :section => section)
      expect(enrollment.program).to be_nil
    end

    it "should return nil if the enrolled section is archived" do
      program = create(:program)
      course = create(:course , :program => program)
      section = create(:section , :course => course, :is_archived => true)
      enrollment = create(:enrollment, :section => section)
      expect(enrollment.program).to be_nil
    end
  end

  describe '.enroll_demo_students' do
    let(:student) { create(:student) }
    let(:section) { create(:section) }
    let(:enrollment) { create(:active_enrollment, :user => student, :section => section) }

    before do
      allow(Enrollment).to receive(:enroll)

      allow(enrollment).to receive(:unblock_access!)
      allow(Enrollment).to receive(:where).and_return([enrollment])
    end

    it 'enrolls specified students in the specified section' do
      expect(Enrollment).to receive(:enroll).with([student], section)
      Enrollment.enroll_demo_students([student], section)
    end

    it 'raises an error if no m3 enrollments get created' do
      allow(Rails.env).to receive(:live?).and_return(true)
      allow(Enrollment).to receive(:where).and_return([])
      expect{ Enrollment.enroll_demo_students([student], section) }.to raise_error('no m3 enrollments')
    end

    it 'raises an error if no active m3 enrollments get created' do
      allow(Rails.env).to receive(:live?).and_return(true)
      allow(Enrollment).to receive(:where).and_return([build_stubbed(:dropped_enrollment)])
      expect{ Enrollment.enroll_demo_students([student], section) }.to raise_error('no active m3 enrollments')
    end

    it 'unlocks the m3 enrollments that get created' do
      expect(enrollment).to receive(:unblock_access!)
      Enrollment.enroll_demo_students([student], section)
    end
  end

  describe ".enroll" do
    let(:enroller) { double('EnrollmentEngine::Enroller', errors: {}, warnings: {}) }
    let(:student) { create(:student) }
    let(:student2) { create(:student) }
    let(:student3) { create(:student) }
    let(:program) { create(:program) }
    let(:course) { create(:course, :program => program) }
    let(:section) { create(:section, :course => course) }
    let(:upgrade_response) do
      Maestro::EditionUpgrade.new(
        'upgraded_user_guids' => []
      )
    end

    before do
      allow(Maestro::EditionUpgrade).to receive(:grant_users).and_return upgrade_response
      allow(student).to receive(:sufficient_access_for_course?) { true }
      allow(student2).to receive(:sufficient_access_for_course?) { true }
      allow(EnrollmentEngine::Enroller).to receive(:new) { enroller }
      allow(enroller).to receive(:enroll) { enroller }
      allow(Ua::UserLogEntries).to receive(:create)
    end

    context '.grant_next_edition_access_to_users' do
      let(:upgrade_response) do
        Maestro::EditionUpgrade.new(
          'upgraded_user_guids' => [student.guid]
        )
      end
      it 'makes call to MaestroClient for all users' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student], section)
      end

      it 'makes call to MaestroClient for multiple successful users' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student, student2], section)
      end

      it 'makes call to MaestroClient for only successful users' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student, student2, student3], section)
      end

      it 'DOES make a call to MaestroClient as call comes before enroller.' do
        allow(enroller).to receive(:errors) { { base: ['uh-oh'] } }
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student], section)
      end

      context 'Ua::UserLogEntries' do
        it 'sends correct attributes to Ua::UserLogEntries.create' do
          expect(Ua::UserLogEntries).to receive(:create)
            .with(students_guids: [student.guid], section_guid: section.guid)

          Enrollment.enroll([student], section)
        end
      end
    end

    context '.grant_next_edition_access_to_users' do
      it 'makes call to MaestroClient for one successful user' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student], section)
      end

      it 'makes call to MaestroClient for multiple successful users' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student, student2], section)
      end

      it 'makes call to MaestroClient for only successful users' do
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student, student2, student3], section)
      end

      it 'DOES NOT make a call to MaestroClient for unsuccessful users' do
        allow(enroller).to receive(:errors) { { base: ['uh-oh'] } }
        expect(upgrade_response).to receive(:upgraded_user_guids)
        Enrollment.enroll([student], section)
      end
    end

    it 'uses EnrollmentEngine::Enroller to transfer students into the specified section' do
      expect(enroller).to receive(:enroll)
      Enrollment.enroll([student], section)
    end

    context 'given a successful transfer' do
      context "user has sufficient access to complete course" do
        it 'adds the student to the success array' do
          expected = { success: [student] }
          expect(Enrollment.enroll([student], section)).to eq expected
        end
      end

      context "user does not have sufficient access to complete course" do
        it 'adds the student to the success array' do
          allow(student).to receive(:sufficient_access_for_course?) { false }
          expected = { insufficient_access: [student] }
          expect(Enrollment.enroll([student], section)).to eq expected
        end
      end
    end

    context 'given an unsuccessful transfer' do
      it 'adds the student to the failure array' do
        allow(enroller).to receive(:errors) { { base: ['uh-oh'] } }
        expected = { failed: [student] }
        expect(Enrollment.enroll([student], section)).to eq expected
      end
    end
  end

  # Updates come from rostering subscription - lock_and_process_section_data is now an after_commit callback
  describe '.lock_and_process_section_data' do
    let(:user)    { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }

    context 'given a new enrollment' do

      context 'when there are errors on the enrollment' do
        it 'does not try to lock and process section data' do
          enrollment = Enrollment.new
          enrollment.user = user
          enrollment.section = section
          enrollment.state = 'fugue'
          expect(enrollment).not_to receive(:lock_and_process_section_data)
          enrollment.save
        end
      end

      context 'when there are no errors on the enrollment, and user and course are not demo' do
        it 'tries to lock and process section data' do
          enrollment = Enrollment.new
          enrollment.user = user
          enrollment.section = section
          enrollment.state = 'enrolled'
          expect(enrollment).to receive(:lock_and_process_section_data)
          enrollment.save
        end
      end
    end

    context 'given the enrollment has been updated' do
      let(:enrollment) { create(:enrollment) }

      before do
        allow(Enrollment).to receive(:find).and_return(enrollment)
      end

      it 'does not attempt to transfer section data' do
        expect(enrollment).not_to receive(:lock_and_process_section_data)
        enrollment.state = "transferred"
        enrollment.save
      end
    end
  end

  describe '#for_demo_purposes?' do
    it 'returns true when the user is fake and the section is in a demo course' do
      user = create(:student, :fake => true)
      course = create(:course, :is_demo => true)
      section = create(:section, :course => course)
      enrollment = create(:enrollment, :user => user, :section => section)
      expect(enrollment).to be_for_demo_purposes
    end

    it 'returns false when the user is not fake but the section is in a demo course' do
      user = create(:student)
      course = create(:course, :is_demo => true)
      section = create(:section, :course => course)
      enrollment = create(:enrollment, :user => user, :section => section)
      expect(enrollment).not_to be_for_demo_purposes
    end

    it 'returns false when the user is fake but the section is not in a demo course' do
      user = create(:student, :fake => true)
      course = create(:course)
      section = create(:section, :course => course)
      enrollment = create(:enrollment, :user => user, :section => section)
      expect(enrollment).not_to be_for_demo_purposes
    end
  end

  describe '#lockable?' do
    it 'returns true when the state is enrolled, there are no errors, and the enrollment is not for a demo' do
      enrollment = build_stubbed(:enrollment, :state => 'enrolled')
      expect(enrollment).to be_lockable
    end

    it 'returns false when the state is not enrolled' do
      enrollment = build_stubbed(:enrollment, :state => 'transferred')
      expect(enrollment).not_to be_lockable
    end

    it 'returns false then there are errors on the enrollments' do
      enrollment = build_stubbed(:enrollment)
      allow(enrollment).to receive(:errors).and_return(['foo'])
      expect(enrollment).not_to be_lockable
    end

    it 'returns false when the enrollment is for a demo' do
      enrollment = build_stubbed(:enrollment)
      allow(enrollment).to receive(:for_demo_purposes?).and_return(true)
      expect(enrollment).not_to be_lockable
    end
  end

  describe '#lock_and_process_section_data' do
    let(:student) { create(:student) }
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:section_from) { create(:section, course: course) }
    let(:section_to) { create(:section, course: course) }
    let!(:enrollment) do
      create(
        :active_enrollment,
        user: student,
        section: section_to,
        transferred_from: section_from.id
      )
    end
    let(:work_transfer_queue) { double('StudentWorkTransferWorker') }
    let(:announcement_creator_queue) { double('AnnouncementCreatorWorker') }

    before do
      allow(StudentWorkTransferWorker).to receive(:perform_async)
        .and_return(work_transfer_queue)
      allow(MissingAnnouncementCreatorWorker).to receive(:perform_async)
        .and_return(announcement_creator_queue)
      allow(section_to).to receive(:has_current_assignments?).and_return(false)
      create(:enrollment, user: student, section: section_from, state: 'transferred')
      allow(enrollment).to receive(:previous_section).and_return(section_from)
    end

    it 'adds the process method to the sidekiq queue' do
      enrollment.lock_and_process_section_data

      expect(StudentWorkTransferWorker).to have_received(:perform_async)
        .with(student.id, section_from.id, section_to.id)
    end

    context 'when the enrollment state is not lockable' do
      it 'does nothing' do
        allow(enrollment).to receive(:lockable?).and_return(false)
        enrollment.lock_and_process_section_data

        expect(enrollment.reload).not_to be_blocked
      end
    end

    context 'when the previous section was Section.section_zero' do
      it 'passes a zero as an argument to the transfer_work method and adds a job to the queue' do
        allow(enrollment).to receive(:previous_section).and_return(Section.section_zero)

        enrollment.lock_and_process_section_data

        expect(StudentWorkTransferWorker).to have_received(:perform_async)
          .with(student.id, 0, section_to.id)
      end
    end

    context "when the previous section is archived" do
      it "transfers the work from the archived section" do
        section_from.update!(is_archived: true)

        enrollment.lock_and_process_section_data

        expect(StudentWorkTransferWorker).to have_received(:perform_async)
          .with(student.id, section_from.id, section_to.id)
      end
    end

    it 'tells Announcement to create missing notifications' do
      enrollment.lock_and_process_section_data

      expect(MissingAnnouncementCreatorWorker).to have_received(:perform_async)
    end
  end

  describe "#previous_section" do
    let(:section) { create(:section)}
    let(:other_section) { create(:section)}

    it "returns the transferred section if the enrollment was transferred" do
      enrollment = create(:enrollment, :section => section, :transferred_from => other_section.id)
      expect(enrollment.previous_section).to eq(other_section)
    end

    it "returns section zero if the enrollment was dropped and re-enrolled " do
      enrollment = create(:enrollment, :section => section, :transferred_from => section.id)
      expect(enrollment.previous_section).to eq(Section.section_zero)
    end

    it "returns section zero if the enrollment was not transferred" do
      enrollment = create(:enrollment, :section => section)
      expect(enrollment.previous_section).to eq(Section.section_zero)
    end
  end

  describe 'validation of assign_related_objects' do
    let(:student)   { create(:student) }
    let(:course) { build_stubbed(:course) }
    let(:section)    { create(:section, course: course) }
    let(:another_section)    { create(:section, course: course) }
    let(:archived_section) { create(:section, course: course, :is_archived => true)}
    let(:archived_instructor) { create(:instructor, :archived =>true) }

    let(:valid_attrs) do { "section_guid" => section.guid,
                           "user_guid" => student.guid,
                           "transferred_from_guid" => another_section.guid,
                           "sync_token" => 1,
                           "request_id" => SecureRandom.uuid }
    end

    let(:archived_attrs) do { "section_guid" => section.guid,
                           "user_guid" => student.guid,
                           "transferred_from_guid" => archived_section.guid,
                           "section_transferred_to_guid" => archived_section.guid,
                           "added_by_guid" => archived_instructor.guid,
                           "dropped_by_guid" => archived_instructor.guid,
                           "sync_token" => 1,
                           "request_id" => SecureRandom.uuid }
    end


    it 'finds and sets related objects from guids' do
      enable_dangerfield do
        enrollment = Enrollment.new
        Enrollment.dangerfield_update_attributes(valid_attrs, enrollment)
        enrollment = Enrollment.last
        expect(enrollment.section.id).to eq(section.id)
        expect(enrollment.user.id).to eq(student.id)
        expect(enrollment.transferred_from).to eq(another_section.id)
      end
    end

    it 'finds and sets related objects from guids when some are rchived' do
      enable_dangerfield do
        enrollment = Enrollment.new
        Enrollment.dangerfield_update_attributes(archived_attrs, enrollment)
        enrollment = Enrollment.last
        expect(enrollment.section.id).to eq(section.id)
        expect(enrollment.user.id).to eq(student.id)
        expect(enrollment.transferred_from).to eq(archived_section.id)
        expect(enrollment.section_transferred_to).to eq(archived_section.id)
        expect(enrollment.added_by_id).to eq(archived_instructor.id)
        expect(enrollment.dropped_by_id).to eq(archived_instructor.id)
      end
    end
  end


  describe "dangerfield reject_if" do
    let(:user) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:course) { build_stubbed(:course) }
    let (:section) { create(:section, course: course, :instructor=> instructor)}
    let(:enrollment) { create(:enrollment, :user => user, :section => section) }
    let (:no_user_attrs) do { "sync_token"=> 1,
                               "request_id" => SecureRandom.uuid,
                               "blocked" => false,
                               "sufficient_access" => true,
                               "guid" => nil,
                               "section_guid" => "#{section.guid}",
                               "user_guid" => SecureRandom.uuid,
                               "state"=> 'enrolled',
                               "transferred_from_guid"=> nil,
                               "dropped_by_guid"=> nil
    }
    end

    let (:no_section_attrs) do { "sync_token"=> 1,
                                  "request_id" => SecureRandom.uuid,
                                  "blocked" => false,
                                  "sufficient_access" => true,
                                  "guid" => nil,
                                  "section_guid" => SecureRandom.uuid,
                                  "user_guid" => "#{user.guid}",
                                  "state"=> 'enrolled',
                                  "transferred_from_guid"=> nil,
                                  "dropped_by_guid"=> nil
    }
    end


    let (:valid_attrs) do { "sync_token"=> 1,
                                 "request_id" => SecureRandom.uuid,
                                 "blocked" => false,
                                 "sufficient_access" => true,
                                 "guid" => nil,
                                 "section_guid" => "#{section.guid}",
                                 "user_guid" => "#{user.guid}",
                                 "state"=> 'enrolled',
                                 "transferred_from_guid"=> nil,
                                 "dropped_by_guid"=> nil
    }
    end

    context 'no_user_or_no_section_added? returns false' do
      it 'is a new record and both user and section found so it gets added' do
        enable_dangerfield do
          new_enrollment = Enrollment.new
          Enrollment.dangerfield_update_attributes(valid_attrs, new_enrollment)
          expect(new_enrollment.guid).to_not be_nil
          expect(new_enrollment.sync_token).to eq(1)
        end
      end
    end

    context 'no_user_or_no_section_added? returns true' do
      it 'is a new record and user not found so it gets rejected' do
        enable_dangerfield do
          new_enrollment = Enrollment.new
          Enrollment.dangerfield_update_attributes(no_user_attrs, new_enrollment)
          expect(new_enrollment.guid).to be_nil
          expect(new_enrollment.sync_token).to eq(0)
        end
      end

      it 'is a new record and section is not found so it gets rejected' do
        enable_dangerfield do
          new_enrollment = Enrollment.new
          Enrollment.dangerfield_update_attributes(no_section_attrs, new_enrollment)
          expect(new_enrollment.guid).to be_nil
          expect(new_enrollment.sync_token).to eq(0)
        end
      end
    end
  end


  describe 'validate dangerfield_skip_save_if' do
    let(:valid_attrs) do
      {
        'blocked' => false,
        'guid' => SecureRandom.uuid,
        'request_id' => SecureRandom.uuid,
        'sufficient_access' => true,
        'sync_token' => enrollment.sync_token + 1,
        "section_guid" => enrollment.section.guid,
        "user_guid" => enrollment.user.guid
      }
    end

    context "when the enrollment's section is archived" do
      let(:enrollment) { create(:enrollment_in_archived_section, state: 'enrolled') }
      let(:archive_section_update_attrs) { valid_attrs.merge({ "state" => 'archived' }) }

      it 'does not update the record' do
        enable_dangerfield do
          Enrollment.dangerfield_update_attributes(archive_section_update_attrs, enrollment)
          expect(enrollment.state).to eq('enrolled')
        end
      end
    end

    context "when the enrollment's section is not archived" do
      let(:enrollment) { create(:enrollment, state: 'enrolled') }
      let(:archive_section_update_attrs) { valid_attrs.merge('state' => 'archived') }

      it 'updates the record' do
        enable_dangerfield do
          Enrollment.dangerfield_update_attributes(archive_section_update_attrs, enrollment)
          expect(enrollment.state).to eq('archived')
        end
      end
    end
  end

  context 'update_gradebook' do
    context 'after commit' do
      let(:enrollment) { create(:enrollment) }
      let(:section) { create(:section) }
      let(:user) { create(:student) }

      it 'triggers update_gradebook in after_commit' do
        enrollment.state = 'marked_complete'
        expect(enrollment).to receive(:update_gradebook)
        enrollment.save
      end

      it 'triggers notify_update when enrollment is created' do
        new_enrollment = Enrollment.new
        new_enrollment.section = section
        new_enrollment.user = user
        new_enrollment.state = 'enrolled'
        expect(new_enrollment).to receive(:notify_update)
        new_enrollment.save
      end

      it 'triggers notify_deletion for a dropped enrollment' do
        new_enrollment = Enrollment.new
        new_enrollment.section = section
        new_enrollment.user = user
        new_enrollment.state = 'enrolled'
        new_enrollment.state = 'dropped'
        expect(new_enrollment).to receive(:notify_deletion)
        new_enrollment.save
      end

      it 'triggers notify_deletion for a transferred enrollment' do
        new_enrollment = Enrollment.new
        new_enrollment.section = section
        new_enrollment.user = user
        new_enrollment.state = 'enrolled'
        new_enrollment.state = 'transferred'
        expect(new_enrollment).to receive(:notify_deletion)
        new_enrollment.save
      end

      it 'triggers notify_deletion for an archived enrollment' do
        new_enrollment = Enrollment.new
        new_enrollment.section = section
        new_enrollment.user = user
        new_enrollment.state = 'enrolled'
        new_enrollment.state = 'archived'
        expect(new_enrollment).to receive(:notify_deletion)
        new_enrollment.save
      end

      it 'triggers notify_deletion for a destroyed enrollment' do
        new_enrollment = Enrollment.new
        new_enrollment.section = section
        new_enrollment.user = user
        new_enrollment.state = 'enrolled'
        expect(new_enrollment).to receive(:notify_deletion)
        new_enrollment.save
        new_enrollment.destroy
      end
    end
  end
end


