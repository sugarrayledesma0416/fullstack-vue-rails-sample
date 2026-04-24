describe ProgramConfig do
  let(:program) { create(:program) }
  let(:datastore) do
    {
      course_setup_descriptions: {
        express_course: '<b>Express</b> course description',
        advanced_course: '<b>Advanced</b> course description',
        learning_tracks: {
          header: 'Learning tracks',
          general: 'General learning track description.',
          options_overall: 'Learning track options description.',
          options: [
            {
              label: 'Essentials',
              explanation: 'What option 1 covers'
            },
            {
              label: 'Complete',
              explanation: 'What option 2 covers'
            }
          ]
        }
      },
      pronto: nil,
      settings: [
        {
          label: 'Label 1',
          link: 'some/link/1',
          type: 'link'
        },
        {
          label: 'Label 2',
          link: 'some/link/2',
          type: 'link'
        }
      ],
      speech_rec: '',
      study_center: '',
      teacher_vtext: {
        url: 'teacher_vtext/url/book.html'
      },
      vocab_tools: '',
      vtext: {
        type: 'vText or eCompanion',
        url: 'vtext/url/book.html'
      }
    }
  end
  let(:course_setup_descriptions) { datastore[:course_setup_descriptions] }
  let(:learning_tracks) { course_setup_descriptions[:learning_tracks] }
  let(:options) { learning_tracks[:options] }

  let(:program_config) do
    described_class.create!(
      datastore.merge(
        program_id: program.id,
        creator_id: creator.id
      )
    )
  end

  let(:creator) { create(:user) }

  def create_program_config(attrs = {})
    create(
      :program_config,
      {
        creator: creator,
        program: program
      }.merge(attrs)
    )
  end

  describe 'validations' do
    def build_program_config(attrs = {})
      build(
        :program_config,
        {
          creator: creator,
          program: program
        }.merge(attrs)
      )
    end

    it 'requires a program' do
      program_config = described_class.new(
        creator_id: creator.id
      )
      expect(program_config).not_to be_valid
    end

    it 'requires a creator' do
      program_config = described_class.new(
        program_id: program.id
      )
      expect(program_config).not_to be_valid
    end

    it 'does not create the record if it same as a previous one' do
      described_class.create!(
        datastore.merge(
          program_id: program.id,
          creator_id: creator.id
        )
      )
      new_program_config = described_class.new(
        datastore.merge(
          program_id: program.id,
          creator_id: creator.id
        )
      )
      expect(new_program_config).not_to be_valid
      expect(
        new_program_config.errors.full_messages
      ).to(
        include 'No changes : Program settings remain the same.'
      )
    end

    it 'cannot be edited' do
      program_config.program_id = create(:program).id
      expect do
        program_config.save!
      end.to raise_exception ActiveRecord::ReadOnlyRecord
    end

    context 'when the program is not a VOL program,' do
      let(:program) { create(:program) }

      it 'is valid when the no standard set is present nor a grade range' do
        config = build_program_config(datastore)

        expect(config).to be_valid
      end

      it 'is valid when a supported standard set is present with a grade range' do
        standard_set = create(:standard_set)

        config = build_program_config(
          datastore.merge(
            standards_settings: {
              supported_standard_set_ids: [standard_set.id.to_s],
              min_grade: 'K',
              max_grade: '5'
            }
          )
        )

        expect(config).to be_valid
      end

      it 'is invalid when a standard set is present but not a grade range' do
        standard_set = create(:standard_set)

        config = build_program_config(
          datastore.merge(
            standards_settings: {
              supported_standard_set_ids: [standard_set.id.to_s]
            }
          )
        )

        expect(config).to be_invalid
      end

      it 'is invalid when a grade range is present but not a standard set' do
        config = build_program_config(
          datastore.merge(
            standards_settings: {
              min_grade: 'PK',
              max_grade: '9'
            }
          )
        )

        expect(config).to be_invalid
      end
    end

    context 'when the program is a VOL program,' do
      let(:program) { create(:vol_program) }

      it 'is valid when the no standard set is present' do
        config = build_program_config(datastore)

        expect(config).to be_valid
      end

      it 'is valid when a supported standard set is present' do
        standard_set = create(:standard_set)

        config = build_program_config(
          datastore.merge(
            standards_settings: {
              supported_standard_set_ids: [standard_set.id.to_s],
              min_grade: 'K',
              max_grade: '12'
            }
          )
        )
        config.valid?

        expect(config).to be_valid
      end
    end

    context 'when validating course_setup_descriptions attribute,' do
      context 'when the program is not a VOL program,' do
        let(:program) { create(:program) }

        it 'is valid when the express_course attribute is missing' do
          course_setup_descriptions.delete(:express_course)

          config = build_program_config(datastore)

          expect(config).to be_valid
        end

        it 'is valid when the advanced_course attribute is missing' do
          course_setup_descriptions.delete(:advanced_course)

          config = build_program_config(datastore)

          expect(config).to be_valid
        end

        it 'is valid when the learning_tracks attribute is missing' do
          course_setup_descriptions.delete(:learning_tracks)

          config = build_program_config(datastore)

          expect(config).to be_valid
        end
      end

      context 'when the program is a VOL program,' do
        let(:program) { create(:vol_program) }

        it 'is invalid when express_course attribute is missing' do
          course_setup_descriptions.delete(:express_course)

          config = build_program_config(datastore)
          config.valid?

          expect(config.errors.full_messages_for(:base)).to contain_exactly(
            'Course setup description missing: Express course'
          )
        end

        it 'is invalid when advanced_course attribute is missing' do
          course_setup_descriptions.delete(:advanced_course)

          config = build_program_config(datastore)
          config.valid?

          expect(config.errors.full_messages_for(:base)).to contain_exactly(
            'Course setup description missing: Advanced course'
          )
        end

        it 'is invalid when both the express course and the advanced course ' \
          'attributes are missing' do
          course_setup_descriptions.delete(:express_course)
          course_setup_descriptions.delete(:advanced_course)

          config = build_program_config(datastore)
          config.valid?

          expect(config.errors.full_messages_for(:base)).to contain_exactly(
            'Course setup description missing: Express course, Advanced course'
          )
        end

        it 'is invalid when the learning_tracks attribute is missing' do
          course_setup_descriptions.delete(:learning_tracks)

          config = build_program_config(datastore)
          config.valid?

          expect(config.errors.full_messages_for(:base)).to contain_exactly(
            'Learning tracks description missing: Header, General, Options overall',
            'Options description missing: Label, Explanation',
            'Options description missing: Label, Explanation'
          )
        end

        context 'when validating learning_tracks attribute,' do
          it 'is invalid when the header attribute is missing' do
            learning_tracks.delete(:header)

            config = build_program_config(datastore)
            config.valid?

            expect(config.errors.full_messages_for(:base)).to contain_exactly(
              'Learning tracks description missing: Header'
            )
          end

          it 'is invalid when the general attribute is missing' do
            learning_tracks.delete(:general)

            config = build_program_config(datastore)
            config.valid?

            expect(config.errors.full_messages_for(:base)).to contain_exactly(
              'Learning tracks description missing: General'
            )
          end

          it 'is invalid when the options_overall attribute is missing' do
            learning_tracks.delete(:options_overall)

            config = build_program_config(datastore)
            config.valid?

            expect(config.errors.full_messages_for(:base)).to contain_exactly(
              'Learning tracks description missing: Options overall'
            )
          end

          it 'is invalid when the options attribute is missing' do
            learning_tracks.delete(:options)

            config = build_program_config(datastore)
            config.valid?

            expect(config.errors.full_messages_for(:base)).to contain_exactly(
              'Options description missing: Label, Explanation',
              'Options description missing: Label, Explanation'
            )
          end

          it 'is valid when the options attribute is empty' do
            learning_tracks[:options] = []

            config = build_program_config(datastore)

            expect(config).to be_valid
          end

          it 'is valid when the options attribute has only one option' do
            options.shift

            config = build_program_config(datastore)

            expect(config).to be_valid
          end

          context 'when validationg an option attribute,' do
            let(:option) { options.first }

            it 'is invalid when the label attribute is missing' do
              option.delete(:label)

              config = build_program_config(datastore)
              config.valid?

              expect(config.errors.full_messages_for(:base)).to contain_exactly(
                'Options description missing: Label'
              )
            end

            it 'is invalid when the explanation attribute is missing' do
              option.delete(:explanation)

              config = build_program_config(datastore)
              config.valid?

              expect(config.errors.full_messages_for(:base)).to contain_exactly(
                'Options description missing: Explanation'
              )
            end
          end
        end
      end
    end
  end

  describe 'scopes' do
    let(:active_program_config) do
      described_class.create!(
        datastore.merge(
          program_id: program.id,
          creator_id: creator.id
        )
      )
    end
    let(:other_program_config) do
      described_class.create!(
        datastore.merge(
          program_id: create(:program).id,
          creator_id: creator.id
        )
      )
    end
    let(:same_program_config) do
      described_class.create!(
        datastore.merge(
          vtext: {
            type: 'different vtext',
            url: 'vtext/url/book.html'
          },
          program_id: program.id,
          creator_id: creator.id
        )
      )
    end

    before do
      # The program configs are sorted by creation time, that's why we create
      # this record first by travelling in the past.
      Timecop.travel(10.minutes.ago) do
        same_program_config
      end
      active_program_config
      other_program_config
    end

    describe '.program_version_history' do
      it 'returns the settings for the given program' do
        results = described_class.program_version_history(program)
        expect(results).to eq(
          [
            active_program_config,
            same_program_config
          ]
        )
      end
    end

    describe '.currently_active' do
      it 'returns the active settings for the given program' do
        results = described_class.currently_active(program)
        expect(results).to eq active_program_config
      end
    end
  end

  describe '#ai_grading_feature_enabled?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.ai_grading_feature_enabled?).to be false
    end

    it 'retuns false when the attribute is false' do
      program_config = create(
        :program_config,
        ai_settings: { grading_suggestions: false }
      )

      expect(program_config.ai_grading_feature_enabled?).to be false
    end

    it 'retuns true when the attribute is true' do
      program_config = create(
        :program_config,
        ai_settings: { grading_suggestions: true }
      )

      expect(program_config.ai_grading_feature_enabled?).to be true
    end
  end

  describe '#ai_program_level' do
    it 'returns nil when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.ai_program_level).to be_nil
    end

    it 'returns the attribute value when the attribute is in the datastore' do
      program_config = create(
        :program_config,
        ai_settings: { program_level: 'introductory' }
      )

      expect(program_config.ai_program_level).to eq 'introductory'
    end
  end

  describe '#allow_assessments_randomization' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.allow_assessments_randomization).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, allow_assessments_randomization: '')

      expect(program_config.allow_assessments_randomization).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, allow_assessments_randomization: false)

      expect(program_config.allow_assessments_randomization).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, allow_assessments_randomization: true)

      expect(program_config.allow_assessments_randomization).to be true
    end
  end

  describe '#allow_assessments_randomization?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.allow_assessments_randomization?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, allow_assessments_randomization: '')

      expect(program_config.allow_assessments_randomization?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, allow_assessments_randomization: false)

      expect(program_config.allow_assessments_randomization?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, allow_assessments_randomization: true)

      expect(program_config.allow_assessments_randomization?).to be true
    end
  end

  describe '#audio_transcripts' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.audio_transcripts).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, audio_transcripts: '')

      expect(program_config.audio_transcripts).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, audio_transcripts: false)

      expect(program_config.audio_transcripts).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, audio_transcripts: true)

      expect(program_config.audio_transcripts).to be true
    end
  end

  describe '#audio_transcripts?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.audio_transcripts?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, audio_transcripts: '')

      expect(program_config.audio_transcripts?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, audio_transcripts: false)

      expect(program_config.audio_transcripts?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, audio_transcripts: true)

      expect(program_config.audio_transcripts?).to be true
    end
  end

  describe '#content_menu_additional_entries' do
    it 'returns an empty array when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.content_menu_additional_entries).to eq([])
    end

    it 'returns an array of object representing the attribute' do
      program_config = create(
        :program_config,
        content_menu_additional_entries: [
          {
            label: 'label 1',
            program_id: '1234',
            target_user: 'target user 1',
            url: 'url 1'
          },
          {
            label: 'label 2',
            program_id: '5678',
            target_user: 'target user 2',
            url: 'url 2'
          }
        ]
      )

      expect(program_config.content_menu_additional_entries).to match(
        [
          an_object_having_attributes(
            label: 'label 1',
            program_id: '1234',
            target_user: 'target user 1',
            url: 'url 1'
          ),
          an_object_having_attributes(
            label: 'label 2',
            program_id: '5678',
            target_user: 'target user 2',
            url: 'url 2'
          )
        ]
      )
    end
  end

  describe '#course_setup_descriptions' do
    let(:datastore) do
      {
        course_setup_descriptions: {
          express_course: 'Things fast',
          advanced_course: 'Things slow',
          learning_tracks: {
            header: 'Learning tracks',
            general: 'General learning track description.',
            options_overall: 'Learning track options description.',
            options: [
              {
                label: 'Essentials 1',
                explanation: 'What option 1 covers'
              },
              {
                label: 'Essentials 2',
                explanation: 'What option 2 covers'
              }
            ]
          }
        }
      }
    end
    let(:course_setup_descriptions) { datastore[:course_setup_descriptions] }

    context 'when the datastore contains a course_setup_descriptions attribute,' do
      it 'returns a representation of the attribute' do
        config = create(:program_config, datastore)

        expect(config.course_setup_descriptions).to have_attributes(
          express_course: 'Things fast',
          advanced_course: 'Things slow',
          learning_tracks: an_object_having_attributes(
            header: 'Learning tracks',
            general: 'General learning track description.',
            options_overall: 'Learning track options description.',
            options: [
              an_object_having_attributes(
                label: 'Essentials 1',
                explanation: 'What option 1 covers'
              ),
              an_object_having_attributes(
                label: 'Essentials 2',
                explanation: 'What option 2 covers'
              )
            ]
          )
        )
      end

      context 'when the course_setup_descriptions has no learning tracks,' do
        it 'returns a representation of the attribute' do
          course_setup_descriptions.delete(:learning_tracks)

          config = create(:program_config, datastore)

          expect(config.course_setup_descriptions).to have_attributes(
            express_course: 'Things fast',
            advanced_course: 'Things slow',
            learning_tracks: an_object_having_attributes(
              header: '',
              general: '',
              options_overall: '',
              options: [
                an_object_having_attributes(
                  label: '',
                  explanation: ''
                ),
                an_object_having_attributes(
                  label: '',
                  explanation: ''
                )
              ]
            )
          )
        end
      end

      context 'when the learning tracks have no options attribute' do
        it 'returns a representation of the attribute' do
          course_setup_descriptions[:learning_tracks].delete(:options)

          config = create(:program_config, datastore)

          expect(config.course_setup_descriptions).to have_attributes(
            express_course: 'Things fast',
            advanced_course: 'Things slow',
            learning_tracks: an_object_having_attributes(
              header: 'Learning tracks',
              general: 'General learning track description.',
              options_overall: 'Learning track options description.',
              options: [
                an_object_having_attributes(
                  label: '',
                  explanation: ''
                ),
                an_object_having_attributes(
                  label: '',
                  explanation: ''
                )
              ]
            )
          )
        end
      end
    end

    context 'when the datastore does not contain a course_setup_descriptions attribute,' do
      it 'returns an empty course setup description object' do
        config = create(:program_config)

        expect(config.course_setup_descriptions).to have_attributes(
          express_course: '',
          advanced_course: '',
          learning_tracks: an_object_having_attributes(
            header: '',
            general: '',
            options_overall: '',
            options: [
              an_object_having_attributes(
                label: '',
                explanation: ''
              ),
              an_object_having_attributes(
                label: '',
                explanation: ''
              )
            ]
          )
        )
      end
    end
  end

  describe '#ebook' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.ebook).to be_nil
    end

    it 'returns the attribute value if the attribute is in the datastore' do
      program_config = create(:program_config, ebook: 'Override eBook title for Content Menu')

      expect(program_config.ebook).to eq('Override eBook title for Content Menu')
    end
  end

  describe '#hide_activities' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_activities).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_activities: '')

      expect(program_config.hide_activities).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_activities: false)

      expect(program_config.hide_activities).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_activities: true)

      expect(program_config.hide_activities).to be true
    end
  end

  describe '#hide_activities?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_activities?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_activities: '')

      expect(program_config.hide_activities?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_activities: false)

      expect(program_config.hide_activities?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_activities: true)

      expect(program_config.hide_activities?).to be true
    end
  end

  describe '#hide_assessment' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_assessment).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_assessment: '')

      expect(program_config.hide_assessment).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_assessment: false)

      expect(program_config.hide_assessment).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_assessment: true)

      expect(program_config.hide_assessment).to be true
    end
  end

  describe '#hide_assessment?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_assessment?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_assessment: '')

      expect(program_config.hide_assessment?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_assessment: false)

      expect(program_config.hide_assessment?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_assessment: true)

      expect(program_config.hide_assessment?).to be true
    end
  end

  describe '#hide_my_content' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_my_content).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_my_content: '')

      expect(program_config.hide_my_content).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_my_content: false)

      expect(program_config.hide_my_content).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_my_content: true)

      expect(program_config.hide_my_content).to be true
    end
  end

  describe '#hide_my_content?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_my_content?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_my_content: '')

      expect(program_config.hide_my_content?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_my_content: false)

      expect(program_config.hide_my_content?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_my_content: true)

      expect(program_config.hide_my_content?).to be true
    end
  end

  describe '#hide_translation' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_translation).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_translation: '')

      expect(program_config.hide_translation).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_translation: false)

      expect(program_config.hide_translation).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_translation: true)

      expect(program_config.hide_translation).to be true
    end
  end

  describe '#hide_translation?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.hide_translation?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, hide_translation: '')

      expect(program_config.hide_translation?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, hide_translation: false)

      expect(program_config.hide_translation?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, hide_translation: true)

      expect(program_config.hide_translation?).to be true
    end
  end

  describe '#practice_test_analytics_enabled' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.practice_test_analytics_enabled).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, practice_test_analytics_enabled: '')

      expect(program_config.practice_test_analytics_enabled).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, practice_test_analytics_enabled: false)

      expect(program_config.practice_test_analytics_enabled).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, practice_test_analytics_enabled: true)

      expect(program_config.practice_test_analytics_enabled).to be true
    end
  end

  describe '#practice_test_analytics_enabled?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.practice_test_analytics_enabled?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, practice_test_analytics_enabled: '')

      expect(program_config.practice_test_analytics_enabled?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, practice_test_analytics_enabled: false)

      expect(program_config.practice_test_analytics_enabled?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, practice_test_analytics_enabled: true)

      expect(program_config.practice_test_analytics_enabled?).to be true
    end
  end

  describe '#pronto' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.pronto).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, pronto: '')

      expect(program_config.pronto).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, pronto: false)

      expect(program_config.pronto).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, pronto: true)

      expect(program_config.pronto).to be true
    end
  end

  describe '#pronto?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.pronto?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, pronto: '')

      expect(program_config.pronto?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, pronto: false)

      expect(program_config.pronto?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, pronto: true)

      expect(program_config.pronto?).to be true
    end
  end

  describe '#question_banks_enabled' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.question_banks_enabled).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, question_banks_enabled: '')

      expect(program_config.question_banks_enabled).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, question_banks_enabled: false)

      expect(program_config.question_banks_enabled).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, question_banks_enabled: true)

      expect(program_config.question_banks_enabled).to be true
    end
  end

  describe '#question_banks_enabled?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.question_banks_enabled?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, question_banks_enabled: '')

      expect(program_config.question_banks_enabled?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, question_banks_enabled: false)

      expect(program_config.question_banks_enabled?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, question_banks_enabled: true)

      expect(program_config.question_banks_enabled?).to be true
    end
  end

  describe '#share_to_portfolio' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.share_to_portfolio).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, share_to_portfolio: false)

      expect(program_config.share_to_portfolio).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, share_to_portfolio: true)

      expect(program_config.share_to_portfolio).to be true
    end
  end

  describe '#share_to_portfolio?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.share_to_portfolio?).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, share_to_portfolio: false)

      expect(program_config.share_to_portfolio?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, share_to_portfolio: true)

      expect(program_config.share_to_portfolio?).to be true
    end
  end

  describe '#show_skills_and_refinement_filters' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.show_skills_and_refinement_filters).to be false
    end

    it 'returns false when the attribute is set to false' do
      program_config = create(:program_config, show_skills_and_refinement_filters: false)

      expect(program_config.show_skills_and_refinement_filters).to be false
      expect(program_config.show_skills_and_refinement_filters?).to be false
    end

    it 'returns true when the attribute is set to true,' do
      program_config = create(:program_config, show_skills_and_refinement_filters: true)

      expect(program_config.show_skills_and_refinement_filters).to be true
      expect(program_config.show_skills_and_refinement_filters?).to be true
    end
  end

  describe '#pmr_standard_reports_allowed' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.pmr_standard_reports_allowed).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, pmr_standard_reports_allowed: false)

      expect(program_config.pmr_standard_reports_allowed).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, pmr_standard_reports_allowed: true)

      expect(program_config.pmr_standard_reports_allowed).to be true
    end
  end

  describe '#pmr_standard_reports_allowed?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.pmr_standard_reports_allowed?).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, pmr_standard_reports_allowed: false)

      expect(program_config.pmr_standard_reports_allowed?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, pmr_standard_reports_allowed: true)

      expect(program_config.pmr_standard_reports_allowed?).to be true
    end
  end

  describe '#enable_concurrent_enrollment' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.enable_concurrent_enrollment).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, enable_concurrent_enrollment: false)

      expect(program_config.enable_concurrent_enrollment).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, enable_concurrent_enrollment: true)

      expect(program_config.enable_concurrent_enrollment).to be true
    end
  end

  describe '#enable_concurrent_enrollment?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.enable_concurrent_enrollment?).to be false
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, enable_concurrent_enrollment: false)

      expect(program_config.enable_concurrent_enrollment?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, enable_concurrent_enrollment: true)

      expect(program_config.enable_concurrent_enrollment?).to be true
    end
  end

  describe '#enable_concurrent_enrollment=' do
    let(:program_config_instance) {
      described_class.new(program_id: program.id, creator_id: creator.id)
    }

    it 'assigns true to enable_concurrent_enrollment field' do
      program_config_instance.enable_concurrent_enrollment = true
      expect(program_config_instance.enable_concurrent_enrollment). to be(true)
    end

    it 'assigns false to enable_concurrent_enrollment field' do
      program_config_instance.enable_concurrent_enrollment = false
      expect(program_config_instance.enable_concurrent_enrollment). to be(false)
    end
  end

  describe '#settings' do
    it 'returns an empty array when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.settings).to eq([])
    end

    it 'returns an array of setting objects representing the attribute' do
      expect(program_config.settings).to match(
        [
          an_object_having_attributes(
            label: 'Label 1',
            link: 'some/link/1',
            type: 'link'
          ),
          an_object_having_attributes(
            label: 'Label 2',
            link: 'some/link/2',
            type: 'link'
          )
        ]
      )
    end
  end

  describe '#settings_as_json' do
    it 'returns a JSON representation of an empty array when the setting attribute ' \
       'is not in the database' do
      program_config = create(:program_config)

      expect(program_config.settings_as_json).to eq '{}'
    end

    it 'returns the settings as a JSON string' do
      expect(program_config.settings_as_json).to eq datastore[:settings].to_json
    end
  end

  describe '#speech_rec' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.speech_rec).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, speech_rec: '')

      expect(program_config.speech_rec).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, speech_rec: false)

      expect(program_config.speech_rec).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, speech_rec: true)

      expect(program_config.speech_rec).to be true
    end
  end

  describe '#speech_rec?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.speech_rec?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, speech_rec: '')

      expect(program_config.speech_rec?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, speech_rec: false)

      expect(program_config.speech_rec?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, speech_rec: true)

      expect(program_config.speech_rec?).to be true
    end
  end

  describe '#study_center' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.study_center).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, study_center: '')

      expect(program_config.study_center).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, study_center: false)

      expect(program_config.study_center).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, study_center: true)

      expect(program_config.study_center).to be true
    end
  end

  describe '#study_center?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.study_center?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, study_center: '')

      expect(program_config.study_center?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, study_center: false)

      expect(program_config.study_center?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, study_center: true)

      expect(program_config.study_center?).to be true
    end
  end

  describe '#standards_settings=' do
    let(:standard_set_1) { create(:standard_set) }
    let(:standard_set_2) { create(:standard_set) }
    standards_settings = { min_grade: 'K', max_grade: '12' }

    context 'when setting an array of ids,' do
      it 'saves the ids' do
        program_config.standards_settings = standards_settings.merge(
          supported_standard_set_ids: [
            standard_set_1.id.to_s,
            standard_set_2.id.to_s
          ]
        )

        expect(program_config.supported_standard_set_ids).to contain_exactly(
          standard_set_1.id,
          standard_set_2.id
        )
      end

      it 'converts ids to integer before saving them' do
        program_config.standards_settings = standards_settings.merge(
          supported_standard_set_ids: [
            standard_set_1.id.to_s,
            standard_set_2.id.to_s
          ]
        )
        expect(program_config.supported_standard_set_ids).to contain_exactly(
          standard_set_1.id,
          standard_set_2.id
        )
      end

      it 'removes duplicated ids and saves the ids' do
        program_config.standards_settings = standards_settings.merge(
          supported_standard_set_ids: [
            standard_set_1.id.to_s,
            standard_set_1.id.to_s,
            standard_set_2.id.to_s
          ]
        )

        expect(program_config.supported_standard_set_ids).to contain_exactly(
          standard_set_1.id,
          standard_set_2.id
        )
      end

      it 'raises an error when passing invalid ids' do
        expect do
          program_config.standards_settings = standards_settings.merge(
            supported_standard_set_ids: [
              standard_set_1.id.to_s,
              'invalid_id'
            ]
          )
        end.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couln't find all Standard sets with 'id': (#{standard_set_1.id}, " \
          "invalid_id) (found 1 results, but was looking for 2). Couldn't " \
          'find Standard sets with ids invalid_id'
        )
      end
    end

    context 'when setting an individual id,' do
      it 'saves the id' do
        program_config.standards_settings = standards_settings.merge(
          supported_standard_set_ids: standard_set_1.id.to_s
        )

        expect(program_config.supported_standard_set_ids).to contain_exactly(
          standard_set_1.id
        )
      end

      it 'raises an error when passing an invalid id' do
        expect do
          program_config.standards_settings = standards_settings.merge(
            supported_standard_set_ids: 'invalid_id'
          )
        end.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couln't find Standard set with 'id'=[invalid_id]"
        )
      end
    end
  end

  describe '#grouped_supported_standard_set_ids' do
    it 'returns an empty array when the setting is not defined' do
      program_config = create(:program_config)

      expect(program_config.grouped_supported_standard_set_ids).to eq([])
    end

    it 'returns the list of supported standard set ids grouped by display name when the setting is defined' do
      standard_set_1 = create(:standard_set, display_name: 'display name 1')
      standard_set_2 = create(:standard_set, display_name: 'display name 1')
      standard_set_3 = create(:standard_set, display_name: 'display name 2')

      program_config = create(
        :program_config_with_standard_sets,
        supported_standard_sets: [
          standard_set_1, standard_set_2, standard_set_3
        ]
      )

      expect(program_config.grouped_supported_standard_set_ids).to contain_exactly(
        "#{standard_set_1.id},#{standard_set_2.id}", standard_set_3.id.to_s
      )
    end
  end

  describe '#supported_standard_set_ids' do
    it 'returns an empty array when the setting is not defined' do
      program_config = create(:program_config)

      expect(program_config.supported_standard_set_ids).to eq([])
    end

    it 'returns the list of supported standard setting ids when the setting is defined' do
      standard_set_1 = create(:standard_set)
      standard_set_2 = create(:standard_set)

      program_config = create(
        :program_config_with_standard_sets,
        supported_standard_sets: [
          standard_set_1, standard_set_2
        ]
      )

      expect(program_config.supported_standard_set_ids).to contain_exactly(
        standard_set_1.id, standard_set_2.id
      )
    end
  end

  describe '#has_supported_standard_sets_selected' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.has_supported_standard_sets_selected?).to be false
    end

    it 'returns true when the attribute is present in the datastore' do
      standard_set_1 = create(:standard_set)
      standard_set_2 = create(:standard_set)

      program_config = create(
        :program_config_with_standard_sets,
        supported_standard_sets: [standard_set_1, standard_set_2]
      )

      expect(program_config.has_supported_standard_sets_selected?).to be true
    end
  end

  describe '#supported_standard_sets' do
    it 'returns an empty array when the setting is not defined' do
      program_config = create(:program_config)

      expect(program_config.supported_standard_sets).to eq([])
    end

    it 'returns a collection of StandardSettings when the setting is defined' do
      standard_set_1 = create(:standard_set)
      standard_set_2 = create(:standard_set)
      program_config = create(
        :program_config_with_standard_sets,
        supported_standard_sets: [standard_set_1, standard_set_2]
      )

      expect(program_config.supported_standard_sets).to contain_exactly(
        standard_set_1, standard_set_2
      )
    end
  end

  describe '#teacher_vtext' do
    it 'returns nil when the attribute if not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.teacher_vtext).to be_nil
    end

    it 'returns a structure representing the attribute if present in the datastore' do
      program_config = create(:program_config, teacher_vtext: { url: 'some url' })

      expect(program_config.teacher_vtext).to have_attributes(
        url: 'some url'
      )
    end
  end

  describe '#teacher_vtext?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.teacher_vtext?).to be false
    end

    it 'returns false when the attribute does not contain a url key' do
      program_config = create(:program_config, teacher_vtext: {})

      expect(program_config.teacher_vtext?).to be false
    end

    it 'returns false when the attribute contains a blank url key' do
      program_config = create(:program_config, teacher_vtext: { url: '' })

      expect(program_config.teacher_vtext?).to be false
    end

    it 'returns true when the attribute contains a non-blank url key' do
      program_config = create(:program_config, teacher_vtext: { url: 'some url' })

      expect(program_config.teacher_vtext?).to be true
    end
  end

  describe '#teacher_vtext_label' do
    it 'returns nil when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.teacher_vtext_label).to be_nil
    end

    it 'returns the attribute value when present in the datastore' do
      program_config = create(:program_config, teacher_vtext_label: 'blah')

      expect(program_config.teacher_vtext_label).to eq('blah')
    end
  end

  describe '#vocab_definition' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_definition).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, vocab_definition: '')

      expect(program_config.vocab_definition).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, vocab_definition: false)

      expect(program_config.vocab_definition).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, vocab_definition: true)

      expect(program_config.vocab_definition).to be true
    end
  end

  describe '#vocab_definition?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_definition?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, vocab_definition: '')

      expect(program_config.vocab_definition?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, vocab_definition: false)

      expect(program_config.vocab_definition?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, vocab_definition: true)

      expect(program_config.vocab_definition?).to be true
    end
  end

  describe '#vocab_tools' do
    it 'returns nil if the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_tools).to be_nil
    end

    it 'returns the attribute value if the attribute is in the datastore' do
      program_config = create(:program_config, vocab_tools: 'vocab tools')

      expect(program_config.vocab_tools).to eq('vocab tools')
    end
  end

  describe '#vocab_tools?' do
    it 'returns false if the atribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_tools).to be_nil
    end

    it 'returns true if the attribute is in the datastore' do
      program_config = create(:program_config, vocab_tools: 'vocab tools')

      expect(program_config.vocab_tools).to eq('vocab tools')
    end
  end

  describe '#vocab_words' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_words).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, vocab_words: '')

      expect(program_config.vocab_words).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, vocab_words: false)

      expect(program_config.vocab_words).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, vocab_words: true)

      expect(program_config.vocab_words).to be true
    end
  end

  describe '#vocab_words?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vocab_words?).to be false
    end

    it 'returns true when the attribute is an empty string in the datastore' do
      # To test compatibility with older records
      program_config = create(:program_config, vocab_words: '')

      expect(program_config.vocab_words?).to be true
    end

    it 'returns false when the attribute is false' do
      program_config = create(:program_config, vocab_words: false)

      expect(program_config.vocab_words?).to be false
    end

    it 'returns true when the attribute is true,' do
      program_config = create(:program_config, vocab_words: true)

      expect(program_config.vocab_words?).to be true
    end
  end

  describe '#vtext' do
    it 'returns nil when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vtext).to be_nil
    end

    it 'returns a structure representing the attribute if present in the datastore' do
      program_config = create(:program_config, vtext: { type: 'some type', url: 'some url' })

      expect(program_config.vtext).to have_attributes(
        type: 'some type',
        url: 'some url'
      )
    end
  end

  describe '#vtext?' do
    it 'returns false when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vtext?).to be false
    end

    it 'return true when the attribute is present in the datastore' do
      program_config = create(:program_config, vtext: { type: 'some type', url: 'some url' })

      expect(program_config.vtext?).to be true
    end
  end

  describe '#vtext_label' do
    it 'returns nil when the attribute is not in the datastore' do
      program_config = create(:program_config)

      expect(program_config.vtext_label).to be_nil
    end

    it 'returns the attribute value when present in the datastore' do
      program_config = create(:program_config, vtext_label: 'blah')

      expect(program_config.vtext_label).to eq('blah')
    end
  end

  describe 'log_datastore' do
    let(:program_config_with_ce) do
      described_class.create!(
        program_id: program.id,
        creator_id: creator.id,
        datastore_json: datastore.merge(
          enable_concurrent_enrollment: true
        )
      )
    end
    let(:log_data) do
      {
        application: 'm3',
        environment: Rails.env,
        vhl_component: :program_config,
        event_action: 'Program Config',
        id: program_config_with_ce.id,
        program_id: program.id,
        creator_id: program_config_with_ce.creator_id,
        datastore_json: program_config_with_ce.datastore
      }
    end

    before do
      allow(STATS_PROXY).to receive(:info)
    end

    context 'when the program_config is saved,' do
      it 'logs the datastore_json stats' do
        expect(STATS_PROXY).to have_received(:info).with(
          hash_including(log_data)
        )
      end
    end
  end
end
