import { mount } from '@vue/test-utils';
import GradeRange from 'features/program_config/components/GradeRange';

const propsWithInitialValues = {
  minGradeStored: '',
  maxGradeStored: '',
  standardDataStore: {
    supportedStandardSetIds: [],
  },
};

const propsWithDbStoredValues = {
  minGradeStored: 'K',
  maxGradeStored: '5',
  standardDataStore: {
    supportedStandardSetIds: [1, 2],
  },
};

const getWrapper = (props) => mount(GradeRange, {
  props: props,
});

describe('Grade Level Range in Program Config', () => {
  let wrapper;

  it('displays the whole Grade Range component', () => {
    wrapper = getWrapper(propsWithInitialValues);
    expect(wrapper.get('[data-test="grade-range-element"]').exists()).toBeTruthy();
  });

  describe('When no standard set is selected', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsWithInitialValues);
    });

    it('has min range dropdown disabled', () => {
      const minGradeEl = wrapper.find('#min-grade-range');
      expect(minGradeEl.element.disabled).toBe(true);
    });

    it('has max range dropdown disabled', () => {
      const maxGradeEl = wrapper.find('#max-grade-range');
      expect(maxGradeEl.element.disabled).toBe(true);
    });
  });

  describe('When at least one standard set is selected', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsWithDbStoredValues);
    });

    it('has min range dropdown enabled', () => {
      const minGradeEl = wrapper.find('#min-grade-range');
      expect(minGradeEl.element.disabled).toBe(false);
    });

    it('has K as selected value in the min grade dropdown', () => {
      const minGradeEl = wrapper.find('#min-grade-range');
      expect(minGradeEl.element.value).toBe(propsWithDbStoredValues.minGradeStored);
    });

    it('has max range dropdown enabled', () => {
      const maxGradeEl = wrapper.find('#max-grade-range');
      expect(maxGradeEl.element.disabled).toBe(false);
    });

    it('has 5 as selected value in the max grade dropdown', () => {
      const maxGradeEl = wrapper.find('#max-grade-range');
      expect(maxGradeEl.element.value).toBe(propsWithDbStoredValues.maxGradeStored);
    });
  });

  describe('When an option is selected in the Min Grade dropdown', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsWithDbStoredValues);
    });

    it('creates valid options for the Max Grade dropdown', async () => {
      const validOptionValues = ['8', '9', '10', '11', '12'];
      const minGradeEl = wrapper.find('#min-grade-range');
      await minGradeEl.setValue('8');
      const maxGradeOptions = wrapper.find('#max-grade-range').findAll('option');
      const maxGradeOptionValues = maxGradeOptions.map((option) => {
        return option.element.value;
      });
      // We removed the empty string representing the option 'Please select an option'
      // becuase this is disabled and we can not choose it
      maxGradeOptionValues.shift();

      expect(maxGradeOptionValues).toEqual(validOptionValues);
    });
  });

  describe('When an option is selected first in the Max Grade dropdown', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsWithDbStoredValues);
    });

    it('shows all the options for the Min Grade dropdown', async () => {
      const validOptionValues = [
        'PK', 'K', '1', '2',
        '3', '4', '5', '6',
        '7', '8', '9', '10',
        '11', '12',
      ];
      const maxGradeEl = wrapper.find('#max-grade-range');
      await maxGradeEl.setValue('8');
      const minGradeEl = wrapper.find('#min-grade-range');
      const minGradeOptions = minGradeEl.findAll('option');
      const minGradeOptionValues = minGradeOptions.map((option) => {
        return option.element.value;
      });
      // We removed the empty string representing the option 'Please select an option'
      // becuase this is disabled and we can not choose it
      minGradeOptionValues.shift();

      expect(minGradeOptionValues).toEqual(validOptionValues);

      // If we select a value in the min grade range now, the max grade range will
      // generate a valid set of options
      await minGradeEl.setValue('3');
      const maxGradeOptions = maxGradeEl.findAll('option');
      const maxGradeOptionValues = maxGradeOptions.map((option) => {
        return option.element.value;
      });

      maxGradeOptionValues.shift();

      expect(maxGradeOptionValues).toEqual(['3', '4', '5', '6', '7', '8', '9', '10', '11', '12']);
    });
  });
});
