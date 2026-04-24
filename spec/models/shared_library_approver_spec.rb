describe SharedLibraryApprover do
  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:user) { create(:instructor) }
  let(:allow_copy) { false }
  let(:unit) { create(:unit, program: program) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }

  let(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson: lesson,
      program: program
    )
  end

  let(:content_json) do
    File.read(
      File.join(
        'spec',
        'fixtures',
        'json',
        'multiple_choice_alternating_references_and_questions.json'
      )
    )
  end

  let(:source_activity) do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [Maestro::LicenseGroup.new('name' => '01-Supersite')]
    )
    create(
      :instructor_created_activity,
      concept: concept,
      content_json: content_json,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  let(:attrs) do
    {
      activity_id: source_activity.id,
      allow_copy: allow_copy,
      school_id: school.id
    }
  end

  let!(:other_school_library_entry) do
    create(
      :shared_library_activity,
      allow_copy: false,
      is_shared: false,
      school_id: create(:school).id,
      source_activity_id: source_activity.id
    )
  end

  let!(:library_entry) do
    create(
      :shared_library_activity,
      allow_copy: false,
      is_shared: false,
      school_id: school.id,
      source_activity_id: source_activity.id
    )
  end

  let(:activity_copy) do
    create(
      :instructor_created_activity,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  let(:approver) { described_class.new(attrs, user) }

  describe '#approve' do
    before do
      allow(InstructorCreatedActivityForCopy).to receive(:copy)
        .and_return(activity_copy)
      allow(SharedLibraryActivity).to receive(
        :assign_activity_copy_id_and_approver
      )
    end

    it 'does not mark the shared library entries for different schools ' \
       'as shared (approved)' do
      approver.approve

      expect(other_school_library_entry.reload.is_shared).to eq(false)
    end

    it 'marks the shared library entry as shared (approved)' do
      approver.approve

      expect(library_entry.reload.is_shared).to eq(true)
    end

    context 'when allow_copy attr is set to false,' do
      let(:allow_copy) { false }

      it 'leaves the allow_copy attr of the library entry set to false' do
        approver.approve

        expect(library_entry.reload.allow_copy).to eq(false)
      end
    end

    context 'when allow_copy attr is set to true,' do
      let(:allow_copy) { true }

      it 'sets the allow_copy attr of the library entry to true' do
        approver.approve

        expect(library_entry.reload.allow_copy).to eq(true)
      end
    end

    context 'when allow_copy attr is not set,' do
      let(:allow_copy) { nil }

      it 'sets the allow_copy attr of the library entry to true' do
        approver.approve

        expect(library_entry.reload.allow_copy).to eq(true)
      end
    end

    it 'assigns the activity copy id and approver' do
      approver.approve
      activity_copy_id = InstructorCreatedActivity.last.id

      expect(SharedLibraryActivity).to have_received(
        :assign_activity_copy_id_and_approver
      ).with(
        source_activity.id,
        activity_copy_id,
        school.id,
        user.id
      )
    end

    it 'creates a copy of the activity, owned by the current user, when ' \
       'the activity is not an assessement' do
      approver.approve

      expect(InstructorCreatedActivityForCopy).to have_received(:copy).with(
        user.id, source_activity
      )
    end

    it 'creates a copy of the activity, owned by the current user, when ' \
       'the activity is an assessement' do
      concept.update!(assessment: true)

      approver.approve

      activity_copy = InstructorCreatedActivity.where(
        ['id <> ?', source_activity.id]
      ).last

      expect(activity_copy).to have_attributes(
        instructor_id: user.id,
        title: "Copy of #{source_activity.title}"
      )
    end

    it 'adds a hidden CourseLibraryActivity record for the activity copy ' \
       'in each open course in the same school and program that is managed ' \
       'by course templates' do
      template_course = create(:course)

      create(
        :course,
        program: program,
        school: create(:school),
        source_template_id: template_course.id
      )

      create(
        :closed_course,
        program: program,
        school: school,
        source_template_id: template_course.id
      )

      create(
        :course,
        program: program,
        school: school,
        source_template_id: nil
      )

      create(
        :course,
        program: create(:program),
        school: school,
        source_template_id: template_course.id
      )

      valid_course = create(
        :course,
        program: program,
        school: school,
        source_template_id: template_course.id
      )

      approver.approve

      results = CourseLibraryActivity.where(activity_id: activity_copy.id)

      expect(results.map { |entry| [entry.course_id, entry.hidden] }).to eq(
        [[valid_course.id, true]]
      )
    end
  end

  describe '#approved_activity_title' do
    it 'strips tags and decodes html entities in the source activity title' do
      source_activity.update!(title: '<b>A &amp; B</b>')

      expect(approver.approved_activity_title).to eq('A & B')
    end
  end
end
