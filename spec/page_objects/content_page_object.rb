 require 'page_objects/page_object'
 require 'page_objects/button_object'

class ContentPageObject < PageObject
  def first_unit= unit
    page.find(first_unit_selector, text: unit).select_option
  end

  def first_unit
    first_unit_elements.detect(&:selected?).text
  end

  def first_units
    first_unit_elements.map(&:text)
  end

  private def first_unit_elements
    page.has_selector?(first_unit_selector)
    page.all(first_unit_selector)
  end

  def first_unit_selector
    '.test-first-unit-select option'
  end

  def last_unit= unit
    page.find(last_unit_selector, text: unit).select_option
  end

  def last_unit
    last_unit_elements.detect(&:selected?).text
  end

  def last_units
    last_unit_elements.map(&:text)
  end

  private def last_unit_elements
    page.has_selector?(last_unit_selector)
    page.all(last_unit_selector)
  end

  def last_unit_selector
    '.test-last-unit-select option'
  end

  def enable_vocab_tutorial_translations=(value)
    vhl_toggle_check(enable_vocab_tutorial_translations_label, value)
  end

  def enable_vocab_tutorial_translations
    page.find_field(enable_vocab_tutorial_translations_label).checked?
  end

  def enable_vocab_tutorial_translations_label
    'Allow students to view English translations for terms in the Vocabulary Tutorials.'
  end

  def allow_audio_transcripts=(value)
    vhl_toggle_check(allow_audio_transcripts_label, value)
  end

  def allow_audio_transcripts
    page.find_field(allow_audio_transcripts_label).checked?
  end

  def allow_audio_transcripts_label
    'Allow students to see transcripts of recorded audio.'
  end

  def video_subtitle_language= language
    page.find(video_subtitle_language_selector, text: language, match: :prefer_exact).select_option
  end

  def video_subtitle_language
    page.all(video_subtitle_language_selector).detect(&:selected?).text
  end

  def video_subtitle_language_selector
    'select[name="video_subtitle_languages"] option'
  end

  def video_transcript_language= language
    page.find(video_transcript_language_selector, text: language, match: :prefer_exact).select_option
  end

  def video_transcript_language
    page.all(video_transcript_language_selector).detect(&:selected?).text
  end

  def video_transcript_language_selector
    'select[name="video_transcript_languages"] option'
  end

  def allow_review_requests=(value)
    vhl_toggle_check(allow_review_requests_label, value)
  end

  def allow_review_requests
    page.find_field(allow_review_requests_label).checked?
  end

  def allow_review_requests_label
    'Allow students to submit to you assignment score review requests, after their final attempt.'
  end

  def allow_help_requests=(value)
    vhl_toggle_check(allow_help_requests_label, value)
  end

  def allow_help_requests
    page.find_field(allow_help_requests_label).checked?
  end

  def allow_help_requests_label
    'Allow students to submit to you assignment help requests, before their final attempt.'
  end

  def chat_availability= value
    page.find(chat_availability_selector(value)).set(true)
  end

  def chat_availability
    %i[never only_partner_chat always].detect do |v|
      page.find(chat_availability_selector(v)).checked?
    end
  end

  def chat_availability_selector(value)
    case value
    when :never then 'input[name="chat_level_disabled"]'
    when :only_partner_chat then 'input[name="chat_level_partner_chat"]'
    when :always then 'input[name="chat_level_partner_chat_and_live_chat"]'
    else raise ArgumentError, "invalid value '#{value}'"
    end
  end

  def has_chat_feature_disabled?
    page.has_selector?('.test-chat-availability', text: 'Your institution has disabled this behavior.')
  end

  def show_estimated_times=(value)
    vhl_toggle_check(show_estimated_times_label, value)
  end

  def show_estimated_times
    page.find_field(show_estimated_times_label).checked?
  end

  def show_estimated_times_label
    'Allow students to see the estimated time necessary to complete assignments.'
  end

  def share_to_google_classroom=(value)
    vhl_toggle_check(share_to_google_classroom_times_label, value)
  end

  def share_to_google_classroom
    page.find_field(share_to_google_classroom_times_label).checked?
  end

  def share_to_google_classroom_times_label
    'Enable the Google Share button for individual content items for use with ' \
    'Google Classroom. Disabling this option will not remove any previously ' \
    'created Google Share links.'
  end

  def has_share_to_google_classroom_option?
    page.has_selector?('.test-google-classroom')
  end

  def has_no_share_to_google_classroom_option?
    page.has_no_selector?('.test-google-classroom')
  end

  def standard_sets
    page.all('.test-standards .checkbox-container').map do |container|
      StandardSetPageElement.new(container)
    end
  end

  def standard_set(name)
    StandardSetPageElement.new(
      page.find('.test-standards .checkbox-container', text: name)
    )
  end

  def has_standard_sets_error_message_visible?
    page.has_selector?(
      '.test-standards-validation-error',
      text: 'You must select at least one standard.',
      visible: true
    )
  end

  def has_standard_sets_error_message_hidden?
    page.has_no_selector?(
      '.test-standards-validation-error',
      text: 'You must select at least one standard.'
    )
  end

  class StandardSetPageElement
    attr_accessor :container

    def initialize(container)
      self.container = container
    end

    def name
      container.text
    end

    def checked?
      input.checked?
    end

    def check
      container.click unless checked?
    end

    def uncheck
      container.click if checked?
    end

    private def input
      container.find('input')
    end
  end

  def button(id)
    element = case id
              when :cancel
                page.find('.test-cancel-btn')
              when :back
                page.find('.test-back-btn', text: 'Previous')
              when :next
                page.find('.test-next-btn', text: 'Next')
              when :save_changes
                page.find('.test-save-changes', text: 'Save changes')
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end

  private def set_check_state(selector, value)
    elm = page.find(selector)
    if value
      page.check(elm['id'], allow_label_click: true)
    else
      page.uncheck(elm['id'], allow_label_click: true)
    end
  end
end
