describe CourseSectionUnarchiver do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, instructor: instructor, course: course) }
  let(:course_section_unarchiver) { described_class.new }

  describe '#unarchive' do
    context 'when section is archived and course is not archived' do
      it 'unarchives the section' do
        section.update!(is_archived: true)
        course_section_unarchiver.unarchive([section.id])
        section.reload
        expect(section).not_to be_is_archived
      end
    end

    context 'when section is not archived and course is archived' do
      it 'unarchives the course' do
        course.update!(is_archived: true)
        course_section_unarchiver.unarchive([section.id])
        course.reload
        expect(course).not_to be_is_archived
      end
    end

    context 'when both section and course are archived' do
      before do
        course.update!(is_archived: true)
        section.update!(is_archived: true)
      end

      it 'unarchives the section' do
        course_section_unarchiver.unarchive([section.id])
        section.reload
        expect(section).not_to be_is_archived
      end

      it 'unarchives the course' do
        course_section_unarchiver.unarchive([section.id])
        course.reload
        expect(course).not_to be_is_archived
      end

      it 'unarchives the section_instructor record' do
        course_section_unarchiver.unarchive([section.id])
        section.reload
        section.section_instructors.unscoped.each do |section_instructor|
          expect(section_instructor).not_to be_is_archived
        end
      end
    end

    context 'with enrollments in an archived section in an archived course,' do
      it 'does not generate errors' do
        course.update!(is_archived: true)

        # student enrollments have to be created before archiving the section
        # because of the belogns_to association requiring section exist
        section.students << create(:student)
        section.update!(is_archived: true)

        expect do
          course_section_unarchiver.unarchive([section.id])
        end.not_to raise_error
      end
    end

    context 'with enrollments' do
      let(:student) { create(:student) }

      before do
        section.students << student
        student.enrollments.by_section(section).first.update!(
          state: 'dropped', dropped_at: Time.zone.now
        )
        section.update!(is_archived: true)
      end

      context 'when students have not enrolled into an active course of the same program' do
        context 'when course is not closed' do
          it 'restores the student enrollment on the unarchived section' do
            course_section_unarchiver.unarchive([section.id])
            expect(student.enrollments.by_section(section).first).to be_enrolled
          end
        end

        context 'when course is closed' do
          it 'restores the enrollment on a marked complete state' do
            course.update!(end_date: 1.day.ago, allow_past_end_date: true)
            course_section_unarchiver.unarchive([section.id])
            expect(student.enrollments.by_section(section).first).to be_complete
          end
        end
      end

      context 'when students have enrolled into an active course of the same program' do
        let(:another_section) do
          create(
            :section,
            course: create(:course, program: program),
            instructor: create(:instructor)
          )
        end

        before do
          another_section.students << student
        end

        context 'when course of section to restore is active' do
          xit 'makes sure that the student is marked as dropped on the unarchived section' do
            section.enrollments.first.update_column(:state, 'enrolled')
            course_section_unarchiver.unarchive([section.id])
            expect(student.enrollments.by_section(section).first).to be_dropped
          end
        end

        context 'when course of section to restore is closed' do
          it 'restores the enrollment on a marked complete state' do
            course.update!(end_date: 1.day.ago, allow_past_end_date: true)
            course_section_unarchiver.unarchive([section.id])
            expect(student.enrollments.by_section(section).first).to be_complete
          end
        end

        context 'when course of another section is closed' do
          it 'restores the enrollment state' do
            another_section.course.update!(end_date: 1.day.ago, allow_past_end_date: true)
            course_section_unarchiver.unarchive([section.id])
            expect(student.enrollments.by_section(section).first).to be_enrolled
          end
        end
      end
    end
  end

  describe '#message' do
    it 'joins the messages returned by the logger object' do
      expected_messages = ['text 1', 'text 2']
      allow(CourseSectionUnarchiver::UnarchiverLogger).to receive(:new)
        .and_return(double('logger', messages: expected_messages))
      expect(course_section_unarchiver.message).to eq('text 1 text 2')
    end
  end

  describe CourseSectionUnarchiver::UnarchiverLogger do
    let(:unarchiver_logger) { described_class.new }

    describe '#messages' do
      let(:student) { create(:student) }

      context 'when adding a section' do
        it 'returns a message with the unarchived section id' do
          unarchiver_logger.log_section(section)
          expect(unarchiver_logger.messages).to include(
            "The sections with IDs #{section.id} have been restored."
          )
        end
      end

      context 'when adding an enrollment' do
        it 'returns a message with the enrollments and their section id' do
          section.students << student
          unarchiver_logger.log_concurrent_enrollment(student.enrollments.first)
          expect(unarchiver_logger.messages).to include(
            'The following enrollments were not restored because of section ' \
            "concurrency: \"section_id: #{section.id} student_ids: (#{student.id})\""
          )
        end
      end

      context 'when no section or enrollments are logged' do
        it 'returns a no sections processed message' do
          expect(unarchiver_logger.messages).to eq(
            ['None of the sections given were in an archived state.']
          )
        end
      end
    end
  end
end
