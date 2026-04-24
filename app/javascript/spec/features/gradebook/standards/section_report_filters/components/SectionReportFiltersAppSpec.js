import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import SectionReportFiltersApp
  from 'features/gradebook/standards/section_report_filters/components/SectionReportFiltersApp';

const standardSets = ['Standard Set A', 'Standard Set B'];
const lessons = [['Lesson 1', '1'], ['Lesson 2', '2']];
const programId = 123;
const courseId = 456;
const sectionId = 789;
const gradebookStandardsStudentsCsvPath = '/gradebook/370/courses/41/sections/58/' +
  'standards/students_csv';
const standardsExportCsvBaseUrl = '/gradebook/370/courses/41/sections/58/standards/' +
  'standard_export_csv';
const sectionReportPath = '/gradebook/370/courses/41/sections/58/standards/' +
  'section_report?direction=asc&sort=standard';
const previouslySelectedActivityIdStrings = null;
const selectedLesson = '';
const selectedStandardSet = '';
const showFilters = { is_active: true };
const validFilters = false;

// Mock the meta tag content function
global.metaTagContent = jest.fn(() => '123');

global.fetch = jest.fn(() =>
  Promise.resolve({
    json: () => Promise.resolve(
      [['Assessment 1', '1'], ['Assessment 2', '2']]
    ),
  })
);

beforeEach(() => {
  fetch.mockClear();
  // Mock document.querySelector to return a fake form element
  const mockForm = document.createElement('form');
  mockForm.classList.add('js-filter-form');

  mockForm.submit = jest.fn();
  document.querySelector = jest.fn().mockImplementation((selector) => {
    if (selector === '.js-filter-form') {
      return mockForm;
    }
    return null;
  });

  // Clear session storage before each test
  window.sessionStorage.clear();
});

describe(
  'SectionReportFiltersApp',
  () => {
    const pinia = createPinia();
    setActivePinia(pinia);

    function getWrapper(options={}) {
      const defaultProps = {
        courseId,
        gradebookStandardsStudentsCsvPath,
        lessons,
        previouslySelectedActivityIdStrings,
        programId,
        sectionId,
        sectionReportPath,
        selectedLesson,
        selectedStandardSet,
        showFilters,
        standardSets,
        standardsExportCsvBaseUrl,
        pmrStandardReportsAllowed: 'true',
        validFilters,
      };

      return mount(
        SectionReportFiltersApp,
        {
          global: {
            plugins: [pinia],
            stubs: { 'music-icon-return': true },
          },
          props: { ...defaultProps, ...options },
        }
      );
    }

    describe('when the component is first rendered', () => {
      describe('the standard set dropdown', () => {
        it('shows the expected options', async () => {
          const wrapper = getWrapper();
          await wrapper.vm.$nextTick();
          const options = wrapper.find('.test-standard-set-display-name').findAll('option');

          expect(options.map((option) => [option.attributes('value'), option.text()])).toEqual(
            [
              [standardSets[0], standardSets[0]],
              [standardSets[1], standardSets[1]],
            ]
          );
        });

        describe('when a selected standard set is provided', () => {
          it('has the expected value', async () => {
            const wrapper = getWrapper({ selectedStandardSet: standardSets[1] });
            await wrapper.vm.$nextTick();
            expect(
              wrapper.find('.test-standard-set-display-name').element.value
            ).toBe(standardSets[0]);
          });
        });
      });

      describe('the lesson select', () => {
        it('is enabled', async () => {
          const wrapper = getWrapper();
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-lesson-id').attributes('disabled')).toBeUndefined();
        });
      });
    });

    describe('when interacting with the submit button', () => {
      it('should find the submit button', async () => {
        const wrapper = getWrapper();
        await wrapper.vm.$nextTick();
        const submitButton = wrapper.find('.test-filter-apply-btn');
        expect(submitButton.exists()).toBeTruthy();
      });
    });

    describe('when selecting assessment type', () => {
      it('should show assessment dropdown for proficiency', async () => {
        const wrapper = getWrapper();
        await wrapper.vm.$nextTick();

        const assessmentTypeSelect = wrapper.find('.test-assessment-type');
        await assessmentTypeSelect.setValue('proficiency');

        const assessmentMultiSelect = wrapper.find('#assessment_ids_select');
        expect(assessmentMultiSelect.isVisible()).toBeTruthy();
        expect(wrapper.find('#category_type_select').isVisible()).toBe(false);
      });

      it('should show category select for progress_monitoring', async () => {
        const wrapper = getWrapper();
        await wrapper.vm.$nextTick();

        const assessmentTypeSelect = wrapper.find('.test-assessment-type');
        await assessmentTypeSelect.setValue('progress_monitoring');

        const categorySelect = wrapper.find('#category_type_select');
        expect(categorySelect.isVisible()).toBeTruthy();
        expect(wrapper.find('#assessment_ids_select').isVisible()).toBeFalsy();
      });
    });

    describe('when handling session storage', () => {
      it('should load stored filters from session storage', async () => {
        const storedFilters = {
          '123': {
            lesson_id: '1',
            standard_set_display_name: 'Standard Set A',
            assessment_ids: '1,2',
          },
        };
        window.sessionStorage.setItem('sectionReportFiltersData', JSON.stringify(storedFilters));

        const wrapper = getWrapper();
        await wrapper.vm.$nextTick();

        expect(wrapper.find('#lesson_id').element.value).toBe('1');
        expect(wrapper.find('#standard_set_display_name').element.value).toBe('Standard Set A');
      });
    });

    describe('when handling unit change', () => {
      it('should clear assessments when unit changes', async () => {
        const wrapper = getWrapper();
        await wrapper.vm.$nextTick();

        wrapper.vm.assessments = [['Assessment 1', '1']];
        wrapper.vm.store.setSelectedLessonId('1');

        await wrapper.find('#lesson_id').setValue('2');

        expect(wrapper.vm.assessments).toEqual([]);
        expect(wrapper.vm.store.selectedAssessmentIds.size).toBe(0);
      });
    });
  }
);
