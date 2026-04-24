import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import GradebookTable from 'features/category_wizard/components/GradebookTable';
import fetchMock from 'fetch-mock';

delete window.location;
window.location = new URL('http://example.com/new');

const config = {
  instAdmin: false,
  programId: 79,
  schoolId: 100,
  isEnterprise: false,
};

const courseOptionsResponse = { settings: [] };

/**
 * This method gets wrapper for GradebookTable component
 * @param {Array.<Category>} categoriesData - categories in the course for the wrapper
 * @return {Wrapper}
 */
const getWrapper = (categoriesData) => {
  const course = new Course();
  const courseDataStore = new CourseDataStore(
    course,
    config.instAdmin,
    config.isEnterprise,
    config.programId,
    config.schoolId
  );
  courseDataStore.store.course.categories = categoriesData;
  return mount(GradebookTable, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
};

let wrapper;
describe('GradebookTable', () => {
  beforeEach(() => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
        { id: 12, name: 'Some category name 2', rank: 2 },
        { id: 13, name: 'Some category name 3', rank: 3 },
      ];
      wrapper = getWrapper(categoriesData);
    });

    it('displays student names column', () => {
      expect(wrapper.get('.test-student-names-column').exists()).toBeTruthy();
    });

    it('displays student names in 4 cells', () => {
      expect(wrapper.findAll('.test-student-name').length).toBe(4);
    });

    it('displays grades in 3 columns, one for each category', () => {
      expect(wrapper.findAll('.test-grades-column').length).toBe(3);
    });

    it('displays 3 GearMenu components one for each category', () => {
      expect(wrapper.findAllComponents({ name: 'GearMenu' }).length).toBe(3);
    });

    it('displays 3 MoveLeft buttons one for each category', () => {
      expect(wrapper.findAll('.test-rank-up-category').length).toBe(3);
    });

    it('displays 3 MoveRight buttons one for each category', () => {
      expect(wrapper.findAll('.test-rank-down-category').length).toBe(3);
    });

    it('displays 3 text inputs for category weighting percent, one for each category', () => {
      expect(wrapper.findAll('.test-weighting-percent-input').length).toBe(3);
    });

    it('displays sample grades for students, for each student and for each category', () => {
      expect(wrapper.findAll('.test-sample-grades').length).toBe(12);
    });

    it('displays first category column for category "Some category name 1"', () => {
      expect(wrapper.findAll('.test-category-name-link')[0].text()).toBe('Some category name 1');
    });

    it('displays second category column for category "Some category name 2"', () => {
      expect(wrapper.findAll('.test-category-name-link')[1].text()).toBe('Some category name 2');
    });

    it('displays third category column for category "Some category name 3"', () => {
      expect(wrapper.findAll('.test-category-name-link')[2].text()).toBe('Some category name 3');
    });
  });

  describe('when there is no categories present in the store', () => {
    beforeEach(async () => {
      const categoriesData = [];
      wrapper = getWrapper(categoriesData);
    });

    it('displays message "[ No gradebook categories yet ]"', () => {
      expect(wrapper.get('.test-no-categories-message').text()).toBe(
        '[ No gradebook categories yet ]');
    });
  });

  describe('when MoveRight button is clicked on first category', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
        { id: 12, name: 'Some category name 2', rank: 2 },
        { id: 13, name: 'Some category name 3', rank: 3 },
      ];
      wrapper = getWrapper(categoriesData);
      const itemElms = wrapper.findAll('.test-rank-down-category');
      await itemElms[0].trigger('click');
    });

    it('displays first category column for category "Some category name 2"', () => {
      expect(wrapper.findAll('.test-category-name-link')[0].text()).toBe('Some category name 2');
    });

    it('displays second category column for category "Some category name 1"', () => {
      expect(wrapper.findAll('.test-category-name-link')[1].text()).toBe('Some category name 1');
    });

    it('displays third category column for category "Some category name 3"', () => {
      expect(wrapper.findAll('.test-category-name-link')[2].text()).toBe('Some category name 3');
    });
  });
  describe('when MoveLeft button is clicked on third category', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
        { id: 12, name: 'Some category name 2', rank: 2 },
        { id: 13, name: 'Some category name 3', rank: 3 },
      ];
      wrapper = getWrapper(categoriesData);
      const itemElms = wrapper.findAll('.test-rank-up-category');
      await itemElms[2].trigger('click');
    });

    it('displays first category column for category "Some category name 1"', () => {
      expect(wrapper.findAll('.test-category-name-link')[0].text()).toBe('Some category name 1');
    });

    it('displays second category column for category "Some category name 3"', () => {
      expect(wrapper.findAll('.test-category-name-link')[1].text()).toBe('Some category name 3');
    });

    it('displays third category column for category "Some category name 2"', () => {
      expect(wrapper.findAll('.test-category-name-link')[2].text()).toBe('Some category name 2');
    });
  });

  describe('when click on category name link', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
      ];
      wrapper = getWrapper(categoriesData);
      const itemElms = wrapper.findAll('.test-category-name-link');
      await itemElms[0].trigger('click');
    });

    it('emits "openEditCategory" event', () => {
      expect(wrapper.emitted().openEditCategory).toBeTruthy();
    });
  });

  describe('when receives "click" event from child component "GearMenu" ' +
  'with id "edit-category" in event payload', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
      ];
      wrapper = getWrapper(categoriesData);
      const gearMenuComp = wrapper.findComponent({ name: 'GearMenu' });
      await gearMenuComp.vm.$emit('click', { id: 'edit-category' });
    });

    it('triggers event "openEditCategory" ', () => {
      expect(wrapper.emitted('openEditCategory')).toHaveLength(1);
    });
  });

  describe('when receives "click" event from child component "GearMenu" ' +
  'with id "delete-category" in event payload', () => {
    describe('dialog not confirmed usecase', () => {
      beforeEach(async () => {
        window.confirm = jest.fn(() => false);
        const categoriesData = [
          { id: 11, name: 'Some category name 1', rank: 1 },
        ];
        wrapper = getWrapper(categoriesData);
        const gearMenuComp = wrapper.findComponent({ name: 'GearMenu' });
        await gearMenuComp.vm.$emit('click', { id: 'delete-category' });
      });

      it('confirm dialog is shown', () => {
        expect(window.confirm).toBeCalledWith('You are about delete this category. Are you Sure?');
      });

      it('category is not removed from the data store', () => {
        expect(wrapper.vm.courseDataStore.store.course.categories.length).toBe(1);
      });
    });
  });

  describe('dialog confirmed usecase', () => {
    beforeEach(async () => {
      window.confirm = jest.fn(() => true);
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
      ];
      wrapper = getWrapper(categoriesData);
      const gearMenuComp = wrapper.findComponent({ name: 'GearMenu' });
      await gearMenuComp.vm.$emit('click', { id: 'delete-category' });
    });

    it('confirm dialog is shown', () => {
      expect(window.confirm).toBeCalledWith('You are about delete this category. Are you Sure?');
    });

    it('category is removed from the data store on confirmation', () => {
      expect(wrapper.vm.courseDataStore.store.course.categories.length).toBe(0);
    });
  });

  describe('when hasAssignments is true for the category', () => {
    beforeEach(async () => {
      window.alert = jest.fn(() => true);
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1, hasAssignments: true },
      ];
      wrapper = getWrapper(categoriesData);
      const gearMenuComp = wrapper.findComponent({ name: 'GearMenu' });
      await gearMenuComp.vm.$emit('click', { id: 'delete-category' });
    });

    it('alert is shown', () => {
      expect(window.alert).toBeCalledWith(
        'You cannot delete this category because it contains assignments'
      );
    });

    it('category is not removed from the data store', () => {
      expect(wrapper.vm.courseDataStore.store.course.categories.length).toBe(1);
    });
  });
});
