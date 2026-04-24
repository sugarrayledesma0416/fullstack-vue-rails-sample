import { shallowMount } from '@vue/test-utils';
import { createRouter, createWebHashHistory } from 'vue-router';
import NewCourseWizardApp from 'features/course_wizard/NewCourseWizardApp';
import PathSelectorStep from 'features/course_wizard/components/PathSelectorStep.vue';

jest.mock('features/course_wizard/services/course_options_http.js', () => {
  return jest.fn().mockImplementation(() => {
    return { settings: [] };
  });
});

const routes = [
  {
    path: '/',
    redirect: '/path',
  },
  {
    path: '/path',
    name: 'path-selector-step',
    component: PathSelectorStep,
  },
];

const router = createRouter({ history: createWebHashHistory(), routes });
const getWrapper = () => {
  return shallowMount(NewCourseWizardApp, {
    global: {
      mocks: {
        $route: routes,
      },
      plugins: [router],
    },
    props: {
      currentUser: { last_name: 'Stracke' },
      loadingIconPath: '',
      gradebookCategories: '',
    },
  });
};

describe('NewCourseWizardApp', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(async () => {
      router.push('/');
      await router.isReady();
      wrapper = getWrapper();
    });

    it('displays "FlashMessages" component', () => {
      expect(wrapper.findComponent({ name: 'FlashMessages' }).exists()).toBeTruthy();
    });

    it('displays "RouterView" component', () => {
      expect(wrapper.findComponent({ name: 'RouterView' }).exists()).toBeTruthy();
    });
  });
});
