import { mount } from '@vue/test-utils';
import StudentSettings from '../../../src/features/student_settings/StudentSettings.vue';
import StudentSettingsStudentRow from '../../../src/features/student_settings/StudentSettingsStudentRow.vue';
import ExampleDialog from '../../../src/features/student_settings/ExampleDialog.vue';
import SectionDefaultsDialog from '../../../src/features/student_settings/SectionDefaultsDialog.vue';
import EmptyStudentState from '../../../src/features/student_settings/EmptyStudentState.vue';
import BulkSettingsDropdowns from '../../../src/features/student_settings/BulkSettingsDropdowns.vue';

describe('StudentSettings', () => {
  let wrapper;
  const defaultProps = {
    backToLink: '/roster',
    courseId: 456,
    programId: 123,
    programLanguageName: 'Spanish',
    programLanguageCode: 'es',
    rostering: false,
    rosterUrl: '/roster',
    sectionName: 'Test Section',
    sectionId: 789,
    students: [
      {
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        video_subtitle_languages: 'foreign',
        video_transcript_languages: 'none',
        audio_transcript: false
      }
    ],
    updateStudentsUrl: '/update-students',
    updateSectionDefaultsUrl: '/update-defaults',
    sectionVideoTranscriptLanguages: 'none',
    sectionVideoSubtitleLanguages: 'foreign',
    sectionAudioTranscript: false,
    aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' },
    aiInputModeValues: ['speech', 'text'],
    sectionInputMode: 'speech',
    hasAiVirtualChatActivities: false
  };

  beforeEach(() => {
    // Mock document.querySelector for dialog operations
    vi.spyOn(document, 'querySelector').mockImplementation((selector) => ({
      show: vi.fn(),
      hide: vi.fn()
    }));

    wrapper = mount(StudentSettings, {
      props: defaultProps,
      global: {
        components: {
          StudentSettingsStudentRow,
          ExampleDialog,
          SectionDefaultsDialog,
          EmptyStudentState,
          BulkSettingsDropdowns
        }
      }
    });
  });

  describe('rendering', () => {
    it('renders the component title', () => {
      expect(wrapper.find('h1.c-heading-v3--2').text()).toBe('Student Interaction Settings');
    });

    it('renders the section name', () => {
      expect(wrapper.find('h4.c-heading-v3--4').text()).toBe('Test Section');
    });

    it('renders the manage default settings link', () => {
      const link = wrapper.find('a[role="button"]');
      expect(link.text()).toBe('Manage default settings');
      expect(link.attributes('href')).toBe('javascript:void(0)');
    });
  });

  describe('backToLabel', () => {
    it('renders a back link with the correct href', () => {
      const link = wrapper.find('[data-testid="back-to-link"]');
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('/roster');
      expect(link.classes()).toContain('c-button-v3');
      expect(link.classes()).toContain('c-button-v3--quaternary');
    });

    it('shows "Back to Roster" when backToLink includes "roster"', () => {
      const wrapper = mount(StudentSettings, {
        props: {
          ...defaultProps,
          backToLink: '/roster/123'
        },
        global: {
          components: {
            StudentSettingsStudentRow,
            ExampleDialog,
            SectionDefaultsDialog,
            EmptyStudentState,
            BulkSettingsDropdowns
          }
        }
      });
      expect(wrapper.find('[data-testid="back-to-link"]').text()).toBe('Back to Roster');
    });

    it('shows "Back to Dashboard" when backToLink includes "grading"', () => {
      const wrapper = mount(StudentSettings, {
        props: {
          ...defaultProps,
          backToLink: '/grading/123'
        },
        global: {
          components: {
            StudentSettingsStudentRow,
            ExampleDialog,
            SectionDefaultsDialog,
            EmptyStudentState,
            BulkSettingsDropdowns
          }
        }
      });
      expect(wrapper.find('[data-testid="back-to-link"]').text()).toBe('Back to Dashboard');
    });

    it('shows "Back" for any other backToLink', () => {
      const wrapper = mount(StudentSettings, {
        props: {
          ...defaultProps,
          backToLink: '/some/other/path'
        },
        global: {
          components: {
            StudentSettingsStudentRow,
            ExampleDialog,
            SectionDefaultsDialog,
            EmptyStudentState,
            BulkSettingsDropdowns
          }
        }
      });
      expect(wrapper.find('[data-testid="back-to-link"]').text()).toBe('Back');
    });
  });

  describe('student table', () => {
    it('renders the table when students exist', () => {
      expect(wrapper.find('table').exists()).toBe(true);
    });

    it('renders BulkSettingsDropdowns when students exist', () => {
      expect(wrapper.findComponent({ name: 'BulkSettingsDropdowns' }).exists()).toBe(true);
    });

    it('does not render BulkSettingsDropdowns when no students exist', async () => {
      await wrapper.setProps({ students: [] });
      expect(wrapper.findComponent({ name: 'BulkSettingsDropdowns' }).exists()).toBe(false);
    });

    it('renders StudentSettingsStudentRow for each student', () => {
      expect(wrapper.findAllComponents(StudentSettingsStudentRow)).toHaveLength(1);
    });

    it('renders correct table headers', () => {
      const headers = wrapper.findAll('th');
      expect(headers).toHaveLength(4);
      expect(headers[0].text()).toContain('All Students');
      expect(headers[1].text()).toContain('Video Subtitles and Closed Captions (CC)');
      expect(headers[2].text()).toContain('Video Transcripts');
      expect(headers[3].text()).toContain('Audio Transcripts');
    });
  });

  describe('example dialogs', () => {
    it('renders both example dialogs', () => {
      expect(wrapper.findAllComponents(ExampleDialog)).toHaveLength(2);
    });

    it('renders video subtitles example dialog with correct props', () => {
      const dialog = wrapper.findAllComponents(ExampleDialog)[0];
      expect(dialog.props('title')).toBe('Video Subtitles & CC Example');
      expect(dialog.props('dialogClass')).toBe('video-subtitles-example-dialog');
    });

    it('renders video transcript example dialog with correct props', () => {
      const dialog = wrapper.findAllComponents(ExampleDialog)[1];
      expect(dialog.props('title')).toBe('Video Transcript Example');
      expect(dialog.props('dialogClass')).toBe('video-transcript-example-dialog');
    });

    it('opens video subtitles example dialog when clicking example link', async () => {
      const link = wrapper.find('[data-testid="video-subtitles-example-link"]');
      await link.trigger('click');
      expect(document.querySelector).toHaveBeenCalledWith('.video-subtitles-example-dialog');
    });

    it('opens video transcript example dialog when clicking example link', async () => {
      const link = wrapper.find('[data-testid="video-transcript-example-link"]');
      await link.trigger('click');
      expect(document.querySelector).toHaveBeenCalledWith('.video-transcript-example-dialog');
    });
  });

  describe('section defaults dialog', () => {
    it('renders the section defaults dialog', () => {
      expect(wrapper.findComponent(SectionDefaultsDialog).exists()).toBe(true);
    });

    it('passes correct props to section defaults dialog', () => {
      const dialog = wrapper.findComponent(SectionDefaultsDialog);
      expect(dialog.props('programLanguageName')).toBe('Spanish');
      expect(dialog.props('sectionVideoTranscriptLanguages')).toBe('none');
      expect(dialog.props('sectionVideoSubtitleLanguages')).toBe('foreign');
      expect(dialog.props('sectionAudioTranscript')).toBe(false);
      expect(dialog.props('updateSectionDefaultsUrl')).toBe('/update-defaults');
    });

    it('opens section defaults dialog when clicking manage default settings link', async () => {
      const link = wrapper.find('[data-testid="section-defaults-link"]');
      await link.trigger('click');
      expect(document.querySelector).toHaveBeenCalledWith('.section-default-settings-dialog');
    });

    it('updates students when section defaults dialog emits update', async () => {
      const newStudents = [{ id: 2, firstName: 'Jane', lastName: 'Smith' }];
      await wrapper.findComponent(SectionDefaultsDialog).vm.$emit('update:students', newStudents);
      expect(wrapper.vm.studentsRef).toEqual(newStudents);
    });

    it('updates section settings when section defaults dialog emits update', async () => {
      const newSettings = {
        sectionVideoTranscriptLanguages: 'foreign',
        sectionVideoSubtitleLanguages: 'foreign_and_english',
        sectionAudioTranscript: true
      };

      await wrapper.findComponent(SectionDefaultsDialog).vm.$emit('update:sectionSettings', newSettings);

      expect(wrapper.vm.sectionVideoTranscriptLanguagesRef).toBe('foreign');
      expect(wrapper.vm.sectionVideoSubtitleLanguagesRef).toBe('foreign_and_english');
      expect(wrapper.vm.sectionAudioTranscriptRef).toBe(true);
    });

    it('passes updated section settings back to dialog after update', async () => {
      const newSettings = {
        sectionVideoTranscriptLanguages: 'foreign',
        sectionVideoSubtitleLanguages: 'foreign_and_english',
        sectionAudioTranscript: true
      };

      await wrapper.findComponent(SectionDefaultsDialog).vm.$emit('update:sectionSettings', newSettings);

      const dialog = wrapper.findComponent(SectionDefaultsDialog);
      expect(dialog.props('sectionVideoTranscriptLanguages')).toBe('foreign');
      expect(dialog.props('sectionVideoSubtitleLanguages')).toBe('foreign_and_english');
      expect(dialog.props('sectionAudioTranscript')).toBe(true);
    });
  });

  describe('empty state', () => {
    beforeEach(() => {
      wrapper = mount(StudentSettings, {
        props: {
          ...defaultProps,
          students: []
        },
        global: {
          components: {
            StudentSettingsStudentRow,
            ExampleDialog,
            SectionDefaultsDialog,
            EmptyStudentState,
            BulkSettingsDropdowns
          }
        }
      });
    });

    it('renders EmptyStudentState when no students exist', () => {
      expect(wrapper.findComponent(EmptyStudentState).exists()).toBe(true);
    });

    it('passes correct props to EmptyStudentState', () => {
      const emptyState = wrapper.findComponent(EmptyStudentState);
      expect(emptyState.props('rostering')).toBe(false);
      expect(emptyState.props('rosterUrl')).toBe('/roster');
    });

    it('shows roster link when not using LMS rostering', () => {
      const emptyState = wrapper.findComponent(EmptyStudentState);
      expect(emptyState.text()).toContain('Add students in the Roster');
    });

    it('shows LMS sync message when using rostering', async () => {
      await wrapper.setProps({ rostering: true });
      const emptyState = wrapper.findComponent(EmptyStudentState);
      expect(emptyState.text()).toContain('Students will display here once they sync.');
    });
  });

  describe('student selection', () => {
    it('updates studentsRef when props.students changes', async () => {
      const newStudents = [
        { id: 3, firstName: 'Alice', lastName: 'Smith' },
        { id: 4, firstName: 'Bob', lastName: 'Jones' }
      ];
      await wrapper.setProps({ students: newStudents });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.studentsRef).toEqual(newStudents);
    });

    it('clears selectedStudentIds when students change', async () => {
      // First select a student
      const studentRow = wrapper.findComponent(StudentSettingsStudentRow);
      await studentRow.vm.$emit('selection-change', { userId: 1, selected: true });
      expect(wrapper.vm.selectedStudentIds).toEqual([1]);

      // Then change the students list
      const newStudents = [
        { id: 3, firstName: 'Alice', lastName: 'Smith' },
        { id: 4, firstName: 'Bob', lastName: 'Jones' }
      ];
      await wrapper.setProps({ students: newStudents });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedStudentIds).toEqual([]);
    });

    it('handles empty students array correctly', async () => {
      await wrapper.setProps({ students: [] });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.studentsRef).toEqual([]);
      expect(wrapper.vm.selectedStudentIds).toEqual([]);
      expect(wrapper.vm.allStudentsSelected).toBe(true);
      expect(wrapper.vm.isIndeterminate).toBe(false);
    });

    it('handles individual student selection', async () => {
      const studentRow = wrapper.findComponent(StudentSettingsStudentRow);
      await studentRow.vm.$emit('selection-change', { userId: 1, selected: true });
      expect(wrapper.vm.selectedStudentIds).toEqual([1]);

      await studentRow.vm.$emit('selection-change', { userId: 1, selected: false });
      expect(wrapper.vm.selectedStudentIds).toEqual([]);
    });

    it('handles select all checkbox', async () => {
      const checkbox = wrapper.find('[data-testid="select-all-students"]');

      checkbox.element.checked = true;
      checkbox.trigger('sl-change');
      await wrapper.vm.$nextTick();
      // Expectation based on a vue binding changing in the sl-change handler
      expect(wrapper.vm.selectedStudentIds).toEqual([1]);
      expect(wrapper.vm.allStudentsSelected).toBe(true);
      expect(wrapper.vm.isIndeterminate).toBe(false);

      // Deselect all
      checkbox.element.checked = false;
      checkbox.trigger('sl-change');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedStudentIds).toEqual([]);
      expect(wrapper.vm.allStudentsSelected).toBe(false);
      expect(wrapper.vm.isIndeterminate).toBe(false);
    });

    it('shows indeterminate state when some students are selected', async () => {
      // Add another student to test with
      await wrapper.setProps({
        students: [
          ...defaultProps.students,
          {
            id: 2,
            firstName: 'Jane',
            lastName: 'Smith',
            video_subtitle_languages: 'foreign',
            video_transcript_languages: 'none',
            audio_transcript: false
          }
        ]
      });

      const studentRow = wrapper.findComponent(StudentSettingsStudentRow);
      await studentRow.vm.$emit('selection-change', { userId: 1, selected: true });

      expect(wrapper.vm.selectedStudentIds).toEqual([1]);
      expect(wrapper.vm.allStudentsSelected).toBe(false);
      expect(wrapper.vm.isIndeterminate).toBe(true);
    });

    it('handles multiple student selections correctly', async () => {
      // Add another student to test with
      await wrapper.setProps({
        students: [
          ...defaultProps.students,
          {
            id: 2,
            firstName: 'Jane',
            lastName: 'Smith',
            video_subtitle_languages: 'foreign',
            video_transcript_languages: 'none',
            audio_transcript: false
          }
        ]
      });
      await wrapper.vm.$nextTick();

      const studentRows = wrapper.findAllComponents(StudentSettingsStudentRow);

      expect(wrapper.vm.selectedStudentIds).toEqual([]);
      expect(wrapper.vm.allStudentsSelected).toBe(false);
      expect(wrapper.vm.isIndeterminate).toBe(false);

      // Select first student
      await studentRows[0].vm.$emit('selection-change', { userId: 1, selected: true });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedStudentIds).toEqual([1]);
      expect(wrapper.vm.allStudentsSelected).toBe(false);
      expect(wrapper.vm.isIndeterminate).toBe(true);

      // Select second student
      await studentRows[1].vm.$emit('selection-change', { userId: 2, selected: true });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedStudentIds).toEqual([1, 2]);
      expect(wrapper.vm.allStudentsSelected).toBe(true);
      expect(wrapper.vm.isIndeterminate).toBe(false);

      // Deselect first student
      await studentRows[0].vm.$emit('selection-change', { userId: 1, selected: false });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedStudentIds).toEqual([2]);
      expect(wrapper.vm.allStudentsSelected).toBe(false);
      expect(wrapper.vm.isIndeterminate).toBe(true);
    });
  });

  describe('Input Mode column', () => {
    it('renders Input Mode column if hasAiVirtualChatActivities is true', async () => {
      await wrapper.setProps({ hasAiVirtualChatActivities: true, aiInputModes: { 'speech': 'Student Audio Response', 'text': 'Student Text Response' }, sectionInputMode: 'speech' });
      const headers = wrapper.findAll('th');
      const inputModeHeader = headers.find(th => th.text().includes('AI Interaction Mode'));
      expect(inputModeHeader).toBeTruthy();
    });

    it('does not render Input Mode column if hasAiVirtualChatActivities is false', async () => {
      await wrapper.setProps({ hasAiVirtualChatActivities: false });
      const headers = wrapper.findAll('th');
      const inputModeHeader = headers.find(th => th.text().includes('AI Interaction Mode'));
      expect(inputModeHeader).toBeFalsy();
    });
  });

  describe('SectionDefaultsDialog integration', () => {
    it('passes aiInputModes, sectionInputMode, and hasAiVirtualChatActivities props to SectionDefaultsDialog', () => {
      const dialog = wrapper.findComponent(SectionDefaultsDialog);
      expect(dialog.props('aiInputModes')).toEqual(wrapper.vm.aiInputModesRef);
      expect(dialog.props('sectionInputMode')).toBe(wrapper.vm.sectionInputModeRef);
      expect(dialog.props('hasAiVirtualChatActivities')).toBe(wrapper.props('hasAiVirtualChatActivities'));
    });

    it('updates sectionInputModeRef when update:section-settings is emitted', async () => {
      const dialog = wrapper.findComponent(SectionDefaultsDialog);
      await dialog.vm.$emit('update:sectionSettings', { sectionInputMode: 'text' });
      expect(wrapper.vm.sectionInputModeRef).toBe('text');
      expect(dialog.props('sectionInputMode')).toBe('text');
    });
  });
  
  describe('language options', () => {
    it('includes all options when program language is not English', () => {
      const options = wrapper.vm.languageOptions;
      expect(options).toHaveLength(3);
      expect(options).toEqual([
        { value: 'none', label: 'Off' },
        { value: 'foreign', label: 'Spanish' },
        { value: 'foreign_and_english', label: 'Spanish and English' }
      ]);
    });

    it('excludes foreign_and_english option when program language is English', async () => {
      await wrapper.setProps({
        programLanguageCode: 'en',
        programLanguageName: 'English'
      });
      const options = wrapper.vm.languageOptions;
      expect(options).toHaveLength(2);
      expect(options).toEqual([
        { value: 'none', label: 'Off' },
        { value: 'foreign', label: 'English' }
      ]);
    });

    it('passes languageOptions to StudentSettingsStudentRow', () => {
      const studentRow = wrapper.findComponent(StudentSettingsStudentRow);
      expect(studentRow.props('languageOptions')).toEqual([
        { value: 'none', label: 'Off' },
        { value: 'foreign', label: 'Spanish' },
        { value: 'foreign_and_english', label: 'Spanish and English' }
      ]);
    });

    it('updates StudentSettingsStudentRow languageOptions when programLanguageCode changes', async () => {
      await wrapper.setProps({
        programLanguageCode: 'en',
        programLanguageName: 'English'
      });
      const studentRow = wrapper.findComponent(StudentSettingsStudentRow);
      expect(studentRow.props('languageOptions')).toEqual([
        { value: 'none', label: 'Off' },
        { value: 'foreign', label: 'English' }
      ]);
    });
  });

  describe('props validation', () => {
    it('requires all necessary props', () => {
      const requiredProps = [
        'backToLink',
        'courseId',
        'programId',
        'programLanguageName',
        'programLanguageCode',
        'rostering',
        'rosterUrl',
        'sectionName',
        'sectionId',
        'students',
        'updateStudentsUrl',
        'updateSectionDefaultsUrl',
        'sectionVideoTranscriptLanguages',
        'sectionVideoSubtitleLanguages',
        'sectionAudioTranscript'
      ];

      requiredProps.forEach(prop => {
        expect(StudentSettings.props[prop].required).toBe(true);
      });
    });
  });
});
