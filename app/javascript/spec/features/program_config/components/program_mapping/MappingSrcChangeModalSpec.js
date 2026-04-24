import { mount } from '@vue/test-utils';
import MappingSrcChangeModal from
  'features/program_config/components/program_mapping/MappingSrcChangeModal';

const programToProgramMapping = {
  declineSourceProgramChange: jest.fn(),
  confirmSourceProgramChange: jest.fn(),
};

const props = {
  currentDestForSrcId: 1,
  type: 'mapping-change-src',
  title: 'Test Program 1',
  newSrcProg: 'Test Program 2',
  confirmButtonText: 'Set Source',
  currentDestForSrcName: '',
  mappingSrcProgramId: 3,
  srcProgId: 4,
};

const getWrapper = () => {
  return mount(MappingSrcChangeModal, {
    global: {
      provide: {
        programId: 5,
        programTitle: 'Test Program 1',
        programToProgramMapping,
      },
    },
    props,
  });
};

describe('MappingSrcChangeModal', () => {
  let wrapper;

  describe('when type is "mapping-change-src"', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "Test Program 1 will be set as the new source."', () => {
      expect(
        wrapper.get('.test-src-change-modal').text()
      ).toContain('Test Program 1 will be set as the new source.');
    });
  });

  describe('when type is "mapping-already-in-use"', () => {
    beforeEach(() => {
      props.type = 'mapping-already-in-use';
      props.currentDestForSrcName = 'Test Program 3';
      wrapper = getWrapper();
    });

    it('displays "Test Program 2 is already used as a source"', () => {
      expect(
        wrapper.get('.test-src-change-modal').text()
      ).toContain('Test Program 2 is already used as a source');
    });

    it('displays "Would you like to delete the existing mapping between ' +
       'Test Program 2 and Test Program 3?"', () => {
      expect(
        wrapper.get('.test-src-change-modal').text()
      ).toContain('Would you like to delete the existing mapping between ' +
      'Test Program 2 and Test Program 3?');
    });
  });

  describe('when type is "mapping-change-and-in-use"', () => {
    beforeEach(() => {
      props.type = 'mapping-change-and-in-use';
      props.currentDestForSrcName = 'Test Program 3';
      wrapper = getWrapper();
    });

    it('displays "Test Program 2 is already used as a source"', () => {
      expect(
        wrapper.get('.test-src-change-modal').text()
      ).toContain('Test Program 2 is already used as a source');
    });

    it('displays "Would you like to delete the existing mapping between ' +
       'Test Program 2 and Test Program 3, and set it as a new source?"', () => {
      expect(
        wrapper.get('.test-src-change-modal').text()
      ).toContain('Would you like to delete the existing mapping between ' +
      'Test Program 2 and Test Program 3, and set it as a new source?');
    });
  });

  describe('when cancel button is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-modal-cancel').trigger('click');
    });

    it('declines the source program change', () => {
      expect(programToProgramMapping.declineSourceProgramChange).toHaveBeenCalled();
    });

    it('emits close event', () => {
      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when confirm button is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-modal-confirm').trigger('click');
    });

    it('confirms the source program change', () => {
      expect(programToProgramMapping.confirmSourceProgramChange).toHaveBeenCalledWith(
        props.srcProgId, props.currentDestForSrcId
      );
    });

    it('emits close event', () => {
      expect(wrapper.emitted().close).toBeTruthy();
    });
  });
});
