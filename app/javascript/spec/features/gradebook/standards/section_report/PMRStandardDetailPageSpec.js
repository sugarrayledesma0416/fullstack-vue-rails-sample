import { mount } from '@vue/test-utils';
import PMRStandardDetailPage from
  'features/gradebook/standards/section_report/PMRStandardDetailPage';
import GoToEnroll from 'features/gradebook/standards/section_report/GoToEnroll';

describe('PMRStandardDetailPage.vue', () => {
  const defaultProps = {
    courseId: 1,
    newInstructorEnrollmentPath: '/enroll',
    programId: 101,
    lessonName: 'Sample Lesson Name',
    sectionId: 201,
    singlePmrStandardData: { data: [] },
    standardIdForDetailPage: 301,
    standardsAssigningUrl: '/assign-standards',
    studentReportData: { data: [] },
    unitId: 401,
    zeroStudentCount: false,
  };

  const createWrapper = (props = {}) =>
    mount(PMRStandardDetailPage, {
      props: {
        ...defaultProps,
        ...props,
      },
      global: {
        stubs: {
          SectionSummaryTable: true,
          GoToEnroll: true,
        },
      },
    }
    );

  let wrapper;
  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders the lesson title with the correct text', () => {
    const lessonTitle = wrapper.find('.test-unit-name');
    expect(lessonTitle.text()).toBe(defaultProps.lessonName);
  });

  describe('when singlePmrStandardData is present', () => {
    let singleStandardTable;
    beforeEach(() => {
      singleStandardTable = wrapper.findComponent({ ref: 'refSingleStandard' });
    });

    it('renders the SectionSummaryTable for PMR standard average', () => {
      expect(singleStandardTable.exists()).toBeTruthy();
    });

    it('renders the table for PMR standard average with correct mode', () => {
      expect(singleStandardTable.props().tableMode).toBe('pmrSingleStandard');
    });

    it('renders the table for PMR standard average with correct table data', () => {
      expect(singleStandardTable.props().tableData).toStrictEqual(
        defaultProps.singlePmrStandardData
      );
    });
  });

  describe('when singlePmrStandardData is not present', () => {
    let singleStandardTable;
    beforeEach(() => {
      const wrapper = createWrapper({ singlePmrStandardData: null });
      singleStandardTable = wrapper.findComponent({ ref: 'refSingleStandard' });
    });

    it('does not render the SectionSummaryTable for PMR standard average', () => {
      expect(singleStandardTable.exists()).toBeFalsy();
    });
  });

  it('renders the GoToEnroll component if `zeroStudentCount` is true', () => {
    const wrapper = createWrapper({ zeroStudentCount: true });
    const goToEnroll = wrapper.findComponent(GoToEnroll);
    expect(goToEnroll.exists()).toBeTruthy();
  });

  describe('when zeroStudentCount is false', () => {
    describe('when studentReportData is present', () => {
      let studentTable;
      beforeEach(() => {
        wrapper = createWrapper({ zeroStudentCount: false });
        studentTable = wrapper.findComponent({ ref: 'refStudentPerformance' });
      });

      it('renders the SectionSummaryTable for student performance', () => {
        expect(studentTable.exists()).toBeTruthy();
      });

      it('renders the table for student performance with correct mode', () => {
        expect(studentTable.props().tableMode).toBe('pmrStudents');
      });

      it('renders the table for student performance with correct table data', () => {
        expect(studentTable.props().tableData).toStrictEqual(defaultProps.studentReportData);
      });
    });

    describe('when studentReportData is not present', () => {
      let studentTable;
      beforeEach(() => {
        wrapper = createWrapper({ studentReportData: null });
        studentTable = wrapper.findComponent({ ref: 'refStudentPerformance' });
      });

      it('does not render the SectionSummaryTable for student performance', () => {
        expect(studentTable.exists()).toBeFalsy();
      });
    });
  });
});


