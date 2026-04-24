import { shallowMount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import useSectionReportFilterStore from 'features/gradebook/standards/section_report_filters/stores/use_section_report_filter_store';
import useStudentDetailReportStore from 'features/gradebook/standards/student_detail_report/stores/use_student_detail_report_store';
import { nextTick } from 'vue';
import LandingStandardsReportsApp
  from 'features/gradebook/standards/landing_standards_reports/LandingStandardsReportsApp';
import SectionReportFiltersApp
  from 'features/gradebook/standards/section_report_filters/components/SectionReportFiltersApp';
import PMRSectionReportApp
  from 'features/gradebook/standards/section_report/PMRSectionReportApp';
import SectionReportApp
  from 'features/gradebook/standards/section_report/SectionReportApp';

const createMockStudents = () => [
  { id: 24, first_name: 'First', last_name: 'User' },
  { id: 25, first_name: 'Second', last_name: 'User' }
];

const createMockLessons = () => [
  ['Unit 1 | Exploring Your Identity', 3481],
  ['Unit 2 | Believing in Yourself', 3482]
];

const createMockStandardSets = () => ['CCSS', 'CA ELA', 'Texas TEKS'];

const defaultProps = {
  availableSets: JSON.stringify({ 'CCSS': [{ id: 38, display_name: 'CCSS' }] }),
  config: JSON.stringify({ units: [{ id: 2965, name: 'Unit 1', rank: 0 }] }),
  rosterStudentList: JSON.stringify(createMockStudents()),
  standardSets: JSON.stringify(createMockStandardSets()),
  lessons: JSON.stringify(createMockLessons()),
  standardsAssigningUrl: '/instructor/370/standards_assigning',
  sectionReportPath: '/gradebook/370/sections/58/standards/section_report',
  studentReportDataPath: '/gradebook/370/sections/58/standards/student_report_data',
  standardsExportCsvBaseUrl: '/gradebook/370/sections/58/standards/export_csv',
  gradebookStandardsStudentsCsvPath: '/gradebook/370/sections/58/standards/students_csv',
  newInstructorEnrollmentPath: '/instructor/370/enrollments/new',
  programId: '370',
  courseId: '41',
  sectionId: '58',
  studentId: '25',
  standardSet: '38',
  pmrStandardReportsAllowed: 'true',
  validFilters: 'false',
  selectedLesson: '',
  previouslySelectedActivityIdStrings: '',
  errorIconPath: '/error-icon',
  successIconPath: '/success-icon',
};

function createWrapper(propsOverride = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  return shallowMount(LandingStandardsReportsApp, {
    global: {
      plugins: [pinia],
      stubs: {
        SectionReportFiltersApp: true,
        StudentDetailReportApp: true,
        PMRSectionReportApp: true,
        SectionReportApp: true,
        AssessmentItemsModal: true,
        StandardButton: true,
        ExportIcon: true,
        HowToUse: true,
        ChooseFiltersStart: true,
      }
    },
    props: {
      ...defaultProps,
      ...propsOverride,
    },
  });
}

const mockSessionStorage = (() => {
  let store = {};
  return {
    getItem: jest.fn((key) => store[key] || null),
    setItem: jest.fn((key, value) => { store[key] = value.toString(); }),
    removeItem: jest.fn((key) => { delete store[key]; }),
    clear: jest.fn(() => { store = {}; }),
  };
})();

Object.defineProperty(window, 'sessionStorage', {
  value: mockSessionStorage,
});

describe('LandingStandardsReportsApp', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    mockSessionStorage.clear();
    wrapper = createWrapper();
    store = useSectionReportFilterStore();
  });

  afterEach(() => {
    wrapper?.unmount();
  });

  describe('Component rendering', () => {
    it('renders correctly', () => {
      expect(wrapper.exists()).toBeTruthy();
    });

    it('renders SectionReportFiltersApp component', () => {
      expect(wrapper.findComponent(SectionReportFiltersApp).exists()).toBeTruthy();
    });

    it('renders section navigation tab', () => {
      const sectionButton = wrapper.find('.test-show-section-report');

      expect(sectionButton.exists()).toBeTruthy();
    });

    it('renders student navigation tab', () => {
      const studentButton = wrapper.find('.test-show-student-report');

      expect(studentButton.exists()).toBeTruthy();
    });
  });

  describe('Tab functionality', () => {
    it('sets section as the initial tab', () => {
      expect(wrapper.vm.currentTab).toBe('section');
    });

    it('marks section button as current on initial load', () => {
      const sectionButton = wrapper.find('.test-show-section-report');

      expect(sectionButton.classes()).toContain('is-current');
    });

    it('switches to student tab when button is clicked', async () => {
      const studentButton = wrapper.find('.test-show-student-report');
      await studentButton.trigger('click');
      await nextTick();

      expect(wrapper.vm.currentTab).toBe('student');
    });

    it('marks student button as current after clicking', async () => {
      const studentButton = wrapper.find('.test-show-student-report');
      await studentButton.trigger('click');
      await nextTick();

      expect(studentButton.classes()).toContain('is-current');
    });

    it('saves tab selection to sessionStorage', async () => {
      const studentButton = wrapper.find('.test-show-student-report');
      await studentButton.trigger('click');
      await nextTick();

      expect(mockSessionStorage.setItem).toHaveBeenCalledWith('reportTabActive', 'student');
    });

    it('restores tab from sessionStorage', () => {
      mockSessionStorage.setItem('reportTabActive', 'student');
      const newWrapper = createWrapper();

      expect(newWrapper.vm.currentTab).toBe('student');
      newWrapper.unmount();
    });
  });

  describe('Student tab behavior', () => {
    it('disables the Student tab button if there is no student', () => {
      wrapper = createWrapper({ studentId: '' });
      const studentButton = wrapper.find('.test-show-student-report');

      expect(studentButton.element.disabled).toBeTruthy();
    });

    it('shows correct title on Student button when no students are present', () => {
      wrapper = createWrapper({ studentId: '' });
      const studentButton = wrapper.find('.test-show-student-report');

      expect(studentButton.attributes('title')).toBe(
        'No students enrolled in this section yet. Go to enroll in order to see this report.'
      );
    });

    it('handles empty string studentId without breaking the component', () => {
      wrapper = createWrapper({ studentId: '' });
      const studentButton = wrapper.find('.test-show-student-report');
      expect(studentButton.element.disabled).toBeTruthy();
    });


    it('shows SectionReportFiltersApp when currentTab is section', () => {
      expect(wrapper.findComponent(SectionReportFiltersApp).exists()).toBe(true);
      expect(wrapper.findComponent(SectionReportApp).exists()).toBe(false);
    });

    it('shows StudentDetailReportApp when currentTab is student', async () => {
      wrapper.vm.currentTab = 'student';
      await nextTick();
      expect(wrapper.find('.test-show-section-report-content').classes()).toContain('u-dis-none');
      expect(
        wrapper.find('.test-show-student-report-content').isVisible()
      ).not.toContain('u-dis-none');
    });

    it('toggles assessment items modal visibility', async () => {
      await wrapper.vm.toggleAssessmentItemsModalVisibility();
      expect(wrapper.vm.showAssessmentItems).toBe(true);
      await wrapper.vm.toggleAssessmentItemsModalVisibility();
      expect(wrapper.vm.showAssessmentItems).toBe(false);
    });

    describe('export button behavior', () => {
      it('disables section export when filters are incomplete', () => {
        const sectionStore = useSectionReportFilterStore();
        sectionStore.selectedStandardSetRef = null;
        sectionStore.selectedLessonId = null;
        sectionStore.selectedAssessmentIdsString = null;

        wrapper.vm.currentTab = 'section';
        expect(wrapper.vm.isExportButtonDisabled).toBe(true);
      });

      it('disables student export when student store is incomplete', () => {
        const studentStore = useStudentDetailReportStore();
        studentStore.selectedStandardSetRef = null;
        studentStore.selectedUnitId = null;
        studentStore.selectedStandardId = null;
        studentStore.selectedAssessmentIDs = null;

        wrapper.vm.currentTab = 'student';
        expect(wrapper.vm.isExportButtonDisabled).toBe(true);
      });
    });

    describe('when clicking on an assessment percent', () => {
      it('Shows the assessment items review modal', async () => {
        await wrapper.vm.toggleAssessmentItemsModalVisibility();
        expect(wrapper.vm.showAssessmentItems).toBe(true);
      });
    });
  });

  describe('Report titles', () => {
    it('displays default title when no filter data', () => {
      expect(wrapper.vm.reportTitle).toBe('');
    });

    it('displays proficiency report title', () => {
      wrapper.vm.filtersData = { assessment_type: 'proficiency' };

      expect(wrapper.vm.reportTitle).toBe('Proficiency Reports');
    });

    it('displays progress monitoring report title', () => {
      wrapper.vm.filtersData = { assessment_type: 'progress_monitoring' };

      expect(wrapper.vm.reportTitle).toBe('Progress Monitoring Reports');
    });

    it('displays student name in student report title', async () => {
      await wrapper.vm.setActiveTab('student');

      expect(wrapper.vm.reportTitle).toBe('Second User Overview');
    });

    it('displays default student title when student not found', async () => {
      wrapper = createWrapper({ studentId: '999' });
      await wrapper.vm.setActiveTab('student');

      expect(wrapper.vm.reportTitle).toBe('Student Overview');
    });
  });

  describe('Assessment items modal', () => {
    it('starts with assessment items modal hidden', () => {
      expect(wrapper.vm.showAssessmentItems).toBeFalsy();
    });

    it('shows assessment items modal when toggled from hidden state', async () => {
      await wrapper.vm.toggleAssessmentItemsModalVisibility();

      expect(wrapper.vm.showAssessmentItems).toBeTruthy();
    });

    it('hides assessment items modal when toggled from visible state', async () => {
      await wrapper.vm.toggleAssessmentItemsModalVisibility();
      await wrapper.vm.toggleAssessmentItemsModalVisibility();

      expect(wrapper.vm.showAssessmentItems).toBeFalsy();
    });

    it('opens assessment item modal when review items modal is opened', async () => {
      const mockEvent = {
        studentId: defaultProps.studentId,
        standardSetId: defaultProps.standardSet,
        itemGuids: ['item1', 'item2'],
        standardLabel: 'Reading Standard',
      };
      await wrapper.vm.openReviewItemsModal(mockEvent);

      expect(wrapper.vm.assessmentItemModalConfig.isModalOpen).toBeTruthy();
    });

    it('sets correct item guids when opening review items modal', async () => {
      const mockEvent = {
        studentId: defaultProps.studentId,
        standardSetId: defaultProps.standardSet,
        itemGuids: ['item1', 'item2'],
        standardLabel: 'Reading Standard',
      };
      await wrapper.vm.openReviewItemsModal(mockEvent);

      expect(wrapper.vm.assessmentItemModalConfig.itemGuids).toEqual(['item1', 'item2']);
    });

    it('sets correct standard label when opening review items modal', async () => {
      const mockEvent = {
        studentId: defaultProps.studentId,
        standardSetId: defaultProps.standardSet,
        itemGuids: ['item1', 'item2'],
        standardLabel: 'Reading Standard',
      };
      await wrapper.vm.openReviewItemsModal(mockEvent);

      expect(wrapper.vm.assessmentItemModalConfig.standardLabel).toBe('Reading Standard');
    });
  });

  describe('Report data handling', () => {
    const createMockSectionData = (assessmentType = 'proficiency') => ({
      assessments: { valid_filters: true },
      filters_data: { assessment_type: assessmentType, lesson_id: '3481' },
    });

    it('sets section report data when handling proficiency filter data', () => {
      const mockParams = createMockSectionData('proficiency');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.sectionReportData).toEqual({ valid_filters: true });
    });

    it('sets valid filters reference when handling proficiency filter data', () => {
      const mockParams = createMockSectionData('proficiency');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.validFiltersRef).toBeTruthy();
    });

    it('sets filters data when handling proficiency filter data', () => {
      const mockParams = createMockSectionData('proficiency');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.filtersData).toEqual(mockParams.filters_data);
    });

    it('sets PMR reports flag to false when handling proficiency filter data', () => {
      const mockParams = createMockSectionData('proficiency');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.isPMRReports).toBeFalsy();
    });

    it('sets PMR reports flag to true when handling progress monitoring filter data', () => {
      const mockParams = createMockSectionData('progress_monitoring');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.isPMRReports).toBeTruthy();
    });

    it('sets correct assessment type when handling progress monitoring filter data', () => {
      const mockParams = createMockSectionData('progress_monitoring');
      wrapper.vm.getSectionFilterData(mockParams);

      expect(wrapper.vm.filtersData.assessment_type).toBe('progress_monitoring');
    });

    it('saves filter data to sessionStorage', () => {
      const mockParams = createMockSectionData();
      wrapper.vm.getSectionFilterData(mockParams);

      expect(mockSessionStorage.setItem).toHaveBeenCalledWith(
        'sectionReportFiltersData',
        expect.stringContaining('proficiency')
      );
    });
  });

  describe('Export functionality', () => {
    const setupValidFilters = () => {
      store.selectedStandardSetRef = 'CCSS';
      store.selectedLessonId = '3481';
      store.selectedAssessmentIds = new Set(['1', '2']);
      wrapper.vm.validFiltersRef = true;
    };

    it('enables export button when all required filters are selected for proficiency', () => {
      setupValidFilters();

      expect(wrapper.vm.isExportButtonDisabled).toBeFalsy();
    });

    it('enables export button when all required filters are selected for PMR', () => {
      setupValidFilters();
      store.selectedAssessmentOption = 'progress_monitoring';
      store.isCategoryChecked = { 0: true };
      wrapper.vm.isPMRReports = true;

      expect(wrapper.vm.isExportButtonDisabled).toBeFalsy();
    });

    it('disables export button when filters are incomplete', () => {
      expect(wrapper.vm.isExportButtonDisabled).toBeTruthy();
    });
  });

  describe('Component interactions', () => {
    it('renders SectionReportApp for proficiency report type', async () => {
      wrapper.vm.sectionReportData = { some: 'data' };
      wrapper.vm.filtersData = { assessment_type: 'proficiency' };
      wrapper.vm.isPMRReports = false;
      await nextTick();

      expect(wrapper.findComponent(SectionReportApp).exists()).toBeTruthy();
    });

    it('does not render PMRSectionReportApp for proficiency report type', async () => {
      wrapper.vm.sectionReportData = { some: 'data' };
      wrapper.vm.filtersData = { assessment_type: 'proficiency' };
      wrapper.vm.isPMRReports = false;
      await nextTick();

      expect(wrapper.findComponent(PMRSectionReportApp).exists()).toBeFalsy();
    });

    it('renders PMRSectionReportApp for progress monitoring report type', async () => {
      wrapper.vm.sectionReportData = { some: 'data' };
      wrapper.vm.filtersData = { assessment_type: 'progress_monitoring' };
      wrapper.vm.isPMRReports = true;
      await nextTick();

      expect(wrapper.findComponent(PMRSectionReportApp).exists()).toBeTruthy();
    });

    it('does not render SectionReportApp for progress monitoring report type', async () => {
      wrapper.vm.sectionReportData = { some: 'data' };
      wrapper.vm.filtersData = { assessment_type: 'progress_monitoring' };
      wrapper.vm.isPMRReports = true;
      await nextTick();

      expect(wrapper.findComponent(SectionReportApp).exists()).toBeFalsy();
    });

    it('shows getting started content when no section report data', () => {
      const gettingStarted = wrapper.find('.test-standards-getting-started');
      expect(gettingStarted.exists()).toBeTruthy();
    });
  });
});
