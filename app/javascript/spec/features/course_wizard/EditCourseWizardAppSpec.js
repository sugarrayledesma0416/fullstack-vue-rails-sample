import { shallowMount } from '@vue/test-utils';
import { createRouter, createWebHashHistory } from 'vue-router';
import EditCourseWizardApp from 'features/course_wizard/EditCourseWizardApp';
import PathSelectorStep from 'features/course_wizard/components/PathSelectorStep.vue';

jest.mock('features/course_wizard/services/course_options_http.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      course: {
        name: 'Test Course',
        endDate: '11/2/2021',
        firstUnitId: 1,
        lastUnitId: 2,
        level: 64,
        startDate: '11/1/2021',
        standard_set_ids: [1, 2]
      },
      settings: [],
      supported_standard_sets: [
        { id: 1, name: 'standard 1'},
        { id: 2, name: 'standard 2' },
        { id: 3, name: 'standard 3' },
      ],
    };
  });
});

jest.mock('features/course_wizard/services/course_http.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      getContentStepData() {
        return {
          course_has_individual_assignments: true,
        };
      },
    };
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
  return shallowMount(EditCourseWizardApp, {
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
      potentialInstructors: ''
    },
  });
};

describe('EditCourseWizardApp', () => {
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

    it('displays "EditCourseTabs" component', () => {
      expect(wrapper.findComponent({ name: 'EditCourseTabs' }).exists()).toBeTruthy();
    });

    it('displays "RouterView" component', () => {
      expect(wrapper.findComponent({ name: 'RouterView' }).exists()).toBeTruthy();
    });
  });
});
