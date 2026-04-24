import { mount } from '@vue/test-utils';
import ConfirmExportDialog from 'features/portfolio/ConfirmExportDialog';

jest.mock('!!raw-loader!MusicAssets/images/music/icons/close.svg', () => jest.fn());

let wrapper;

function getWrapper() {
  return mount(ConfirmExportDialog, {});
}

describe('ConfirmExportDialog', () => {
  beforeEach(() => wrapper = getWrapper());

  it('displays BasicDialog component', () => {
    expect(wrapper.find('.test-dialog-box').exists()).toBeTruthy();
  });

  it('emits "close" event on cancel button click', async () => {
    await wrapper.get('.test-cancel-btn').trigger('click');
    expect(wrapper.emitted().close).toBeTruthy();
  });

  it('emits "confirm" event on OK button click', async () => {
    await wrapper.get('.test-confirm-btn').trigger('click');
    expect(wrapper.emitted().confirm).toBeTruthy();
  });
});
