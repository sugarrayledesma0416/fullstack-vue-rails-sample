require 'rails_helper'

RSpec.describe SectionStudentSettings do
  let(:instructor) { create(:instructor) }
  let(:student1) { create(:student) }
  let(:student2) { create(:student) }
  let(:student3) { create(:student) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:program) { create(:program) }
  let(:settings) { described_class.new(section) }

  let(:valid_settings) do
    {
      audio_transcript: true,
      video_subtitle_languages: 'foreign_and_english',
      video_transcript_languages: 'foreign_and_english',
      input_mode: 'speech'
    }
  end

  before do
    create(:enrollment, user: student1, section:)
    create(:enrollment, user: student2, section:)
    create(:enrollment, user: student3, section:)
  end

  describe '#update_section_defaults' do
    context 'with valid settings' do
      it 'updates section defaults' do
        result = settings.update_section_defaults(valid_settings)

        section.reload
        expect(section.audio_transcript).to be true
        expect(section.video_subtitle_languages).to eq('foreign_and_english')
        expect(section.video_transcript_languages).to eq('foreign_and_english')
        expect(section.input_mode).to eq('speech')
        expect(result).to eq(valid_settings)
      end

      context 'when apply_to_all is true' do
        it 'updates section defaults and removes all student configs in a transaction' do
          config1 = create(:student_section_config, section:, user: student1, input_mode: 'text')
          config2 = create(:student_section_config, section:, user: student2, input_mode: 'text')
          config3 = create(:student_section_config, section:, user: student3, input_mode: 'text')

          expect do
            settings.update_section_defaults(valid_settings, apply_to_all: true)
          end.to change(StudentSectionConfig, :count).by(-3)

          section.reload
          expect(section.audio_transcript).to be true
          expect(section.video_subtitle_languages).to eq('foreign_and_english')
          expect(section.video_transcript_languages).to eq('foreign_and_english')
          expect(section.input_mode).to eq('speech')
        end

        it 'rolls back both changes if section update fails' do
          # Create some existing student configs
          config1 = create(:student_section_config, section:, user: student1)
          config2 = create(:student_section_config, section:, user: student2)

          # Make the section update fail
          allow(section).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(section))

          expect do
            settings.update_section_defaults(valid_settings, apply_to_all: true)
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(StudentSectionConfig.count).to eq(2)
          section.reload
          expect(section.audio_transcript).not_to be true
          expect(section.video_subtitle_languages).not_to eq('foreign_and_english')
          expect(section.video_transcript_languages).not_to eq('foreign_and_english')
        end

        it 'rolls back both changes if student config deletion fails' do
          # Create some existing student configs
          config1 = create(:student_section_config, section:, user: student1)
          config2 = create(:student_section_config, section:, user: student2)

          # Make the student config deletion fail
          allow(StudentSectionConfig).to receive(:where).and_raise(ActiveRecord::StatementInvalid.new('Database error'))

          expect do
            settings.update_section_defaults(valid_settings, apply_to_all: true)
          end.to raise_error(ActiveRecord::StatementInvalid)

          expect(StudentSectionConfig.count).to eq(2)
          section.reload
          expect(section.audio_transcript).not_to be true
          expect(section.video_subtitle_languages).not_to eq('foreign_and_english')
          expect(section.video_transcript_languages).not_to eq('foreign_and_english')
        end
      end
    end
  end

  describe '#update_students' do
    context 'when settings differ from course defaults' do
      before do
        course.update(
          allow_audio_transcripts: false,
          video_subtitle_languages: 'foreign',
          video_transcript_languages: 'foreign'
        )
      end

      it 'creates new configs for all students in bulk' do
        expect do
          settings.update_students([student1.id, student2.id, student3.id], valid_settings)
        end.to change(StudentSectionConfig, :count).by(3)

        # Verify all students have the correct config
        [student1, student2, student3].each do |student|
          config = StudentSectionConfig.find_by(user: student, section:)
          expect(config).to be_present
          expect(config.audio_transcript).to be true
          expect(config.video_subtitle_languages).to eq('foreign_and_english')
          expect(config.video_transcript_languages).to eq('foreign_and_english')
          expect(config.input_mode).to eq('speech')
        end
      end

      it 'updates existing configs and creates new ones in bulk' do
        # Create an existing config for student1 with different settings
        existing_config = create(
          :student_section_config,
          user: student1,
          section:,
          audio_transcript: false,
          video_subtitle_languages: 'foreign',
          video_transcript_languages: 'foreign',
          input_mode: 'text'
        )

        # The course defaults are already set to false/foreign in the before block
        # So when we update to true/foreign_and_english, it should:
        # 1. Update student1's existing config
        # 2. Create new configs for student2 and student3
        expect do
          settings.update_students([student1.id, student2.id, student3.id], valid_settings)
        end.to change(StudentSectionConfig, :count).by(2)

        # Verify student1's config was updated
        existing_config.reload
        expect(existing_config.audio_transcript).to be true
        expect(existing_config.video_subtitle_languages).to eq('foreign_and_english')
        expect(existing_config.video_transcript_languages).to eq('foreign_and_english')
        expect(existing_config.input_mode).to eq('speech')
        # Verify new configs were created for other students
        [student2, student3].each do |student|
          config = StudentSectionConfig.find_by(user: student, section:)
          expect(config).to be_present
          expect(config.audio_transcript).to be true
          expect(config.video_subtitle_languages).to eq('foreign_and_english')
          expect(config.video_transcript_languages).to eq('foreign_and_english')
          expect(config.input_mode).to eq('speech')
        end
      end

      it 'removes configs that match defaults after update' do
        # Create configs for all students with non-default values
        create(
          :student_section_config,
          user: student1,
          section:,
          audio_transcript: true,
          video_subtitle_languages: 'foreign_and_english',
          video_transcript_languages: 'foreign_and_english',
          input_mode: 'speech'
        )
        create(
          :student_section_config,
          user: student2,
          section:,
          audio_transcript: true,
          video_subtitle_languages: 'foreign_and_english',
          video_transcript_languages: 'foreign_and_english',
          input_mode: 'speech'
        )
        create(
          :student_section_config,
          user: student3,
          section:,
          audio_transcript: true,
          video_subtitle_languages: 'foreign_and_english',
          video_transcript_languages: 'foreign_and_english',
          input_mode: 'speech'
        )

        # Update settings to match course defaults
        settings_to_update = {
          audio_transcript: false,
          video_subtitle_languages: 'foreign',
          video_transcript_languages: 'foreign'
        }

        expect do
          settings.update_students([student1.id, student2.id, student3.id], settings_to_update)
        end.to change(StudentSectionConfig, :count).by(-3)

        # Verify all configs were removed
        [student1, student2, student3].each do |student|
          expect(StudentSectionConfig.exists?(user: student, section:)).to be false
        end
      end
    end

    context 'when student validation fails' do
      context 'when student is not enrolled in section' do
        let(:unenrolled_student) { create(:student) }

        it 'raises UserNotFoundError' do
          expect do
            settings.update_students([unenrolled_student.id], valid_settings)
          end.to raise_error(described_class::UserNotFoundError,
                             'One or more students may not be enrolled in this section.')
        end
      end

      context 'when some students are not enrolled' do
        let(:student4) { create(:student) }
        let(:student5) { create(:student) }

        before do
          create(:enrollment, user: student4, section:)
          # student5 is not enrolled
        end

        it 'raises UserNotFoundError when some students are not enrolled' do
          expect do
            settings.update_students([student1.id, student2.id, student4.id, student5.id],
                                     valid_settings)
          end.to raise_error(described_class::UserNotFoundError,
                             'One or more students may not be enrolled in this section.')
        end
      end

      context 'when some user_ids do not exist' do
        it 'raises UserNotFoundError when student count does not match' do
          expect do
            settings.update_students([student1.id, student2.id, 999_999], valid_settings)
          end.to raise_error(described_class::UserNotFoundError,
                             'We couldn\'t find one or more students.')
        end
      end

      context 'when student has multiple enrollments (one transferred, one enrolled)' do
        before do
          # Create a transferred enrollment for student1 in the same section
          create(:enrollment, user: student1, section: section, state: 'transferred')
        end

        it 'successfully updates settings for enrolled students with multiple enrollment records' do
          expect do
            settings.update_students([student1.id, student2.id, student3.id], valid_settings)
          end.to change(StudentSectionConfig, :count).by(3)

          # Verify all students have the correct config
          [student1, student2, student3].each do |student|
            config = StudentSectionConfig.find_by(user: student, section:)
            expect(config).to be_present
            expect(config.audio_transcript).to be true
            expect(config.video_subtitle_languages).to eq('foreign_and_english')
            expect(config.video_transcript_languages).to eq('foreign_and_english')
            expect(config.input_mode).to eq('speech')
          end
        end
      end
    end

    context 'when user_ids are strings' do
      it 'handles string user_ids correctly' do
        expect do
          settings.update_students(
            [student1.id.to_s, student2.id.to_s, student3.id.to_s],
            valid_settings
          )
        end.to change(StudentSectionConfig, :count).by(3)

        # Verify all students have the correct config
        [student1, student2, student3].each do |student|
          config = StudentSectionConfig.find_by(user: student, section:)
          expect(config.audio_transcript).to be true
          expect(config.video_subtitle_languages).to eq('foreign_and_english')
          expect(config.video_transcript_languages).to eq('foreign_and_english')
          expect(config.input_mode).to eq('speech')
        end
      end
    end
  end
end
