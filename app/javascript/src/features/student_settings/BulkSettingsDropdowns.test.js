import { mount } from '@vue/test-utils';
import BulkSettingsDropdowns from './BulkSettingsDropdowns.vue';
import BulkSettingsConfirmationDialog from './BulkSettingsConfirmationDialog.vue';
import { postToEndpoint } from '../../shared/ajax_utils';
import { setupToastMock, clearToastMock, getMockToast } from './__mocks__/toastMock';
import SettingsDropdown from './SettingsDropdown.vue';

// Mock the postToEndpoint function
vi.mock('../../shared/ajax_utils', () => ({
  postToEndpoint: vi.fn()
}));

describe('BulkSettingsDropdowns', () => {
  let wrapper;
  const defaultProps = {
    languageOptions: [
      { value: 'none', label: 'Off' },
      { value: 'foreign', label: 'Spanish' },
      { value: 'foreign_and_english', label: 'Spanish and English' }
    ],
    programLanguageName: 'Spanish',
    selectedStudentIds: [1, 2, 3],
    updateStudentsUrl: '/update-students'
  };

  beforeEach(() => {
    setupToastMock();
    clearToastMock();

    wrapper = mount(BulkSettingsDropdowns, {
      props: defaultProps,
      global: {
        components: {
          BulkSettingsConfirmationDialog,
          SettingsDropdown
        }
      }
    });
  });

  describe('rendering', () => {
    it('renders all three dropdowns', () => {
      const dropdowns = wrapper.findAll('sl-dropdown');
      expect(dropdowns).toHaveLength(3);
    });

    it('renders video subtitles dropdown with correct options', () => {
      const menuItems = wrapper.findAll('[data-testid="video-subtitles-dropdown"] sl-menu-item');

      expect(menuItems).toHaveLength(3);
      expect(menuItems[0].text()).toBe('Off');
      expect(menuItems[1].text()).toBe('Spanish');
      expect(menuItems[2].text()).toBe('Spanish and English');
    });

    it('renders video transcripts dropdown with correct options', () => {
      const menuItems = wrapper.findAll('[data-testid="video-transcripts-dropdown"] sl-menu-item');

      expect(menuItems).toHaveLength(3);
      expect(menuItems[0].text()).toBe('Off');
      expect(menuItems[1].text()).toBe('Spanish');
      expect(menuItems[2].text()).toBe('Spanish and English');
    });

    it('renders audio transcripts dropdown with correct options', () => {
      const menuItems = wrapper.findAll('[data-testid="audio-transcripts-dropdown"] sl-menu-item');

      expect(menuItems).toHaveLength(2);
      expect(menuItems[0].text()).toBe('On');
      expect(menuItems[1].text()).toBe('Off');
    });

    it('renders the confirmation dialog', () => {
      expect(wrapper.findComponent(BulkSettingsConfirmationDialog).exists()).toBe(true);
    });

    it('passes correct props to confirmation dialog', () => {
      const dialog = wrapper.findComponent(BulkSettingsConfirmationDialog);
      expect(dialog.props('selectedCount')).toBe(3);
      expect(dialog.props('programLanguageName')).toBe('Spanish');
      expect(dialog.props('pendingSettings')).toEqual({});
    });
  });

  describe('props validation', () => {
    it('requires languageOptions prop', () => {
      expect(BulkSettingsDropdowns.props.languageOptions.required).toBe(true);
    });

    it('requires programLanguageName prop', () => {
      expect(BulkSettingsDropdowns.props.programLanguageName.required).toBe(true);
    });

    it('requires selectedStudentIds prop', () => {
      expect(BulkSettingsDropdowns.props.selectedStudentIds.required).toBe(true);
    });

    it('requires updateStudentsUrl prop', () => {
      expect(BulkSettingsDropdowns.props.updateStudentsUrl.required).toBe(true);
    });
  });

  describe('dropdown interactions', () => {
    it('sets up confirmation dialog when video subtitles option is selected', async () => {
      const subtitlesDropdown = wrapper.find('[data-testid="video-subtitles-dropdown"]');
      await subtitlesDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      expect(wrapper.vm.pendingSettings).toEqual({
        video_subtitle_languages: 'foreign'
      });
    });

    it('sets up confirmation dialog when video transcripts option is selected', async () => {
      const transcriptsDropdown = wrapper.find('[data-testid="video-transcripts-dropdown"]');
      await transcriptsDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      expect(wrapper.vm.pendingSettings).toEqual({
        video_transcript_languages: 'foreign'
      });
    });

    it('sets up confirmation dialog when audio transcripts option is selected', async () => {
      const audioDropdown = wrapper.find('[data-testid="audio-transcripts-dropdown"]');
      await audioDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'on' } }
      });

      expect(wrapper.vm.pendingSettings).toEqual({
        audio_transcript: true
      });
    });

    it('does not set up confirmation dialog when no students are selected', async () => {
      await wrapper.setProps({ selectedStudentIds: [] });

      const subtitlesDropdown = wrapper.find('[data-testid="video-subtitles-dropdown"]');
      await subtitlesDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      expect(wrapper.vm.pendingSettings).toEqual({});
    });
  });

  describe('confirmation dialog interactions', () => {
    it('emits update:students event when confirmation is accepted', async () => {
      // Mock successful API response
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true });
      });

      const subtitlesDropdown = wrapper.find('[data-testid="video-subtitles-dropdown"]');
      await subtitlesDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      await wrapper.findComponent(BulkSettingsConfirmationDialog).vm.$emit('confirm');

      // Verify the API was called with correct parameters
      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-students',
        {
          user_ids: [1, 2, 3],
          video_subtitle_languages: 'foreign'
        },
        expect.any(Function)
      );

      // Verify success toast was shown
      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('check');
      expect(alert.innerHTML).toContain('Video subtitles setting successfully applied for 3 students');
      expect(getMockToast()).toHaveBeenCalled();

      // Verify the event was emitted
      expect(wrapper.emitted('update:students')).toBeTruthy();
      expect(wrapper.emitted('update:students')[0][0]).toEqual({
        video_subtitle_languages: 'foreign'
      });
    });

    it('does not emit update:students event when confirmation is cancelled', async () => {
      const subtitlesDropdown = wrapper.find('[data-testid="video-subtitles-dropdown"]');
      await subtitlesDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      await wrapper.findComponent(BulkSettingsConfirmationDialog).vm.$emit('cancel');

      expect(postToEndpoint).not.toHaveBeenCalled();
      expect(wrapper.emitted('update:students')).toBeFalsy();
    });

    it('handles API error gracefully', async () => {
      // Mock failed API response
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      const subtitlesDropdown = wrapper.find('[data-testid="video-subtitles-dropdown"]');
      await subtitlesDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'foreign' } }
      });

      await wrapper.findComponent(BulkSettingsConfirmationDialog).vm.$emit('confirm');

      // Verify the API was called
      expect(postToEndpoint).toHaveBeenCalled();

      // Verify error toast was shown
      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('alert-circle');
      expect(alert.innerHTML).toContain('There was an error updating the video subtitles setting for 3 students');
      expect(getMockToast()).toHaveBeenCalled();

      // Verify no event was emitted on error
      expect(wrapper.emitted('update:students')).toBeFalsy();
    });
  });

  describe('Input Mode dropdown', () => {
    it('renders input mode dropdown only if hasAiVirtualChatActivities is true', async () => {
      // With AI enabled
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' }
      });
      expect(wrapper.find('[data-testid="input-mode-dropdown"]').exists()).toBe(true);

      // With AI disabled
      await wrapper.setProps({ hasAiVirtualChatActivities: false });
      expect(wrapper.find('[data-testid="input-mode-dropdown"]').exists()).toBe(false);
    });

    it('renders all aiInputModes as options', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' }
      });
      const menuItems = wrapper.find('[data-testid="input-mode-dropdown"]').findAll('sl-menu-item');
      expect(menuItems).toHaveLength(2);
      expect(menuItems[0].text()).toBe('Student Audio Response');
      expect(menuItems[1].text()).toBe('Student Text Response');
    });

    it('sets up confirmation dialog when input mode option is selected', async () => {
      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' }
      });
      const inputModeDropdown = wrapper.find('[data-testid="input-mode-dropdown"]');
      await inputModeDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'text' } }
      });

      expect(wrapper.vm.pendingSettings).toEqual({ input_mode: 'text' });
      expect(wrapper.vm.settingName).toBe('Input Mode');
    });

    it('emits update:students event with input_mode when confirmation is accepted', async () => {
      // Mock API
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true });
      });

      await wrapper.setProps({
        hasAiVirtualChatActivities: true,
        aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' }
      });
      const inputModeDropdown = wrapper.find('[data-testid="input-mode-dropdown"]');
      await inputModeDropdown.find('sl-menu').trigger('sl-select', {
        detail: { item: { value: 'speech' } }
      });

      await wrapper.findComponent(BulkSettingsConfirmationDialog).vm.$emit('confirm');

      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-students',
        {
          user_ids: [1, 2, 3],
          input_mode: 'speech'
        },
        expect.any(Function)
      );
      expect(wrapper.emitted('update:students')).toBeTruthy();
      expect(wrapper.emitted('update:students')[0][0]).toEqual({ input_mode: 'speech' });
    });
  });
});
