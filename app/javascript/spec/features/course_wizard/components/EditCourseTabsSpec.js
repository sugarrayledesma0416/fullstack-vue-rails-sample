import { mount } from '@vue/test-utils';
import { createRouter, createWebHashHistory } from 'vue-router';
import ContentStep from 'features/course_wizard/components/content_step/ContentStep';
import EditCourseTabs from 'features/course_wizard/components/EditCourseTabs';
import SummaryStep from 'features/course_wizard/components/SummaryStep';

const routes = [
  {
    path: '/',
    redirect: '/content',
  },
  {
    path: '/content',
    name: 'content-step',
    component: ContentStep,
  },
  {
    path: '/summary',
    name: 'summary-step',
    component: SummaryStep,
  },
];

const router = createRouter({ history: createWebHashHistory(), routes });
const editCourseTabs = ['Course', 'Content', 'Gradebook', 'Summary'];

/**
 * This method gets wrapper for EditCourseTabs component
 * @return {VueWrapper}
 */
const getWrapper = () => {
  return mount(EditCourseTabs, {
    global: {
      plugins: [router],
    },
  });
};

describe('EditCourseTabs', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays tabs for each course step', () => {
      const tabs = wrapper.findAll('.test-edit-course-tab');
      tabs.forEach((tab, index) => {
        expect(tab.text()).toBe(editCourseTabs[index]);
      });
    });
  });

  describe('When a course step is loaded', () => {
    beforeEach(async () => {
      await router.push('/content');
      wrapper = getWrapper();
    });

    it('adds class "current" on the current active tab', () => {
      const tabs = wrapper.findAll('.test-edit-course-tab');
      expect(tabs[1].classes('current')).toBeTruthy();
    });
  });

  describe('When a course tab is selected', () => {
    beforeEach(async () => {
      spyOn(router, 'push');
      wrapper = getWrapper();
      const tabs = wrapper.findAll('.link');
      await tabs[3].trigger('click');
    });

    it('calls router`s push method', () => {
      expect(router.push).toHaveBeenCalledWith({ name: 'summary-step' });
    });
  });
});
