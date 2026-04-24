RSpec.describe StudentInteractionSettings do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:course) do
    create(
      :course,
      program:,
      allow_audio_transcripts: true,
      video_transcript_languages: 'foreign',
      video_subtitle_languages: 'foreign'
    )
  end
  let(:section) { create(:section, course:) }

  context 'when user is an instructor' do
    describe '#audio_transcript' do
      let(:interaction_settings) { described_class.new(instructor, section) }

      it 'returns true' do
        expect(interaction_settings.audio_transcript).to be true
      end
    end
  end

  context 'when user is a student' do
    let(:interaction_settings) { described_class.new(student, section) }

    describe '#audio_transcript' do
      context 'with student section config' do
        it 'returns the value from student config when not nil' do
          section_config = create(
            :student_section_config,
            section:,
            user: student,
            audio_transcript: false
          )
          expect(interaction_settings.audio_transcript).to eq(false)
        end

        it 'falls back to section value when student config is nil' do
          create(
            :student_section_config,
            section:,
            user: student,
            audio_transcript: nil
          )
          section.update(audio_transcript: false)
          expect(interaction_settings.audio_transcript).to eq(false)
        end
      end

      context 'without student section config' do
        it 'falls back to section value when present' do
          section.update(audio_transcript: false)
          expect(interaction_settings.audio_transcript).to eq(false)
        end

        it 'falls back to course value when section value is nil' do
          section.update(audio_transcript: nil)
          expect(interaction_settings.audio_transcript).to eq(true)
        end
      end
    end

    describe '#video_transcript_languages' do
      context 'with student section config' do
        it 'returns the value from student config when not nil' do
          section_config = create(
            :student_section_config,
            section:,
            user: student,
            video_transcript_languages: 'none'
          )
          expect(interaction_settings.video_transcript_languages).to eq('none')
        end

        it 'falls back to section value when student config is nil' do
          create(
            :student_section_config,
            section:,
            user: student,
            video_transcript_languages: nil
          )
          section.update(video_transcript_languages: 'none')
          expect(interaction_settings.video_transcript_languages).to eq('none')
        end
      end

      context 'without student section config' do
        it 'falls back to section value when present' do
          section.update(video_transcript_languages: 'none')
          expect(interaction_settings.video_transcript_languages).to eq('none')
        end

        it 'falls back to course value when section value is nil' do
          section.update(video_transcript_languages: nil)
          expect(interaction_settings.video_transcript_languages).to eq('foreign')
        end

        it 'returns none if no course is present' do
          section.course = nil
          expect(interaction_settings.video_transcript_languages).to eq('none')
        end
      end
    end

    describe '#video_subtitle_languages' do
      context 'with student section config' do
        it 'returns the value from student config when not nil' do
          section_config = create(
            :student_section_config,
            section:,
            user: student,
            video_subtitle_languages: 'none'
          )
          expect(interaction_settings.video_subtitle_languages).to eq('none')
        end

        it 'falls back to section value when student config is nil' do
          create(
            :student_section_config,
            section:,
            user: student,
            video_subtitle_languages: nil
          )
          section.update(video_subtitle_languages: 'none')
          expect(interaction_settings.video_subtitle_languages).to eq('none')
        end
      end

      context 'without student section config' do
        it 'falls back to section value when present' do
          section.update(video_subtitle_languages: 'none')
          expect(interaction_settings.video_subtitle_languages).to eq('none')
        end

        it 'falls back to course value when section value is nil' do
          section.update(video_subtitle_languages: nil)
          expect(interaction_settings.video_subtitle_languages).to eq('foreign')
        end

        it 'returns foreign if no course is present' do
          section.course = nil
          expect(interaction_settings.video_subtitle_languages).to eq('foreign')
        end
      end
    end

    describe '#input_mode' do
      context 'with student section config' do
        it 'returns the value from student config when not nil' do
          create(:student_section_config, section: section, user: student, input_mode: 'text')
          interaction_settings = described_class.new(student, section)
          expect(interaction_settings.input_mode).to eq('text')
        end

        it 'falls back to section value when student config is nil' do
          create(:student_section_config, section: section, user: student, input_mode: nil)
          section.update(input_mode: 'speech-and-text')
          interaction_settings = described_class.new(student, section)
          expect(interaction_settings.input_mode).to eq('speech-and-text')
        end
      end

      context 'without student section config' do
        it 'falls back to section value when present' do
          section.update(input_mode: 'text-no-audio')
          interaction_settings = described_class.new(student, section)
          expect(interaction_settings.input_mode).to eq('text-no-audio')
        end

        it 'falls back to default value when section value is nil' do
          section.update(input_mode: nil)
          interaction_settings = described_class.new(student, section)
          expect(interaction_settings.input_mode).to eq('speech')
        end
      end
    end

    describe '#effective_default_input_mode' do
      it 'returns section.input_mode if present' do
        section.update(input_mode: 'text')
        interaction_settings = described_class.new(student, section)
        expect(interaction_settings.effective_default_input_mode).to eq('text')
      end

      it 'returns "speech" if section.input_mode is nil' do
        section.update(input_mode: nil)
        interaction_settings = described_class.new(student, section)
        expect(interaction_settings.effective_default_input_mode).to eq('speech')
      end
    end

    describe '#config_matches_effective_defaults?' do
      context 'when there is no config' do
        it 'returns true' do
          expect(interaction_settings.config_matches_effective_defaults?).to be true
        end
      end

      context 'when there is a config' do
        let(:config) { create(:student_section_config, section:, user: student) }
        let(:interaction_settings) { described_class.new(student, section, config) }

        it 'returns true when all values are nil' do
          expect(interaction_settings.config_matches_effective_defaults?).to be true
        end

        it 'returns true when values match effective defaults' do
          config.update!(
            audio_transcript: true,
            video_subtitle_languages: 'foreign',
            video_transcript_languages: 'foreign'
          )
          expect(interaction_settings.config_matches_effective_defaults?).to be true
        end

        it 'returns true when some values are nil and others match' do
          config.update!(
            audio_transcript: true,
            video_subtitle_languages: nil,
            video_transcript_languages: 'foreign'
          )
          expect(interaction_settings.config_matches_effective_defaults?).to be true
        end

        it 'returns false when any non-nil value differs from effective default' do
          config.update!(
            audio_transcript: false,
            video_subtitle_languages: nil,
            video_transcript_languages: nil
          )
          expect(interaction_settings.config_matches_effective_defaults?).to be false
        end
      end

      it 'returns true if input_mode matches effective default' do
        section.update(input_mode: 'text')
        config = create(:student_section_config, section: section, user: student, input_mode: 'text')
        interaction_settings = described_class.new(student, section, config)
        expect(interaction_settings.config_matches_effective_defaults?).to be true
      end

      it 'returns false if input_mode does not match effective default' do
        section.update(input_mode: 'speech')
        config = create(:student_section_config, section: section, user: student, input_mode: 'text')
        interaction_settings = described_class.new(student, section, config)
        expect(interaction_settings.config_matches_effective_defaults?).to be false
      end

      it 'returns true if input_mode is nil (uses default)' do
        section.update(input_mode: 'speech')
        config = create(:student_section_config, section: section, user: student, input_mode: nil)
        interaction_settings = described_class.new(student, section, config)
        expect(interaction_settings.config_matches_effective_defaults?).to be true
      end
    end
  end
end
