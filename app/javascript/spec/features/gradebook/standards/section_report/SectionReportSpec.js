import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import SectionReportApp from 'features/gradebook/standards/section_report/SectionReportApp';
import SectionSummaryTable from 'features/gradebook/standards/section_report/SectionSummaryTable';

jest.mock('shared/ajax_utils', () => ({
  postToEndpoint: jest.fn(),
}));

const pinia = createPinia();
setActivePinia(pinia);

const props = {
  sectionReportData: {
    section_name: 'sec test 1',
    lesson_name: 'Unit 1 | Exploring Your Identity',
    unit_id: 2965,
    student_count: false,
    assistant_role_policy: false,
    report_rows: {
      column_headers: [
        {
          954135: {
            label: 'Mid-Unit',
            student_count: 2,
            score_count: 0,
          },
          954139: {
            label: 'End-of-Unit',
            student_count: 2,
            score_count: 0,
          },
          standard: 'Standard',
        },
      ],
      data: [
        {
          label: '6.L.1',
          id: 20155,
          description: 'Demonstrate command of the conventions of Standard English grammar and usage when writing or speaking.',
          total_number_of_items: 0,
          activities: [
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
          ],
        },
        {
          label: '6.L.2',
          id: 21894,
          description: 'Demonstrate command of the conventions of Standard English capitalization, punctuation, and spelling when writing.',
          total_number_of_items: 0,
          activities: [
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
          ],
        },
        {
          label: '6.L.4',
          id: 41417,
          description: 'Determine or clarify the meaning of unknown and multiple‐meaning words and phrases based on grade 6 reading and content, choosing flexibly from a range of strategies.',
          total_number_of_items: 0,
          activities: [
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
            {
              results_cell_classes: 'u-txt-ctr',
              percentage_color: null,
              percentage_format: '--',
              result: null,
            },
          ],
        },
      ],
    },
    valid_filters: true,
  },
  filtersData: {
    assessment_ids: '954135,954139',
    lesson_id: 3481,
    standard_set_display_name: 'AZ ELA',
  },
  standardsAssigningUrl: '/instructor/370/standards_assigning',
  newInstructorEnrollmentPath: '/instructor/370/enrollments/new?return_to=%2F370%2Fsections%2F58%2Froster',
  studentReportDataPath: '/gradebook/370/courses/41/sections/58/standards/student_report_data',
  sortReportPath: '/gradebook/370/courses/41/sections/58/standards/section_report?direction=asc&sort=standard',
  standardsLandingPagePath: '/gradebook/370/courses/41/sections/58/standards/landing_page',
};

function getWrapper() {
  return mount(
    SectionReportApp,
    {
      global: {
        plugins: [pinia],
        stubs: {
          'vhl-magnifying-glass-icon': true,
          'vhl-thick-arrow-icon': true,
          'vhl-assessment-count-icon': true,
          'vhl-column-unsorted-icon': true,
          'vhl-column-descending-icon': true,
          'vhl-column-ascending-icon': true,
          SectionSummaryTable,
        },
      },
      props: props,
    }
  );
}

describe(
  'SectionReportApp',
  () => {
    let wrapper;
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('renders SectionSummaryTable when singleRowStandardData is null', () => {
      expect(wrapper.findComponent(SectionSummaryTable).exists()).toBe(true);
    });

    it('renders correct table when singleRowStandardData is set', async () => {
      const sinsgleRowData = {
        column_headers: [
          {
            954135: {
              label: 'Mid-Unit',
              student_count: 2,
              score_count: 0,
            },
            standard: 'Standard',
          },
        ],
        data: [
          {
            label: '6.L.1',
            id: 20155,
            description: 'Demonstrate command of the conventions of Standard English grammar and usage when writing or speaking.',
            total_number_of_items: 0,
            activities: [
              {
                results_cell_classes: 'u-txt-ctr',
                percentage_color: null,
                percentage_format: '--',
                result: null,
              },
              {
                results_cell_classes: 'u-txt-ctr',
                percentage_color: null,
                percentage_format: '--',
                result: null,
              },
            ],
          },
        ],
      };

      await wrapper.vm.showStandardSingleRow({ report_rows: sinsgleRowData });
      expect(wrapper.findComponent(SectionSummaryTable).props().isSingleRow).toBe(true);
    });
  }
);
