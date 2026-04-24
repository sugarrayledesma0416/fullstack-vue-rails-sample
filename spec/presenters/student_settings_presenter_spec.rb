describe StudentSettingsPresenter do
  let(:program) { create(:program) }
  let(:course) { create(:course) }
  let(:other_section) { create(:section, course:) }
  let(:section) { create(:section, course:) }
  let(:current_user) { create(:user) }
  let(:presenter) { StudentSettingsPresenter.new(section, program, current_user) }

  describe '#student_data' do
    let(:student) { create(:student) }
    let!(:enrollment) do
      create(:enrollment, section:, user: student, state: 'enrolled')
    end
    let!(:other_enrollment) do
      create(:enrollment, section: other_section, user: student, state: 'enrolled')
    end

    let(:default_student_data) do
      {
        id: student.id,
        firstName: student.first_name,
        lastName: student.last_name,
        audio_transcript: false,
        video_subtitle_languages: 'foreign',
        video_transcript_languages: 'none'
      }
    end

    context 'when student has no section-specific configuration' do
      it 'returns student data with course default settings including input_mode' do
        section.update(input_mode: 'text')
        expect(presenter.student_data).to eq([{
          id: student.id,
          firstName: student.first_name,
          lastName: student.last_name,
          audio_transcript: false,
          video_subtitle_languages: 'foreign',
          video_transcript_languages: 'none',
          input_mode: 'text'
        }])
      end

      it 'returns student data with default input_mode when section input_mode is nil' do
        section.update(input_mode: nil)
        expect(presenter.student_data.first[:input_mode]).to eq('speech')
      end
    end

    context 'when student has section-specific configuration' do
      let!(:student_section_config) do
        create(:student_section_config,
               user: student,
               section:,
               audio_transcript: true,
               video_subtitle_languages: 'foreign_and_english',
               video_transcript_languages: 'foreign_and_english',
               input_mode: 'speech-and-text')
      end

      it 'returns student data with overridden settings' do
        expect(presenter.student_data).to eq([{
          id: student.id,
          firstName: student.first_name,
          lastName: student.last_name,
          audio_transcript: true,
          video_subtitle_languages: 'foreign_and_english',
          video_transcript_languages: 'foreign_and_english',
          input_mode: 'speech-and-text'
        }])
      end
    end

    context 'when student has multiple section configurations' do
      it 'returns student data with overridden settings from the correct section' do
        create(:student_section_config,
               user: student,
               section: other_section,
               audio_transcript: false,
               video_subtitle_languages: 'none',
               video_transcript_languages: 'foreign')
        create(:student_section_config,
               user: student,
               section:,
               audio_transcript: true,
               video_subtitle_languages: 'foreign_and_english',
               video_transcript_languages: 'foreign_and_english')

        expect(presenter.student_data).to eq([{
                                               id: student.id,
                                               firstName: student.first_name,
                                               lastName: student.last_name,
                                               audio_transcript: true,
                                               video_subtitle_languages: 'foreign_and_english',
                                               video_transcript_languages: 'foreign_and_english',
                                               input_mode: 'speech'
                                             }])
      end
    end

    context 'when student has partial section configuration' do
      let!(:student_section_config) do
        create(:student_section_config,
               user: student,
               section:,
               audio_transcript: true,
               video_subtitle_languages: nil,
               video_transcript_languages: nil)
      end

      it 'returns student data with mixed settings' do
        expect(presenter.student_data).to eq([{
                                               id: student.id,
                                               firstName: student.first_name,
                                               lastName: student.last_name,
                                               audio_transcript: true,
                                               video_subtitle_languages: 'foreign',
                                               video_transcript_languages: 'none',
                                               input_mode: 'speech'
                                             }])
      end
    end
  end

  describe '#section_video_transcript_languages' do
    context 'when section has a value' do
      before do
        section.update(video_transcript_languages: 'none')
      end

      it 'returns the section value' do
        expect(presenter.section_video_transcript_languages).to eq('none')
      end
    end

    context 'when section value is nil' do
      before do
        section.update(video_transcript_languages: nil)
        course.update(video_transcript_languages: 'foreign')
      end

      it 'falls back to course value' do
        expect(presenter.section_video_transcript_languages).to eq('foreign')
      end
    end
  end

  describe '#section_video_subtitle_languages' do
    context 'when section has a value' do
      before do
        section.update(video_subtitle_languages: 'none')
      end

      it 'returns the section value' do
        expect(presenter.section_video_subtitle_languages).to eq('none')
      end
    end

    context 'when section value is nil' do
      before do
        section.update(video_subtitle_languages: nil)
        course.update(video_subtitle_languages: 'foreign')
      end

      it 'falls back to course value' do
        expect(presenter.section_video_subtitle_languages).to eq('foreign')
      end
    end
  end

  describe '#section_audio_transcript' do
    context 'when section has a value' do
      before do
        section.update(audio_transcript: true)
      end

      it 'returns the section value' do
        expect(presenter.section_audio_transcript).to be true
      end
    end

    context 'when section value is nil' do
      before do
        section.update(audio_transcript: nil)
        course.update(allow_audio_transcripts: true)
      end

      it 'falls back to course value' do
        expect(presenter.section_audio_transcript).to be true
      end
    end
  end

  describe '#students' do
    let(:student1) { create(:student, last_name: 'Adams') }
    let(:student2) { create(:student, last_name: 'Brown') }
    let(:student3) { create(:student, last_name: 'Carter') }

    before do
      create(:enrollment, section:, user: student2, state: 'enrolled')
      create(:enrollment, section:, user: student1, state: 'enrolled')
      create(:enrollment, section:, user: student3, state: 'dropped')
    end

    it 'returns enrolled students ordered by last name' do
      expect(presenter.students.map(&:last_name)).to eq(%w[Adams Brown])
    end

    it 'excludes dropped students' do
      expect(presenter.students).not_to include(student3)
    end
  end

  describe '#section' do
    it 'returns the section' do
      expect(presenter.section).to eq(section)
    end
  end

  describe '#program' do
    it 'returns the program' do
      expect(presenter.program).to eq(program)
    end
  end

  describe '#section_input_mode' do
    it 'returns the section input_mode if present' do
      section.update(input_mode: 'text')
      expect(presenter.section_input_mode).to eq('text')
    end

    it 'returns "speech" if section input_mode is nil' do
      section.update(input_mode: nil)
      expect(presenter.section_input_mode).to eq('speech')
    end
  end

  describe '#ai_input_modes' do
    it 'returns the AI input modes display mapping' do
      expected_mapping = {
        'speech' => 'Student Audio Response',
        'speech-and-text' => 'Student Audio or Text Response',
        'text' => 'Student Text Response',
        'text-no-audio' => 'Text Only Chat'
      }
      expect(presenter.ai_input_modes).to eq(expected_mapping)
    end
  end

  describe '#ai_input_mode_values' do
    it 'returns the AI input mode values' do
      expect(presenter.ai_input_mode_values).to eq(%w[speech text speech-and-text text-no-audio])
    end
  end

  describe '#back_to_link' do
    let(:request) { double('request', host: 'example.com') }
    let(:presenter_with_request) do
      StudentSettingsPresenter.new(section, program, current_user, request)
    end

    context 'when there is no referer' do
      before do
        allow(request).to receive(:referer).and_return(nil)
      end

      it 'returns the instructor dashboard path' do
        expect(presenter_with_request.back_to_link).to eq("/instructor/dashboard/#{program.id}")
      end
    end

    context 'when referer is from a different host' do
      before do
        allow(request).to receive(:referer).and_return('https://other-domain.com/some/path')
      end

      it 'returns the instructor dashboard path' do
        expect(presenter_with_request.back_to_link).to eq("/instructor/dashboard/#{program.id}")
      end
    end

    context 'when referer is from same host' do
      before do
        allow(request).to receive(:referer).and_return('https://example.com/courses/123')
      end

      it 'returns the referer path' do
        expect(presenter_with_request.back_to_link).to eq('/courses/123')
      end
    end

    context 'when referer is malformed' do
      before do
        allow(request).to receive(:referer).and_return('not-a-valid-url')
      end

      it 'returns the instructor dashboard path' do
        expect(presenter_with_request.back_to_link).to eq("/instructor/dashboard/#{program.id}")
      end
    end
  end

  describe '#rostering?' do
    context 'when current_user has rostering? as true' do
      before do
        allow(current_user).to receive(:rostering?).and_return(true)
        allow(current_user).to receive(:cartridge?).and_return(false)
      end

      it 'returns true' do
        expect(presenter.rostering?).to be true
      end
    end

    context 'when current_user has cartridge? as true' do
      before do
        allow(current_user).to receive(:rostering?).and_return(false)
        allow(current_user).to receive(:cartridge?).and_return(true)
      end

      it 'returns true' do
        expect(presenter.rostering?).to be true
      end
    end

    context 'when both rostering? and cartridge? are false' do
      before do
        allow(current_user).to receive(:rostering?).and_return(false)
        allow(current_user).to receive(:cartridge?).and_return(false)
      end

      it 'returns false' do
        expect(presenter.rostering?).to be false
      end
    end
  end
end
