import { mount } from '@vue/test-utils';
import ModalComponent from 'features/modal/ModalComponent';

describe('ModalComponent', () => {
  let wrapper;

  const propsData = {
    title: 'Test title',
    isConfirmationDialog: false,
    isPlainInformationDialog: false,
  };

  function getWrapper(propsData) {
    return mount(
      ModalComponent, {
        global: {
          stubs: { VhlPanel: true },
        },
        propsData,
      });
  }

  describe('when mounted.', () => {
    describe('when isConfirmationDialog prop values are false.', () => {
      beforeEach(() => {
        wrapper = getWrapper(propsData);
      });

      it('shows close button on dialog', () => {
        expect(wrapper.get('.test-modal-close-button').exists()).toBeTruthy();
      });

      it('displays panel component', () => {
        expect(wrapper.findComponent({ name: 'VhlPanel' }).exists()).toBeTruthy();
      });
    });

    describe('when isConfirmationDialog prop value is true.', () => {
      beforeEach(() => {
        const props = { ...propsData, ...{ isConfirmationDialog: true }};
        wrapper = getWrapper(props);
      });

      it('does not show close button on dialog', () => {
        expect(wrapper.find('.test-modal-close-button').exists()).toBeFalsy();
      });

      it('displays panel component', () => {
        expect(wrapper.findComponent({ name: 'VhlPanel' }).exists()).toBeTruthy();
      });
    });
  });
});
