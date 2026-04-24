import { mount } from '@vue/test-utils';
import StudentSettingsStudentRow from './StudentSettingsStudentRow.vue';
import { postToEndpoint } from '../../shared/ajax_utils';
import { setupToastMock, clearToastMock, getMockToast } from './__mocks__/toastMock';

// Mock the ajax_utils module
vi.mock('../../shared/ajax_utils', () => ({
  postToEndpoint: vi.fn()
}));

describe('StudentSettingsStudentRow', () => {
  let wrapper;
  const defaultProps = {
    student: {
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      video_subtitle_languages: 'foreign',
      video_transcript_languages: 'none',
      audio_transcript: false
    },
    programId: 123,
    languageOptions: [
      { value: 'none', label: 'Off' },
      { value: 'foreign', label: 'Spanish' },
      { value: 'foreign_and_english', label: 'Spanish and English' }
    ],
    courseId: 456,
    sectionId: 789,
    updateStudentsUrl: '/update-students'
  };

  beforeEach(() => {
    setupToastMock();
    clearToastMock();

    wrapper = mount(StudentSettingsStudentRow, {
      props: defaultProps
    });
  });

  describe('rendering', () => {
    it('renders student name correctly', () => {
      expect(wrapper.find('[data-testid="student-name"]').text()).toBe('Doe, John');
    });

    it('renders video subtitles select with correct value', () => {
      const select = wrapper.find('[data-testid="video-subtitles"]');
      expect(select.attributes('value')).toBe('foreign');
    });

    it('renders video transcripts select with correct value', () => {
      const select = wrapper.find('[data-testid="video-transcripts"]');
      expect(select.attributes('value')).toBe('none');
    });

    it('renders audio transcript checkbox with correct value', () => {
      const checkbox = wrapper.find('[data-testid="audio-transcript"]');
      expect(checkbox.attributes('checked')).toBe('false');
    });

    it('renders correct options in video subtitles select', () => {
      const options = wrapper.findAll('[data-testid="video-subtitles"] sl-option');
      expect(options).toHaveLength(3);
      expect(options[0].text()).toBe('Off');
      expect(options[1].text()).toBe('Spanish');
      expect(options[2].text()).toBe('Spanish and English');
    });

    it('renders correct options in video transcripts select', () => {
      const options = wrapper.findAll('[data-testid="video-transcripts"] sl-option');
      expect(options).toHaveLength(3);
      expect(options[0].text()).toBe('Off');
      expect(options[1].text()).toBe('Spanish');
      expect(options[2].text()).toBe('Spanish and English');
    });
  });

  describe('form interactions', () => {
    it('updates video subtitles when select changes', async () => {
      await wrapper.vm.handleVideoSubtitlesChange({ target: { value: 'foreign_and_english' } });

      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-students',
        {
          user_ids: [1],
          video_subtitle_languages: 'foreign_and_english'
        },
        expect.any(Function)
      );
    });

    it('updates video transcripts when select changes', async () => {
      await wrapper.vm.handleVideoTranscriptsChange({ target: { value: 'foreign' } });

      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-students',
        {
          user_ids: [1],
          video_transcript_languages: 'foreign'
        },
        expect.any(Function)
      );
    });

    it('updates audio transcript when checkbox changes', async () => {
      // Call the handler directly with a mock event
      await wrapper.vm.handleAudioTextChange({ target: { checked: true } });

      expect(postToEndpoint).toHaveBeenCalledWith(
        '/update-students',
        {
          user_ids: [1],
          audio_transcript: true
        },
        expect.any(Function)
      );
    });
  });

  describe('props validation', () => {
    it('requires student prop', () => {
      expect(StudentSettingsStudentRow.props.student.required).toBe(true);
    });

    it('requires programId prop', () => {
      expect(StudentSettingsStudentRow.props.programId.required).toBe(true);
    });

    it('requires languageOptions prop', () => {
      expect(StudentSettingsStudentRow.props.languageOptions.required).toBe(true);
    });

    it('requires courseId prop', () => {
      expect(StudentSettingsStudentRow.props.courseId.required).toBe(true);
    });

    it('requires sectionId prop', () => {
      expect(StudentSettingsStudentRow.props.sectionId.required).toBe(true);
    });

    it('requires updateStudentsUrl prop', () => {
      expect(StudentSettingsStudentRow.props.updateStudentsUrl.required).toBe(true);
    });
  });

  describe('API interactions', () => {
    it('shows success toast when video subtitles update succeeds', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true, config: { video_subtitle_languages: 'foreign_and_english' } });
      });

      await wrapper.vm.handleVideoSubtitlesChange({ target: { value: 'foreign_and_english' } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('check');
      expect(alert.innerHTML).toContain('Video subtitles setting successfully applied for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
      expect(wrapper.vm.localStudent.video_subtitle_languages).toBe('foreign_and_english');
    });

    it('shows error toast when video subtitles update fails', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      await wrapper.vm.handleVideoSubtitlesChange({ target: { value: 'foreign_and_english' } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('alert-circle');
      expect(alert.innerHTML).toContain('There was an error updating the video subtitles setting for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
    });

    it('shows success toast when video transcripts update succeeds', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true, config: { video_transcript_languages: 'foreign' } });
      });

      await wrapper.vm.handleVideoTranscriptsChange({ target: { value: 'foreign' } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('check');
      expect(alert.innerHTML).toContain('Video transcripts setting successfully applied for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
      expect(wrapper.vm.localStudent.video_transcript_languages).toBe('foreign');
    });

    it('shows error toast when video transcripts update fails', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      await wrapper.vm.handleVideoTranscriptsChange({ target: { value: 'foreign' } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('alert-circle');
      expect(alert.innerHTML).toContain('There was an error updating the video transcripts setting for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
    });

    it('shows success toast when audio transcript update succeeds', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: true, config: { audio_transcript: true } });
      });

      await wrapper.vm.handleAudioTextChange({ target: { checked: true } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('check');
      expect(alert.innerHTML).toContain('Audio transcript setting successfully applied for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
      expect(wrapper.vm.localStudent.audio_transcript).toBe(true);
    });

    it('shows error toast when audio transcript update fails', async () => {
      postToEndpoint.mockImplementation((url, data, callback) => {
        callback({ success: false });
      });

      await wrapper.vm.handleAudioTextChange({ target: { checked: true } });

      const alert = document.querySelector('[data-testid="student-settings-alert"]');
      expect(alert).toBeTruthy();
      expect(alert.innerHTML).toContain('alert-circle');
      expect(alert.innerHTML).toContain('There was an error updating the audio transcript setting for John Doe');
      expect(getMockToast()).toHaveBeenCalled();
    });
  });
});
