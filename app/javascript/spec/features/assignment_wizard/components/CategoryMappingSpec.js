import { mount } from '@vue/test-utils';
import CategoryMapping from 'features/assignment_wizard/components/CategoryMapping';

const categoryMappingList = [
  'Credit',
  'Graded',
  'Quizzes',
  'Tests',
];

const courseInfoCategories = [
  { id: 44, name: 'Credit' },
  { id: 45, name: 'Graded' },
  { id: 46, name: 'Quizzes' },
  { id: 47, name: 'Tests' },
];

const categories = {
  Credit: { id: 44, name: 'Credit' },
  Graded: { id: 45, name: 'Graded' },
  Quizzes: { id: 46, name: 'Quizzes' },
  Tests: { id: 47, name: 'Tests' },
};
let usingPredefinedTrack = true;

const getWrapper = () => {
  return mount(CategoryMapping, {
    props: {
      categoryMappingList,
      categories,
      courseInfoCategories,
      usingPredefinedTrack,
    },
  });
};

describe('CategoryMapping', () => {
  let wrapper;

  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('emits close event on cancel button click', async () => {
      await wrapper.get('.test-modal-cancel').trigger('click');
      expect(wrapper.emitted().close).toBeTruthy();
    });

    it('emits save event on save button click', async () => {
      await wrapper.get('.test-save-category-mappings').trigger('click');
      expect(wrapper.emitted().save).toBeTruthy();
    });

    it('displays the category mapping list', () => {
      const groupLabels = wrapper.findAll('.test-mappings-table__label');
      groupLabels.forEach((groupLabel, index) => {
        expect(groupLabel.text()).toBe(categoryMappingList[index]);
      });
    });

    it('displays select box with correct category value for each group in ' +
       'the mapping list', () => {
      const selectElms = wrapper.findAll('.test-mappings-table__category-select');
      selectElms.forEach((selectElm, index) => {
        const group = categoryMappingList[index];
        expect(selectElm.element.value).toBe(categories[group].id.toString());
      });
    });
  });

  describe('when any category is not mapped with the Learning Group / Course Template', () => {
    beforeEach(() => {
      categories['Credit'] = null;
      wrapper = getWrapper();
    });

    it('disables the save button', () => {
      expect(wrapper.get('.test-save-category-mappings').element).toBeDisabled();
    });
  });

  describe('when usingPredefinedTrack is true', () => {
    beforeEach(() => {
      usingPredefinedTrack = true;
      wrapper = getWrapper();
    });

    it('it shows the title "For the activities in each Learning "' +
       '"Group, choose a gradebook category.', () => {
      expect(wrapper.get('.test-category-mappings__title').text()).toBe(
        'For the activities in each Learning Group, choose a gradebook category.'
      );
    });

    it('Table headers should be "Learning Group" & "Gradebook Category"', () => {
      const headers = wrapper.findAll('.test-mappings-table__header');
      expect(headers[0].text()).toBe('Learning Group');
      expect(headers[1].text()).toBe('Gradebook Category');
    });
  });

  describe('when usingPredefinedTrack is false', () => {
    beforeEach(() => {
      usingPredefinedTrack = false;
      wrapper = getWrapper();
    });

    it('it shows the title "Associate the gradebook categories "' +
       '"from the template to your course.', () => {
      expect(wrapper.get('.test-category-mappings__title').text()).toBe(
        'Associate the gradebook categories from the template to your course.'
      );
    });

    it('Table headers should be "Template" & "Course"', () => {
      const headers = wrapper.findAll('.test-mappings-table__header');
      expect(headers[0].text()).toBe('Template');
      expect(headers[1].text()).toBe('Course');
    });
  });
});
