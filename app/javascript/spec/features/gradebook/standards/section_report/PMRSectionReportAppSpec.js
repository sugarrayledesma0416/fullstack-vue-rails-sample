import { shallowMount } from '@vue/test-utils';
import { PageTypes, Tabs } from 'features/gradebook/standards/section_report/consts';
import PMRSectionReportApp from 'features/gradebook/standards/section_report/PMRSectionReportApp';
import PMRSectionSummaryTable from
  'features/gradebook/standards/section_report/PMRSectionSummaryTable';
import fetchMock from 'fetch-mock';

describe('PMRSectionReportApp.vue', () => {
  let wrapper;

  const sectionReportData = {
    report_rows: {
      data: [
        { id: 1, name: 'Test Assessment 1' },
        { id: 2, name: 'Test Assessment 2' },
      ],
    },
    student_count: 10,
    unit_id: 123,
  };

  const filtersData = {
    assessment_type: 'progress_monitoring',
    assessment_ids: [1, 2],
    categories: ['Quizzes', 'Unit Test'],
    lesson_id: 45,
    standard_set_display_name: 'Test Standard Set',
  };
  const byStandardUrl = '/path/to/report' +
  '&assessment_type=progress_monitoring&lesson_id=45' +
  '&standard_set_display_name=Test%20Standard%20Set&view_by=standards';

  function getWrapper() {
    return shallowMount(PMRSectionReportApp, {
      props: {
        courseId: 1,
        filtersData,
        lessonName: 'Some lesson name',
        newInstructorEnrollmentPath: '/path/to/enrollment',
        programId: 101,
        sectionId: 201,
        sectionReportData,
        sectionReportPath: '/path/to/report',
        sortReportPath: '/path/to/sort',
        standardsAssigningUrl: '/path/to/standards',
      },
    });
  }

  beforeEach(() => {
    fetchMock.mock(
      byStandardUrl,
      { status: 200, body: {}}
    );
    wrapper = getWrapper();
  });

  afterEach(() => {
    fetchMock.restore();
    wrapper.unmount();
  });

  describe('Rendering and structure', () => {
    it('renders the component', () => {
      expect(wrapper.exists()).toBeTruthy();
    });

    it('applies the correct default class based on currentPageType', () => {
      expect(wrapper.classes()).toContain('pmr-section-report--by-assessment');
    });

    it('displays PMRSectionSummaryTable by default', () => {
      const table = wrapper.findComponent(PMRSectionSummaryTable);
      expect(table.exists()).toBeTruthy();
    });

    it('passes the correct props to PMRSectionSummaryTable', () => {
      const table = wrapper.findComponent(PMRSectionSummaryTable);
      expect(table.props('tableData')).toEqual(sectionReportData.report_rows.data);
    });

    it('does not show standard detail view', () => {
      expect(wrapper.findComponent({ name: 'PMRStandardDetailPage' }).exists()).toBeFalsy();
    });

    describe('when event "showStandardSingleRow" is received ' +
      'from component PMRSectionSummaryTable', () => {
      beforeEach(async () => {
        fetchMock.mock(
          '/path/to/sort',
          { status: 200, body: {}}
        );
        const comp = wrapper.findComponent({ name: 'PMRSectionSummaryTable' });
        await comp.vm.$emit('showStandardSingleRow', {});
      });

      it('shows standard detail view', () => {
        expect(wrapper.findComponent({ name: 'PMRStandardDetailPage' }).exists()).toBeTruthy();
      });
    });
  });

  describe('when "By Standards" tab is clicked', () => {
    beforeEach(async () => {
      const tabElm = wrapper.get('.test-tab-show-by-standards-report');
      await tabElm.trigger('click');
    });

    it('switches to the byStandards tab', () => {
      expect(wrapper.vm.currentTab).toBe(Tabs.byStandards);
    });

    it('updates PMRSectionSummaryTable tableMode to byPMRStandards', () => {
      const table = wrapper.findComponent(PMRSectionSummaryTable);
      expect(table.props('tableMode')).toBe('byPMRStandards');
    });

    it('does not show standard detail view', () => {
      expect(wrapper.findComponent({ name: 'PMRStandardDetailPage' }).exists()).toBeFalsy();
    });

    describe('when event "showStandardSingleRow" is received ' +
      'from component PMRSectionSummaryTable', () => {
      beforeEach(async () => {
        fetchMock.mock(
          '/path/to/sort',
          { status: 200, body: {}}
        );
        const comp = wrapper.findComponent({ name: 'PMRSectionSummaryTable' });
        await comp.vm.$emit('showStandardSingleRow', {});
      });

      it('shows standard detail view', () => {
        expect(wrapper.findComponent({ name: 'PMRStandardDetailPage' }).exists()).toBeTruthy();
      });
    });
  });

  describe('when sectionReportData prop is changed', () => {
    beforeEach(async () => {
      await wrapper.setProps({ sectionReportData: { report_rows: { data: [] }}});
    });

    it('resets sectionReportDataByStandards when sectionReportData prop changes', () => {
      expect(wrapper.vm.sectionReportDataByStandards).toBeNull();
    });

    it('resets currentPageType to pmrByAssessmentView', () => {
      expect(wrapper.vm.currentPageType).toBe(PageTypes.pmrByAssessmentView);
    });

    it('resets currentTab to byAssessment', () => {
      expect(wrapper.vm.currentTab).toBe(Tabs.byAssessment);
    });

    it('resets studentReportData to null', () => {
      expect(wrapper.vm.studentReportData).toBeNull();
    });
  });
});
