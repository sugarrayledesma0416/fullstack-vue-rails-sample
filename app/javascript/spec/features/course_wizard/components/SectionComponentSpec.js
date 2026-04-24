import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import SectionComponent from 'features/course_wizard/components/SectionComponent';

jest.mock('features/course_wizard/services/course_options_http.js', () => {
  return jest.fn().mockImplementation(() => {
    return { settings: [] };
  });
});

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  vol: true,
  isEnterprise: false
};

const course = new Course();
const courseDataStore = new CourseDataStore(
  course,
  config.instAdmin,
  config.isEnterprise,
  config.programId,
  config.schoolId
);

const getWrapper = () => {
  return mount(SectionComponent, {
    global: {
      provide: {
        courseDataStore,
        config,
      },
    },
  });
};

describe('SectionComponent', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays Section dropdown with value "1"', () => {
      expect(wrapper.get('.test-section-dropdown').element.value).toBe('1');
    });
  });

  describe('when section dropdown value is changed', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('changes the count of section text fields to the dropdown value ', async () => {
      let inputs;
      const select = wrapper.get('.test-section-dropdown');
      const options = select.findAll('option');

      options[1].element.selected = true;
      await select.trigger('change');
      inputs = wrapper.findAll('.test-section-name-input');
      expect(inputs.length).toBe(2);

      options[2].element.selected = true;
      await select.trigger('change');
      inputs = wrapper.findAll('.test-section-name-input');
      expect(inputs.length).toBe(3);
    });
  });

  describe('when section name is greater than 75 characters', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const input = wrapper.get('.test-section-name-input');
      await input.setValue('11111111112222222222333333333344444444445555555555666666666677777777778888888888');
    });

    it('displays error message "Your section name cannot be longer than 75 characters." ', () => {
      expect(wrapper.get('.test-section-name-validation-error').text()).toBe(
        'Your section name cannot be longer than 75 characters.');
    });
  });

  describe('when section name is blank', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const input = wrapper.get('.test-section-name-input');
      await input.setValue('some value');
      await input.setValue('');
    });

    it('displays error message "Section name is required." ', () => {
      expect(wrapper.get('.test-section-name-validation-error').text()).toBe(
        'Section name is required.');
    });
  });
});
