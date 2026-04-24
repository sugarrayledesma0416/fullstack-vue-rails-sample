import { mount } from '@vue/test-utils';
import PMRSectionSummaryTable from
  'features/gradebook/standards/section_report/PMRSectionSummaryTable';
import Tooltip from 'features/gradebook/standards/section_report/Tooltip';

describe('PMRSectionSummaryTable.vue', () => {
  const defaultProps = {
    tableCaption: 'Some caption',
  };

  const createWrapper = (props = {}) => {
    return mount(PMRSectionSummaryTable, {
      global: {
        stubs: {
          'vhl-assessment-count-icon-gray': true,
          'vhl-assessment-count-icon-white': true,
          'vhl-magnifying-glass-icon': true,
          PMRSectionSummaryTable,
          Tooltip,
        },
      },
      propsData: { ...defaultProps, ...props },
    });
  };

  describe('when tableMode is byPMRAssessment', () => {
    let wrapper;
    beforeEach(() => {
      const tableData = [
        {
          activities: [
            {
              percentage_color: 'some_class',
              percentage_format: '67%',
              result: '{2 of 3}',
              standard_description: 'Standard 1 description',
              standard_name: 'Standard 1',
            },
            {
              percentage_color: '',
              percentage_format: '',
              result: null,
              standard_description: 'Standard 2 description',
              standard_name: 'Standard 2',
            },
          ],
          category: 'Quizzes',
          label: 'Quiz 1',
          student_count: 4,
          submission_count: 3,
        },
        {
          activities: [
            {
              percentage_color: 'some_class',
              percentage_format: '45%',
              result: '{4.5 of 10}',
              standard_description: 'Standard 1 description',
              standard_name: 'Standard 1',
            },
            {
              percentage_color: 'some_class',
              percentage_format: '55%',
              result: '{5.5 of 10}',
              standard_description: 'Standard 2 description',
              standard_name: 'Standard 2',
            },
            {
              percentage_color: 'some_class',
              percentage_format: '100%',
              result: '{10 of 10}',
              standard_description: 'Standard 3 description',
              standard_name: 'Standard 3',
            },
          ],
          category: 'Unit Test',
          label: 'Unit Test 1',
          student_count: 4,
          submission_count: 2,
        },
      ];

      const props = {
        tableData,
        tableMode: 'byPMRAssessment',
      };
      wrapper = createWrapper(props);
    });

    it('renders the table with the correct caption', () => {
      expect(wrapper.find('.test-section-summary-table-caption').text()).toBe('Some caption');
    });

    it('displays correct row header text for each assessment data row', () => {
      const rowHeaderTexts = wrapper.findAll('.test-row-header-txt').map((elm) => elm.text());
      expect(rowHeaderTexts).toStrictEqual(['Quiz 1', 'Unit Test 1']);
    });

    it('renders the correct number of non-null data cells based on table data', () => {
      const dataCells = wrapper.findAll('.test-data-cell');
      // one cell in row 1 and 3 cells in row 2
      const nonNullDataCellCount = 1+3;
      expect(dataCells.length).toBe(nonNullDataCellCount);
    });

    it('displays the tooltip standard name on cell hover', async () => {
      const dataCell = wrapper.find('.test-data-cell');

      await dataCell.trigger('mouseenter');
      expect(wrapper.findComponent(Tooltip).props().title).toBe('Standard 1');
    });

    it('displays the tooltip with standard description on cell hover', async () => {
      const dataCell = wrapper.find('.test-data-cell');

      await dataCell.trigger('mouseenter');
      expect(wrapper.findComponent(Tooltip).props().description).toBe('Standard 1 description');
    });

    it('calculates header colspan correctly based on maxCellCount', () => {
      // in row 2
      const maxCellCount = 3;
      const headerColspan = wrapper.vm.headerColspan();
      expect(headerColspan).toBe(maxCellCount);
    });
  });

  describe('when tableMode is byPMRStandards', () => {
    let wrapper;
    beforeEach(() => {
      const tableData = [
        {
          activities: [
            {
              activity_name: 'Quiz 1',
              category: 'Quizzes',
              percentage_color: 'some_class',
              percentage_format: '40%',
              result: '{2 of 5}',
              student_count: 3,
              submission_count: 2,
            },
            {
              activity_name: 'Quiz 2',
              category: 'Quizzes',
              percentage_color: '',
              percentage_format: '',
              result: null,
              student_count: 3,
              submission_count: 1,
            },
          ],
          description: 'Standard 1 description',
          id: 1,
          label: 'Standard 1',
          total_number_of_items: 2,
        },
        {
          activities: [
            {
              activity_name: 'Quiz 1',
              category: 'Quizzes',
              percentage_color: 'some_class',
              percentage_format: '45%',
              result: '{4.5 of 10}',
              student_count: 3,
              submission_count: 2,
            },
            {
              activity_name: 'Quiz 2',
              category: 'Quizzes',
              percentage_color: 'some_class',
              percentage_format: '55%',
              result: '{5.5 of 10}',
              student_count: 3,
              submission_count: 1,
            },
            {
              activity_name: 'Unit Test 1',
              category: 'Unit Test',
              percentage_color: 'some_class',
              percentage_format: '100%',
              result: '{10 of 10}',
              student_count: 3,
              submission_count: 1,
            },
          ],
          description: 'Standard 2 description',
          id: 2,
          label: 'Standard 2',
          total_number_of_items: 2,
        },
      ];

      const props = {
        tableData,
        tableMode: 'byPMRStandards',
      };
      wrapper = createWrapper(props);
    });

    it('renders the table with the correct caption', () => {
      expect(wrapper.find('.test-section-summary-table-caption').text()).toBe('Some caption');
    });

    it('displays correct row header text for each standard data row', () => {
      expect(wrapper.find('.test-row-header-txt').text()).toBe('Standard 1');
    });

    it('renders the correct number of non-null data cells based on table data', () => {
      const dataCells = wrapper.findAll('.test-data-cell');
      // one cell in row 1 and 3 cells in row 2
      const nonNullDataCellCount = 1+3;
      expect(dataCells.length).toBe(nonNullDataCellCount);
    });

    it('displays the tooltip with standard description on row header cell hover', async () => {
      const rowHeaderCell = wrapper.find('.test-row-header-txt');

      await rowHeaderCell.trigger('mouseenter');
      expect(wrapper.findComponent(Tooltip).props().description).toBe('Standard 1 description');
    });

    it('displays the tooltip with assessment title on cell hover', async () => {
      const dataCell = wrapper.find('.test-data-cell');

      await dataCell.trigger('mouseenter');
      expect(wrapper.findComponent(Tooltip).props().title).toBe('Quiz 1');
    });

    it('displays the tooltip with assessment submission detail on cell hover', async () => {
      const dataCell = wrapper.find('.test-data-cell');

      await dataCell.trigger('mouseenter');
      expect(wrapper.findComponent(Tooltip).props().description).toBe('(2 of 3)');
    });

    it('calculates header colspan correctly based on maxCellCount', () => {
    // in row 2
      const maxCellCount = 3;
      const headerColspan = wrapper.vm.headerColspan();
      expect(headerColspan).toBe(maxCellCount);
    });
  });
});
