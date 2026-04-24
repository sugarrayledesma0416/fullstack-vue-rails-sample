import { mount } from '@vue/test-utils';
import fetchMock from 'fetch-mock';
import UploadFilesTab from 'features/bulk_resources_upload/components/UploadFilesTab.vue';

const props = {
  presignedUrl: JSON.stringify({
    url: 'https://test-bucket.s3.amazonaws.com/',
    fields: {
      key: 'test-key',
      'Content-Type': 'application/zip'
    }
  }),
  rootUrl: '/activity_revisions_counts/check_availability',
  isCreationInProgress: false
};

beforeEach(() => {
  fetchMock.restore();
  fetchMock.mock('*', { status: 200, body: {} });
});

function getComponent(additionalProps = {}) {
  return mount(UploadFilesTab, {
    props: { ...props, ...additionalProps },
    global: {
      stubs: {
        'sl-dialog': {
          template: '<div><slot /></div>',
          methods: {
            show: () => {}
          }
        },
        'sl-progress-bar': {
          template: '<div class="test-bulk-upload-progress-bar" :value="value" :label="label"></div>',
          props: ['value', 'label'],
          computed: {
            testClass() {
              return (className) => `test-${className}`;
            }
          }
        },
        'sl-spinner': {
          template: '<div class="spinner"></div>'
        }
      }
    }
  });
}

function createFile(name, type) {
  return new File(['test content'], name, { type });
}

function createEvent(file) {
  return {
    target: {
      files: [file],
      value: 'test file'
    }
  };
}

describe('UploadFilesTab', () => {
  describe('ZIP file input', () => {
    it('accepts ZIP files', () => {
      const wrapper = getComponent();
      const zipInput = wrapper.find('.test-bulk-upload-zip-input');

      expect(zipInput.attributes('accept')).toBe('.zip');
    });

    it('shows error message when the user upload a non-zip file', async () => {
      const wrapper = getComponent();
      const file = createFile('test.txt', 'text/plain');
      const event = createEvent(file);

      await wrapper.vm.onZipFileChange(event);

      expect(wrapper.emitted('showEmit')[0][0]).toEqual({
        message: 'Only ZIP files are allowed.',
        type: 'error'
      });
    });

    it('accepts CSV files', () => {
      const wrapper = getComponent();
      const csvInput = wrapper.find('.test-bulk-upload-csv-input');

      expect(csvInput.attributes('accept')).toBe('.csv');
    });

    it('shows error message when the user upload a non-csv file', async () => {
      const wrapper = getComponent();
      const file = createFile('test.txt', 'text/plain');
      const event = createEvent(file);

      await wrapper.vm.onCsvFileChange(event);

      expect(wrapper.emitted('showEmit')[0][0]).toEqual({
        message: 'Only CSV files are allowed.',
        type: 'error'
      });
    });
  });

  describe('Upload Status Table', () => {
    it('shows correct headers on the status table', () => {
      const wrapper = getComponent();
      const table = wrapper.find('.test-bulk-upload-status-table');
      
      expect(table.exists()).toBeTruthy();
      const headers = table.findAll('.test-upload-files-table-header');
      expect(headers[0].text()).toBe('File');
      expect(headers[1].text()).toBe('Status');
      expect(headers[2].text()).toBe('Last update');
    });

    it('shows ZIP and CSV files on the status table', () => {
      const wrapper = getComponent();
      const table = wrapper.find('.test-bulk-upload-status-table');
      
      const rows = table.findAll('.test-upload-files-table-row');
      expect(rows.length).toBe(2);
      
      const zipRow = rows[0];
      const csvRow = rows[1];
      
      expect(zipRow.text()).toBe('ZIP');
      expect(csvRow.text()).toBe('CSV');
    });

    it('shows "Not uploaded" status for ZIP and CSV files', () => {
      const wrapper = getComponent();
      const table = wrapper.find('.test-bulk-upload-status-table');
      
      const zipRow = table.find('.test-upload-files-table-zip-status');
      const csvRow = table.find('.test-upload-files-table-csv-status');
      
      expect(zipRow.text()).toBe('Not uploaded');
      expect(csvRow.text()).toBe('Not uploaded');
    });
  });

  describe('View Last Creation Button', () => {
    it('shows correct text when the user check the uploads disclosure', () => {
      const wrapper = getComponent();
      const button = wrapper.find('.test-view-last-creation-button');
      expect(button.exists()).toBeTruthy();
      expect(button.text()).toBe('View Last Creation');
    });
  });

  describe('Creation In Progress Overlay', () => {
    it('shows overlay when creation is in progress', async () => {
      const wrapper = getComponent({ isCreationInProgress: true });
      
      const overlay = wrapper.find('.blur-overlay');
      expect(overlay.exists()).toBeTruthy();
      expect(overlay.isVisible()).toBeTruthy();
    });

    it('shows correct message when creation is in progress', async () => {
      const wrapper = getComponent({ isCreationInProgress: true });
      
      const overlayMessage = wrapper.find('.overlay-message');
      expect(overlayMessage.text()).toContain('A resource creation process is already in progress.');
      expect(overlayMessage.text()).toContain('Please wait until it completes.');
    });
  });

  describe('Component Structure', () => {
    it('renders with correct structure', () => {
      const wrapper = getComponent();
      
      const details = wrapper.find('sl-details');
      expect(details.exists()).toBeTruthy();
      
      const uploadSection = wrapper.find('.test-uploads-section');
      expect(uploadSection.exists()).toBeTruthy();
      
      const statusSection = wrapper.find('.test-status-section');
      expect(statusSection.exists()).toBeTruthy();
    });

    it('has correct CSS classes', () => {
      const wrapper = getComponent();
      
      const details = wrapper.find('sl-details');
      expect(details.classes()).toContain('uploads-sl-details');
      expect(details.classes()).toContain('common-styles');
    });
  });

  describe('Progress Bar Component', () => {
    it('shows progress bar when loading', async () => {
      const wrapper = getComponent();
      
      expect(wrapper.vm.zipLoading).toBe(false);
      
      wrapper.vm.zipLoading = true;
      expect(wrapper.vm.zipLoading).toBe(true);
      
      await wrapper.vm.$nextTick();
      
      const progressContainer = wrapper.find('.test-progress-bar-section');
      expect(progressContainer.exists()).toBeTruthy();
      
      const progressBar = progressContainer.find('.test-bulk-upload-progress-bar');
      expect(progressBar.exists()).toBeTruthy();
    });

    it('shows correct progress when loading', async () => {
      const wrapper = getComponent();
      
      wrapper.vm.zipLoading = true;
      wrapper.vm.zipUploadProgress = 50;
      
      await wrapper.vm.$nextTick();
      
      const progressBar = wrapper.find('.test-bulk-upload-progress-bar');
      expect(progressBar.exists()).toBeTruthy();
      expect(progressBar.attributes('value')).toBe('50');
    });

    it('does not show progress bar when not loading', () => {
      const wrapper = getComponent();
      
      const progressBar = wrapper.find('.test-bulk-upload-progress-bar');
      expect(progressBar.exists()).toBeFalsy();
    });
  });
}); 
