describe CourseLibraryEditPolicy do
  def assign_instructor(user, section, role, extra_args = {})
    create(
      :section_instructor,
      {
        instructor: user,
        role: SectionInstructor::INSTRUCTOR_ROLES[role],
        section: section
      }.merge(extra_args)
    )
  end

  let(:owner) { create(:instructor) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: owner) }
  let(:current_focus) { instance_double(Focus, course: course) }
  let(:section_1) { create(:section, course: course, instructor: owner) }
  let(:section_2) { create(:section, course: course, instructor: owner) }

  let(:policy) do
    described_class.new(instructor, current_focus)
  end

  before do
    allow(current_focus).to receive(:focused?).and_return(true)
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because be_can_edit doesn't make sense.
  describe '#can_edit?' do
    it 'is true when the specified instructor is the course owner' do
      expect(described_class.new(owner, current_focus).can_edit?).to be_truthy
    end

    it 'is false if the focus is on a section and not the course' do
      allow(current_focus).to receive(:focused_on_course?).and_return(false)
      expect(policy.can_edit?).to be_falsey
    end

    it 'is true if the specified instructor is a co-instructor in all sections' do
      assign_instructor(instructor, section_1, :co_instructor)
      assign_instructor(instructor, section_2, :co_instructor)

      expect(policy.can_edit?).to be_truthy
    end

    it 'is true if the specified instructor is a co-instructor for any section' do
      assign_instructor(instructor, section_1, :co_instructor)

      expect(policy.can_edit?).to be_truthy
    end

    it 'is false if the specified instructor is an assistant for all sections' do
      assign_instructor(instructor, section_1, :assistant)
      assign_instructor(instructor, section_2, :assistant)

      expect(policy.can_edit?).to be_falsey
    end

    it 'is true when the specified instructor is a co-instructor for one ' \
       'section and an assitant for another section' do
      assign_instructor(instructor, section_1, :assistant)
      assign_instructor(instructor, section_2, :co_instructor)

      expect(policy.can_edit?).to be_truthy
    end

    it 'is false if the specified instructor is a co-instructor but the ' \
       'section instructor records are archived' do
      assign_instructor(instructor, section_1, :co_instructor, is_archived: 1)
      assign_instructor(instructor, section_2, :co_instructor, is_archived: 1)

      expect(policy.can_edit?).to be_falsey
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because be_can_edit_activity doesn't make sense.
  describe 'can_edit_activity?' do
    let(:owner_policy) do
      described_class.new(owner, current_focus)
    end

    context 'when the course owner is the author of the specified activity,' do
      let(:activity) do
        build(:instructor_created_activity, instructor_id: owner.id)
      end

      it 'is false if the course is closed' do
        course.update!(start_date: 60.days.ago, end_date: 31.days.ago, allow_past_end_date: true)

        expect(owner_policy.can_edit_activity?(activity)).to be_falsey
      end

      it 'is false if a co-instructor who is not the author is specified' do
        assign_instructor(instructor, section_1, :co_instructor)

        expect(policy.can_edit_activity?(activity)).to be_falsey
      end

      it 'is true if the course is not closed' do
        expect(owner_policy.can_edit_activity?(activity)).to be_truthy
      end
    end

    context 'when the author of the activity is not the course owner,' do
      let(:activity) do
        build(:instructor_created_activity, instructor_id: instructor.id)
      end

      it 'is false if the specified instructor is not the author of the ' \
         'activity even if they are the course owner' do
        expect(owner_policy.can_edit_activity?(activity)).to be_falsey
      end

      it 'is false if the instructor is not a co-instructor on any section' do
        assign_instructor(instructor, section_1, :assistant)

        expect(policy.can_edit_activity?(activity)).to be_falsey
      end

      it 'is false if the instructor is a co-instructor on any section but ' \
         'the course is closed' do
        assign_instructor(instructor, section_1, :co_instructor)
        course.update!(start_date: 60.days.ago, end_date: 31.days.ago, allow_past_end_date: true)

        expect(policy.can_edit_activity?(activity)).to be_falsey
      end

      it 'is true if the instructor is a co-instructor on any section and ' \
         'the course is not closed' do
        assign_instructor(instructor, section_1, :co_instructor)

        expect(policy.can_edit_activity?(activity)).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher
end
