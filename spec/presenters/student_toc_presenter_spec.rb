describe StudentTocPresenter do
  include Rails.application.routes.url_helpers

  let(:student) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program_with_lessons, id: 49) }
  let(:course) { build_stubbed(:course, program: program) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:lesson) { build_stubbed(:lesson_with_toc_entries) }
  let(:activities) { [instance_double(Activity)] }

  let(:presenter) do
    described_class.new(program, student, section, {}, nil, section.id)
  end

  before do
    allow(program).to receive(:best_display_lesson).and_return(lesson)
    allow(lesson).to receive(:program).and_return(program)
    allow(section).to receive(:program).and_return(program)
    allow(section).to receive(:units).and_return([])
    allow(presenter).to receive(:activities).and_return(activities)
  end

  describe '.new' do
    it 'inits current_user' do
      expect(
        described_class.new(program, 'student', nil, {}, nil, '0').current_user
      ).to eq('student')
    end

    it 'inits program' do
      expect(
        described_class.new(program, 'student', nil, {}, nil, '0').program
      ).to eq(program)
    end

    it 'inits current section_id' do
      expect(
        described_class.new(program, 'student', nil, {}, nil, '0').section_id
      ).to eq('0')
    end

    context 'when initializing school' do
      it 'inits school if section is present and has a course' do
        expect(
          described_class.new(program, 'student', section, {}, nil, section.id).school
        ).to eq(section.school)
      end

      it 'does not init school if section is present and has no course' do
        allow(section).to receive(:course).and_return(nil)
        expect(
          described_class.new(program, 'student', section, {}, nil, section.id).school
        ).to be_nil
      end

      it 'does not init school if section is not present' do
        expect(
          described_class.new(program, 'student', nil, {}, nil, section.id).school
        ).to be_nil
      end
    end

    it 'raises an error when valid params are not passed' do
      expect do
        described_class.new(nil, 'student', nil, {}, nil, '0')
      end.to raise_error ArgumentError
      expect do
        described_class.new('program', 'student', nil, {}, nil, nil)
      end.to raise_error ArgumentError
      expect do
        described_class.new('program', 'student', nil, nil, nil, '0')
      end.to raise_error ArgumentError
      expect do
        described_class.new('program', nil, nil, {}, nil, '0')
      end.to raise_error ArgumentError
    end
  end

  describe '#assignments' do
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:student) { create(:student) }

    before do
      allow(presenter).to receive(:activities).and_return([activity])
    end

    it 'returns assignments for the currently visible activities if ' \
       'the assignments are assigned to all students' do
      assignment = create(
        :assignment,
        assignable: activity,
        individually_assignable: false,
        section: section
      )

      expect(presenter.assignments).to contain_exactly(assignment)
    end

    it 'returns assignments for the currently visible activities if ' \
       'the assignments are individually assigned to the current student' do
      assignment = create(
        :assignment,
        assignable: activity,
        individually_assignable: true,
        section: section
      )
      IndividualAssignment.create!(
        activity_id: activity.id,
        section_id: section.id,
        user_id: student.id
      )

      expect(presenter.assignments).to contain_exactly(assignment)
    end

    it 'does not return assignments for the currently visible activities if ' \
       'the assignments are not individually assigned to the current student' do
      create(
        :assignment,
        assignable: activity,
        individually_assignable: true,
        section: section
      )

      expect(presenter.assignments).to eq([])
    end
  end

  describe "#base_url" do
    it "returns section toc url" do
      expect(presenter.base_url).to eq(section_toc_path(section, program, {}))
    end

    it "appends option to the url" do
      options = {:all_units => true }
      expect(presenter.base_url(options)).to eq(section_toc_path(section, program, options))
    end
  end

  describe "#attempt_status" do
    it "retrives activity status from attempts" do
      expect(Attempt).to receive(:status_for_activities).with(student, [section], activities)
      presenter.attempt_status
    end
  end

  describe '#has_note?' do
    let(:activity) { build_stubbed(:activity) }

    before  do
      allow(presenter).to receive(:activities).and_return([activity])
    end

    context 'when student is not enrolled in a course' do
      it 'returns false' do
        presenter = StudentTocPresenter.new(program, student, nil, {}, nil, section.id)
        expect(presenter.has_note?(activity)).to be_falsey
      end
    end

    context 'when section course is not available (i.e. archived)' do
      it 'returns false' do
        allow(section).to receive(:course).and_return(nil)
        presenter = StudentTocPresenter.new(program, student, section, {}, nil, section.id)
        expect(presenter.has_note?(activity)).to be_falsey
      end
    end

    it 'extends section functionality' do
      presenter.has_note?(activity)
      expect(section).to be_a StudentActivityPresenter::ActivityNotesSection
    end

    it 'returns true when given activity has at least one instructor note' do
      instructor_note = build_stubbed(:activity_note, activity: activity)
      allow(ActivityNote).to receive_message_chain(:where, :group_by)
        .and_return(activity.id => [instructor_note])

      expect(presenter.has_note?(activity)).to be_truthy
    end

    it 'returns false when given activity does not have any instructor notes' do
      expect(presenter.has_note?(activity)).to be_falsey
    end
  end

  describe '#grade_for' do
    let(:activity_456) { instance_double(Activity, id: 456) }

    let(:grade_123) do
      instance_double(GradebookEngine::ScoreAction, activity_id: 123)
    end

    let(:grade_456) do
      instance_double(GradebookEngine::ScoreAction, activity_id: 456)
    end

    before do
      allow(GradebookEngine::GradebookAPI).to receive(:user_strand_grades)
        .and_return(123 => grade_123, 456 => grade_456)
    end

    it 'returns the grade for a given activity when a grade exists' do
      expect(presenter.grade_for(activity_456)).to eq grade_456
    end

    it 'returns nil when no grade exists for a given activity,' do
      activity_789 = instance_double(Activity, id: 789)
      expect(presenter.grade_for(activity_789)).to be_nil
    end
  end
end
