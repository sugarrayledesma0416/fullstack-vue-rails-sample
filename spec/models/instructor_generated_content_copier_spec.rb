describe InstructorGeneratedContentCopier do
  def create_or_update_concept(lesson, program)
    concept_id = lesson.strands.first.location

    concept = Concept.find_by(id: concept_id)
    if concept
      concept.update!(lesson_id: lesson.id, program_id: program.id)
      concept
    else
      create(
        :concept,
        id: concept_id,
        lesson: lesson,
        program: program
      )
    end
  end

  describe '#copy' do
    # Data setup:
    #
    # A source program with TOC entries
    let(:source_program) { create(:program_with_toc_entries) }

    # A target program
    let(:destination_program) { create(:program_with_toc_entries) }

    # An instructor
    let(:instructor) { create(:instructor) }

    # Mock call to MAE to create xml content
    let(:mock_content_object) do
      instance_double(
        MaestroActivityEngine::InstructorCreatedContent,
        activity_type: 'composition'
      )
    end

    let(:mock_content_exam) do
      instance_double(
        MaestroActivityEngine::InstructorCreatedContent,
        activity_type: 'exam'
      )
    end

    # IGC activities for the instructor and source program
    let(:src_lesson_1) { source_program.lessons[0] }
    let(:src_strand_1) do
      create_or_update_concept(src_lesson_1, source_program)
    end

    let(:src_lesson_2) { source_program.lessons[1] }
    let(:src_strand_2) do
      create_or_update_concept(src_lesson_2, source_program)
    end

    let(:src_lesson_3) { source_program.lessons[2] }
    let(:src_strand_3) do
      create_or_update_concept(src_lesson_3, source_program)
    end

    let(:dest_lesson_1) { destination_program.lessons[0] }

    let(:dest_strand_1) do
      create_or_update_concept(dest_lesson_1, destination_program)
    end
    let(:dest_lesson_2) { destination_program.lessons[1] }

    let(:dest_strand_2) do
      create_or_update_concept(dest_lesson_2, destination_program)
    end
    let(:dest_lesson_3) { destination_program.lessons[2] }

    let(:dest_strand_3) do
      create_or_update_concept(dest_lesson_3, destination_program)
    end

    let!(:igc_activity_1) do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new)
        .and_return(mock_content_object)
      allow(mock_content_object).to receive(:generate_xml).and_return('<xml />')
      create(
        :instructor_created_activity,
        instructor_id: instructor.id,
        language_code: 'es',
        lesson: source_program.lessons.first,
        title: 'igc 1',
        toc_location: src_strand_1.id
      )
    end

    let!(:igc_activity_2) do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new)
        .and_return(mock_content_object)
      allow(mock_content_object).to receive(:generate_xml).and_return('<xml />')
      create(
        :instructor_created_activity,
        instructor_id: instructor.id,
        language_code: 'es',
        lesson: source_program.lessons[1],
        title: 'igc 2',
        toc_location: src_strand_2.id
      )
    end

    let!(:igc_activity_3) do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new)
        .and_return(mock_content_exam)
      allow(mock_content_exam).to receive(:generate_xml).and_return('<xml />')
      create(
        :instructor_created_activity,
        instructor_id: instructor.id,
        language_code: 'es',
        lesson: source_program.lessons[2],
        title: 'igc 3',
        toc_location: src_strand_3.id,
        activity_type: 'exam',
        content_summary: {
          multiple_choice: 5,
          open_ended: 7,
          fill_in_the_blank: 15
        }.to_json
      )
    end

    # Activity records that we expect to exist if the copy
    #   is successful
    let(:dest_activity_1) do
      InstructorCreatedActivity.where(
        instructor_id: instructor.id,
        lesson_id: dest_lesson_1.id,
        toc_location: dest_strand_1,
        title: igc_activity_1.title
      ).first
    end

    let(:dest_activity_2) do
      InstructorCreatedActivity.where(
        instructor_id: instructor.id,
        lesson_id: dest_lesson_2.id,
        toc_location: dest_strand_2,
        title: igc_activity_2.title
      ).first
    end

    let(:dest_activity_3) do
      InstructorCreatedActivity.where(
        instructor_id: instructor.id,
        lesson_id: dest_lesson_3.id,
        toc_location: dest_strand_3,
        title: igc_activity_3.title
      ).first
    end

    before do
      create(
        :program_to_program_mapping,
        dest_program_id: destination_program.id,
        dest_strand_id: dest_strand_1.id,
        src_strand_id: src_strand_1.id
      )
      create(
        :program_to_program_mapping,
        dest_program_id: destination_program.id,
        dest_strand_id: dest_strand_2.id,
        src_strand_id: src_strand_2.id
      )
      create(
        :program_to_program_mapping,
        dest_program_id: destination_program.id,
        dest_strand_id: dest_strand_3.id,
        src_strand_id: src_strand_3.id
      )
    end

    context 'when all activities are to be copied,' do
      # The object under test
      let(:copier) do
        described_class.new(
          dest_program_id: destination_program.id,
          copied_ids: [],
          to_be_copied_ids: [
            igc_activity_1.id, igc_activity_2.id, igc_activity_3.id
          ]
        )
      end

      before do
        # run the copy
        copier.copy
      end

      # For each combination of source-activity, destination-activity,
      #   and destination-activity-associated values, run a given block.
      #
      # This is to DRY a few `it`s that differ only in their expectations.
      def check_copied_activities
        src_and_dest_activity_combinations = [
          [igc_activity_1, dest_activity_1, dest_lesson_1, dest_strand_1],
          [igc_activity_2, dest_activity_2, dest_lesson_2, dest_strand_2],
          [igc_activity_3, dest_activity_3, dest_lesson_3, dest_strand_3]
        ]

        src_and_dest_activity_combinations.each do |combination|
          yield(*combination)
        end
      end

      # Method to return an activity as a hash, minus any keys that we expect
      #   to have the same value in both source and destination.
      def unchanged_fields(activity)
        changed_fields = %w[
          concept_id
          created_at
          id
          instructor_revision_id
          lesson_id
          toc_location
          updated_at
        ]
        activity.attributes.except(*changed_fields)
      end

      it 'sets values for strand and lesson ID to values for destination program' do
        check_copied_activities do |_, dest_a, dest_lesson, dest_strand|
          expect(dest_a).to have_attributes(
            concept_id: dest_strand.id,
            toc_location: dest_strand.id,
            lesson_id: dest_lesson.id
          )
        end
      end

      it 'increments the instructor revision ID' do
        check_copied_activities do |src_a, dest_a, _, _|
          # The revision ID should have changed.
          expect(dest_a.instructor_revision_id).not_to eq(src_a.instructor_revision_id)
        end
      end

      it 'creates a new revision record' do
        check_copied_activities do |_, dest_a, _, _|
          # A record for the new revision ID should exist.
          expect(
            InstructorActivityRevision.find(dest_a.instructor_revision_id)
        ).to be_present
        end
      end

      it 'leaves other fields unchanged in new activity' do
        check_copied_activities do |src_a, dest_a, _, _|
          expect(unchanged_fields(dest_a)).to eq(unchanged_fields(src_a))
        end
      end

      it "copies the source activity's XML to the destination activity's " \
         'content filepath' do
        check_copied_activities do |src_a, dest_a, _, _|
          src_xml = File.read(src_a.content_filepath)
          dest_xml = File.read(dest_a.content_filepath)

          expect(src_xml).to eq(dest_xml)
        end
      end
    end

    context 'when the copier is initialized with a list of IDs to copy' do
      let(:partial_copier) do
        described_class.new(
          dest_program_id: destination_program.id,
          copied_ids: [],
          to_be_copied_ids: [igc_activity_2.id]
        )
      end

      it 'copies only the activities that are specified' do
        begin
          partial_copier.copy
          # If the test fails, display some useful debugging info.
        rescue IgcCopyException => e
          puts e.data.inspect
          raise e
        end

        # igc_activity_1 should not have been copied.
        expect(dest_activity_1).not_to be_present

        # igc_activity_2 should have been copied.
        expect(dest_activity_2).to be_present

        # igc_activity_3 should not have been copied.
        expect(dest_activity_3).not_to be_present
      end
    end
  end
end
