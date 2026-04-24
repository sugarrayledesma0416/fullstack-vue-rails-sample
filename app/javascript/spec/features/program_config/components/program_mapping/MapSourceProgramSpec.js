import { mount } from '@vue/test-utils';
import MapSourceProgram from 'features/program_config/components/program_mapping/MapSourceProgram';

let programToProgramMapping;

const props = {
  canMap: false,
  mappingSrcProgramId: '1',
  mappingSrcPrograms: [
    ['Program 1', 1],
    ['Program 1', 2],
  ],
  sourceChanged: false,
};
const getWrapper = () => {
  return mount(MapSourceProgram, {
    global: {
      provide: {
        programId: 1,
        programToProgramMapping,
        programTitle: 'Test Program',
      },
    },
    props,
  });
};

describe('MapSourceProgram', () => {
  let wrapper;

  describe('on mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays all the programs in select box', () => {
      const options = wrapper.get('.test-mapping-src-program').findAll('option');
      props.mappingSrcPrograms.forEach((program, i) => {
        const option = options[i+1];
        expect(parseInt(option.attributes('value'))).toEqual(program[1]);
        expect(option.text()).toEqual(program[0]);
      });
    });

    it("displays Lesson's name", () => {
      expect(wrapper.get('.test-program-title').text()).toContain('Test Program');
    });
  });

  describe('When lessons list is populated, map to destination is allowed', () => {
    beforeEach(() => {
      props.canMap = true;
      wrapper = getWrapper();
    });

    it("displays enabled 'Map to Destination' button", () => {
      expect(wrapper.get('.test-map-to-destination').element).not.toBeDisabled();
    });
  });

  describe('When lessons list is empty, map to destination is not allowed', () => {
    beforeEach(() => {
      props.canMap = false;
      wrapper = getWrapper();
    });

    it('displays disabled "Map to Destination" button"', () => {
      expect(wrapper.get('.test-map-to-destination').element).toBeDisabled();
    });
  });

  describe('When no mapping exists for the current destination', () => {
    beforeEach(async () => {
      props.canMap = true;
      props.mappingSrcProgramId = '';
      programToProgramMapping = {
        mapAutomatically: jest.fn(),
      };
      wrapper = getWrapper();
      await wrapper.get('.test-map-to-destination').trigger('click');
    });

    it('maps source to destination on "Map to Destination" click "', () => {
      expect(programToProgramMapping.mapAutomatically).toHaveBeenCalled();
    });

    it('does not display "MapAutomatically" modal', () => {
      expect(wrapper.findComponent({ name: 'MapAutomatically' }).exists()).toBeFalsy();
    });
  });

  describe('When mapping exists for the current destination', () => {
    beforeEach(async () => {
      props.canMap = true;
      props.mappingSrcProgramId = '1';
      programToProgramMapping = {
        mapAutomatically: jest.fn(),
      };
      wrapper = getWrapper();
      await wrapper.get('.test-map-to-destination').trigger('click');
    });

    it('does not maps source to destination on "Map to Destination" click "', async () => {
      expect(programToProgramMapping.mapAutomatically).not.toHaveBeenCalled();
    });

    it('displays "MapAutomatically" modal', async () => {
      expect(wrapper.findComponent({ name: 'MapAutomatically' }).exists()).toBeTruthy();
    });
  });

  describe('When source program is changed', () => {
    beforeEach(async () => {
      programToProgramMapping = {
        onSrcProgramChange: jest.fn(),
      };
      wrapper = getWrapper();
      const select = wrapper.find('.test-mapping-src-program');
      select.element.value = '2';
      await select.trigger('change');
    });

    it('reset the lessons and strands by calling "onSrcProgramChange" handler', async () => {
      expect(programToProgramMapping.onSrcProgramChange).toHaveBeenCalled();
    });
  });
});
