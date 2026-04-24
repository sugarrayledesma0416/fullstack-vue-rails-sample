import { shallowMount } from '@vue/test-utils';
import Export from 'features/portfolio/Export';

let wrapper;

function getWrapper() {
  return shallowMount(Export, {});
}

describe('Export', () => {
  describe('when showConfirmDialog is false', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('does not display "ConfirmExportDialog" dialog', () => {
      expect(wrapper.findComponent({ name: 'ConfirmExportDialog' }).exists()).toBeFalsy();
    });
  });

  describe('when "Export To Portfolio" button is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const elm = wrapper.get('.test-export-portfolio-btn');
      await elm.trigger('click');
    });

    it('displays "ConfirmExportDialog" dialog', () => {
      expect(wrapper.findComponent({ name: 'ConfirmExportDialog' }).exists()).toBeTruthy();
    });
  });
});
