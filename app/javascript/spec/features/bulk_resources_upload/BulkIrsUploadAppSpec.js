import { mount } from '@vue/test-utils';
import fetchMock from 'fetch-mock';
import BulkIrsUploadApp from 'features/bulk_resources_upload/BulkIrsUploadApp.vue'

const props = {
  presignedUrl: '/activity_revisions_counts/download_activity_revisions_csv',
  rootUrl: '/activity_revisions_counts/check_availability'
};

beforeEach(() => {
  fetchMock.restore();
  fetchMock.mock('*', { status: 200, body: {} });
});

function getComponent(){
  return mount(BulkIrsUploadApp,
      {
      props: props
    });
}

describe('BulkIrsUploadApp', () => {
  it('upload files tab component is available', () => {
    const wrapper = getComponent();
    expect(wrapper.find('.test-upload-files-tab').exists()).toBeTruthy();
    expect(wrapper.find('.test-upload-files-tab').isVisible()).toBeTruthy();
  });

  it('validation tab component is available', () => {
    const wrapper = getComponent();
    expect(wrapper.find('.test-validation-tab').exists()).toBeTruthy();
    expect(wrapper.find('.test-validation-tab').isVisible()).toBeTruthy();
  });

  it('creation tab component is available', () => {
    const wrapper = getComponent();
    expect(wrapper.find('.test-creation-tab').exists()).toBeTruthy();
    expect(wrapper.find('.test-creation-tab').isVisible()).toBeTruthy();
  });

  it('delete confirmation modal exist but is not visible', () => {
    const wrapper = getComponent();
    const dialog = wrapper.find('sl-dialog.test-delete-confirmation-modal');
    expect(dialog.exists()).toBeTruthy();
    expect(dialog.attributes('open')).toBeUndefined();
  });
});
