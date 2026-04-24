import { shallowMount } from '@vue/test-utils';
import ProgramMappingComponent from
  'features/program_config/components/program_mapping/ProgramMappingComponent';

const getWrapper = () => {
  return shallowMount(ProgramMappingComponent, {
    global: {
      provide: {
        programId: 1,
      },
    },
    props: {
      programMappingData: {
        mapping_src_prog_id: 2,
        mapping_src_lessons_strands: [
          { name: 'Lesson 1' },
          { name: 'Lesson 2' },
        ],
        mapping_src_programs_array: [],
      },
    },
  });
};

describe('ProgramMappingComponent', () => {
  let wrapper;

  describe('on mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "MapSourceProgram" component', () => {
      expect(wrapper.findComponent({ name: 'MapSourceProgram' }).exists()).toBeTruthy();
    });

    it('displays "MappingTable" component', () => {
      expect(wrapper.findAllComponents({ name: 'MappingTable' }).length).toBe(2);
    });
  });
});
