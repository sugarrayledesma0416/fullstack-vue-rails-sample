import Course from 'features/course_wizard/models/course';
import Tutorial from 'features/category_wizard/components/Tutorial';
import TutorialStore from 'features/category_wizard/models/tutorial_store';
import { mount } from '@vue/test-utils';
import { reactive } from 'vue';

const tutorial = new TutorialStore();
const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  vol: true,
};

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};

const getWrapper = () => {
  return mount(Tutorial, {
    global: {
      provide: {
        config,
        courseDataStore,
        tutorial,
      },
      stubs: { VhlLink: true },
    },
  });
};

describe('Tutorial Component', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('contains the tutorial title as "What is a category?"', () => {
      expect(wrapper.get('.test-tutorial-title').text()).toBe('What is a category?');
    });

    it('contains all the tutorial instructions', () => {
      expect(
        wrapper.get('.test-instructions-toc').text()
      ).toBe('In your gradebook, each activity you assign...');

      expect(
        wrapper.get('.test-instructions-assign').text()
      ).toBe('...needs to be associated with a category.');

      expect(
        wrapper.get('.test-instructions-grade').text()
      ).toBe('The categories you create are used to calculate your students\' final grades.');
    });

    it('displays "StandardButton" component for "get started" button', () => {
      expect(wrapper.findComponent({ name: 'StandardButton' }).exists()).toBeFalsy();
    });
  });

  describe('on tutorial image click', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-lightbox-image-toc').trigger('click');
    });

    it('makes zoomed image visible', () => {
      expect(wrapper.get('.test-zoomed-image-toc').isVisible()).toBeTruthy();
    });
  });
});
