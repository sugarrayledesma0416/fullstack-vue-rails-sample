feature 'Program configs', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include CapybaraViewHelpers
  include WaitForAjax

  let(:program) { create(:program_with_toc_entries) }
  let(:creator) { build_stubbed(:user) }
  let(:user) { create(:student) }
  let(:setting_name) { 'vtext' }
  let(:first_setting_value) { 'first_url' }
  let(:second_setting_value) { 'second_url' }
  let(:src_program_1) { create(:program_with_toc_entries) }
  let(:src_program_2) { create(:program_with_toc_entries) }
  let(:english_program) { create(:program_with_toc_entries, language_code: 'en') }
  let(:src_strand_1) do
    create(
      :concept,
      program: src_program_1,
      lesson: src_program_1.lessons.first,
      id: src_program_1.lessons.first.strands(true).first.location.to_i
    )
  end
  let(:dest_strand_1) do
    create(
      :concept,
      program: program,
      lesson: program.lessons.first,
      name: program.lessons.first.strands(true).first.title,
      id: program.lessons.first.strands(true).first.location.to_i
    )
  end
  let!(:dest_strand_2) do
    create(
      :concept,
      program: program,
      lesson: program.lessons.first,
      name: program.lessons.first.strands(true)[1].title,
      id: program.lessons.first.strands(true)[1].location.to_i
    )
  end
  let!(:mapping) do
    create(
      :program_to_program_mapping,
      dest_program: program,
      dest_strand: dest_strand_1,
      src_strand: src_strand_1
    )
  end
  let!(:program_edition) do
    create(
      :program_edition,
      program_id: program.id,
      previous_edition_program_id: src_program_1.id
    )
  end
  let!(:english_program_edition) do
    create(
      :program_edition,
      program_id: english_program.id,
      previous_edition_program_id: src_program_2.id
    )
  end

  before do
    # Ensure a concept exists for each strand in the lesson xml, otherwise
    # program_to_program mapping creation will fail validating presence
    # of source strand.
    src_program_1.lessons.each do |lesson|
      lesson.strands.each do |strand|
        next if strand.location.to_i == src_strand_1.id

        create(
          :concept,
          id: strand.location,
          lesson: lesson,
          program: program
        )
      end
    end

    create(
      :concept,
      program: src_program_2,
      lesson: src_program_2.lessons.first,
      id: src_program_2.lessons.first.strands(true).first.location.to_i
    )
    allow(VocabWordsCleaner).to receive(:clean)
    allow(VocabListV2Extractor).to receive(:generate_vocabulary_for)
    user.roles << Role.create!(name: Role::PROGRAM_CONFIG_MANAGER)
    initialize_client_calls_for_user(user)
    log_in_as(user)
  end

  scenario 'As a program manager, I can manage program configurations' do
    vtext_url = '/vtext/panorama4e/ebook/pan4e_new.html'
    vocab_tools_title = 'My Vocabtools'
    ai_program_level = 'introductory'

    standard_set_1 = create(:standard_set)
    standard_set_2 = create(:standard_set)
    standard_set_3 = create(:standard_set)

    visit edit_program_config_path(program)

    # TODO: This is failing with a ProgramConfig.count of 1 after the click.
    # This test was added after fixing a bug in which submitting the form
    # without changing any settings changed the concurrent enrollment settings.
    # This should prevent similar bugs in the future.
    # purpose 'I see no updates when I submit a form without changing any settings' do
    #   program_config_count = ProgramConfig.count
    #   # find('.test-program-config-submit').click
    #   find('input[type="submit"]').click
    #   expect(ProgramConfig.count).to eq(program_config_count)
    #   expect_flash_message(:error, 'No changes : Program settings remain the same.')
    # end

    purpose 'I see the list of existing standard sets' do
      expect(
        page.all('.test-supported-standard-set-ids label').map(&:text)
      ).to contain_exactly(
        standard_set_1.display_name,
        standard_set_2.display_name,
        standard_set_3.display_name
      )
    end

    purpose 'I select supported standard sets' do
      find('label', text: standard_set_1.display_name).click
      find('label', text: standard_set_3.display_name).click

      select('Grade 1', from: 'min-grade-range')
      select('Grade 9', from: 'max-grade-range')
    end

    purpose 'I can change the AI feature settings' do
      vhl_check('Enable Grading Suggestions')
      select('introductory', from: 'datastore_ai_settings_program_level')
    end

    purpose 'I can change program config options' do
      find_field('datastore_vtext_url').set(vtext_url)

      vhl_check('Enable Speech Recognition')
      vhl_check('Vocabulary Tools', exact: true)
      find_field('datastore_vocab_tools').set(vocab_tools_title)
      vhl_check('Allow assessments randomization')
    end

    purpose 'I see a success message when I submit' do
      find('.test-program-config-submit').click
      expect_flash_message(:notice, 'New configuration created.')
    end

    purpose 'My changes have been saved in the model' do
      program_config = ProgramConfig.last
      expect(program_config.vtext.url).to eq(vtext_url)
      # rubocop:disable RSpec/PredicateMatcher
      # because 'be_speech_rec' and 'be_allow_assessments_randomization' do
      # not make sense.
      expect(program_config.speech_rec?).to be_truthy
      expect(program_config.vocab_tools).to eq(vocab_tools_title)
      expect(program_config.allow_assessments_randomization?).to be_truthy
      # rubocop:enable RSpec/PredicateMatcher
      expect(program_config.supported_standard_sets).to contain_exactly(
        standard_set_1, standard_set_3
      )
      expect(program_config.standards_settings[:min_grade]).to eq('1')
      expect(program_config.standards_settings[:max_grade]).to eq('9')
    end

    purpose 'My changes are visible in the view' do
      expect(find_field('datastore_vtext_url').value).to eq vtext_url
      expect(find_field('Enable Speech Recognition')).to be_checked
      expect(find_field('vocab_tools_enabled')).to be_checked
      expect(find_field('datastore_vocab_tools').value).to eq vocab_tools_title
      expect(find_field('Allow assessments randomization')).to be_checked
      expect(find_field('Enable Grading Suggestions')).to be_checked
      expect(find_field('Program Level').value).to eq ai_program_level

      step 'I see the list of existing standard sets' do
        expect(
          page.all('.test-supported-standard-set-ids label').map(&:text)
        ).to contain_exactly(
          standard_set_1.display_name,
          standard_set_2.display_name,
          standard_set_3.display_name
        )
      end

      step 'I see the supported standard sets' do
        [standard_set_1, standard_set_3].each do |standard_set|
          checkbox = find("input[type='checkbox'][value='#{standard_set.id}']")
          expect(checkbox).to be_checked
        end
      end
    end

    purpose 'I have a link to update the vocabulary for a program' do
      visit edit_program_config_path(program)
      expect(page).to have_selector(
        '.test-vocab_tools_status',
        text: ''
      )
      find('#update_vocab_tools').click
      wait_for_ajax
      expect(page).to have_selector(
        '.test-vocab_tools_status',
        text: 'Updated, check the program vocabulary.'
      )
      expect(VocabWordsCleaner).to have_received(:clean)
        .with(program.id.to_s, true)
      expect(VocabListV2Extractor).to have_received(:generate_vocabulary_for)
        .with(program)
    end

    purpose 'The link to update vocabulary does not submit the edit form' do
      # We test that the form is not submitted.
      expect_url(edit_program_config_path(program))
    end

    visit program_update_vocab_tools_path(program)

    purpose 'I can build a program-to-program mapping' do
      visit edit_program_config_path(program)

      purpose 'The correct source program is selected' do
        expect(page).to have_select(
          'Source',
          selected: mapping.src_strand.program.title
        )
      end

      purpose 'I see a disclosure for each lesson of the program' do
        src_program_1.lessons.each do |lesson|
          expect(page).to have_selector(
            '.c-disclosure__header', text: lesson.name, visible: true
          )
        end
      end

      within(page.first('.test-lesson-title')) do
        step 'I expand the disclosure by clicking on the header' do
          find('.c-disclosure__header', text: src_program_1.lessons.first.name).click
        end

        step 'I see all the lesson strands' do
          src_program_1.lessons.first.strands.each do |strand|
            expect(page).to have_selector('.test-concept_name', text: strand.title)
          end
        end

        expect(page).to have_select(
          "ptp_mapping_dest_lesson_id_#{mapping.src_strand.id}",
          selected: mapping.dest_strand.lesson.name
        )
        expect(page).to have_select(
          "ptp_mapping_dest_strand_id_#{mapping.src_strand.id}",
          selected: mapping.dest_strand.name
        )
        page.select(
          dest_strand_2.lesson.name,
          from: "ptp_mapping_dest_lesson_id_#{mapping.src_strand.id}",
          exact: true
        )
      end

      purpose 'I can map a strand' do
        select(
          dest_strand_2.name,
          from: "ptp_mapping_dest_strand_id_#{mapping.src_strand.id}",
          exact: true
        )
      end

      purpose 'I see a success message when I submit' do
        find('.test-program-config-submit').click
        expect_flash_message(:notice, 'My Content mapping successful!')
      end

      purpose 'the strand I mapped has selectors selected' do
        within(page.first('.test-lesson-title')) do
          expect(page).to have_select(
            "ptp_mapping_dest_lesson_id_#{mapping.src_strand.id}",
            selected: dest_strand_2.lesson.name
          )
          expect(page).to have_select(
            "ptp_mapping_dest_strand_id_#{mapping.src_strand.id}",
            selected: dest_strand_2.name
          )
        end
      end

      purpose 'I can select another program as the program source' do
        page.select(
          src_program_2.title,
          from: 'Source',
          exact: true
        )
      end

      purpose 'I confirm the change' do
        within('.test-src-change-modal') do
          click_button('Set Source')
        end
      end

      purpose 'The source program has changed' do
        expect(page).to have_select(
          'Source',
          selected: src_program_2.title
        )
      end

      purpose 'I see a disclosure for each lesson of the program' do
        src_program_2.lessons.each do |lesson|
          expect(page).to have_selector(
            '.c-disclosure__header', text: lesson.name, visible: true
          )
        end
      end

      purpose 'No strand is mapped' do
        within(page.first('.test-lesson-title')) do
          step 'I expand the disclosure by clicking on the header' do
            find('.c-disclosure__header', text: src_program_2.lessons.first.name).click
          end

          src_program_2.lessons.first.strands.each do |strand|
            expect(page).to have_selector('.test-concept_name', text: strand.title)
          end
        end
      end

      purpose 'I can automatically map destination lesson strands' do
        click_button('Map to Destination')
        wait_for_ajax

        # There is no modal to validate in this view...
        within(page.first('.test-lesson-title')) do
          src_program_2.lessons.first.strands.each do |strand|
            expect(page).to have_select(
              "ptp_mapping_dest_lesson_id_#{strand.location}",
              selected: src_program_2.lessons.first.name
            )
          end
        end
      end
    end
  end

  scenario 'As a program manager, I can manage english vocab tools configuration' do
    purpose 'I can see configuration related to english vocab tools' do
      visit edit_program_config_path(english_program)
      within(find('.test-hide-translation')) do
        expect(page).to have_selector('.test-datastore-hide-translation')
        expect(page).to have_text('Hide Translation Column in Vocab Tools')
      end

      within(find('.test-vocab-definition')) do
        expect(page).to have_selector('.test-datastore-vocab-definition')
        expect(page).to have_text('Show Definition Column in Vocabulary Tools')
      end
    end

    purpose 'I can change program config options' do
      vhl_check('Vocabulary Tools')
      expect(find('.test-vocab-tools')).to be_checked
      expect(find('.test-datastore-hide-translation')).to be_checked
      expect(find('.test-datastore-vocab-definition')).to be_checked
    end

    purpose 'I see a success message when I submit' do
      find('.test-program-config-submit').click
      expect_flash_message(:notice, 'New configuration created.')
    end

    purpose 'My changes have been saved in the model' do
      program_config = ProgramConfig.last
      expect(program_config.vocab_tools?).to be_truthy
      expect(program_config.vocab_definition?).to be_truthy
      expect(program_config.hide_translation?).to be_truthy
    end

    purpose 'My changes are visible in the view' do
      expect(find('.test-vocab-tools')).to be_checked
      expect(find('.test-datastore-hide-translation')).to be_checked
      expect(find('.test-datastore-vocab-definition')).to be_checked
    end
  end

  # TODO: Many of these tests duplicate the tests in the OtherFeaturesSettingsSpec.
  #       What can we eliminate?
  scenario 'As a program manager, I can manage concurrent enrollment configuration' do
    purpose 'I can see configuration related to concurrent enrollment setting' do
      visit edit_program_config_path(english_program)
      within(find('.test-enable-concurrent-enrollment')) do
        expect(page).to have_selector('.test-datastore-enable-concurrent-enrollment')
        expect(page).to have_text('Enable Concurrent Enrollment')
      end
    end

    purpose 'I can check the "Enable Concurrent Enrollment" checkbox' do
      vhl_check('Enable Concurrent Enrollment', allow_label_click: true)
      expect(find('.test-datastore-enable-concurrent-enrollment')).to be_checked
    end

    purpose 'I see the concurrent enrollment modal' do
      expect(page).to have_selector(
        '.test-enable-concurrent-enrollment-change-requirement'
      )
    end

    purpose 'I can click the "Cancel" button in the concurrent enrollment modal' do
      find('.test-cancel-concurrent-enrollment-btn', text: 'Cancel').click
    end

    purpose 'I can see the "Enable Concurrent Enrollment" checkbox unchecked' do
      expect(find('.test-datastore-enable-concurrent-enrollment')).not_to be_checked
    end

    purpose 'I can check the "Enable Concurrent Enrollment" checkbox again' do
      vhl_check('Enable Concurrent Enrollment', allow_label_click: true)
      expect(find('.test-datastore-enable-concurrent-enrollment')).to be_checked
    end

    purpose 'I can click the "Confirm" button in the concurrent enrollment modal' do
      find('.test-confirm-concurrent-enrollment-btn', text: 'Confirm').click
    end

    purpose 'I see a success message when I click "Submit"' do
      click_button('Submit')
      expect_flash_message(:notice, 'New configuration created.')
    end

    purpose 'My changes have been saved in the model' do
      program_config = ProgramConfig.last
      expect(program_config.enable_concurrent_enrollment?).to be_truthy
    end
  end
end
