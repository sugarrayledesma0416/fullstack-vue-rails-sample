describe SectionLearningTrack do
  let(:course) { create(:course, name: 'Foo') }
  let(:section) { create(:section, name: 'Bar', course: course) }
  let(:course_package) { double('Maestro::CoursePackage', id: 1) }
  let(:concept_1) { create(:concept, name: 'Concept 1', base_name: 'Contextos') }
  let(:lesson) { create(:lesson_with_unit, name: 'foo') }
  let(:lesson_2) { create(:lesson_with_unit, name: 'bar') }
  let(:lesson_3) { create(:lesson_with_unit, name: 'baz') }
  let(:activity_1) do
    create(:activity, concept: concept_1, lesson: lesson, license_group_id: 1, toc_location: 1)
  end
  let(:activity_2) do
    create(:activity, concept: concept_1, lesson: lesson, license_group_id: 2, toc_location: 2)
  end
  let(:activity_3) do
    create(:activity, concept: concept_1, lesson: lesson, license_group_id: 100, toc_location: 3)
  end
  let(:category_foo) { create(:category, name: 'Foo', course: course) }
  let(:category_bar) { create(:category, name: 'Bar', course: course) }
  let(:group_set) { create(:group_set, name: 'Whatever') }
  let(:learn_group) { create(:track_group, name: 'Learn', group_set: group_set) }
  let(:practice_group) { create(:track_group, name: 'Practice', group_set: group_set) }
  let(:interact_group) { create(:track_group, name: 'Interact', group_set: group_set) }
  let(:due_date) { Date.today }
  let(:assignment_1) do
    create(:assignment,
           section: section,
           assignable: activity_1,
           category: category_foo,
           due_date: Date.tomorrow,
           track_group: learn_group,
           rank: 1)
  end
  let(:assignment_2) do
    create(:assignment,
           section: section,
           assignable: activity_2,
           category: category_foo,
           due_date: due_date,
           track_group: practice_group,
           rank: 2)
  end
  let(:assignment_3) do
    create(:assignment,
           section: section,
           assignable: activity_3,
           category: category_foo,
           due_date: due_date,
           track_group: practice_group,
           rank: 3)
  end

  let(:track) { described_class.new(section, [course_package], nil) }

  def add_external_assignment(lesson, name)
    GradebookEngine::GradebookAPI.create_external_assignment(
      category_id: category_foo.id,
      day_id: course.start_date + 1,
      lesson_id: lesson.id,
      name: name,
      points_possible: 55,
      school_id: section.school_id,
      section_id: section.id
    )
  end

  def remove_external_assignments
    GradebookEngine::ExternalAssignment.delete_all
    GradebookEngine::ExternalActivity.delete_all
  end

  def expected_activities_hash(activity)
    {
      activity_requirements: {
        instructor_graded: activity.instructor_graded?,
        require_microphone: activity.chat_or_recording?,
        require_partner: activity.partner_chat?
      },
      activity_type: activity.activity_type,
      group: 'Practice',
      group_id: practice_group.id,
      due_date: Date.tomorrow.strftime('%m/%d/%Y'),
      category: 'Foo',
      individually_assignable: false,
      id: activity.id,
      is_igc: false,
      lesson_name: activity.lesson.name,
      minutes_to_complete: nil,
      strand: activity.concept.base_name.strip,
      strand_name: activity.concept.name,
      title: activity.title,
      unit_id: activity.lesson.unit_id
    }
  end

  before do
    allow(track).to receive(:license_group_ids).and_return([1, 2, 3])
  end

  describe '#assignments' do
    it 'does not include any activities that do not have a toc_location' do
      activity_without_toc_location = create(:activity,
                                             concept: concept_1,
                                             license_group_id: 1,
                                             toc_location: nil)
      assignment_1
      create(:assignment,
             section: section,
             assignable: activity_without_toc_location,
             category: category_foo,
             due_date: Date.tomorrow,
             track_group: learn_group,
             rank: 4)
      expect(track.send(:assignments)).to eq [assignment_1]
    end

    it 'includes any activities that are instructor created (have a instructor_revision_id)' do
      instructor_created_activity = create(:activity,
                                           concept: concept_1,
                                           license_group_id: 1,
                                           toc_location: 5,
                                           instructor_revision_id: 1)
      assignment_1
      igc_assignment = create(:assignment,
                              section: section,
                              assignable: instructor_created_activity,
                              category: category_foo,
                              due_date: Date.tomorrow,
                              track_group: learn_group,
                              rank: 4)
      expect(track.send(:assignments)).to eq [assignment_1, igc_assignment]
    end

    context 'when the assignments do not have the same due date' do
      it 'orders them by the due date' do
        assignment_1
        assignment_2
        expect(track.send(:assignments)).to eq [assignment_2, assignment_1]
      end
    end

    context 'when the assignments are on the same due date' do
      context 'when different assignment ranks' do
        it 'orders them by their ranks' do
          assignment_2
          assignment_3
          expect(track.send(:assignments)).to eq [assignment_2, assignment_3]
        end
      end

      context 'when same assignment ranks' do
        it 'orders them by concept ranks and toc location' do
          lesson = create(:lesson,
                          toc_entries_xml: Nokogiri::XML(File.open('spec/fixtures/xml/lesson.xml') ).to_xml)
          strand_a_activity_1 = create(:activity,
                                       lesson: lesson,
                                       title: 'AA',
                                       toc_location: 214_600_000,
                                       concept_rank: 10)
          strand_a_activity_2 = create(:activity,
                                       lesson: lesson,
                                       title: 'BB',
                                       toc_location: 214_600_000,
                                       concept_rank: 20)
          strand_b_activity_1 = create(:activity,
                                       lesson: lesson,
                                       title: 'DD',
                                       toc_location: 214_800_000,
                                       concept_rank: 10)
          assignment_4 = create(:assignment,
                                section: section,
                                assignable: strand_b_activity_1,
                                due_date: due_date,
                                rank: 1,
                                individually_assignable: nil)
          assignment_5 = create(:assignment,
                                section: section,
                                assignable: strand_a_activity_2,
                                due_date: due_date,
                                rank: 1,
                                individually_assignable: nil)
          assignment_6 = create(:assignment,
                                section: section,
                                assignable: strand_a_activity_1,
                                due_date: due_date,
                                rank: 1,
                                individually_assignable: nil)
          expect(track.send(:assignments)).to eq [assignment_6, assignment_5, assignment_4]
        end
      end
    end
  end

  describe '#activities' do
    let(:due_date_str) { due_date.strftime('%m/%d/%Y') }

    context 'with chat activities' do
      let(:partner_chat_activity) do
        create(
          :partner_chat_activity,
          concept: concept_1,
          lesson:,
          license_group_id: 1,
          toc_location: 1
        )
      end
      let(:group_chat_activity) do
        create(
          :group_chat_activity,
          concept: concept_1,
          lesson:,
          license_group_id: 1,
          toc_location: 1
        )
      end
      let(:infogap_chat_activity) do
        create(
          :activity,
          concept: concept_1,
          lesson:,
          license_group_id: 1,
          toc_location: 1,
          activity_type: 'info_gap_partner_chat'
        )
      end
      let(:non_chat_activity) do
        create(
          :activity,
          concept: concept_1,
          lesson:,
          license_group_id: 1,
          toc_location: 1,
          activity_type: 'foo'
        )
      end

      before do
        create(:assignment,
               section:,
               assignable: partner_chat_activity,
               category: category_foo,
               due_date: Date.tomorrow,
               track_group: practice_group,
               rank: 3)
        create(:assignment,
               section:,
               assignable: group_chat_activity,
               category: category_foo,
               due_date: Date.tomorrow,
               track_group: practice_group,
               rank: 4)
        create(:assignment,
               section:,
               assignable: infogap_chat_activity,
               category: category_foo,
               due_date: Date.tomorrow,
               track_group: practice_group,
               rank: 5)
        create(:assignment,
               section:,
               assignable: non_chat_activity,
               category: category_foo,
               due_date: Date.tomorrow,
               track_group: practice_group,
               rank: 6)
      end

      context 'when the copy-to section is within a chat disabled course' do
        it 'does not return chat-type activities' do
          course = create(:course, chat_level: 'disabled')
          track = described_class.new(section, [course_package], course.id)
          allow(track).to receive(:license_group_ids).and_return([1])

          expect(track.activities).to eq [expected_activities_hash(non_chat_activity)]
        end
      end

      context 'when the copy-to section is within a chat enabled course' do
        it 'returns chat-type activities' do
          track = described_class.new(section, [course_package], course.id)
          allow(track).to receive(:license_group_ids).and_return([1])
          expected = [
            partner_chat_activity,
            group_chat_activity,
            infogap_chat_activity,
            non_chat_activity
          ].map do |act|
            expected_activities_hash(act)
          end

          expect(track.activities).to eq(expected)
        end
      end

      context 'when assigning into a template section' do
        # This spec asserts that looking up template courses & their configurations
        # will work.
        it 'returns the expected activities' do
          course = create(:course_template_with_section)
          track = described_class.new(section, [course_package], course.id)
          allow(track).to receive(:license_group_ids).and_return([1])
          expected = [
            partner_chat_activity,
            group_chat_activity,
            infogap_chat_activity,
            non_chat_activity
          ].map do |act|
            expected_activities_hash(act)
          end
          expect(track.activities).to eq(expected)
        end
      end
    end

    it 'array of activity hashes, excluding activities outside accepted license groups' do
      assignment_1
      assignment_2
      assignment_3
      expected = [
        {
          activity_requirements: {
            instructor_graded: activity_2.instructor_graded?,
            require_microphone: activity_2.chat_or_recording?,
            require_partner: activity_2.partner_chat?
          },
          activity_type: activity_2.activity_type,
          group: 'Practice',
          group_id: practice_group.id,
          due_date: due_date_str,
          category: 'Foo',
          individually_assignable: false,
          id: activity_2.id,
          is_igc: false,
          lesson_name: activity_2.lesson.name,
          minutes_to_complete: nil,
          strand: activity_2.concept.base_name.strip,
          strand_name: activity_2.concept.name,
          title: activity_2.title,
          unit_id: activity_2.lesson.unit_id
        },
        {
          activity_requirements: {
            instructor_graded: activity_1.instructor_graded?,
            require_microphone: activity_1.chat_or_recording?,
            require_partner: activity_1.partner_chat?
          },
          activity_type: activity_1.activity_type,
          group: 'Learn',
          group_id: learn_group.id,
          due_date: Date.tomorrow.strftime('%m/%d/%Y'),
          category: 'Foo',
          individually_assignable: false,
          id: activity_1.id,
          is_igc: false,
          lesson_name: activity_1.lesson.name,
          minutes_to_complete: nil,
          strand: activity_1.concept.base_name.strip,
          strand_name: activity_1.concept.name,
          title: activity_1.title,
          unit_id: activity_1.lesson.unit_id
        }
      ]
      expect(track.activities).to eq(expected)
    end

    it 'sets group to activity concept name when there is no group' do
      create(:assignment,
             section: section,
             assignable: activity_1,
             category: category_foo,
             due_date: due_date,
             track_group: nil,
             rank: 1)
      create(:assignment,
             section: section,
             assignable: activity_2,
             category: category_bar,
             due_date: due_date,
             track_group: nil,
             rank: 2)
      expected = [
        {
          activity_requirements: {
            instructor_graded: activity_1.instructor_graded?,
            require_microphone: activity_1.chat_or_recording?,
            require_partner: activity_1.partner_chat?
          },
          activity_type: activity_1.activity_type,
          group: 'Concept 1',
          group_id: nil,
          due_date: due_date_str,
          category: 'Foo',
          individually_assignable: false,
          id: activity_1.id,
          is_igc: false,
          lesson_name: activity_1.lesson.name,
          minutes_to_complete: nil,
          strand: activity_1.concept.base_name.strip,
          strand_name: activity_1.concept.name,
          title: activity_1.title,
          unit_id: activity_1.lesson.unit_id
        }, {
          activity_requirements: {
            instructor_graded: activity_2.instructor_graded?,
            require_microphone: activity_2.chat_or_recording?,
            require_partner: activity_2.partner_chat?
          },
          activity_type: activity_2.activity_type,
          group: 'Concept 1',
          group_id: nil,
          due_date: due_date_str,
          category: 'Bar',
          individually_assignable: false,
          id: activity_2.id,
          is_igc: false,
          lesson_name: activity_2.lesson.name,
          minutes_to_complete: nil,
          strand: activity_2.concept.base_name.strip,
          strand_name: activity_2.concept.name,
          title: activity_2.title,
          unit_id: activity_2.lesson.unit_id
        }
      ]
      expect(track.activities).to eq(expected)
    end

    it 'sorts activities by assignment due date' do
      assignment_1
      activity_4 = create(:activity, :toc_location => 4)
      create(:assignment,
             section: section,
             assignable: activity_4,
             due_date: due_date - 1,
             track_group: interact_group,
             category: category_bar)
      expected = [
        {
          activity_requirements: {
            instructor_graded: activity_4.instructor_graded?,
            require_microphone: activity_4.chat_or_recording?,
            require_partner: activity_4.partner_chat?
          },
          activity_type: activity_4.activity_type,
          group: 'Interact',
          group_id: interact_group.id,
          due_date: (due_date - 1).strftime('%m/%d/%Y'),
          category: 'Bar',
          individually_assignable: false,
          id: activity_4.id,
          is_igc: false,
          lesson_name: activity_4.lesson.name,
          minutes_to_complete: nil,
          strand: activity_4.concept.base_name.strip,
          strand_name: activity_4.concept.name,
          title: activity_4.title,
          unit_id: activity_4.lesson.unit_id
        }, {
          activity_requirements: {
            instructor_graded: activity_1.instructor_graded?,
            require_microphone: activity_1.chat_or_recording?,
            require_partner: activity_1.partner_chat?
          },
          activity_type: activity_1.activity_type,
          group: 'Learn',
          group_id: learn_group.id,
          due_date: Date.tomorrow.strftime('%m/%d/%Y'),
          category: 'Foo',
          individually_assignable: false,
          id: activity_1.id,
          is_igc: false,
          lesson_name: activity_1.lesson.name,
          minutes_to_complete: nil,
          strand: activity_1.concept.base_name.strip,
          strand_name: activity_1.concept.name,
          title: activity_1.title,
          unit_id: activity_1.lesson.unit_id
        }
      ]
      expect(track.activities).to eq(expected)
    end
  end

  describe '#license_group_ids' do
    before do
      allow(track).to receive(:license_group_ids).and_call_original
    end

    context 'when a course id is given' do
      it 'returns the license group ids for that course' do
        allow(track).to receive(:current_course_id).and_return(5)
        allow(Course).to receive(:find_guid).and_return('5')
        expect(Maestro::CourseLicense).to receive(:all).with('5').and_return(
          [
            double('License', license_group: double('LicenseGroup', id: 3))
          ]
        )
        expect(track.license_group_ids).to eq([3])
      end
    end

    context 'when a course id is not given' do
      it 'returns the default license group ids' do
        expect(track.license_group_ids).to eq(SectionLearningTrack::DEFAULT_LICENSE_GROUP_IDS)
      end
    end
  end

  describe '#insufficient_license_groups' do
    it 'returns true if activities have been filtered out' do
      assignment_1
      assignment_2
      assignment_3
      expect(track.insufficient_license_groups).to be_truthy
    end

    it 'returns false is no activities have been filtered out' do
      assignment_1
      assignment_2
      expect(track.insufficient_license_groups).to be_falsey
    end
  end

  describe '#course_package_ids' do
    it 'returns an array of course package ids' do
      expect(track.course_package_ids).to eq([1])
    end
  end

  describe '#description' do
    it 'returns a description string' do
      allow(CourseTimeCalculator).to receive(:formatted_time)
        .with(anything).and_return({ weeks: "1 week", days: "0 days" })
      expect(track.description).to eq('Foo (1 week)')
    end
  end

  describe '#categories' do
    it 'returns a hash mapping old categories to categories' do
      category_foo
      category_bar
      expect(track.categories).to eq({
        'Foo' => category_foo,
        'Bar' => category_bar
      })
    end
  end

  describe '#strands' do
    it 'returns an array of included strands with no duplicates' do
      assignment_1
      assignment_2
      expect(track.strands).to eq [concept_1.base_name]
    end
  end

  describe '#units' do
    before do
      assignment_1
      assignment_2
      assignment_3
    end

    it 'returns all units for which activities have been assigned in primary key order' do
      expect(track.units).to eq [lesson.unit]
    end

    context 'when there are external assignments' do
      before do
        GradebookEngine::GradebookAPI.add('section', id: section.id)
        GradebookEngine::GradebookAPI.add('lesson', id: lesson_2.id, unit_id: lesson_2.unit_id)
        GradebookEngine::GradebookAPI.add('lesson', id: lesson_3.id, unit_id: lesson_3.unit_id)
        GradebookEngine::GradebookAPI.add('category', id: category_foo.id)
        add_external_assignment(lesson_2, 'Ext 1')
        add_external_assignment(lesson_3, 'Ext 2')
      end

      after do
        remove_external_assignments
      end

      it 'returns units for which external activities have been assigned in primary key order' do
        expect(track.units).to eq [lesson.unit, lesson_2.unit, lesson_3.unit]
      end
    end

    context 'when current events unit is present' do
      let(:current_events_lesson) { create(:current_events_lesson) }
      let(:current_events_activity) do
        create(:activity,
               concept: concept_1,
               lesson: current_events_lesson,
               license_group_id: 1,
               toc_location: 1)
      end

      before do
        current_events_activity
      end

      context 'when it does not have assignments' do
        it 'is not included in the returned units' do
          expect(track.units).to eq [lesson.unit]
        end
      end

      context 'when it has assignments' do
        it 'is included in the returned units' do
          create(:assignment,
                 section: section,
                 assignable: current_events_activity,
                 category: category_foo,
                 due_date: Date.tomorrow,
                 track_group: learn_group,
                 rank: 4,
                 individually_assignable: nil)

          expect(track.units).to eq [lesson.unit, current_events_lesson.unit]
        end
      end
    end
  end

  describe '#first_unit_id' do
    it 'returns the id of the first assigned unit' do
      unit_1 = build_stubbed(:unit)
      unit_2 = build_stubbed(:unit)
      allow(track).to receive(:units).and_return([unit_1, unit_2])
      expect(track.first_unit_id).to eq(unit_1.id)
    end

    it 'returns nil when there are no units' do
      allow(track).to receive(:units).and_return([])
      expect(track.first_unit_id).to eq(nil)
    end
  end

  describe '#last_unit_id' do
    it 'returns the id of the first assigned unit' do
      unit_1 = build_stubbed(:unit)
      unit_2 = build_stubbed(:unit)
      allow(track).to receive(:units).and_return([unit_1, unit_2])
      expect(track.last_unit_id).to eq(unit_2.id)
    end

    it 'returns nil when there are no units' do
      allow(track).to receive(:units).and_return([])
      expect(track.last_unit_id).to eq(nil)
    end
  end
end
