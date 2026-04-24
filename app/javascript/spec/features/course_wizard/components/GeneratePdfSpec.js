import { mount } from '@vue/test-utils';
import CourseSerializer from 'features/course_wizard/services/course_serializer.js';
import GeneratePdf from 'features/course_wizard/components/GeneratePdf';

const config = { programId: '79' };

const course = {
  categories: [],
  endDate: '11/2/2021',
  firstUnitId: 1,
  lastUnitId: 2,
  level: 64,
  name: 'Test Course',
  startDate: '11/1/2021',
};

const courseDataStore = {
  store: {
    course,
    courseOptions: {
      components: [],
      levels: [{ id: 64, name: 'Portales' }],
      units: [
        { id: 1, label: 'Lession 1' },
        { id: 2, label: 'Lession 2' },
      ],
    },
  },
};
courseDataStore.courseSerializer = new CourseSerializer(course);

const getWrapper = () => {
  return mount(GeneratePdf, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
};

describe('GeneratePdf', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('contains the generate pdf form', () => {
      expect(wrapper.find('.test-generate-pdf-form').exists()).toBeTruthy();
    });

    it('displays generate pdf link', () => {
      expect(wrapper.find('.test-generate-pdf').exists()).toBeTruthy();
    });
  });

  describe('when generate pdf link is clicked', () => {
    beforeEach(async () => {
      // Needed because the HTMLFormElement implementation in jest-dom
      // does not have a submit fuction.
      window.HTMLFormElement.prototype.submit = jest.fn();
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-generate-pdf');
      await inputElm.trigger('click');
    });

    it('submits the generate pdf form', () => {
      expect(window.HTMLFormElement.prototype.submit).toHaveBeenCalled();
    });
  });
});
