import { mount } from '@vue/test-utils';
import SectionDefaultsDialog from './SectionDefaultsDialog.vue';
import { postToEndpoint } from '../../shared/ajax_utils';
import { setupToastMock, clearToastMock, getMockToast } from './__mocks__/toastMock';

// Mock the ajax_utils module
vi.mock('../../shared/ajax_utils', () => ({
  postToEndpoint: vi.fn()
}));

describe('SectionDefaultsDialog', () => {
  let wrapper;
  const defaultProps = {
    languageOptions: [
      { value: 'none', label: 'Off' },
      { value: 'foreign', label: 'Spanish' },
      { value: 'foreign_and_english', label: 'Spanish and English' }
    ],
    programLanguageName: 'Spanish',
    sectionVideoTranscriptLanguages: 'none',
    sectionVideoSubtitleLanguages: 'foreign',
    sectionAudioTranscript: false,
    sectionInputMode: 'speech',
    hasAiVirtualChatActivities: true,
    aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
    updateSectionDefaultsUrl: '/update-section-defaults'
  };

  beforeEach(() => {
    setupToastMock();
    clearToastMock();

    wrapper = mount(SectionDefaultsDialog, {
      props: defaultProps
    });
  });

  describe('rendering', () => {
    it('renders with correct initial values', () => {
      expect(wrapper.find('[name="video_subtitle_languages"]').attributes('value')).toBe('foreign');
      expect(wrapper.find('[name="video_transcript_languages"]').attributes('value')).toBe('none');
      expect(wrapper.find('[name="audio_transcript"]').attributes('checked')).toBe('false');
      expect(wrapper.find('[name="apply_to_all"]').attributes('checked')).toBe('false');
      expect(wrapper.find('[name="input_mode"]').attributes('value')).toBe('speech');
    });

    it('renders correct options in dropdowns', () => {
      const subtitleOptions = wrapper.findAll('[name="video_subtitle_languages"] sl-option');
      expect(subtitleOptions).toHaveLength(3);
      expect(subtitleOptions[0].text()).toBe('Off');
      expect(subtitleOptions[1].text()).toBe('Spanish');
      expect(subtitleOptions[2].text()).toBe('Spanish and English');

      const transcriptOptions = wrapper.findAll('[name="video_transcript_languages"] sl-option');
      expect(transcriptOptions).toHaveLength(3);
      expect(transcriptOptions[0].text()).toBe('Off');
      expect(transcriptOptions[1].text()).toBe('Spanish');
      expect(transcriptOptions[2].text()).toBe('Spanish and English');
    }); 
  });

  describe('form interactions', () => {
    it('updates video subtitles when select changes', () => {
      wrapper.vm.handleVideoSubtitlesChange({ target: { value: 'foreign_and_english' } });

      expect(wrapper.vm.videoSubtitleLanguages).toBe('foreign_and_english');
    });

    it('updates video transcripts when select changes', () => {
      wrapper.vm.handleVideoTranscriptsChange({ target: { value: 'foreign' } });

      expect(wrapper.vm.videoTranscriptLanguages).toBe('foreign');
    });

    it('updates audio transcript when checkbox changes', () => {
      wrapper.vm.handleAudioTranscriptChange({ target: { checked: true } });

      expect(wrapper.vm.audioTranscript).toBe(true);
    });

    it('updates apply to all when checkbox changes', () => {
      wrapper.vm.handleApplyToAllChange({ target: { checked: true } });

      expect(wrapper.vm.applyToAll).toBe(true);
    });

    it('resets form data when dialog is shown', () => {
      // First change some values
      wrapper.vm.videoSubtitleLanguages = 'foreign_and_english';
      wrapper.vm.videoTranscriptLanguages = 'foreign';
      wrapper.vm.audioTranscript = true;
      wrapper.vm.inputMode = 'text';
      wrapper.vm.applyToAll = true;

      // Trigger the show event
      wrapper.vm.resetForm({ eventPhase: Event.AT_TARGET });

      // Verify values are reset to initial props
      expect(wrapper.vm.videoSubtitleLanguages).toBe(defaultProps.sectionVideoSubtitleLanguages);
      expect(wrapper.vm.videoTranscriptLanguages).toBe(defaultProps.sectionVideoTranscriptLanguages);
      expect(wrapper.vm.audioTranscript).toBe(defaultProps.sectionAudioTranscript);
      expect(wrapper.vm.inputMode).toBe(defaultProps.sectionInputMode);
      expect(wrapper.vm.applyToAll).toBe(false);
    });

    it('does not reset form data when child publishes show event', () => {
      // First change some values
      wrapper.vm.videoSubtitleLanguages = 'foreign_and_english';
      wrapper.vm.videoTranscriptLanguages = 'foreign';
      wrapper.vm.audioTranscript = true;
      wrapper.vm.inputMode = 'text';
      wrapper.vm.applyToAll = true;

      // Trigger the show event
      wrapper.vm.resetForm({ eventPhase: Event.BUBBLING_PHASE });

      // Verify values are reset to initial props
      expect(wrapper.vm.videoSubtitleLanguages).toBe('foreign_and_english');
      expect(wrapper.vm.videoTranscriptLanguages).toBe('foreign');
      expect(wrapper.vm.audioTranscript).toBe(true);
      expect(wrapper.vm.inputMode).toBe('text');
      expect(wrapper.vm.applyToAll).toBe(true);
    });
  });

  describe('form submission', () => {
    it('submits form with correct data', async () => {
      // Set form values
      wrapper.vm.videoSubtitleLanguages = 'foreign_and_english';
      wrapper.vm.videoTranscriptLanguages = 'foreign';
      wrapper.vm.audioTranscript = true;
      wrapper.vm.inputMode = 'text';
      wrapper.vm.applyToAll = true;

      // Submit form
      await wrapper.vm.handleSubmit();

      // Verify API call
      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-section-defaults',
        {
          audio_transcript: true,
          video_subtitle_languages: 'foreign_and_english',
          video_transcript_languages: 'foreign',
          input_mode: 'text',
          apply_to_all: true
        },
        expect.any(Function)
      );
    });

    it('shows success toast when API call succeeds', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true, students: [] });
      });

      await wrapper.vm.handleSubmit();

      const alert = document.querySelector('[data-testid="section-defaults-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('check');
      expect(alert.innerHTML).toContain('Default settings updated successfully');
      expect(getMockToast()).toHaveBeenCalled();
    });

    it('shows error toast when API call fails', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      await wrapper.vm.handleSubmit();

      const alert = document.querySelector('[data-testid="section-defaults-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('alert-circle');
      expect(alert.innerHTML).toContain('There was an error updating the default settings');
      expect(getMockToast()).toHaveBeenCalled();
    });

    it('emits update:students event when API call succeeds', async () => {
      const mockStudents = [
        { id: 1, firstName: 'John', lastName: 'Doe' },
        { id: 2, firstName: 'Jane', lastName: 'Smith' }
      ];

      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true, students: mockStudents });
      });

      await wrapper.vm.handleSubmit();

      expect(wrapper.emitted('update:students')).toBeTruthy();
      expect(wrapper.emitted('update:students')[0]).toEqual([mockStudents]);
    });

    it('emits update:sectionSettings event with new settings when API call succeeds', async () => {
      // Set form values
      wrapper.vm.videoSubtitleLanguages = 'foreign_and_english';
      wrapper.vm.videoTranscriptLanguages = 'foreign';
      wrapper.vm.audioTranscript = true;
      wrapper.vm.inputMode = 'text';

      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true });
      });

      await wrapper.vm.handleSubmit();

      expect(wrapper.emitted('update:sectionSettings')).toBeTruthy();
      expect(wrapper.emitted('update:sectionSettings')[0]).toEqual([{
        sectionVideoTranscriptLanguages: 'foreign',
        sectionVideoSubtitleLanguages: 'foreign_and_english',
        sectionAudioTranscript: true,
        sectionInputMode: 'text'
      }]);
    });

    it('does not emit update:students event when API call fails', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      await wrapper.vm.handleSubmit();

      expect(wrapper.emitted('update:students')).toBeFalsy();
    });
  });

  describe('props validation', () => {
    it('requires languageOptions prop', () => {
      expect(SectionDefaultsDialog.props.languageOptions.required).toBe(true);
    });

    it('requires programLanguageName prop', () => {
      expect(SectionDefaultsDialog.props.programLanguageName.required).toBe(true);
    });

    it('requires sectionVideoTranscriptLanguages prop', () => {
      expect(SectionDefaultsDialog.props.sectionVideoTranscriptLanguages.required).toBe(true);
    });

    it('requires sectionVideoSubtitleLanguages prop', () => {
      expect(SectionDefaultsDialog.props.sectionVideoSubtitleLanguages.required).toBe(true);
    });

    it('requires sectionAudioTranscript prop', () => {
      expect(SectionDefaultsDialog.props.sectionAudioTranscript.required).toBe(true);
    });

    it('requires sectionInputMode prop', () => {
      expect(SectionDefaultsDialog.props.sectionInputMode.required).toBe(true);
    });

    it('requires hasAiVirtualChatActivities prop', () => {
      expect(SectionDefaultsDialog.props.hasAiVirtualChatActivities.required).toBe(true);
    });

    it('requires updateSectionDefaultsUrl prop', () => {
      expect(SectionDefaultsDialog.props.updateSectionDefaultsUrl.required).toBe(true);
    });
  });

  describe('Input Mode field', () => {
    it('renders input mode dropdown only if hasAiVirtualChatActivities is true', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
        sectionInputMode: 'speech'
      });
      expect(wrapper.find('[name="input_mode"]').exists()).toBe(true);

      await wrapper.setProps({ hasAiVirtualChatActivities: false });
      expect(wrapper.find('[name="input_mode"]').exists()).toBe(false);
    });

    it('renders all aiInputModes as options', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
        sectionInputMode: 'speech'
      });
      const options = wrapper.findAll('[name="input_mode"] sl-option');
      expect(options).toHaveLength(2);
      expect(options[0].text()).toBe('Student Audio Response');
      expect(options[1].text()).toBe('Student Text Response');
    });

    it('updates inputMode when dropdown changes', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
        sectionInputMode: 'speech'
      });
      wrapper.vm.handleInputModeChange({ target: { value: 'text' } });
      expect(wrapper.vm.inputMode).toBe('text');
    });

    it('includes inputMode in form submission and emits update:sectionSettings', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
        sectionInputMode: 'speech'
      });
      wrapper.vm.inputMode = 'text';
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true });
      });
      await wrapper.vm.handleSubmit();
      expect(postToEndpoint).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({ input_mode: 'text' }),
        expect.any(Function)
      );
      expect(wrapper.emitted('update:sectionSettings')[0][0]).toEqual(
        expect.objectContaining({ sectionInputMode: 'text' })
      );
    });

    it('resets inputMode to sectionInputMode when dialog is shown', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
        sectionInputMode: 'speech'
      });
      wrapper.vm.inputMode = 'text';
      wrapper.vm.resetForm({ eventPhase: Event.AT_TARGET });
      expect(wrapper.vm.inputMode).toBe('speech');
    });
  });
});
