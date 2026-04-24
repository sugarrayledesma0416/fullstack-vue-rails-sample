describe IgcCopyJob do
  # TODO: refactor data setup common to this and the copier spec

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

  # An instructor
  let(:instructor) { create(:instructor) }
  let(:instructor2) { create(:instructor) }

  # IGC activities for the instructor and source program
  let(:src_lesson_1) { source_program.lessons[0] }
  let(:src_strand_1) do
    create(
      :concept,
      id: src_lesson_1.strands.first.location,
      lesson: src_lesson_1,
      program: source_program
    )
  end

  let!(:src_toc_entry_1) do
    create(:toc_entry, location: src_strand_1.id).tap do |entry|
      src_lesson_1.toc_entries[0] = entry
    end
  end

  let(:src_lesson_2) { source_program.lessons[1] }
  let(:src_strand_2) do
    create(
      :concept,
      id: src_lesson_2.strands.first.location,
      lesson: src_lesson_2,
      program: source_program
    )
  end

  let!(:src_toc_entry_2) do
    create(:toc_entry, location: src_strand_2.id).tap do |entry|
      src_lesson_2.toc_entries[0] = entry
    end
  end

  let(:src_lesson_3) { source_program.lessons[2] }
  let(:src_strand_3) do
    create(
      :concept,
      id: src_lesson_3.strands.first.location,
      lesson: src_lesson_3,
      program: source_program
    )
  end

  let!(:src_toc_entry_3) do
    create(:toc_entry, location: src_strand_3.id).tap do |entry|
      src_lesson_3.toc_entries[0] = entry
    end
  end

  let(:dest_lesson_1) { destination_program.lessons[0] }
    let(:dest_strand_1) do
      create(
        :concept,
        id: dest_lesson_1.strands.first.location,
        lesson: dest_lesson_1,
        program: destination_program
      )
    end
  let(:dest_lesson_2) { destination_program.lessons[1] }
    let(:dest_strand_2) do
      create(
        :concept,
        id: dest_lesson_2.strands.first.location,
        lesson: dest_lesson_2,
        program: destination_program
      )
    end
  let(:dest_lesson_3) { destination_program.lessons[2] }
    let(:dest_strand_3) do
      create(
        :concept,
        id: dest_lesson_3.strands.first.location,
        lesson: dest_lesson_3,
        program: destination_program
      )
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
      toc_location: src_strand_3.id,
      activity_type: 'exam',
      content_summary: {
        multiple_choice: 5,
        open_ended: 7,
        fill_in_the_blank: 15
      }.to_json
    )
  end

  let!(:instr_2_igc_activity_1) do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new).and_return(mock_content_object)
    allow(mock_content_object).to receive(:generate_xml).and_return('<xml />')
    create(
      :instructor_created_activity,
      instructor_id: instructor2.id,
      language_code: 'es',
      lesson: source_program.lessons.first,
      toc_location: src_strand_1.id
    )
  end

  let!(:instr_2_igc_activity_2) do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new)
      .and_return(mock_content_object)
    allow(mock_content_object).to receive(:generate_xml).and_return('<xml />')
    create(
      :instructor_created_activity,
      instructor_id: instructor2.id,
      language_code: 'es',
      lesson: source_program.lessons[1],
      toc_location: src_strand_2.id
    )
  end

  let!(:instr_2_igc_activity_3) do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    allow(MaestroActivityEngine::InstructorCreatedContent).to receive(:new)
      .and_return(mock_content_exam)
    allow(mock_content_exam).to receive(:generate_xml).and_return('<xml />')
    create(
      :instructor_created_activity,
      instructor_id: instructor2.id,
      language_code: 'es',
      lesson: source_program.lessons[1],
      toc_location: src_strand_2.id,
      activity_type: 'exam',
      content_summary: {
        multiple_choice: 5,
        open_ended: 7,
        fill_in_the_blank: 15
      }.to_json
    )
  end

  let(:igc_copy_job) do
    create(
      :igc_copy_job,
      instructor_id: instructor.id,
      src_program_id: source_program.id,
      dest_program_id: destination_program.id,
      to_be_copied_ids: [igc_activity_1.id, igc_activity_2.id, igc_activity_3.id],
      copied_ids: []
    )
  end

  let(:partial_igc_copy_job) do
    create(
      :igc_copy_job,
      instructor_id: instructor2.id,
      src_program_id: source_program.id,
      dest_program_id: destination_program.id,
      to_be_copied_ids: [instr_2_igc_activity_1.id],
      copied_ids: []
    )
  end

  let!(:mapping_for_strand_1) do
    create(
      :program_to_program_mapping,
      dest_program_id: destination_program.id,
      dest_strand_id: dest_strand_1.id,
      src_strand_id: src_strand_1.id
    )
  end

  let!(:mapping_for_strand_2) do
    create(
      :program_to_program_mapping,
      dest_program_id: destination_program.id,
      dest_strand_id: dest_strand_2.id,
      src_strand_id: src_strand_2.id
    )
  end

  let!(:mapping_for_strand_3) do
    create(
      :program_to_program_mapping,
      dest_program_id: destination_program.id,
      dest_strand_id: dest_strand_3.id,
      src_strand_id: src_strand_3.id
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

  let(:instr_2_dest_activity_1) do
    InstructorCreatedActivity.where(
      instructor_id: instructor2.id,
      lesson_id: dest_lesson_1.id,
      toc_location: dest_strand_1,
      title: instr_2_igc_activity_1.title
    ).first
  end

  let(:instr_2_dest_activity_2) do
    InstructorCreatedActivity.where(
      instructor_id: instructor2.id,
      lesson_id: dest_lesson_2.id,
      toc_location: dest_strand_2,
      title: instr_2_igc_activity_2.title
    ).first
  end

  let(:instr_2_dest_activity_3) do
    InstructorCreatedActivity.where(
      instructor_id: instructor2.id,
      lesson_id: dest_lesson_3.id,
      toc_location: dest_strand_3,
      title: instr_2_igc_activity_3.title
    ).first
  end

  describe '#run' do
    context 'if running for the first time' do
      it 'should copy all activities' do
        igc_copy_job.run

        [dest_activity_1, dest_activity_2, dest_activity_3].each do |activity|
          expect(activity).to be_present
        end
      end
    end

    context 'if running for a second time' do
      it 'should copy only what the record says should be copied' do
        partial_igc_copy_job.run

        expect(instr_2_dest_activity_1).to be_present
        expect(instr_2_dest_activity_2).not_to be_present
        expect(instr_2_dest_activity_3).not_to be_present
      end
    end

    context 'if the copy-attempt count reached a threshold' do
      it 'terminates the copy-attempt loop' do
        # This `allow` disables the real implementation of `#copy`,
        #   preventing anything from being copied and forcing
        #   the copy job to use up all of its attempts.
        #
        # NOTE: The `expect_any_instance_of_` by itself is sufficient
        #   both to suppress the real implementation and to keep count
        #   of the calls. I'm including the `allow` separately for clarity.
        allow_any_instance_of(InstructorGeneratedContentCopier)
          .to receive(:copy)

        expect_any_instance_of(InstructorGeneratedContentCopier)
          .to receive(:copy).exactly(5).times

        expect { igc_copy_job.run }.to raise_error('Not all activities were copied.')
      end
    end
  end

  describe '#to_be_copied_ids' do
    describe 'getter' do
      it 'parses value as array' do
        # setter is implicitly tested here
        igc_copy_job.to_be_copied_ids = [1, 2, 3]
        expect(igc_copy_job.to_be_copied_ids).to eq([1, 2, 3])
      end
    end
  end
end
