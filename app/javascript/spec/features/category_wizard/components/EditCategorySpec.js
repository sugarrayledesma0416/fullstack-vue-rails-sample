import Category from 'features/category_wizard/models/category';
import Course from 'features/course_wizard/models/course';
import EditCategory from 'features/category_wizard/components/EditCategory';
import { mount } from '@vue/test-utils';
import { reactive } from 'vue';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};

const category1 = reactive(new Category());
category1.name = 'Homework';
category1.weightingPercent = 80;

const category2 = reactive(new Category());
category2.name = 'Quizzes';
category2.weightingPercent = 20;

courseDataStore.store.course.categories.push(category1);
courseDataStore.store.course.categories.push(category2);

/**
 * This method gets wrapper for Category component
 * @param {Object} courseDataStore
 * @param {number} categoryIndex
 * @return {Wrapper}
 */
function getWrapper(courseDataStore, categoryIndex) {
  return mount(EditCategory, {
    global: {
      provide: { courseDataStore },
      stubs: {
        EditGrading: true,
        EditLateness: true,
        TabSetTab: true,
        TabSet: true,
      },
    },
    props: { categoryIndex },
  });
}

describe('EditCategory Component', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(courseDataStore, 0);
    });

    it('displays the title as "Edit Category"', () => {
      expect(wrapper.get('.test-edit-category-title').text()).toBe('Edit Category');
    });

    it('displays the name of the category as "Homework"', () =>{
      expect(wrapper.get('.test-edit-category-name').element.value).toBe('Homework');
    });

    it('displays the weight of the category as "80"', () =>{
      expect(wrapper.get('.test-edit-category-weight').element.value).toBe('80');
    });

    it('does not display the error message block for name', () => {
      expect(wrapper.find('.test-edit-category-name-error').exists()).toBeFalsy();
    });

    it('does not display the error message block for weight', () => {
      expect(wrapper.find('.test-edit-category-weight-error').exists()).toBeFalsy();
    });

    it('displays tabset component', () => {
      expect(wrapper.findComponent({ name: 'TabSet' }).exists()).toBeTruthy();
    });
  });

  describe('category name as empty', () => {
    beforeEach(() => {
      courseDataStore.store.course.categories[0].name = '';
      wrapper = getWrapper(courseDataStore, 0);
    });

    it('displays the error message block for name', () => {
      expect(wrapper.find('.test-edit-category-name-error').exists()).toBeTruthy();
    });

    it('displays error message as "This is a required field"', () => {
      expect(
        wrapper.find('.test-edit-category-name-error').text()
      ).toBe('This is a required field');
    });
  });

  describe('when category weight is empty', () => {
    beforeEach(() => {
      courseDataStore.store.course.categories[0].weightingPercent = '';
      wrapper = getWrapper(courseDataStore, 0);
    });

    it('displays error message as "Category weight is required"', () => {
      expect(
        wrapper.find('.test-edit-category-weight-error').text()
      ).toBe('Category weight is required');
    });
  });

  describe('when edit category is changed', () => {
    beforeEach(() => {
      wrapper = getWrapper(courseDataStore, 1);
    });

    it('displays the weight of the category as "20"', () =>{
      expect(wrapper.get('.test-edit-category-weight').element.value).toBe('20');
    });
  });
});
