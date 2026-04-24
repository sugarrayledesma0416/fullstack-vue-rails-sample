RSpec.describe Instructor::CreatedActivity::NewActivityLinkContentPresenter do
  include ActionView::TestCase::Behavior
  subject(:presenter) { described_class.new(view, instructor_presenter) }

  let(:instructor_presenter) { instance_double(InstructorContentPresenter) }
  let(:program_id) { 123 }
  let(:display_lesson_id) { 456 }
  let(:current_topic) { 789 }

  before do
    allow(instructor_presenter).to receive_message_chain(:program, :id)
      .and_return(program_id)
    allow(instructor_presenter).to receive_message_chain(:display_lesson, :id)
      .and_return(display_lesson_id)
    allow(instructor_presenter).to receive(:current_topic).and_return(current_topic)
  end

  describe '#menubar_classes' do
    it 'return expected classes' do
      expected_classes = %w[c-menubar js-nav-system]
      expect(presenter.menubar_classes.split).to match_array(expected_classes)
    end
  end

  describe '#menu_item_classes' do
    it 'return expected classes' do
      expected_classes = %w[c-menu__item js-nav-system__item]
      expect(presenter.menu_item_classes.split).to match_array(expected_classes)
    end
  end

  describe '#menu_item_link_classes' do
    it 'return expected classes' do
      expected_classes =
        %w[c-button js-nav-system__link m4-button--primary u-pad-8 u-pad-lt-16 u-pad-rt-16]
      expect(presenter.menu_item_link_classes.split).to match_array(expected_classes)
    end
  end

  describe '#button_icon' do
    before do
      allow(Music::Components).to receive(:icon)
    end

    it 'return expected classes' do
      presenter.button_icon
      expect(Music::Components).to have_received(:icon)
        .with(variant: 'add', size: 'sm', invert: true, classes: ['u-mar-rt-6'])
    end
  end

  describe '#button_label' do
    it 'returns expected label' do
      expect(presenter.button_label).to eq('Create')
    end
  end

  describe '#menu_inner_classes' do
    it 'return expected classes' do
      expected_classes = %w[c-menu__inner u-bord-radius-16 js-nav-system__subnav]
      expect(presenter.menu_inner_classes.split).to match_array(expected_classes)
    end
  end

  describe '#menu_subitem_classes' do
    it 'return expected classes' do
      expected_classes = %w[c-menu__subitem js-nav-system__subnav__item]
      expect(presenter.menu_subitem_classes.split).to match_array(expected_classes)
    end
  end

  describe '#menu_subitem_link_classes' do
    it 'return expected classes' do
      expected_classes = %w[menu__link u-txt-bold js-nav-system__subnav__link]
      expect(presenter.menu_subitem_link_classes(:fake_activity_type).split)
        .to match_array(expected_classes)
    end
  end

  describe '#new_created_activity_link' do
    let(:fake_path) { '/fake-path' }
    let(:fake_label) { 'Fake Label' }
    let(:fake_class) { 'fake-class' }

    before do
      allow(Rails).to receive_message_chain(
        :application, :routes, :url_helpers, :new_instructor_created_activity_path
      ).and_return(fake_path)
      allow(presenter).to receive(:activity_label).and_return(fake_label)
      allow(presenter).to receive(:menu_subitem_link_classes).and_return(fake_class)
      allow(view).to receive(:link_to)
      presenter.new_created_activity_link(activity_type, activity_params)
    end

    context 'when no activity_params is provided' do
      let(:activity_type) { :multiple_choice_same }
      let(:activity_params) { {} }

      it 'calls activity_label properly' do
        expect(presenter).to have_received(:activity_label).with(activity_type, activity_params)
      end

      it 'calls new_instructor_created_activity_path properly' do
        expected_params = {
          program_id:,
          lesson_id: display_lesson_id,
          toc_entry_id: current_topic,
          from_my_content: 'true',
          activity_type:
        }

        expect(Rails.application.routes.url_helpers)
          .to have_received(:new_instructor_created_activity_path).with(expected_params)
      end

      it 'calls link_to properly' do
        expect(view).to have_received(:link_to)
          .with(fake_label, fake_path, class: fake_class, role: 'menuitem')
      end
    end

    context 'when activity_params is provided' do
      let(:activity_type) { :multiple_choice }
      let(:activity_params) { { choice_count: 2 } }

      it 'calls new_instructor_created_activity_path properly' do
        expected_params = {
          program_id:,
          lesson_id: display_lesson_id,
          toc_entry_id: current_topic,
          from_my_content: 'true',
          activity_type:,
          **activity_params
        }

        expect(Rails.application.routes.url_helpers)
          .to have_received(:new_instructor_created_activity_path).with(expected_params)
      end
    end
  end

  describe '#menu_subitem_element' do
    let(:fake_link) { '<a href="/fake-path">Fake Label</a>' }
    let(:fake_class) { 'fake-class' }

    before do
      allow(presenter).to receive(:menu_subitem_classes).and_return(fake_class)
      allow(presenter).to receive(:new_created_activity_link).and_return(fake_link.html_safe)
    end

    it 'creates content_tag properly' do
      result = presenter.menu_subitem_element(:multiple_choice, choice_count: 2)

      expect(result).to eq("<li class=\"#{fake_class}\" role=\"none\">#{fake_link}</li>")
    end
  end
end
