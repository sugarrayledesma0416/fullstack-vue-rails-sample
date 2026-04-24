import { mount } from '@vue/test-utils';
import StudentPreview from 'features/section_wizard/components/StudentPreview';

const datastore = {
  section: {
    additionalInfo: 'some additional info',
    course: { name: 'course 1' },
    instructorLastNames: ['instructor last name 1', 'instructor last name 2'],
    name: 'section 1',
  },
};

let wrapper;

/**
 * This method gets wrapper for StudentPreview component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(StudentPreview, {
    global: {
      provide: {
        datastore,
      },
    },
  });
}

describe('StudentPreview', () => {
  beforeEach(() => {
    wrapper = getWrapper();
  });

  describe('when StudentPreview is mounted', () => {
    it('displays 1 data row for preview', () => {
      expect(wrapper.findAll('.test-section-row-preview')).toHaveLength(1);
    });

    it('displays value "instructor last name 1, instructor last name 2" for column "Instructor"',
      () => {
        expect(
          wrapper.find('.test-section-row-preview-instructor').text()
        ).toBe('instructor last name 1, instructor last name 2');
      }
    );

    it('displays value "course 1" for column "Course"', () => {
      expect(wrapper.find('.test-section-row-preview-course').text()).toBe('course 1');
    });

    it('displays value "section 1" for column "Section"', () => {
      expect(wrapper.find('.test-section-row-preview-section').text()).toBe('section 1');
    });

    it('displays value "some additional info" for column "More Info"', () => {
      expect(
        wrapper.find('.test-section-row-preview-more-info').text()
      ).toBe('some additional info');
    });
  });
});
