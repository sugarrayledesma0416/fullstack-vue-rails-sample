describe ProgramSettings do
  let(:creator) { create(:user) }
  let(:program_1) { create(:program, id: 80) }
  let(:program_2) { create(:program, id: 82) }
  let(:program_3) { create(:program, id: 84) }
  let(:program_4) { create(:program, id: 86) }
  let(:program_without_config) { create(:program, id: 38) }
  let(:additional_entries) do
    [
      { url: 'External link', label: 'http://example.com' },
      { url: 'Other link', label: 'https:/securelink.com' }
    ]
  end
  let(:program_1_settings) do
    {
      settings:
      [
        {
          type: 'link',
          label: 'Dictionary',
          link: 'http://www.wordreference.com/enfr/'
        },
        {
          type: 'link',
          label: 'My Vocabulary',
          link: '/80/vocab_words'
        }
      ],
      vocab_words: true,
      vtext_label: 'vWritings',
      teacher_vtext_label: "professor's guideline",
      hide_assessment: true,
      hide_activities: true,
      hide_my_content: true,
      vocab_definition: true,
      content_menu_additional_entries: additional_entries
    }
  end
  let(:program_2_settings) do
    {
      settings:
      [
        {
          type: 'link',
          label: 'Dictionary',
          link: 'http://www.wordreference.com/enit/'
        },
        {
          type: 'link',
          label: 'Vocabulary Tools',
          link: '/82/vocab_tools/units'
        }
      ],
      vocab_tools: '',
      study_center: true,
      audio_transcripts: true,
      vtext: { url: '/vtext/sentieri2e/book.html' },
      teacher_vtext: { url: '/vtext/teacher/sentieri2e/book.html' },
      allow_assessments_randomization: true,
      question_banks_enabled: true,
      share_to_portfolio: true,
      show_skills_and_refinement_filters: true,
      pmr_standard_reports_allowed: true,
      enable_concurrent_enrollment: true,
      ai_settings: { grading_suggestions: true }
    }
  end
  let(:program_3_settings) do
    {
      settings:
      [
        {
          type: 'link',
          label: 'Dictionary',
          link: 'http://www.wordreference.com/enit/'
        },
        {
          type: 'link',
          label: 'Vocabulary Tools',
          link: '/84/vocab_tools/units'
        }
      ],
      vocab_tools: 'My Vocabulary',
      ebook: 'New book access',
      speech_rec: true,
      enable_concurrent_enrollment: false,
      ai_settings: { grading_suggestions: false }
    }
  end
  let(:program_4_settings) do
    {
      settings:
      [
        {
          type: 'link',
          label: 'Dictionary',
          link: 'http://www.wordreference.com/enit/'
        },
        {
          type: 'link',
          label: 'Vocabulary Tools',
          link: '/84/vocab_tools/units'
        }
      ],
      vocab_tools: '',
      speech_rec: nil,
      vtext: { url: '' },
      teacher_vtext: { url: '' }
    }
  end
  let(:settings_1) { described_class.new(program_1) }
  let(:settings_2) { described_class.new(program_2) }
  let(:settings_3) { described_class.new(program_3) }
  let(:settings_4) { described_class.new(program_4) }

  let(:program_2_links) do
    [OpenStruct.new(type: 'link',
                    label: 'Dictionary',
                    link: 'http://www.wordreference.com/enit/'),
     OpenStruct.new(type: 'link',
                    label: 'Vocabulary Tools',
                    link: '/82/vocab_tools/units')]
  end

  before do
    ProgramConfig.create(
      program_1_settings.merge(
        program_id: program_1.id,
        creator_id: creator.id
      )
    )
    ProgramConfig.create(
      program_2_settings.merge(
        program_id: program_2.id,
        creator_id: creator.id
      )
    )
    ProgramConfig.create(
      program_3_settings.merge(
        program_id: program_3.id,
        creator_id: creator.id
      )
    )
    ProgramConfig.create(
      program_4_settings.merge(
        program_id: program_4.id,
        creator_id: creator.id
      )
    )
  end

  describe '#links' do
    context 'when the settings file is valid' do
      it 'returns settings of type link' do
        expect(settings_2.links).to match_array program_2_links
      end
    end

    context 'when there is no program config record' do
      let(:no_settings) { described_class.new(program_without_config) }

      it 'returns empty array' do
        expect(no_settings.links).to be_empty
      end
    end
  end

  describe '#has_vocab_words?' do
    it 'returns false if the vocab works key does not exists' do
      expect(settings_2).not_to have_vocab_words
    end

    it 'returns true if the vocab words key exists' do
      expect(settings_1).to have_vocab_words
    end
  end

  describe '#has_vocab_definition?' do
    it 'returns true if the has_vocab_definition key is set' do
      expect(settings_1).to have_vocab_definition
    end

    it 'returns false if the has_vocab_definition key is not set' do
      expect(settings_2).not_to have_vocab_definition
    end
  end

  describe '#has_vocab_tools?' do
    it 'returns false if the vocab_tools key does not exist' do
      expect(settings_1).not_to have_vocab_tools
    end

    it 'returns true if the vocab_tools key does exist' do
      expect(settings_2).to have_vocab_tools
    end
  end

  describe '#vocab_tools_label' do
    it 'returns nil if there is no vocab-tools key' do
      expect(settings_1.vocab_tools_label).to be_nil
    end

    it 'returns "Vocabulary Tools" for a vocab-tools key with no value' do
      expect(settings_2.vocab_tools_label).to eq 'Vocabulary Tools'
    end

    it 'returns value of vocab-tools key if it is specified' do
      expect(settings_3.vocab_tools_label).to eq 'My Vocabulary'
    end

    it 'returns "Vocabulary Tools" for a vocab-tools key with an empty string' do
      expect(settings_4.vocab_tools_label).to eq 'Vocabulary Tools'
    end
  end

  describe '#hide_assessment?' do
    it 'returns false if hide_assessment does not exist' do
      expect(settings_2.hide_assessment?).to be_falsey
    end

    it 'returns true if hide_assessment does exist and is set to true' do
      expect(settings_1.hide_assessment?).to be_truthy
    end
  end

  describe '#has_assessment?' do
    it 'returns true if hide_assessment does not exist' do
      expect(settings_2.has_assessment?).to be_truthy
    end

    it 'returns false if hide_assessment exists and is set to true' do
      expect(settings_1.has_assessment?).to be_falsey
    end
  end

  describe '#hide_activities?' do
    it 'returns false if hide_activities does not exist' do
      expect(settings_2.hide_activities?).to be false
    end

    it 'returns true if hide_activities does exist and is set to true' do
      expect(settings_1.hide_activities?).to be true
    end
  end

  describe '#has_activities?' do
    it 'returns true if hide_activities does not exist' do
      expect(settings_2.has_activities?).to be true
    end

    it 'returns false if hide_activities exists and is set to true' do
      expect(settings_1.has_activities?).to be false
    end
  end

  describe '#hide_my_content?' do
    it 'returns false if hide_my_content does not exist' do
      expect(settings_2.hide_my_content?).to be false
    end

    it 'returns true if hide_my_content does exist and is set to true' do
      expect(settings_1.hide_my_content?).to be true
    end
  end

  describe '#has_my_content?' do
    it 'returns true if hide_my_content does not exist' do
      expect(settings_2.has_my_content?).to be true
    end

    it 'returns false if hide_my_content exists and is set to true' do
      expect(settings_1.has_my_content?).to be false
    end
  end

  describe '#has_audio_transcripts?' do
    it 'returns true if has_audio_transcripts does not exist' do
      expect(settings_2.has_audio_transcripts?).to be true
    end

    it 'returns false if has_audio_transcripts exists and is set to true' do
      expect(settings_1.has_audio_transcripts?).to be false
    end
  end

  describe '#allow_assessments_randomization?' do
    it 'returns false if allow_assessments_randomization does not exist' do
      expect(settings_1.allow_assessments_randomization?).to be false
    end

    it 'returns true if allow_assessments_randomization and is set to true' do
      expect(settings_2.allow_assessments_randomization?).to be true
    end
  end

  describe '#question_banks_enabled?' do
    it 'returns false if question_banks_enabled does not exist' do
      expect(settings_1.question_banks_enabled?).to be false
    end

    it 'returns true if question_banks_enabled and is set to true' do
      expect(settings_2.question_banks_enabled?).to be true
    end
  end

  describe '#has_vtext_link?' do
    context 'when program does not have vtext' do
      it 'returns nil' do
        expect(settings_1).not_to have_vtext_link
      end
    end

    context 'when program has vtext' do
      it 'returns vtext url' do
        expect(settings_2).to have_vtext_link
      end
    end

    context 'when program vtext url is empty' do
      it 'returns false' do
        expect(settings_4).not_to have_vtext_link
      end
    end
  end

  describe '#vtext_icon' do
    it 'returns vtext as default if no virtual textbook type is set' do
      expect(settings_4.vtext_icon).to eq 'vtext'
    end

    it 'returns the virtual textbook type in lower case, if it has been set' do
      program_4_settings[:vtext][:type] = 'eCompanion'
      ProgramConfig.create(
        program_4_settings.merge(
          program_id: program_4.id,
          creator_id: creator.id,
          created_at: 1.day.from_now
        )
      )

      expect(settings_4.vtext_icon).to eq 'ecompanion'
    end
  end

  describe '#vtext_description' do
    it "returns 'Interactive virtual textbook' if the virtual texbook is vText" do
      expect(settings_4.vtext_description).to eq 'Interactive virtual textbook'
    end

    it "returns 'Virtual textbook' if virtual textbook is something other than vText" do
      program_4_settings[:vtext][:type] = 'eCompanion'
      ProgramConfig.create(
        program_4_settings.merge(
          program_id: program_4.id,
          creator_id: creator.id,
          created_at: 1.day.from_now,
        )
      )

      expect(settings_4.vtext_description).to eq 'Virtual textbook'
    end
  end

  describe '#vtext_label' do
    it 'returns the overriden vtext label if exists' do
      expect(settings_1.vtext_label).to eq 'vWritings'
    end

    context 'when the vtext label has not been overriden' do
      it 'returns nil' do
        expect(settings_2.vtext_label).to be_nil
      end
    end
  end

  describe '#teacher_vtext_label' do
    it 'returns the overriden teacher vtext label if exists' do
      expect(settings_1.teacher_vtext_label).to eq "professor's guideline"
    end

    context 'when the teacher vtext label has not been overriden' do
      it 'returns nil' do
        expect(settings_2.teacher_vtext_label).to be_nil
      end
    end
  end

  describe '#ebook_label' do
    it 'returns "eBook" when the default ebook label should be used' do
      expect(settings_1.ebook_label).to eq 'eBook'
    end

    it 'returns the specified menu label in the overridden configuration when defined' do
      expect(settings_3.ebook_label).to eq 'New book access'
    end
  end

  describe '#use_default_ebook_label?' do
    it 'returns true if the ebook label has not been overridden' do
      expect(settings_1.use_default_ebook_label?).to be true
    end

    it 'returns true if the ebook label has been overridden to an empty string' do
      expect(settings_2.use_default_ebook_label?).to be true
    end

    it 'returns false if the ebook label has been overriden to a non-empty string' do
      expect(settings_3.use_default_ebook_label?).to be false
    end
  end

  describe '#vtext_link' do
    it 'returns the base vtext link' do
      expect(settings_2.vtext_link).to eq '/vtext/sentieri2e/book.html'
    end
  end

  describe '#has_teacher_vtext_link?' do
    context 'when program does not have techer vtext' do
      it 'returns nil' do
        expect(settings_1).not_to have_teacher_vtext_link
      end
    end

    context 'when program has teacher vtext' do
      it 'returns vtext url' do
        expect(settings_2).to have_teacher_vtext_link
      end
    end

    context 'when program teacher vtext url is empty' do
      it 'returns false' do
        expect(settings_4).not_to have_teacher_vtext_link
      end
    end
  end

  describe '#teacher_vtext_link' do
    context 'when program does not have teacher vtext' do
      it 'returns nil' do
        expect(settings_1.teacher_vtext_link).to be_nil
      end
    end

    context 'when program has teacher vtext' do
      it 'returns vtext url' do
        expect(settings_2.teacher_vtext_link)
          .to eq '/vtext/teacher/sentieri2e/book.html'
      end
    end

    context 'when program teacher vtext url is empty' do
      it 'returns nil' do
        expect(settings_4.teacher_vtext_link).to be_nil
      end
    end
  end

  describe '#has_study_center?' do
    it 'returns false if the study_center does not exist' do
      expect(settings_1).not_to have_study_center
    end

    it 'returns true if the study_center does exist' do
      expect(settings_2).to have_study_center
    end
  end

  describe '#share_to_portfolio?' do
    it 'returns false if share_to_portfolio does not exist' do
      expect(settings_1.share_to_portfolio?).to be false
    end

    it 'returns true if share_to_portfolio exists and is set to true' do
      expect(settings_2.share_to_portfolio?).to be true
    end
  end

  describe '#show_skills_and_refinement_filters?' do
    it 'returns false if show_skills_and_refinement_filters does not exist' do
      expect(settings_1.show_skills_and_refinement_filters?).to be false
    end

    it 'returns true if show_skills_and_refinement_filters exists and is set to true' do
      expect(settings_2.show_skills_and_refinement_filters?).to be true
    end
  end

  describe '#enable_concurrent_enrollment?' do
    it 'returns false if enable_concurrent_enrollment does not exist' do
      expect(settings_1.enable_concurrent_enrollment?).to be false
    end

    it 'returns true if enable_concurrent_enrollment exists and is set to true' do
      expect(settings_2.enable_concurrent_enrollment?).to be true
    end

    it 'returns false if enable_concurrent_enrollment exists and is set to false' do
      expect(settings_3.enable_concurrent_enrollment?).to be false
    end
  end

  describe '#ai_grading_feature_enabled?' do
    it 'returns false if ai_settings does not exist' do
      expect(settings_1.ai_grading_feature_enabled?).to be false
    end

    it 'returns true if ai_settings exists and grading_suggestions is set to true' do
      expect(settings_2.ai_grading_feature_enabled?).to be true
    end

    it 'returns false if ai_settings exists and grading_suggestions is set to false' do
      expect(settings_3.ai_grading_feature_enabled?).to be false
    end
  end

  describe '#pmr_standard_reports_allowed?' do
    it 'returns false if pmr_standard_reports_allowed does not exist' do
      expect(settings_1.pmr_standard_reports_allowed?).to be false
    end

    it 'returns true if pmr_standard_reports_allowed exists and is set to true' do
      expect(settings_2.pmr_standard_reports_allowed?).to be true
    end
  end

  describe '#has_speech_rec?' do
    it 'returns false if the speech rec key does not exist' do
      expect(settings_1).not_to have_speech_rec
    end

    it 'returns true if the speech rec key does exist' do
      expect(settings_3).to have_speech_rec
    end
  end

  describe '#content_menu_additional_entries' do
    context 'without additional menu entries' do
      it 'returns an empty array' do
        expect(settings_2.content_menu_additional_entries).to eq([])
      end
    end

    context 'with additional menu entries' do
      it 'returns the menu entries as an array of objects' do
        first_additional_entry = settings_1.content_menu_additional_entries[0]
        second_additional_entry = settings_1.content_menu_additional_entries[1]
        expect(first_additional_entry).to have_attributes(additional_entries[0])
        expect(second_additional_entry).to have_attributes(additional_entries[1])
      end
    end
  end
end
