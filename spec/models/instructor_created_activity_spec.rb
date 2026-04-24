describe InstructorCreatedActivity do
  let(:instructor_content_klass) do
    MaestroActivityEngine::InstructorCreatedContent
  end
  let(:mock_content) { instance_double(instructor_content_klass) }
  let(:strand) { create(:toc_entry) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }

  let!(:concept) do
    create(:concept, lesson: lesson, program: program, id: strand.location)
  end

  let(:mock_content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::CompositionContent,
      activity_type: 'composition',
      content_summary: { question_1: 1 },
      grading_method: 'instructor_graded',
      has_rubric?: false,
      chat_activity?: false,
      composition_activity?: false,
      video_activity?: false,
      recording_activity?: false,
      has_video_recording?: false,
      has_audio_recording?: false,
      max_attempts: 2,
      points_possible: 10,
      submittable?: true,
      randomizable?: true
    )
  end

  let(:svr_content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::SoloVideoRecordingContent,
      activity_type: 'solo_video_recording',
      has_rubric?: false,
      chat_activity?: false,
      composition_activity?: false,
      video_activity?: false,
      recording_activity?: false,
      has_video_recording?: false,
      has_audio_recording?: false,
    )
  end

  let(:instructor) { create(:instructor) }
  let(:other_instructor) { create(:instructor) }

  let(:activity) do
    described_class.new(
      instructor_id: instructor.id,
      lesson: lesson,
      title: 'foo',
      toc_entry_id: strand.location,
      randomizable: false
    )
  end

  let(:activity_for_other_instructor) do
    described_class.new(
      instructor_id: other_instructor.id,
      lesson: lesson,
      title: 'foo',
      toc_entry_id: strand.location,
      randomizable: false
    )
  end

  let(:svr_activity) { create(:solo_video_recording_activity) }

  let(:references_params) do
    [{ body: 'b1', header: 'h1', type: 't1' },
     { body: 'b2', header: 'h2', type: 't2' }]
  end

  before do
    allow(activity_for_other_instructor).to receive(:content_object).and_return(mock_content_object)
    allow(instructor_content_klass).to receive(:new).and_return(mock_content)
    allow(mock_content).to receive(:generate_xml).and_return('<xml />')
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )

    stub_request(:any, %r{https\://s3\.amazonaws\.com/vhlcentral\.activities/.*\.xml})
      .to_return(status: 200, body: '', headers: {})
  end

  describe '#all_courses' do
    let(:instructor) { create(:instructor) }
    let(:course_1) { create(:course) }
    let(:course_2) { create(:course) }
    let(:course_3) { create(:course) }
    let(:section_1) { create(:section, course: course_1, instructor:) }
    let(:section_2) { create(:section, course: course_2, instructor:) }
    let(:category) { create(:category) }
    let(:assignment_1) { create(:assignment, section: section_1) }
    let(:assignment_2) { create(:assignment, section: section_2) }
    let(:lesson) { create(:lesson) }
    let(:activity) { create(:instructor_created_activity, lesson:, instructor:) }

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup).to receive(:all).and_return([double(id: 1, name: 'Test License Group')])

      activity.assignments << assignment_1
      activity.assignments << assignment_2
      create(:course_library_activity, activity:, course: course_1)
      create(:course_library_activity, activity:, course: course_2)
    end

    describe '#all_courses' do
      it 'returns a unique list of all associated courses' do
        expect(activity.all_courses).to match_array([course_1, course_2])
      end

      it 'includes assignment_courses' do
        section_3 = create(:section, course: course_3, instructor:)
        assignment_3 = create(:assignment, section: section_3)
        activity.assignments << assignment_3

        expect(activity.all_courses).to match_array([course_1, course_2, course_3])
      end

      it 'removes duplicate courses from the list' do
        activity.assignments << assignment_1

        expect(activity.all_courses).to match_array([course_1, course_2])
      end

      it 'handles cases where no courses are associated' do
        new_activity = create(:instructor_created_activity, instructor:)
        expect(new_activity.all_courses).to be_empty
      end
    end
  end

  describe 'validations' do
    let(:activity_attrs) do
      { concept:, lesson:, toc_entry_id: strand.location }
    end

    it 'is not valid without a title' do
      activity.title = nil
      expect(activity).not_to be_valid
    end

    it 'is valid with a non-json activity' do
      activity = build(
        :instructor_created_activity,
        activity_attrs.merge(activity_type: 'composition')
      )

      expect(activity).to be_valid
    end

    it 'is valid with a non-fill-in-the-blanks json activity' do
      activity = build(
        :instructor_created_activity,
        activity_attrs.merge(activity_type: 'multiple_answer')
      )
      content_json = File.read(
        'spec/fixtures/json/multiple_answer_activity.json'
      )
      activity.content_json = content_json

      expect(activity).to be_valid
    end

    context 'with a fill-in-the-blanks activity' do
      let(:activity) do
        build(
          :instructor_created_activity,
          activity_attrs.merge(activity_type: 'fill_in_the_blanks')
        )
      end

      it 'is valid with JSON with no empty wols' do
        content_json = File.read('spec/fixtures/json/fill_in_the_blanks.json')
        activity.content_json = content_json

        expect(activity).to be_valid
      end

      it 'is not valid with JSON containing empty wols' do
        content_json = File.read(
          'spec/fixtures/json/fill_in_the_blanks_empty_wols.json'
        )
        activity.content_json = content_json

        activity.valid?

        expect(activity.errors[:base]).to eq(
          ['There is an error with the fill-in-the-blanks values.']
        )
      end
    end

    context 'with an exam containing a fill-in-the-blanks activity' do
      let(:valid_content_json) do
        File.read('spec/fixtures/json/exam_with_fill_in_the_blanks.json')
      end

      let(:invalid_content_json) do
        File.read('spec/fixtures/json/exam_with_empty_wols.json')
      end

      let(:activity) do
        build(
          :instructor_created_activity,
          activity_attrs.merge(
            activity_type: 'exam', process_as_assessment: true
          )
        )
      end

      it 'is valid with JSON containing no empty wols' do
        activity.content_json = valid_content_json

        expect(activity).to be_valid
      end

      it 'is not valid with JSON containing empty wols' do
        activity.content_json = invalid_content_json

        activity.valid?

        expect(activity.errors[:base]).to eq(
          ['There is an error with the fill-in-the-blanks values.']
        )
      end

      it 'reverts to the last revision if the current revision has empty wols' do
        activity.content_json = valid_content_json
        activity.save!

        reloaded_activity = described_class.find(activity.id)
        reloaded_activity.update(content_json: invalid_content_json)

        expect(reloaded_activity.content_json).to eq(valid_content_json)
      end
    end
  end

  describe 'callbacks' do
    context 'when saving an activity,' do
      let(:json) { 'json' }
      let(:activity_attrs) do
        {
          concept: concept,
          lesson: lesson,
          toc_entry_id: strand.location
        }
      end

      let(:activity) do
        build(
          :instructor_created_activity_with_non_db_attrs,
          activity_attrs
        )
      end

      before do
        allow(activity.activity_content).to receive(:content_json).and_return(json)
        allow(activity).to receive(:content_object).and_return(mock_content_object)
        allow(activity).to receive(:assign_new_content_instance).and_return(mock_content)
        allow(activity.activity_content).to receive(:build_from_json)
          .and_return(mock_content).twice
        allow(activity).to receive(:set_denormalized_values)
        activity.save!
      end

      it 'creates a revision for it' do
        expect(activity.instructor_activity_revisions.count).to be_eql(1)
      end

      it 'creates a revision when saving a persisted activity ' do
        revision_id = activity.instructor_revision_id
        activity.save!
        expect(activity.reload.instructor_revision_id).not_to eq(revision_id)
      end

      it 'saves the revision with the generate_content of activity' do
        expect(activity.content_json).to eq(json)
      end

      context 'when the activity location changes,' do
        let(:closed_course) { create(:closed_course, owner: instructor) }
        let(:open_course) { create(:course, owner: instructor) }

        let(:closed_section) do
          create(:section, course: closed_course, instructor: instructor)
        end

        let(:open_section) do
          create(:section, course: open_course, instructor: instructor)
        end

        let(:other_instructor_section) do
          create(
            :section,
            course: create(:course, owner: other_instructor),
            instructor: other_instructor
          )
        end

        let!(:closed_course_assignment) do
          create(
            :assignment,
            assignable: activity,
            due_date: closed_course.end_date - 30.days,
            section: closed_section
          )
        end

        let!(:open_course_assignment) do
          create(:assignment, assignable: activity, section: open_section)
        end

        let!(:other_instructor_assignment) do
          create(
            :assignment,
            assignable: activity,
            section: other_instructor_section
          )
        end

        let(:gb_assignment_class) { GradebookEngine::Assignment }

        context 'when just the strand is changed,', new_gb_sync: true do
          let(:new_strand) { create(:toc_entry) }

          before do
            lesson.toc_entries = [strand, new_strand]
            lesson.save!

            create(
              :concept,
              lesson: lesson,
              program: program,
              id: new_strand.location
            )
            activity.update!(toc_location: new_strand.location)
          end

          it 'updates assignments for the edited activity in open courses' do
            [open_course_assignment, other_instructor_assignment].each do |assignment|
              gb_assignment = gb_assignment_class.find_by(
                activity_id: assignment.assignable_id,
                section_id: assignment.section_id
              )
              expect(gb_assignment.strand_id.to_s).to eq(new_strand.location)
            end
          end

          it 'does not update assignments for the edited activity in ' \
             'closed courses' do
            gb_assignment = gb_assignment_class.find_by(
              activity_id: closed_course_assignment.assignable_id,
              section_id: closed_course_assignment.section_id
            )
            expect(gb_assignment.strand_id.to_s).to eq(strand.location)
          end
        end

        context 'when the lesson is changed,', new_gb_sync: true do
          let(:new_strand) { create(:toc_entry) }
          let(:new_lesson) do
            create(:lesson, toc_entries: [new_strand], unit: unit)
          end

          before do
            create(
              :concept,
              lesson: new_lesson,
              program: program,
              id: new_strand.location
            )
            activity.update!(lesson: new_lesson, toc_location: new_strand.location)
          end

          it 'updates assignments for the edited activity in open courses' do
            [open_course_assignment, other_instructor_assignment].each do |assignment|
              gb_assignment = gb_assignment_class.find_by(
                activity_id: assignment.assignable_id,
                section_id: assignment.section_id
              )
              expect(gb_assignment).to have_attributes(
                lesson_id: new_lesson.id,
                strand_id: new_strand.location.to_i
              )
            end
          end

          it 'does not update assignments for the edited activity in ' \
             'closed courses' do
            gb_assignment = gb_assignment_class.find_by(
              activity_id: closed_course_assignment.assignable_id,
              section_id: closed_course_assignment.section_id
            )
            expect(gb_assignment).to have_attributes(
              lesson_id: lesson.id,
              strand_id: strand.location.to_i
            )
          end
        end
      end

      context 'when the activity has an associated custom_rubric record,' do
        let(:source_activity) { create(:activity) }
        let(:course) { create(:course, owner: instructor) }

        let!(:section_1) do
          create(:section, course: course, instructor: instructor)
        end

        let!(:section_2) do
          create(:section, course: course, instructor: instructor)
        end

        let(:activity_attrs) do
          {
            concept: concept,
            draft: true,
            lesson: lesson,
            instructor: instructor,
            toc_entry_id: strand.location
          }
        end

        context 'when the last custom rubric record has a nil revision id,' do
          before do
            activity.custom_rubrics.create!(
              activity_revision_id: nil,
              course_id: course.id,
              instructor_id: instructor.id,
              source_activity_id: source_activity.id
            )
          end

          it 'does not create a new custom rubric record' do
            expect { activity.save! }.not_to change(CustomRubric, :count)
          end

          it 'sets the activity_revision_id of the existing custom rubric ' \
             'record to the new instructor_revision_id of the activity' do
            activity.save!

            expect(activity.custom_rubrics.last.activity_revision_id).to eq(
              activity.instructor_revision_id
            )
          end
        end

        context 'when the last custom rubric record has a non-nil revision id,' do
          before do
            activity.custom_rubrics.create!(
              activity_revision_id: activity.instructor_revision_id,
              course_id: course.id,
              instructor_id: instructor.id,
              source_activity_id: source_activity.id
            )
          end

          it 'creates a new custom rubric record' do
            expect { activity.save! }.to change(CustomRubric, :count).by(1)
          end

          it 'sets the activity_revision_id of the new custom rubric ' \
             'record to the new instructor_revision_id of the activity' do
            activity.save!

            expect(activity.custom_rubrics.last.activity_revision_id).to eq(
              activity.instructor_revision_id
            )
          end
        end

        context 'when the activity draft status is changed to false,' do
          before do
            activity.custom_rubrics.create!(
              activity_revision_id: activity.instructor_revision_id,
              course_id: course.id,
              draft: true,
              instructor_id: instructor.id,
              source_activity_id: source_activity.id
            )
          end

          it 'updates the draft status of the custom_rubric record to false' do
            activity.update!(draft: false)

            expect(activity.custom_rubric.draft).to be_falsey
          end

          context 'when a CourseLibraryActivity record exists for the ' \
                  'source activity of the custom_rubric record,' do
            let!(:course_library_record) do
              CourseLibraryActivity.create!(
                activity: source_activity,
                course: course,
                hidden: false
              )
            end

            it 'changes the status of the CourseLibraryActivity record to ' \
               'hidden if the source activity is not assigned in any ' \
               'section of the course' do
              activity.update!(draft: false)

              expect(course_library_record.reload.hidden).to be_truthy
            end

            it 'does not change the status of the CourseLibraryActivity ' \
               'record to hidden if the source activity is assigned in ' \
               'any section of the course' do
              create(:assignment, assignable: source_activity, section: section_2)

              activity.update!(draft: false)

              expect(course_library_record.reload.hidden).to be_falsey
            end
          end

          context 'when no CourseLibraryActivity record exists,' do
            it 'creates a CourseLibraryActivity record with status of ' \
               'hidden if the source activity is not assigned in any ' \
               'section of the course' do
              activity.update!(draft: false)

              course_library_record = CourseLibraryActivity.find_by(
                activity_id: source_activity,
                course_id: course.id
              )

              expect(course_library_record).to have_attributes(hidden: true)
            end

            it 'does not create a CourseLibraryActivity record if the ' \
               'source activity is assigned in any section of the course' do
              create(:assignment, assignable: source_activity, section: section_2)

              activity.update!(draft: false)

              expect(
                CourseLibraryActivity.where(
                  activity_id: source_activity,
                  course_id: course.id
                )
              ).not_to exist
            end
          end
        end
      end
    end
  end

  describe '#direction_line' do
    it 'returns its value if content object does not exist' do
      activity.direction_line = 'dl 1'
      expect(activity.direction_line).to eq('dl 1')
    end

    it "returns set value over content object's value" do
      activity.direction_line = 'dl 1'
      activity.direction_line = 'baz'
      expect(activity.direction_line).to eq('baz')
    end

    it 'returns the direction line from the content object as HTML, removing newlines' do
      doc = Nokogiri::XML::Document.new
      dl = Nokogiri::XML::Node.new('dl', doc)
      b = Nokogiri::XML::Node.new('b', doc)
      b.content = "direction \nline"
      dl.add_child(b)

      activity.save!
      allow(mock_content_object).to receive(:dl).and_return(dl)
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      expect(activity.direction_line).to eq('<b>direction line</b>')
    end

    it 'handles nil content object gracefully' do
      allow(mock_content_object).to receive(:dl).and_return(nil)
      expect(activity.direction_line).to be_nil
    end
  end

  describe '#question_prompt' do
    it 'returns its value if content object does not exist' do
      activity.question_prompt = 'This is my question prompt.'
      expect(activity.question_prompt).to eq('This is my question prompt.')
    end

    it "returns set value over content object's value" do
      activity.question_prompt = 'This is my question prompt.'
      activity.question_prompt = 'baz'
      expect(activity.question_prompt).to eq('baz')
    end

    it 'returns nil if question node does not exist inside content object' do
      activity.save!
      expect(activity.question_prompt).to be_nil

      allow(activity).to receive(:questions).and_return([])
      expect(activity.question_prompt).to be_nil
    end

    it 'returns the question prompt from the content object as html' do
      doc = Nokogiri::XML::Document.new
      questions = Nokogiri::XML::Node.new('questions', doc)
      prompt = Nokogiri::XML::Node.new('prompt', doc)
      b = Nokogiri::XML::Node.new('b', doc)
      b.content = 'My question prompt'
      questions.add_child(prompt)
      prompt.add_child(b)

      activity.save!
      allow(mock_content_object).to receive(:questions).and_return([questions])
      allow(mock_content_object.questions.first).to receive(:prompt).and_return(prompt)
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      expect(activity.question_prompt).to eq('<b>My question prompt</b>')
    end
  end

  describe '#activity_type' do
    it 'returns audio_composition for activities whose type is recording' do
      activity.activity_type = 'recording_v2'
      expect(activity.activity_type).to eq('audio_composition')
    end

    it 'returns its default value for no-audio activities' do
      activity.activity_type = 'composition'
      expect(activity.activity_type).to eq('composition')
    end
  end

  describe '#video_url' do
    let(:mock_content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::ExternalVideoContent,
        activity_type: 'external_video',
        content_summary: {},
        grading_method: 'ungraded',
        has_rubric?: false,
        chat_activity?: false,
        composition_activity?: false,
        video_activity?: false,
        recording_activity?: false,
        has_video_recording?: false,
        has_audio_recording?: false,
        randomizable?: false,
        max_attempts: 0,
        points_possible: 1,
        submittable?: false
      )
    end

    it 'returns its value if content object does not exist' do
      activity.video_url = 'www.fakeurl.com'
      expect(activity.video_url).to eq('www.fakeurl.com')
    end

    it "returns set value over content object's value" do
      activity.video_url = 'www.fakeurl.com'
      activity.save!

      activity.video_url = 'www.2fake.com'
      expect(activity.video_url).to eq('www.2fake.com')
    end

    it 'returns nil if youtube video id node does not exist in content object' do
      activity.save!
      expect(activity.video_url).to be_falsey
    end

    it 'returns a youtube video url if content_object exists' do
      youtube_url = 'http://www.youtube.com/watch?v=1234567890'

      activity.save!
      allow(mock_content_object).to receive(:video_url).and_return(youtube_url)
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      expect(activity.video_url).to eq('http://www.youtube.com/watch?v=1234567890')
    end
  end

  describe '#video_platform' do
    let(:mock_external_video_content) do
      instance_double(
        MaestroActivityEngine::ActivityContent::ExternalVideoContent,
        activity_type: 'external_video',
        content_summary: {},
        grading_method: 'ungraded',
        chat_activity?: false,
        composition_activity?: false,
        video_activity?: true,
        recording_activity?: false,
        has_video_recording?: false,
        has_audio_recording?: false,
        max_attempts: 0,
        points_possible: 1,
        submittable?: false
      )
    end
    context 'with an existing external video activity' do
      it 'returns the video platform from the xml when @video_platform is nil' do
        activity.instance_variable_set(:@video_platform, nil)
        allow(activity).to receive(:new_record?).and_return(false)
        allow(activity).to receive(:content_object).and_return(mock_external_video_content)
        allow(mock_external_video_content).to receive(:video_platform).and_return('foo')
        expect(activity.video_platform).to eq('foo')
      end
      it 'returns the video platform from the params when @video_platform exists' do
        activity.instance_variable_set(:@video_platform, 'baz')
        allow(activity).to receive(:new_record?).and_return(false)
        expect(activity.video_platform).to eq('baz')
      end
    end
    context 'with a new record' do
      it 'returns an empty string when video_platform is nil' do
        activity.instance_variable_set(:@video_platform, nil)
        expect(activity.video_platform).to eq('')
      end
      it 'returns the video_platform property when defined' do
        activity.instance_variable_set(:@video_platform, 'bar')
        expect(activity.video_platform).to eq('bar')
      end
    end
  end

  describe '#references' do
    context 'new references' do
      it 'returns a new empty ReferenceCollection on initialization' do
        collection = double('InstructorCreatedActivity::ReferenceCollection')
        expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new).with(
          { instructor_id: instructor.id }
        ).and_return(collection)
        expect(activity.references).to eq(collection)
      end

      it 'instatiates a new ReferenceCollection with the specified params' do
        expected_references = { '0' => { body: 'foo', type: 'baz', header: 'bar' } }

        expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new).with(
          { form_params: expected_references, instructor_id: instructor.id }
        )
        activity.references = expected_references
      end
    end

    context 'existing references' do
      it 'initializes a ReferenceCollection with content_object as param' do
        activity.save!
        allow(activity).to receive(:content_object).and_return(mock_content_object)
        allow(mock_content_object).to receive(:references_params).and_return(references_params)

        expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new)
          .with({ content_object: mock_content_object, instructor_id: instructor.id })
        activity.references
      end
    end

    context 'with edited references' do
      it 'returns them over content_object references' do
        activity.references = { '0' => { body: 'foo', type: 'baz', header: 'bar' } }
        activity.save!
        edited_references = { '0' => { body: 'one', type: 'two', header: 'three' } }

        expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new)
          .with({ form_params: edited_references, instructor_id: instructor.id })
        activity.references = edited_references
      end
    end

    context 'without references' do
      it 'initializes a ReferenceCollection with default content_object' do
        allow(activity).to receive(:content_object).and_return(mock_content_object)

        activity.save!
        expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new)
          .with({ content_object: mock_content_object, instructor_id: instructor.id })

        activity.references
      end
    end
  end

  describe '#references=' do
    it 'initializes a ReferenceCollection if reference_params are present' do
      references = { '0' => { a: 'b', c: 'd' }, '1' => { foo: 'bar' } }

      expect(InstructorCreatedActivity::ReferenceCollection).to receive(:new)
        .with({ form_params: references, instructor_id: instructor.id })
      activity.references = references
    end
  end

  describe '#parsed_references' do
    it 'calls parse on ReferenceCollection' do
      collection = double(InstructorCreatedActivity::ReferenceCollection, 'parse' => {})
      allow(activity).to receive(:references).and_return(collection)

      expect(collection).to receive(:parse)
      activity.parsed_references
    end
  end

  describe '#in_library?' do
    let(:course) { create(:course) }
    let(:instructor_created_activity_1) do
      create(
        :instructor_created_activity,
        lesson: lesson,
        toc_entry_id: strand.location
      )
    end

    context 'when activity has not been added to any course library' do
      it 'is false' do
        expect(instructor_created_activity_1.in_library?(course)).to be_falsey
      end
    end

    context 'when activity has been added to another course library' do
      it 'is false' do
        CourseLibraryActivity.create(course: create(:course), activity: instructor_created_activity_1, hidden: true)
        expect(instructor_created_activity_1.in_library?(course)).to be_falsey
      end
    end

    context 'when activity has been added to the given course library' do
      it 'is true' do
        CourseLibraryActivity.create(course: course, activity: instructor_created_activity_1, hidden: true)
        expect(instructor_created_activity_1.in_library?(course)).to be_truthy
      end
    end
  end

  describe '#update' do
    it 'finds or initializes references params' do
      activity.update({})
      expect(activity.references.list).to eq([])

      params = { 'body' => 'foo', 'type' => 'baz', 'header' => 'bar' }
      activity.update(references: { '0' => params })
      expect(activity.references.list[0].attributes).to eq(params)
    end
  end

  describe 'on save' do
    context 'when activity is not process_as_assessment' do
      it 'sets default values for toc_location_rank and concept_rank attributes' do
        activity.save!
        expect(activity.toc_location_rank).to eq(InstructorCreatedActivity::DEFAULT_TOC_RANK)
        expect(activity.concept_rank).to eq(InstructorCreatedActivity::DEFAULT_TOC_RANK)
      end

      it 'sets the toc_location from the toc_entry_id attribute' do
        activity.save!
        expect(activity.toc_location).to eq(strand.location.to_i)
      end

      context 'when the specified toc_entry_id points to a strand' do
        it 'sets the concept_id from the toc_entry_id attribute' do
          activity.save!
          expect(activity.concept_id).to eq(strand.location.to_i)
        end
      end

      context 'in a live environment', test_debt: true do
        it 'sets the cdn flag to true' do
          allow(Rails.env).to receive(:live?).and_return(true)
          allow(activity).to receive(:parse_content).and_return(mock_content_object)
          activity.save!
          expect(activity.cdn).to be_truthy
        end
      end

      context 'in a non-live environment' do
        it 'sets the cdn flag to false' do
          activity.save!
          expect(activity.cdn).to be_falsey
        end
      end
    end

    context 'when activity is process_as_assessment' do
      let(:other_concept) { create(:concept) }

      before do
        allow(activity).to receive(:parse_content).and_return(mock_content_object)
        activity.toc_entry_id = strand.location
        activity.concept_id = other_concept.id
        activity.process_as_assessment = true
        activity.save!
      end

      it 'does not set concept_id based on the toc_entry_id' do
        expect(activity.reload.concept_id).to eq(other_concept.id)
      end
    end

    context 'when program is vista_online_learning' do
      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return([double('LicenseGroup', id: 100, name: 'VOL')])
        allow(program).to receive(:vista_online_learning?).and_return(true)
      end

      it 'sets VOL license group id' do
        activity.save!
        expect(activity.license_group_id).to eq(100)
      end
    end

    context 'when program is different than Portales' do
      before do
        allow(program).to receive(:id).and_return(100)
      end

      it 'sets supersite license group id' do
        activity.save!
        expect(activity.license_group_id).to eq(1)
      end
    end

    it 'sets "video" icon for external video' do
      allow(activity).to receive(:content_json).and_return({})
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      allow(mock_content_object).to receive(:video_activity?).and_return(true)
      allow(activity).to receive(:video_id).and_return('youtube_url')
      activity.save!
      expect(activity.icon).to eq('video')
    end

    it 'sets "microphone" icon for audio composition' do
      allow(activity).to receive(:content_json).and_return({})
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      allow(mock_content_object).to receive(:recording_activity?).and_return(true)
      activity.save!
      expect(activity.icon).to eq('microphone')
    end

    it 'sets chat icon for chat activity' do
      allow(activity).to receive(:content_json).and_return({})
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      allow(mock_content_object).to receive(:chat_activity?).and_return(true)
      activity.activity_type = 'partner_chat'
      activity.save!
      expect(activity.icon).to eq('partner_chat')
    end

    it 'sets solo video recording if it includes svr activity' do
      allow(activity).to receive(:content_json).and_return({})
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      allow(mock_content_object).to receive(:activities).and_return([svr_content_object])
      allow(activity).to receive(:includes_svr?).and_return(true)
      activity.save!
      expect(activity.icon).to eq('solo_video_recording')
    end

    it 'sets multiple activity icons' do
      allow(activity).to receive(:content_json).and_return({})
      allow(activity).to receive(:content_object).and_return(mock_content_object)
      allow(mock_content_object).to receive(:activities).and_return([svr_content_object])
      allow(activity).to receive(:includes_svr?).and_return(true)
      allow(svr_content_object).to receive(:has_video_recording?).and_return(true)
      allow(svr_content_object).to receive(:has_audio_recording?).and_return(true)

      activity.save!
      expect(activity.icon).to eq('solo_video_recording,video,audio')
    end

    context 'when the specified toc_entry_id points to a substrand' do
      let(:substrand) { build_stubbed(:toc_entry) }

      it 'sets the concept_id to the location of the parent strand of that substrand' do
        allow(lesson).to receive(:strand_for_toc_location).with(substrand.location.to_i).and_return(strand)
        activity.toc_entry_id = substrand.location
        activity.save!
        expect(activity.concept_id).to eq(strand.location.to_i)
      end
    end

    it 'creates a new instructor activity revision record' do
      activity.save!
      results = InstructorActivityRevision.where(activity_id: activity)
      expect(results.size).to eq(1)
      expect(activity.reload.instructor_revision_id).to eq(results.first.id)
    end

    it 'rolls back the entire save transaction if creating the revision fails' do
      empty_revisions = double(ActiveRecord::Associations::CollectionProxy, create!: false)
      allow(activity).to receive(:instructor_activity_revisions).and_return(empty_revisions)
      allow(activity.instructor_activity_revisions).to receive(:create!).and_raise(ActiveRecord::Rollback)

      expect { activity.save }.not_to change(Activity, :count)
      expect { activity.save }.not_to change(InstructorActivityRevision, :count)
    end

    it 'rolls back the entire save transaction if updating the head revision column fails' do
      allow(activity).to receive(:update_column).and_raise(ActiveRecord::Rollback)
      expect { activity.save }.not_to change(Activity, :count)
      # ActiveRecord complains if you try to save this object twice
      # possibly due to nested rollbacks in rSpec, so just check the count
      # Mysql2::Error:
      #    Field 'created_at' doesn't have a default value
      expect(InstructorActivityRevision.count).to eq 0
    end

    context 'when valid content_object' do
      it 'populates denormalized values' do
        allow(activity).to receive(:content_object).and_return(mock_content_object)
        activity.save!

        expect(activity.activity_type).to           eq(mock_content_object.activity_type)
        expect(activity.points_possible).to         eq(mock_content_object.points_possible)
        expect(activity.grading_method).to          eq(mock_content_object.grading_method)
        expect(activity.content_summary.to_json).to eq(mock_content_object.content_summary.to_json)
        expect(activity.max_attempts).to            eq(mock_content_object.max_attempts)
        expect(activity.submittable).to             eq(mock_content_object.submittable?)
        expect(activity.randomizable).to            eq(mock_content_object.randomizable?)
      end
    end

    context 'when invalid content_object' do
      it 'does not populate denormalized values' do
        allow(activity).to receive(:content_object).and_return(nil)
        activity.save!

        expect(activity.activity_type).to   be_nil
        expect(activity.points_possible).to be_nil
        expect(activity.grading_method).to  be_nil
        expect(activity.content_summary).to eq({})
        expect(activity.max_attempts).to    be_nil
        expect(activity.submittable).to     be_nil
        expect(activity.randomizable).to    be false
      end
    end
  end

  describe 'scopes' do
    describe '#instructor' do
      it 'returns records for given instructor' do
        activity.save!

        instructor_ids = described_class.instructor(instructor).pluck(:instructor_id)
        expect(instructor_ids).to include(instructor.id)
      end

      it 'does not return records for other instructors' do
        activity.save!
        activity_for_other_instructor.save!

        instructor_ids = described_class.instructor(instructor).pluck(:instructor_id)
        expect(instructor_ids).not_to include(other_instructor.id)
      end

      it 'does not return records if given instructor has no activities' do
        activity_for_other_instructor.save!

        instructor_ids = described_class.instructor(instructor).pluck(:instructor_id)
        expect(instructor_ids).to be_empty
      end
    end

    describe '#with_mapped_concept_in_program' do
      let(:program_1) { create(:program_with_toc_entries) }
      let(:program_1_lesson) { program_1.lessons.first }
      let(:program_1_strand) { program_1_lesson.toc_entries.first }
      let(:unmapped_program_1_strand) { program_1_lesson.toc_entries[1] }
      let(:nil_mapped_program_1_strand) { program_1_lesson.toc_entries[2] }
      let(:program_2) { create(:program_with_toc_entries) }
      let(:program_2_lesson) { program_2.lessons.first }
      let(:program_2_strand) { program_2_lesson.toc_entries.first }

      let(:activity_for_program_1) do
        described_class.new(
          instructor_id: instructor.id,
          lesson: program_1_lesson,
          title: 'foo',
          toc_entry_id: program_1_strand.location
        )
      end

      let(:unmapped_activity_for_program_1) do
        described_class.new(
          instructor_id: instructor.id,
          lesson: program_1_lesson,
          title: 'foo',
          toc_entry_id: unmapped_program_1_strand.location
        )
      end

      let(:nil_mapped_activity_for_program_1) do
        described_class.new(
          instructor_id: instructor.id,
          lesson: program_1_lesson,
          title: 'foo',
          toc_entry_id: nil_mapped_program_1_strand.location
        )
      end

      let(:activity_for_program_2) do
        described_class.new(
          instructor_id: instructor.id,
          lesson: program_2_lesson,
          title: 'foo',
          toc_entry_id: program_2_strand.location
        )
      end

      before do
        create(
          :concept,
          id: program_1_strand.location,
          lesson: program_1_lesson,
          program: program_1
        )

        create(
          :concept,
          id: unmapped_program_1_strand.location,
          lesson: program_1_lesson,
          program: program_1
        )

        create(
          :concept,
          id: nil_mapped_program_1_strand.location,
          lesson: program_1_lesson,
          program: program_1
        )

        create(
          :concept,
          id: program_2_strand.location,
          lesson: program_2_lesson,
          program: program_2
        )

        create(
          :program_to_program_mapping,
          src_strand_id: program_1_strand.location
        )

        create(
          :program_to_program_mapping,
          dest_strand_id: nil,
          src_strand_id: nil_mapped_program_1_strand.location
        )
      end

      it 'returns records for activities with concept in given program' do
        activity_for_program_1.save!
        activity_ids = described_class.with_mapped_concept_in_program(program_1).pluck(:id)
        expect(activity_ids).to include(activity_for_program_1.id)
      end

      it 'does not return records for activities with unmapped concept in given program' do
        activity_for_program_1.save!
        unmapped_activity_for_program_1.save!
        activity_ids = described_class.with_mapped_concept_in_program(program_1).pluck(:id)
        expect(activity_ids).to include(activity_for_program_1.id)
        expect(activity_ids).not_to include(unmapped_activity_for_program_1.id)
      end

      it 'does not return records for activities with concept mapped to nil destination' do
        activity_for_program_1.save!
        nil_mapped_activity_for_program_1.save!
        activity_ids = described_class.with_mapped_concept_in_program(program_1).pluck(:id)
        expect(activity_ids).to include(activity_for_program_1.id)
        expect(activity_ids).not_to include(nil_mapped_activity_for_program_1.id)
      end

      it 'does not return records for activities with concept not in given program' do
        activity_for_program_1.save!
        activity_for_program_2.save!

        activity_ids = described_class.with_mapped_concept_in_program(program_1).pluck(:id)
        expect(activity_ids).not_to include(activity_for_program_2.id)
      end

      it 'does not return records if there are no activities with concept in given program' do
        activity_for_program_2.save!

        activity_ids = described_class.with_mapped_concept_in_program(program_1).pluck(:id)
        expect(activity_ids).to be_empty
      end
    end
  end

  describe 'when activity has xml content' do
    context 'when saving an activity' do
      before do
        allow(activity).to receive(:content_json).and_return(nil)
      end

      it 'sets "microphone" icon for audio_composition activity' do
        allow(activity).to receive(:activity_type).and_return('audio_composition')
        activity.save!
        expect(activity.icon).to eq('microphone')
      end

      it 'sets "video" icon for external video' do
        allow(activity).to receive(:activity_type).and_return('video')
        activity.save!
        expect(activity.icon).to eq('video')
      end

      it 'sets "composition" icon for composition activity' do
        allow(activity).to receive(:activity_type).and_return('composition')
        activity.save!
        expect(activity.icon).to eq('composition')
      end

      it 'sets "microphone,audio" icon for recording_v2 activity' do
        allow(activity).to receive(:activity_type).and_return('recording_v2')
        activity.save!
        expect(activity.icon).to eq('microphone,audio')
      end
    end
  end
end

describe InstructorCreatedActivity::ReferenceCollection do
  let(:mock_content_object) { double('ContentObject') }
  let(:references_params) do
    [{ type: 'text', body: 'b1', header: 'h1' },
     { type: 'text', body: 'b2', header: 'h2' }]
  end
  let(:form_params) { Hash['0' => { 'type' => 'text', 'body' => 'foo', 'header' => 'bar' }] }
  let(:instructor) { build_stubbed(:instructor) }

  describe '#initialize' do
    context 'with content object' do
      it 'assigns list to content_object reference_params' do
        allow(mock_content_object).to receive(:references_params).and_return(references_params)
        expect(InstructorCreatedActivity::Reference).to receive(:new).with(references_params[0])
        expect(InstructorCreatedActivity::Reference).to receive(:new).with(references_params[1])

        described_class.new(content_object: mock_content_object, instructor_id: instructor.id)
      end
    end

    context 'with submitted reference params' do
      it 'assigns list to reference_params' do
        expect(InstructorCreatedActivity::Reference).to receive(:new).with(form_params.values[0])

        described_class.new(form_params: form_params, instructor_id: instructor.id)
      end
    end

    context 'with empty submitted reference params' do
      it 'returns an empty list' do
        collection = described_class.new(form_params: [], instructor_id: instructor.id)
        expect(collection.list).to eq([])
      end
    end

    context 'with instructor_id' do
      it 'assigns instructor_id' do
        collection = described_class.new(instructor_id: 1)
        expect(collection.instructor_id).to eq(1)
      end
    end

    context 'with params' do
      it 'creates a new InstructorCreatedActivity::Reference object for every item in the list' do
        expect(InstructorCreatedActivity::Reference).to receive(:new)
          .with(form_params.values[0].merge('instructor_id' => instructor.id))
        described_class.new(form_params: form_params, instructor_id: instructor.id)
      end
    end
  end

  describe '#to_json' do
    context 'with no references' do
      context 'with a nil content object' do
        it 'returns an empty array as json' do
          expect(described_class.new(content_object: nil, instructor_id: instructor.id).to_json).to eq([].to_json)
        end
      end

      context 'with a false content object' do
        it 'returns an empty array as json' do
          expect(described_class.new(content_object: false, instructor_id: instructor.id).to_json).to eq([].to_json)
        end
      end

      context 'with an empty content object reference params' do
        it 'returns an empty array as json' do
          allow(mock_content_object).to receive(:references_params).and_return([])
          expect(described_class.new(content_object: mock_content_object, instructor_id: instructor.id).to_json).to eq([].to_json)
        end
      end
    end

    context 'with content object references' do
      it 'returns params as json' do
        allow(mock_content_object).to receive(:references_params).and_return(references_params)
        reference_collection = described_class.new(content_object: mock_content_object,
                                                   instructor_id: instructor.id)
        expected_references = references_params.each { |reference| reference.delete('instructor_id') }
        expect(reference_collection.to_json).to eq(expected_references.to_json)
      end
    end

    context 'with submitted references' do
      it 'returns params as json' do
        reference_collection = described_class.new(form_params: form_params,
                                                   instructor_id: instructor.id)

        expected_references = form_params.values.each { |ref| ref.delete('instructor_id') }
        expect(reference_collection.to_json).to eq(expected_references.to_json)
      end
    end
  end

  describe 'populate_list' do
  end

  describe '#parse' do
    context 'with image references' do
      let(:media_item) { double(InstructorMediaItem, id: 1) }
      let(:form_params) { Hash['0' => { 'type' => 'image', 'original_filename' => 'foo.jpg', 'temp_file_path' => '/tmp/blah.jpg', 'id' => '' }] }

      before do
        @collection = described_class.new(form_params: form_params, instructor_id: 1)
        allow(InstructorMediaItem).to receive(:create_from_temp_file).and_return(media_item)
      end

      it 'removes original_filename and temp_file_path keys from reference and set id to instructor media item record id' do
        expect(@collection.parse[0]).to eq('type' => 'image',
                                           'image' => { 'id' => media_item.id.to_s })
      end

      context 'when neither of the existing images are updated' do
        it 'returns an array with the existing id and type' do
          old_references = { '0' => { 'type' => 'image', 'original_filename' => '', 'temp_file_path' => '', 'id' => '1' } }
          @collection = described_class.new(form_params: old_references, instructor_id: instructor.id)
          expect(@collection.parse[0]).to eq('type' => 'image',
                                             'image' => { 'id' => '1' })
        end
      end

      context 'when any of the images are updated' do
        it 'returns a new id for the updated image and the same id for the other one' do
          allow(InstructorMediaItem).to receive(:create_from_temp_file).and_return(double(InstructorMediaItem, id: 3))
          updated_references = { '0' => { 'type' => 'image', 'original_filename' => '', 'temp_file_path' => '', 'id' => '1' },
                                 '1' => { 'type' => 'image', 'original_filename' => 'new.jpg', 'temp_file_path' => '/tmp/new.png', 'id' => '2' } }
          @collection = described_class.new(form_params: updated_references)
          expect(@collection.parse).to eq([{ 'type' => 'image',
                                             'image' => { 'id' => '1' } },
                                           { 'type' => 'image',
                                             'image' => { 'id' => '3' } }])
        end
      end

      context 'when all references are deleted' do
        it 'sets references to an empty array when they are parsed' do
          @collection = described_class.new(form_params: [], instructor_id: instructor.id)
          expect(@collection.parse).to eq([])
        end
      end
    end

    context 'with unknown references' do
      it 'returns an empty array' do
        references = { '0' => { type: 'fake', a: 'b', c: 'd' }, '1' => { type: 'bar', foo: 'bar' } }
        @collection = described_class.new(form_params: references)
        expect(@collection.parse).to eq([])
      end
    end
  end
end

describe InstructorCreatedActivity::Reference do
  let(:media_item) { double(InstructorMediaItem, id: 1) }

  describe '#initialize' do
    it 'initializes and sets attributes based on the pass in params' do
      reference = described_class.new(foo: 'baz', bar: 'blah')
      expect(reference.foo).to eq('baz')
      expect(reference).to be_respond_to(:foo)
      expect(reference.bar).to eq('blah')
      expect(reference).to be_respond_to(:bar)
    end

    it 'sets attributes to the specified params' do
      reference = described_class.new(one: '1')
      expect(reference.attributes).to eq('one' => '1')
    end
  end

  describe '#parse_text' do
    it 'returns type, body and header' do
      reference = described_class.new('type' => 'text', 'header' => 'myheader', 'body' => 'mybody')
      expect(reference.parse_text).to eq('type' => 'text', 'body' => 'mybody', 'header' => 'myheader')
    end
  end

  describe '#parse_audio' do
    context 'when recording is new' do
      it 'creates a recording record and returns type and recording id' do
        recording_path = '/a/path'
        recording = create(:recording)
        expect(Recording).to receive(:create).with(recording_path: recording_path).and_return(recording)

        reference = described_class.new('type' => 'audio', 'recording_path' => recording_path, 'id' => '')

        expect(reference.parse_audio).to eq('type' => 'audio', 'recording' => { 'id' => recording.id.to_s })
      end

      it 'creates recording in media item uses media item id to return type and audio' do
        instructor_media_item_id = 1
        reference = described_class.new('type' => 'audio', 'instructor_media_item_id' => instructor_media_item_id, 'id' => '')

        expect(reference.parse_audio).to eq('type' => 'audio', 'audio' => { 'id' => instructor_media_item_id })
      end
    end

    context 'when recording exists' do
      it 'returns type and existing recording id' do
        expect(Recording).not_to receive(:create)

        reference = described_class.new('type' => 'audio', 'recording_path' => '/a/path', 'id' => '999')

        expect(reference.parse_audio).to eq('type' => 'audio', 'recording' => { 'id' => '999' })
      end
    end
  end

  describe '#parse_wordbank' do
    it 'returns type and body attributes' do
      reference = described_class.new('type' => 'word_bank', 'body' => 'house')
      expect(reference.parse_wordbank).to eq('type' => 'word_bank', 'body' => 'house')
    end

    it 'returns valid parsed words into body' do
      reference = described_class.new('type' => 'word_bank', 'body' => "house\ndog")
      expect(reference.parse_wordbank).to eq('type' => 'word_bank', 'body' => 'house,dog')
    end

    it 'returns valid parsed words into body for multiple and weird words' do
      reference = described_class.new('type' => 'word_bank', 'body' => "cat\ndog\ncat dog")
      expect(reference.parse_wordbank).to eq('type' => 'word_bank', 'body' => 'cat,dog,cat dog')
    end
  end

  describe '#parse_image' do
    it 'creates a media item if type is image and temp_file_path and original_filename are present' do
      expect(InstructorMediaItem).to receive(:create_from_temp_file)
      described_class.new(type: 'image', temp_file_path: 'foo', original_filename: 'bar', id: '').parse_image
    end

    it 'does not create a media item if type is not image' do
      expect(InstructorMediaItem).not_to receive(:create_from_temp_file)
      described_class.new(type: 'text', temp_file_path: 'foo', original_filename: 'bar', id: '').parse_image
    end

    it 'does not create a media item if temp_file_path is not present' do
      expect(InstructorMediaItem).not_to receive(:create_from_temp_file)
      described_class.new(type: 'image', temp_file_path: '', original_filename: 'bar', id: '').parse_image
    end

    it 'does not create a media item if original_filename is not present' do
      expect(InstructorMediaItem).not_to receive(:create_from_temp_file)
      described_class.new(type: 'image', temp_file_path: 'foo', original_filename: '', id: '').parse_image
    end

    it 'returns type and image id' do
      reference = described_class.new(type: 'image',
                                      temp_file_path: 'foo',
                                      original_filename: '',
                                      id: 1)
      expect(reference.parse_image).to eq('type' => 'image',
                                          'image' => { 'id' => 1 })
    end

    it 'creates a record in instructor_media_items table if file was uploaded' do
      params = { 'type' => 'image',
                 'temp_file_path' => 'foo',
                 'original_filename' => 'bar',
                 'id' => 1 }
      expect(InstructorMediaItem).to receive(:create_from_temp_file)
        .with(params)
        .and_return(media_item)
      reference = described_class.new(params)

      expect(reference.parse_image).to eq('type' => 'image',
                                          'image' => { 'id' => media_item.id.to_s })
    end
  end

  describe '#params' do
    context 'with text references' do
      it 'returns type, body and header' do
        params = { 'type' => 'text', 'header' => 'myheader', 'body' => 'mybody' }
        reference = described_class.new(params)
        expect(reference.params).to eq(params)
      end
    end

    context 'with audio references' do
      context 'when the recording record exists' do
        it 'returns type, id and recording path' do
          recording = create(:recording, id: 569)
          params = { 'type' => 'audio', 'id' => '569', 'foo' => 'foo' }

          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'audio', 'id' => '569', 'recording_path' => recording.recording_path)
        end
      end

      context 'when the recording record does not exist' do
        it 'returns type, id and recording path set to nil' do
          params = { 'type' => 'audio', 'id' => '1', 'foo' => 'foo' }

          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'audio', 'id' => '1', 'recording_path' => nil)
        end
      end
    end

    context 'with video recording references' do
      context 'when the video recording record exists' do
        it 'returns type, id and video_recording_path' do
          video_recording = create(:video_recording, id: 569)
          params = { 'type' => 'video_recording', 'id' => '569', 'foo' => 'foo' }

          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'video_recording', 'id' => '569', 'video_recording_path' => video_recording.recording_path)
        end
      end

      context 'when the video recording record does not exist' do
        it 'returns type, id and recording path set to nil' do
          params = { 'type' => 'video_recording', 'id' => '1', 'foo' => 'foo' }

          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'video_recording', 'id' => '1', 'video_recording_path' => nil)
        end
      end
    end

    context 'with image references' do
      context 'when the image record exists' do
        it 'returns type, id and image public filename' do
          instructor_media_item = double(InstructorMediaItem, public_filename: '/a/path')
          params = { 'type' => 'image', 'id' => '1', 'foo' => 'foo' }
          allow(InstructorMediaItem).to receive(:where).with(id: '1').and_return([instructor_media_item])
          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'image', 'id' => '1', 'image_filename' => '/a/path')
        end
      end

      context 'when the image record does not exist' do
        it 'returns type and id and image_filename set to nil' do
          params = { 'type' => 'image', 'id' => '999', 'foo' => 'foo' }
          reference = described_class.new(params)

          expect(reference.params).to eq('type' => 'image', 'id' => '999', 'image_filename' => nil)
        end
      end
    end

    context 'with invalid references' do
      it 'returns nil' do
        params = { 'type' => 'fake', 'id' => 'id', 'foo' => 'foo' }
        reference = described_class.new(params)
        expect(reference.params).to be_nil
      end
    end
  end

  describe '#valid?' do
    it 'returns true if type is a valid reference' do
      reference = described_class.new(type: 'image')
      expect(reference.valid?).to be_truthy
    end

    it 'returns false if type is not a valid reference' do
      reference = described_class.new(type: 'fake')
      expect(reference.valid?).to be_falsey
    end
  end
end
