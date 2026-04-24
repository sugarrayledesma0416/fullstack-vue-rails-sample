import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import GradebookTableContainer from 'features/category_wizard/components/GradebookTableContainer';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');
jest.mock('images/category_wizard/weighting_alert.png', () => '');

const config = {
  instAdmin: false,
  programId: 79,
  schoolId: 100,
  isEnterprise: false
};

const courseOptionsResponse = { settings: [] };

/**
 * This method gets wrapper for GradebookTableContainer component
 * @param {Array.<Category>} categoriesData - categories in the course for the wrapper
 * @return {Wrapper}
 */
function getWrapper(categoriesData) {
  const course = new Course();
  const courseDataStore = new CourseDataStore(
    course,
    config.instAdmin,
    config.isEnterprise,
    config.programId,
    config.schoolId,
  );
  courseDataStore.store.course.categories = categoriesData;
  return mount(GradebookTableContainer, {
    attachTo: document.querySelector('.mount-target'),
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

/*
  Grabs reference(s) to open tooltip(s).
  Returns an Array (NOT a wrapper, b/c the tooltips
  are mounted directly inside the document body).
*/
const openTooltips = (selector) => {
  const tippyRoot = 'body > [data-tippy-root]';
  const wholeSelector = `${tippyRoot} ${selector}`;
  const nodes = document.querySelectorAll(wholeSelector);
  if (nodes.length > 0) {
    return nodes;
  } else {
    throw Error('No open tooltips found.');
  }
};

let wrapper;
describe('GradebookTableContainer', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    await fetchMock.flush(true);
    await flushPromises();

    document.body.innerHTML = `
    <div class="mount-target"></div>
    `;
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      const categoriesData = [];
      wrapper = getWrapper(categoriesData);
    });

    it('displays Add Category button', () => {
      expect(wrapper.get('.test-add-category-btn').exists()).toBeTruthy();
    });

    it('displays GradebookTable component', () => {
      expect(wrapper.findComponent({ name: 'GradebookTable' }).exists()).toBeTruthy();
    });

    it('displays CategoryWeightGraph component', () => {
      expect(wrapper.findComponent({ name: 'CategoryWeightGraph' }).exists()).toBeTruthy();
    });

    describe('when there are categories in the data store', () => {
      beforeEach(() => {
        wrapper.vm.courseDataStore.store.course.categories = [
          { id: 11, name: 'Some category name 1', rank: 1 },
          { id: 12, name: 'Some category name 2', rank: 2 },
          { id: 13, name: 'Some category name 3', rank: 3 },
        ];
      });

      it('does not display information hover for Add Category button', () => {
        expect(wrapper.get('.test-add-category-btn-hover').isVisible()).toBeFalsy();
      });
    });

    describe('when there are no categories in the data store', () => {
      beforeEach(() => {
        wrapper.vm.courseDataStore.store.course.categories = [];
      });

      it('displays information popup for Add Category button', () => {
        expect(openTooltips('.test-add-category-btn-hover').length).toBe(1);
      });
    });
  });

  describe('when Add Category button is clicked', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
      ];
      wrapper = getWrapper(categoriesData);
      const buttonElm = wrapper.get('.test-add-category-btn');
      await buttonElm.trigger('click');
    });

    it('emits "openAddCategory" event', () => {
      expect(wrapper.emitted().openAddCategory).toBeTruthy();
    });
  });

  describe('when receives "openEditCategory" event from child component "GradebookTable"', () => {
    beforeEach(async () => {
      const categoriesData = [
        { id: 11, name: 'Some category name 1', rank: 1 },
      ];
      wrapper = getWrapper(categoriesData);
      const gradebookTableComp = wrapper.findComponent({ name: 'GradebookTable' });
      await gradebookTableComp.vm.$emit('openEditCategory', { someKey: 'some value' });
    });

    it('triggers event "openEditCategory" ', () => {
      expect(wrapper.emitted('openEditCategory')).toHaveLength(1);
    });
  });
});
