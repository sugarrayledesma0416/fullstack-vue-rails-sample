#require 'capybara'
#require 'capybara/rspec'

describe ActivitiesHelper do
  include ActivitiesHelper
  include ApplicationHelper

  describe "format_next_activity_button" do
    let(:activity){ double('Activity') }
    describe "when custom next activity button text is specified (in the xml)" do
      it "returns the custom text " do
        allow(activity).to receive_message_chain('content_object', 'config').and_return(double('config', next_button_text: 'foo'))
        expect(format_next_activity_button(activity)).to eql 'foo'
      end
    end

    describe "when no custom text is not specified" do
      it "returns Next Activity" do
        allow(activity).to receive_message_chain('content_object', 'config')
        expect(format_next_activity_button(activity)).to eql 'Next Activity'
      end
    end
  end

  describe '#show_instructor_notes_link_for?' do
    let(:user){ build_stubbed(:student) }

    context 'when user is an instructor and controller name is "activities"' do
      it 'returns true' do
        allow(user).to receive(:instructor?).and_return(true)
        controller_name = 'activities'
        expect(show_instructor_notes_link_for?(user, controller_name)).to be_truthy
      end
    end

    context 'when user is an instructor and controller name is different than "activities"' do
      it 'returns false' do
        allow(user).to receive(:instructor?).and_return(true)
        controller_name = 'other_controller'
        expect(show_instructor_notes_link_for?(user, controller_name)).to be_falsey
      end
    end

    context 'when user is not an instructor and controller name is "activities"' do
      it 'returns false' do
        allow(user).to receive(:instructor?).and_return(false)
        controller_name = 'activities'
        expect(show_instructor_notes_link_for?(user, controller_name)).to be_falsey
      end
    end

    context 'when user is not an instructor and controller name is different than "activities"' do
      it 'returns false' do
        allow(user).to receive(:instructor?).and_return(false)
        controller_name = 'other_controller'
        expect(show_instructor_notes_link_for?(user, controller_name)).to be_falsey
      end
    end
  end

  describe "#format_help_request_data" do
    let(:activity){ build_stubbed(:activity) }
    let(:program){ build_stubbed(:program) }
    let(:section){ build_stubbed(:section) }
    let(:user){ build_stubbed(:student) }


    it 'returns a hash with passed params' do
      current_view = 'decide'
      http_referer = 'some_referer_url'
      params = 'valid_params'
      expected = { :http_referer    => http_referer,
                   :user_id         => [user.id],
                   :user_type       => user.account_type.downcase,
                   :activity_id     => activity.id,
                   :cms_activity_id => activity.cms_activity_id,
                   :cms_revision_id => activity.cms_revision_id,
                   :program_id      => program.id,
                   :section_id      => section.id,
                   :activity_state  => current_view,
                   :request_params  => params }

      results = format_help_request_data(program, section, [user], activity, current_view, http_referer, params)
      expect(results).to eql expected
    end
  end

  describe "#get_current_button_tag" do
    let(:activity) { build_stubbed(:activity) }
    let(:attempt_track) { double(AttemptTrack) }
    let(:workset) { double(Workset) }
    let(:activity_content)  { 'valid_content' }

    before do
      allow(activity).to receive(:content_object).and_return(activity_content)
      allow(activity_content).to receive(:submittable?).and_return(true)
      allow(attempt_track).to receive(:practice?).and_return(false)
      allow(workset).to receive(:final_activity?).and_return(false)
    end

    context "when activity is submittable" do
      it "returns practice_activity when in practice mode" do
        allow(attempt_track).to receive(:practice?).and_return(true)
        expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'practice_activity'
      end

      it "returns save_submit for most activities" do
        expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'save_submit'
      end

      context "in a workset" do
        context "viewing a partner_chat activity" do
          before do
            allow(activity).to receive(:activity_type).and_return("partner_chat")
          end

          it "returns next_activity_submit if not on the final activity" do
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'next_activity_submit'
          end

          it "returns submit if on final activity" do
            allow(workset).to receive(:final_activity?).and_return(true)
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'submit'
          end
        end

        context 'viewing a smart_book activity' do
          before do
            allow(activity).to receive(:activity_type).and_return('smart_book')
          end

          it "returns next_activity if not on the final activity" do
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'next_activity'
          end

          it "returns return_to if on final activity" do
            allow(workset).to receive(:final_activity?).and_return(true)
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'return_to'
          end
        end

        context "viewing a speech rec listen repeat activity" do
          before do
            allow(activity).to receive(:activity_type).and_return("speech_rec_listen_repeat")
          end

          it "returns next_activity_submit if not on the final activity" do
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'next_activity_submit'
          end

          it "returns submit if on final activity" do
            allow(workset).to receive(:final_activity?).and_return(true)
            expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'submit'
          end
        end
      end

      context "outside a workset" do
        it "returns submit when in a partner_chat" do
          allow(activity).to receive(:activity_type).and_return("partner_chat")
          expect(get_current_button_tag(activity, attempt_track, nil)).to eql 'submit'
        end

        it 'returns return_to when in a smart_book activity' do
          allow(activity).to receive(:activity_type).and_return("smart_book")
          expect(get_current_button_tag(activity, attempt_track, nil)).to eql 'return_to'
        end

        it "returns return_to if unsubmittable" do
        allow(activity_content).to receive(:submittable?).and_return(false)
          expect(get_current_button_tag(activity, attempt_track, nil)).to eql 'return_to'
        end
      end
    end

    context "when activity is unsubmittable" do
      before do
        allow(activity_content).to receive(:submittable?).and_return(false)
      end

      it "returns next_activity if not on the final activity" do
        expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'next_activity'
      end

      it "returns return_to if on the final activity" do
        allow(workset).to receive(:final_activity?).and_return(true)
        expect(get_current_button_tag(activity, attempt_track, workset)).to eql 'return_to'
      end
    end
  end

  describe "#format_flashcards_menu_link" do
    it "should close the flashcards popup" do
      link_text = 'valid link text'
      section_id = 3
      activity_id = 1001541
      link_url = '#'
      response = format_flashcards_menu_link(link_text, activity_id, section_id)
      expect(response).to have_selector("a[href='#'][onclick='window.close()']", :text => 'valid link text')
    end
  end

  describe "#format_flashcards_deck_link" do
    it "should open the correct flashcards in a popup" do
      section_id = 3
      activity_id = 1001541
      deck_type = 'target'
      deck_index = 1
      link_url = section_show_flashcards_deck_path(section_id, activity_id, deck_index +1, deck_type)
      expect(self).to receive(:format_popup_onclick).and_return('onclick_options')
      response = format_flashcards_deck_link(deck_index, section_id, activity_id, deck_type)
      expect(response).to have_selector("a[href='#{link_url}'][onclick='onclick_options']", :text => "Deck #{deck_index + 1}" )
    end

    context "when passed a nil section id," do
      it "creates a link to section id 0" do
        section_id = nil
        activity_id = 1001541
        deck_type = 'target'
        deck_index = 1
        link_url = section_show_flashcards_deck_path(0, activity_id, deck_index +1, deck_type)
        expect(self).to receive(:format_popup_onclick).and_return('onclick_options')
        response = format_flashcards_deck_link(deck_index, section_id, activity_id, deck_type)
        expect(response).to have_selector("a[href='#{link_url}'][onclick='onclick_options']", :text => "Deck #{deck_index + 1}" )
      end
    end
  end

  describe "#format_flashcards_language_link" do
    it "should have a link to the flashcards in the other language" do
      section_id = 3
      activity_id = 1001541
      link_text = 'valid link text'
      deck_type = 'target'
      deck_index = 1
      link_url = section_show_flashcards_deck_path(section_id, activity_id, deck_index, deck_type)
      response = format_flashcards_language_link(link_text, section_id, activity_id, deck_index, deck_type)
      expect(response).to have_selector("a[href='#{link_url}']", :text =>'valid link text')
    end
  end

  describe '#external_reference_links' do
    let(:section_id) { 123646 }
    let(:program_id) { 798465 }
    let(:activity)   { double(Activity, hide_external_references?: false) }

    context 'when external references should be hidden' do
      it 'returns nil' do
        allow(activity).to receive(:hide_external_references?) { true }

        expect(external_reference_links(activity, section_id, program_id))
          .to be_nil
      end
    end

    context 'when external references should not be hidden' do
      context 'when external reference is an activity' do
        it 'returns a popup-formatted external activity link' do
          external_reference =
            MaestroActivityEngine::ActivityContent::ExternalReference::Activity.new
          allow(activity)
            .to receive(:external_references) { [external_reference] }

          expect(self).to receive(:format_external_activity_popup_link)
            .with(external_reference, section_id, program_id)
          external_reference_links(activity, section_id, program_id)
        end
      end

      context 'when external reference is a url' do
        it 'returns a popup-formatted external url link' do
          external_reference =
            MaestroActivityEngine::ActivityContent::ExternalReference::Url.new
          allow(activity)
            .to receive(:external_references) { [external_reference] }

          expect(self).to receive(:format_external_url_popup_link)
            .with(external_reference)
          external_reference_links(activity, section_id, program_id)
        end
      end

      context 'when external reference is not an activity' do
        it 'returns a popup-formatted play link' do
          media_item = double('MediaItem')
          media_item_link = double('MediaItemLink', media_item: media_item)
          external_reference = double('ExternalMedia',
                                      title: 'Media 1',
                                      link: media_item_link)
          allow(activity)
            .to receive(:external_references) { [external_reference] }

          expect(self).to receive(:format_popup_play_link)
            .with(media_item, external_reference.title)
          external_reference_links(activity, section_id, program_id)
        end
      end
    end
  end

  describe "#format_external_activity_popup_link" do
    let(:program) { create(:program) }
    let(:activity) { create(:activity) }
    it "creates a popup link with fixed size" do

      ref_title = 'valid_activity_title'
      external_ref = double('ExternalRef', :title => ref_title, :activity => activity)

      section_id = 5
      link_url = popup_section_activity_path(:section_id => section_id, :id => activity, :program_id => program.id)

      expect(self).to receive(:format_popup_onclick).and_return('onclick_options')

      response = format_external_activity_popup_link(external_ref, section_id, program.id)
      expect(response).to have_selector("a[href='#{link_url}'][onclick='onclick_options']", :text => ref_title)
    end
  end

  describe "#external_reference_path" do
    let(:program) { create(:program) }
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    it "returns the path to the activity pupup for a given program" do
      allow(activity).to receive(:program).and_return(program)

      expected_path = external_reference_path(activity.id, activity, section)
      expect(expected_path).to eql "/sections/#{section.id}/activities/#{activity.id}/popup?program_id=#{program.id}"
    end

    context "when not in any section" do
      it "returns the path to the activity pupup for a given program with section 0" do
        allow(activity).to receive(:program).and_return(program)

        expected_path = external_reference_path(activity.id, activity, nil)
        expect(expected_path).to eql "/sections/0/activities/#{activity.id}/popup?program_id=#{program.id}"
      end
    end

  end

  describe "#format_activity_due_date" do
    it "returns empty string if due date is nil or empty string" do
      expect(format_activity_due_date(nil)).to eql("")
      expect(format_activity_due_date("")).to eql("")
    end

    it "returns just the due date if the activity is not overdue" do
      due_date = Date.today + 1
      overdue  = false
      formatted_date = format_date_time(due_date, :relative_weekday_month_ordinal)
      expect(format_activity_due_date(due_date, overdue)).to eql(formatted_date)
    end

    it "returns just the due date if the activity overdue status is not specified" do
      due_date = Date.today + 1
      formatted_date = format_date_time(due_date, :relative_weekday_month_ordinal)
      expect(format_activity_due_date(due_date)).to eql(formatted_date)
    end

    context 'when separate elements are specified' do
      it 'returns the month and day wrapped in divs' do
        due_date = Date.today
        expected = "<div class='due-date-month'>#{due_date.strftime('%B')}</div><div class='due-date-date'>#{due_date.strftime('%d')}</div>"
        expect(format_activity_due_date(due_date, false, true)).to eq(expected)
      end
    end
  end

  describe "#format_activity_label_with_icons" do
    let(:current_program) { build(:program) }

    before do
      @activity = build_stubbed(:activity, :title => 'My activity title')
      allow(@activity).to receive(:instructor_graded?).and_return(false)
      allow(@activity).to receive(:icon).and_return('')

      # stubbed music application helper - feature_icon.
      icon_path_titles = {
        'music/toc/audio' => 'Audio',
        'music/toc/textbook' => 'Textbook',
        'music/toc/vol_textbook' => 'Textbook',
        'music/toc/video' => 'Video',
        'music/toc/composition' => 'Composition',
        'music/toc/microphone' => 'Microphone',
        'music/toc/virtual_chat' => 'Virtual Chat',
        'music/toc/partner_chat' => 'Partner Chat',
        'music/toc/icon_person' => 'Instructor Graded',
        'music/toc/instructor_note_icon_rounded' => 'Instructor Note'}

      allow_any_instance_of(ApplicationHelper).to receive(:feature_icon) do |block, filepath|
        "<span class='c-embedded-icon'><svg><title>#{icon_path_titles[filepath]}</title></svg>".html_safe
      end
    end

    it "displays a span tag with the activity title" do
      results = format_activity_label_with_icons('label_id', @activity)
      expect(results).to have_selector('span', text: @activity.title)
    end

    context "displays appropriate icons" do
      icons = {'audio,textbook' => 'Audio|Textbook',
               'textbook' => 'Textbook',
               'audio' => 'Audio',
               'video' => 'Video',
               'composition,textbook' => 'Composition|Textbook',
               'microphone' => 'Microphone',
               'microphone,textbook' => 'Microphone|Textbook',
               'virtual_chat' => 'Virtual Chat',
               'partner_chat' => 'Partner Chat'}

      icons.each_pair do |icon, icon_titles|
        it "validate icon #{icon}.svg" do
          allow(@activity).to receive(:icon).and_return(icon)
          results = format_activity_label_with_icons('label_id', @activity, nil, nil, nil, true)
          expect(results).to have_selector('span.c-embedded-icon > svg')
          icon_titles.split('|').each do |title|
            expect(results).to have_selector('title', text: title)
          end
        end

        it "validate icon #{icon}.png" do
          allow(@activity).to receive(:icon).and_return(icon)
          results = format_activity_label_with_icons('label_id', @activity)
          expect(results).to have_selector('span')
          icon.split(',').each do |png|
            expect(results).to have_css("img[src*='#{png}.png']")
          end
        end
      end

    end

    it "displays the instructor .png icon when activity is instructor graded" do
      allow(@activity).to receive(:instructor_graded?).and_return(true)
      results = format_activity_label_with_icons('label_id', @activity)
      expect(results).to have_selector('button#instructor_graded')
      expect(results).to have_css("img[src*='icon_person.png']")
    end

    it "displays the note .png icon when activity has instructor notes" do
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, true)
      expect(results).to have_selector('button#instructor_note')
      expect(results).to have_css("img[src*='instructor_note_icon_rounded.png']")
    end

    it "displays the instructor .svg icon when activity is instructor graded" do
      allow(@activity).to receive(:instructor_graded?).and_return(true)
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, nil, true)
      expect(results).to have_selector('button#instructor_graded svg > title', text: 'Instructor Graded')
    end

    it "displays the note .svg icon when activity has instructor notes" do
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, true, true)
      expect(results).to have_selector('button#instructor_note svg > title', text: 'Instructor Note')
    end

    it "displays activity title as a link if path is provided" do
      results = format_activity_label_with_icons('label_id', @activity, 'link_path')
      expect(results).to have_selector("a[href='link_path']", :text => @activity.title)
    end

    it 'displays the activity title by default if not param is provided' do
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, true, true)
      expect(results).to have_selector('span#label_id')
    end

    it 'displays the activity title if has_title param is provided as true' do
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, true, true, true)
      expect(results).to have_selector('span#label_id')
    end

    it 'does not display the activity title if has_title param is provided as false' do
      results = format_activity_label_with_icons('label_id', @activity, nil, nil, true, true, false)
      expect(results).not_to have_selector('span#label_id')
    end
  end

  describe "#activities_by_component" do
    it "should yield for single length arrays" do
      activities = [build_stubbed(:activity, :component_name => "Component 1")]
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return(nil)
      end
      yield_count = 0

      activities_by_component(activities) do |component_name, activities|
        yield_count+= 1
      end

      expect(yield_count).to eql 1
    end

    it "should yield the component name and full activity list with one component" do
      activities = [].fill(0..1) {build_stubbed(:activity, :component_name => "Component 1")}
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return(nil)
      end
      yield_count = 0

      activities_by_component(activities) do |component_name, component_language, yielded_activities|
        expect(component_name).to eql "Component 1"
        expect(yielded_activities).to eql activities
        yield_count+= 1
      end

      expect(yield_count).to eql 1
    end

    it "should yield twice when given two components" do
      activities = [build_stubbed(:activity, :component_name => "Component 1"),
                    build_stubbed(:activity, :component_name => "Component 2")]
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return(nil)
      end
      yield_count = 0
      component_names = ["component 1", "component 2"]

      activities_by_component(activities) do |component_name, component_language, yielded_activities|
        expect(component_name).to eql component_names[yield_count].titleize
        expect(yielded_activities).to eql [activities[yield_count]]

        yield_count+= 1
      end

      expect(yield_count).to eql 2
    end

    it "should yield to activities with nil component_names" do
      activities = [].fill(0..1) {build_stubbed(:activity, :component_name => nil)}
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return(nil)
      end
      yield_count = 0

      activities_by_component(activities) do |component_name, component_language, yielded_activities|
        expect(component_name).to eql nil
        expect(yielded_activities).to eql activities
        yield_count+= 1
      end

      expect(yield_count).to eql 1
    end

    it "should yield to activities with nil component_names followed by normal activities" do
      activities = [build_stubbed(:activity, :component_name => nil),
                    build_stubbed(:activity, :component_name => "Component 2")]
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return(nil)
      end
      yield_count = 0
      component_names = [nil, "component 2"]

      activities_by_component(activities) do |component_name, component_language, yielded_activities|
        expected_title = component_names[yield_count] ? component_names[yield_count].titleize : nil
        expect(component_name).to eql expected_title
        expect(yielded_activities).to eql [activities[yield_count]]

        yield_count+= 1
      end

      expect(yield_count).to eql 2
    end

    it 'yield to instructor created activities even if then have same strand label as the other activities' do
      instructor_activity = build_stubbed(:activity, :component_name => 'instructor activity')
      allow(instructor_activity).to receive(:instructor_created?).and_return(true)
      another_activity = build_stubbed(:activity, :component_name => 'Component 1')

      activities = [instructor_activity, another_activity]
      activities.each do |activity|
        allow(activity).to receive(:strand_singular_label).and_return('same label')
      end
      yield_count = 0

      activities_by_component(activities) do |component_name, component_language, yielded_activities|
        expect(yielded_activities).to eql [activities[yield_count]]
        yield_count+= 1
      end
      expect(yield_count).to eql 2
    end

    context 'when singular label is present' do
      let(:expected_component_name)  { 'My Component Name' }
      let(:singular_label)  { 'Some singular label' }
      let(:activities) { [build_stubbed(:activity, component_name: expected_component_name)] }

      before do
        activities.each do |activity|
          allow(activity).to receive(:strand_singular_label).and_return(singular_label)
        end
      end

      it 'uses by default the singular label if present' do
        activities_by_component(activities) do |component_name, activities|
          expect(component_name).to eq singular_label
        end
      end

      context 'when forced to use component name' do
        it 'uses the component name even if singular label is present' do
          activities_by_component(activities, use_component_name = true) do |component_name, activities|
            expect(component_name).to eq expected_component_name
          end
        end
      end
    end
  end

  describe "#points_earned_vs_possible(score)" do
    it "returns nil if score is nil" do
      expect(points_earned_vs_possible(nil)).to be nil
    end

    it "returns a formatted score when a score is passed in" do
      score = instance_double(GradebookEngine::AssignmentGrade)
      allow(score).to receive(:formatted_points_earned_for_display).and_return('10')
      allow(score).to receive(:points_possible_for_display).and_return('15')
      expect(points_earned_vs_possible(score)).to eq('10 of 15 pts. ')
    end
  end

  describe "#format_footer_score" do
    include GradebookHelper
    include ScoreHelper

    let(:score) do
      double(GradebookEngine::Grade,
               formatted_points_earned_for_display: "5",
               points_possible_for_display: "10",
               formatted_score: "50.0",
               late?: false,
               pending?: false,
               partial_pending?: false,
               net_penalty_percent: '')
    end
    let(:results) do
      double('MaestroActivityEngine::ActivityContent::Results',
               :total_points_possible => 10,
               :total_points_earned => 5,
               :score => 0.5 )
    end

    let(:rubric_footer) { format_footer_score(score, results, 'a rubric link') }

    context "when the score and results are nil" do
      it "returns an empty p tag" do
        expect(format_footer_score(nil, nil)).to have_selector('.test-footer-score-content')
      end
    end

    context "when the score is nil but results are not" do
      it "shows points earned and possible and score" do
        expect(format_footer_score(nil, results)).to include '5 of 10 pts. 50.0%'
      end
    end

    context "when the score is pending grading" do
      it "shows score as pending" do
        allow(score).to receive(:pending?).and_return(true)
        expect(format_footer_score(score, results)).to have_selector('p', text: 'Score : Pending', exact_text:true)
      end
    end

    context "when the score is partially pending grading" do
      it "shows score as pending" do
        allow(score).to receive(:partial_pending?).and_return(true)
        expect(format_footer_score(score, results)).to have_selector('p', text: 'Score : Pending', exact_text:true)
      end
    end

    context 'when the score has been graded via rubric and is not pending' do
      before do
        allow(score).to receive(:pending?).and_return(false)
      end

      it 'Uses a rubric label' do
        expect(rubric_footer).to include 'Rubric Grade'
      end

      it 'does not show any late penalty' do
        expect(rubric_footer).not_to include 'Late Penalty'
      end

      it 'shows the scores percent' do
        expect(rubric_footer).to include '50.0%'
      end

      it 'Displays a link to the scored rubric page' do
        expect(rubric_footer).to have_selector('.test-scored-rubric-link')
      end

      context 'when the score is late' do
        before do
          allow(score).to receive(:late?).and_return(true)
          allow(score).to receive(:net_penalty_percent).and_return('10')
        end

        it 'shows the late penalty' do
          expect(format_footer_score(score, results, 'a rubric link')).to include 'Late Penalty:'
        end
      end
    end

    context "when the score has been graded and is not pending" do
      before do
        allow(score).to receive(:pending?).and_return(false)
      end

      it "shows the points possible and the points earned" do
        expect(format_footer_score(score, results)).to include '5 of 10 pts.'
      end

      it "shows the scores percent" do
        expect(format_footer_score(score, results)).to include '50.0%'
      end

      it "does not show any late penalty" do
        expect(format_footer_score(score, results)).not_to include 'Late Penalty:'
      end

      context "when the score is late" do
        before do
          allow(score).to receive(:late?).and_return(true)
          allow(score).to receive(:net_penalty_percent).and_return("10")
        end

        it "shows the late penalty" do
          expect(format_footer_score(score, results)).to include 'Late Penalty:'
        end
      end
    end
  end

  describe "#format_answer_key_mode_link" do
    let(:activity) { double("activity", id: 1, gradable?: false, preview?: false) }
    let(:user) { double("user", instructor?: false) }
    let(:a_controller) { double('controller', action_name: '') }

    before do
      @params = {}
    end

    context "when activity is not gradable" do
      it "returns empty string" do
        allow(user).to receive(:instructor?).and_return(true)
        expect(format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params))
          .to be_blank
      end
    end

    context "when current_user is not an instructor" do
      it "returns empty string" do
        allow(activity).to receive(:gradable?).and_return(true)
        expect(format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params))
          .to be_blank
      end
    end

    context "when activity is gradable and current user is an instructor and not cartridge" do
      before do
        allow(activity).to receive(:gradable?).and_return(true)
        allow(user).to receive(:instructor?).and_return(true)
        allow(user).to receive(:cartridge?).and_return(false)
        allow(helper).to receive(:spr?).and_return(false)
      end

      context "when current controller action is not 'answer_keys'" do
        it "returns a link to go to answer key mode" do
          allow(a_controller).to receive(:action_name).and_return('some_action')
          response = helper.format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params)
          expected_path = answer_keys_section_activity_path(0, activity.id)
          expect(response).to have_link('Answer key', href: expected_path)
        end
      end

      context "when current controller action is 'answer_keys'" do
        before do
          allow(a_controller).to receive(:action_name).and_return('answer_keys')
        end

        context "when task_type param is not present" do
          it "returns a link to return to the activity view" do
            response = helper.format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params)
            expected_path = section_activity_path(0, activity)
            expect(response).to have_link('Exit answer key', href: expected_path)
          end
        end

        context "when task_type param is present" do
          it "returns a link to return to the activity grading set" do
            @params[:task_type] = 'needs_grading_section'
            response = helper.format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params)
            expected_path = instructor_grading_styles_path(1, activity, task_type: @params[:task_type]).gsub('&', '&amp;')
            expect(response).to have_link('Exit answer key', href: expected_path)
          end
        end
      end
    end

    context "when activity is gradable and current user is an instructor and cartridge" do
      before do
        allow(activity).to receive(:gradable?).and_return(true)
        allow(user).to receive(:instructor?).and_return(true)
        allow(user).to receive(:cartridge?).and_return(true)
      end

      context "when current controller action is not 'answer_keys'" do
        it "returns a link to go to answer key mode" do
          allow(a_controller).to receive(:action_name).and_return('some_action')
          response = format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params)
          expected_path = answer_keys_cartridge_section_activity_path(0, activity.id)
          expect(response).to have_link('Answer key', href: expected_path)
        end
      end

      context "when current controller action is 'answer_keys'" do
        before do
          allow(a_controller).to receive(:action_name).and_return('answer_keys')
        end

        it "returns a link to return to the activity view" do
          response = format_answer_key_mode_link(user, a_controller, activity, 0, 1, @params)
          expected_path = cartridge_section_activity_path(0, activity)
          expect(response).to have_link('Exit answer key', href: expected_path)
        end
      end
    end

    context 'when a gradable activity is a preview' do
      let(:program) { build_stubbed(:program) }
      let(:preview_params) do
        {
          activity: {
            activity_content: 'some content',
            activity_type: 'valid_type',
            cms_revision_id: 879047,
            content_key: '8eb323c06bc556a13e8832cb5f780aa6'
          },
          program_id: program.id
        }
      end
      let(:params_superset) { preview_params.merge(other: 'junk') }

      before do
        # safe_preview_params_hash is defined in the controller as a
        # helper_method
        allow(helper).to receive(:safe_preview_params_hash)
          .and_return(preview_params)
        allow(activity).to receive(:gradable?).and_return(true)
        allow(activity).to receive(:preview?).and_return(true)
      end

      context "when current controller action is not 'preview_answer_key'," do
        it 'returns a link to go to preview answer key mode' do
          allow(a_controller).to receive(:action_name).and_return('some_action')
          response = helper.format_answer_key_mode_link(
            user, a_controller, activity, 0, 1, params_superset
          )
          expected_path = preview_answer_key_path(preview_params)
          expect(response).to have_link('Answer key', href: expected_path)
        end
      end

      context "when current controller action is 'preview_answer_key'," do
        it 'returns a link to return to the activity preview' do
          allow(a_controller).to receive(:action_name).and_return('preview_answer_key')
          response = helper.format_answer_key_mode_link(
            user, a_controller, activity, 0, 1, params_superset
          )
          expected_path = preview_activity_path(preview_params)
          expect(response).to have_link('Exit answer key', href: expected_path)
        end
      end
    end
  end

  describe '#show_attachment_info' do
    let(:attachment) { double('attachment', :file_name => 'some_file', :file_size => 4000) }

    before do
      @results = show_attachment_info(0, attachment)
    end

    it 'displays a container for to hold all links and info about the attachment' do
      expect(@results).to have_selector 'div[class=composition_link_container]'
    end

    it 'displays a container with the download link with the file name as text for the given attachment' do
      expect(@results).to have_selector(
        'div[data-container=download_link]',
        text: attachment.file_name
      )
    end

    it 'displays a container with the file size of the given attachment' do
      expect(@results).to have_selector(
        'div[data-container=file_size]',
        text: "(#{number_to_human_size(attachment.file_size)})"
      )
    end

    it 'displays a container with the removal link for the given attachment' do
      expect(@results).to have_selector(
        'div[data-container=remove_link]',
        text: "Remove uploaded file"
      )
    end
  end

  describe "#format_lesson_and_strand_header" do
    context "when given a lesson label and activity header that forms a string less than 55 characters, i.e. 'Lesson 1 | Short activity header' " do
      it "returns the formatted string 'Lesson 1 | Short activity header'" do
        result = format_lesson_and_strand_header('Lesson 1', 'Short header')
        expect(result).to eql '<span class="current_strand_lesson">Lesson 1</span>| Short header'
      end
    end
    context "when the lesson label and activity header have a combined length greater than 55 (including spaces and pipes)" do
      context "when there is no pipe in the activity list header" do
        it "returns a break after the lesson name and pipe, and the activity list header is on a second line i.e. Lesson 1 | (br tag) Activity header ..." do
          result = format_lesson_and_strand_header('Lesson 1', (1..50).to_a.to_s)
          expect(result).to eql '<span class="current_strand_lesson">Lesson 1</span>|<br/>' + (1..50).to_a.to_s
        end
      end
      context "when there is a pipe in the activity list header" do
        it "returns a string with a break after the last pipe where the string is less than 55 chars long i.e 'Lesson 1 | header | (....) | <- last pipe before char 55'" do
          result = format_lesson_and_strand_header('Lesson 1', "#{(1..10).to_a.to_s} | #{(1..40).to_a.to_s}")
          expect(result).to eql "<span class=\"current_strand_lesson\">Lesson 1</span>| #{(1..10).to_a.to_s} |<br/>#{(1..40).to_a.to_s}"
        end
      end
    end
  end

  describe '#show_accent_bar_for_activity?' do
    context 'when the accent bar is enabled,' do
      let(:activity) { build_stubbed(:activity) }
      let(:enable_accentbar) { true }

      before do
        allow(activity).to receive(:activity_content).and_return(activity_content)
        allow(activity).to receive(:santillana?).and_return(true)
      end

      context 'when the activity has no activity_content,' do
        let(:activity_content) { nil }

        context 'when the activity is a santillana book activity,' do
          before do
            allow(activity).to receive(:santillana?).and_return(true)
          end

          it 'returns false' do
            expect(show_accent_bar_for_activity?(enable_accentbar, activity)).to eq(false)
          end
        end

        context 'when the activity is not a santillana book activity,' do
          before do
            allow(activity).to receive(:santillana?).and_return(false)
          end

          it 'returns true' do
            expect(show_accent_bar_for_activity?(enable_accentbar, activity)).to eq(false)
          end
        end
      end

      context 'when the activity has an activity_content,' do
        let(:activity_content) do
          instance_double(MaestroActivityEngine::ActivityContent::Content)
        end

        context 'when the activity is a santillana book activity,' do
          before do
            allow(activity).to receive(:santillana?).and_return(true)
          end

          it 'returns false' do
            expect(show_accent_bar_for_activity?(enable_accentbar, activity)).to eq(false)
          end
        end

        context 'when the activity is not a santillana book activity,' do
          before do
            allow(activity).to receive(:santillana?).and_return(false)
          end

          it 'returns true' do
            expect(show_accent_bar_for_activity?(enable_accentbar, activity)).to eq(true)
          end
        end
      end
    end

    context 'when the accent bar is not enabled,' do
      let(:enable_accentbar) { false }

      it 'returns false' do
        expect(show_accent_bar_for_activity?(enable_accentbar, nil)). to eq(false)
      end
    end
  end

  describe '#get_activity_shell_icon_path' do
    context 'when the program is Supersite Junior,' do
      before do
        allow(helper).to receive(:supersite_junior?).and_return(true)
      end

      it "returns an icon's path for Supersite Junior." do
        result = 'music/features/jr/activity-shell/icons/my_icon'
        expect(helper.get_activity_shell_icon_path('my_icon')).to eq(result)
      end
    end

    context 'when the program is Supersite,' do
      before do
        allow(helper).to receive(:supersite_junior?).and_return(false)
      end

      it 'returns an icon\'s path for Supersite.' do
        result = 'music/features/activity-shell/icons/my_icon'
        expect(helper.get_activity_shell_icon_path('my_icon')).to eq(result)
      end
    end
  end

  describe '#title_and_dl_audio_paths' do
    let(:activity) { build_stubbed(:activity) }

    context 'when both title and direction line audio filepaths are present' do
      it 'returns an array with both audio filepaths' do
        allow(activity).to receive(:title_audio_filepath).and_return('/path/to/title.mp3')
        allow(activity).to receive(:direction_line_audio_filepath).and_return('/path/to/dl.mp3')

        expect(title_and_dl_audio_paths(activity)).to eq(['/path/to/title.mp3', '/path/to/dl.mp3'])
      end
    end

    context 'when only title audio filepath is present' do
      it 'returns an array with only the title audio filepath' do
        allow(activity).to receive(:title_audio_filepath).and_return('/path/to/title.mp3')
        allow(activity).to receive(:direction_line_audio_filepath).and_return(nil)

        expect(title_and_dl_audio_paths(activity)).to eq(['/path/to/title.mp3'])
      end
    end

    context 'when only direction line audio filepath is present' do
      it 'returns an array with only the direction line audio filepath' do
        allow(activity).to receive(:title_audio_filepath).and_return(nil)
        allow(activity).to receive(:direction_line_audio_filepath).and_return('/path/to/dl.mp3')

        expect(title_and_dl_audio_paths(activity)).to eq(['/path/to/dl.mp3'])
      end
    end

    context 'when neither title nor direction line audio filepaths are present' do
      it 'returns an empty array' do
        allow(activity).to receive(:title_audio_filepath).and_return(nil)
        allow(activity).to receive(:direction_line_audio_filepath).and_return(nil)

        expect(title_and_dl_audio_paths(activity)).to eq([])
      end
    end
  end

  describe '#current_student_section_ai_config' do
    let(:section) { create(:section, input_mode: 'speech', audio_transcript: false) }
    let(:user) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:student_config) { create(:student_section_config, section: section, user: user) }
    let(:activity) { create(:activity) }
    let(:content_object) { double('ContentObject') }
    let(:item) { double('Item', input_mode: 'speech', allow_audio_transcript: false) }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:item).and_return([item])
    end

    context 'when user and section_id are present' do
      context 'when user is an instructor' do
        it 'returns the section default config' do
          config = helper.current_student_section_ai_config(section.id, instructor)
          expect(config).to eq(
            inputMode: 'speech',
            allowAudioTranscript: false
          )
        end
      end

      context 'when student has a specific config' do
        before do
          student_config.update(
            input_mode: 'speech',
            audio_transcript: true
          )
          section.update(
            input_mode: 'speech',
            audio_transcript: false
          )
        end

        it 'returns the student specific config' do
          config = helper.current_student_section_ai_config(section.id, user)
          expect(config).to eq(
            inputMode: 'speech',
            allowAudioTranscript: true
          )
        end
      end

      context 'when student has no specific config' do
        before do
          student_config.destroy
          section.update(
            input_mode: 'speech',
            audio_transcript: false
          )
        end

        it 'returns the section default config' do
          config = helper.current_student_section_ai_config(section.id, user)
          expect(config).to eq(
            inputMode: 'speech',
            allowAudioTranscript: false
          )
        end
      end

      context 'when student config has nil values' do
        before do
          student_config.update(
            input_mode: nil,
            audio_transcript: nil
          )
          section.update(
            input_mode: 'text',
            audio_transcript: true
          )
        end

        it 'falls back to section defaults when student config values are nil' do
          config = helper.current_student_section_ai_config(section.id, user)
          expect(config).to eq(
            inputMode: 'text',
            allowAudioTranscript: true
          )
        end
      end

      context 'when student config has mixed nil and non-nil values' do
        before do
          student_config.update(
            input_mode: 'speech-and-text',
            audio_transcript: nil
          )
          section.update(
            input_mode: 'text',
            audio_transcript: false
          )
        end

        it 'uses student config for non-nil values and section defaults for nil values' do
          config = helper.current_student_section_ai_config(section.id, user)
          expect(config).to eq(
            inputMode: 'speech-and-text',
            allowAudioTranscript: false
          )
        end
      end
    end

    context 'when section is not found' do
      it 'returns default config from activity' do
        config = helper.current_student_section_ai_config(999999, user, activity: activity)
        expect(config).to eq(
          inputMode: 'speech',
          allowAudioTranscript: false
        )
      end

      it 'returns empty hash when no activity provided' do
        config = helper.current_student_section_ai_config(999999, user)
        expect(config).to eq({})
      end
    end

    context 'when user is nil' do
      it 'returns default config from activity' do
        config = helper.current_student_section_ai_config(section.id, nil, activity: activity)
        expect(config).to eq(
          inputMode: 'speech',
          allowAudioTranscript: false
        )
      end

      it 'returns empty hash when no activity provided' do
        config = helper.current_student_section_ai_config(section.id, nil)
        expect(config).to eq({})
      end
    end

    context 'when section_id is nil' do
      it 'returns default config from activity' do
        config = helper.current_student_section_ai_config(nil, user, activity: activity)
        expect(config).to eq(
          inputMode: 'speech',
          allowAudioTranscript: false
        )
      end

      it 'returns empty hash when no activity provided' do
        config = helper.current_student_section_ai_config(nil, user)
        expect(config).to eq({})
      end
    end

    context 'when both user and section_id are nil' do
      it 'returns default config from activity' do
        config = helper.current_student_section_ai_config(nil, nil, activity: activity)
        expect(config).to eq(
          inputMode: 'speech',
          allowAudioTranscript: false
        )
      end

      it 'returns empty hash when no activity provided' do
        config = helper.current_student_section_ai_config(nil, nil)
        expect(config).to eq({})
      end
    end

    context 'when activity is provided' do
      let(:activity_with_config) { create(:activity) }
      let(:content_object_with_config) { double('ContentObject') }
      let(:item_with_config) { double('Item', input_mode: 'text-no-audio', allow_audio_transcript: true) }

      before do
        allow(activity_with_config).to receive(:content_object).and_return(content_object_with_config)
        allow(content_object_with_config).to receive(:item).and_return([item_with_config])
      end

      it 'uses activity config when section is not found' do
        config = helper.current_student_section_ai_config(999999, user, activity: activity_with_config)
        expect(config).to eq(
          inputMode: 'text-no-audio',
          allowAudioTranscript: true
        )
      end

      it 'uses activity config when user is nil' do
        config = helper.current_student_section_ai_config(section.id, nil, activity: activity_with_config)
        expect(config).to eq(
          inputMode: 'text-no-audio',
          allowAudioTranscript: true
        )
      end
    end

    context 'when activity has no content_object or item' do
      let(:activity_without_config) { create(:activity) }

      it 'returns empty hash when activity has no content_object' do
        allow(activity_without_config).to receive(:content_object).and_return(nil)
        config = helper.current_student_section_ai_config(999999, user, activity: activity_without_config)
        expect(config).to eq({})
      end

      it 'returns empty hash when activity has no item' do
        allow(activity_without_config).to receive(:content_object).and_return(content_object)
        allow(content_object).to receive(:item).and_return([])
        config = helper.current_student_section_ai_config(999999, user, activity: activity_without_config)
        expect(config).to eq({})
      end
    end
  end

  describe '#single_line_title' do
    it 'replaces <br /> with space' do
      expect(helper.single_line_title('a<br />b')).to eq('a b')
    end

    it 'replaces <br> with space' do
      expect(helper.single_line_title('a<br>b')).to eq('a b')
    end

    it 'replaces <br > with space' do
      expect(helper.single_line_title('a<br >b')).to eq('a b')
    end

    it 'replaces multiple <br> tags with spaces' do
      expect(helper.single_line_title('a<br>b<br>c')).to eq('a b c')
    end

    it 'replaces <br    /> with space' do
      expect(helper.single_line_title('a<br    />b')).to eq('a b')
    end

    it 'replaces <br / > with space' do
      expect(helper.single_line_title('a<br / >b')).to eq('a b')
    end

    it 'squishes spaces before and after <br> tags' do
      expect(helper.single_line_title('a <br /> b')).to eq('a b')
    end

    it 'preserves <b> tags' do
      expect(helper.single_line_title('a <b>b</b>')).to eq('a <b>b</b>')
    end

    it 'preserves <i> tags' do
      expect(helper.single_line_title('a <i>b</i>')).to eq('a <i>b</i>')
    end

    it 'preserves <strong> tags' do
      expect(
        helper.single_line_title('a <strong>b</strong>')
      ).to eq('a <strong>b</strong>')
    end

    it 'preserves <em> tags' do
      expect(helper.single_line_title('a <em>b</em>')).to eq('a <em>b</em>')
    end

    it 'preserves <span> tags w/ lang attrs' do
      expect(
        helper.single_line_title('a <span lang="en">b</span>')
      ).to eq('a <span lang="en">b</span>')
    end

    it 'strips <script> tags' do
      expect(helper.single_line_title('a <script>b</script>')).to eq('a b')
    end

    it 'does not strip entities' do
      expect(helper.single_line_title('a &bull; b')).to eq('a • b')
    end
  end
end
