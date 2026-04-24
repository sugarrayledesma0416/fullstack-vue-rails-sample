<template>
  <div class="l-grid  report-header">
    <div class="l-col-12  u-txt-ctr  u-pad-top-24">
      <ol class="c-subnav  report-header-ol  js-subnav  js-nav-system">
        <div class="report-tab  u-dis-flex">
          <li>
            <button
              class="c-no-button  c-subnav__link"
              :class="[
                {'is-current': currentTab === 'section'},
                testClass('show-section-report')]"
              type="button"
              data-tab-info="section-report"
              @click="setActiveTab('section')">
              Section
            </button>
          </li>
          <li>
            <button
              class="c-no-button  c-subnav__link"
              :class="[
                {'is-current': currentTab === 'student'},
                testClass('show-student-report')]"
              type="button"
              data-tab-info="student-report"
              :disabled="!props.studentId"
              :title="!props.studentId ? NO_STUDENTS_WARNING : ''"
              @click="setActiveTab('student')">
              Student
            </button>
          </li>
        </div>
        <div class="u-pad-bot-12">
          <h2 class="u-txt-20  u-mar-0">
            {{ reportTitle }}
          </h2>
        </div>
        <div class="export-how-to-use">
          <StandardButton
            class="export-btn"
            :title="exportButtonTitle"
            :disabled="isExportButtonDisabled"
            @click="exportStandardReportCSV">
            <ExportIcon />
            <span class="export-btn-text">Export</span>
          </StandardButton>

          <HowToUse :currentTab="currentTab" />
        </div>
      </ol>
    </div>
    <div
      :class="[
        'filter-app-wrapper  l-col-12',
        {'u-dis-flex': currentTab === 'section'},
        {'u-dis-none': currentTab === 'student'},
        testClass('show-section-report-content')
      ]">
      <SectionReportFiltersApp
        :showFilters="showFilters"
        :standardSets="JSON.parse(props.standardSets)"
        :selectedStandardSet="props.selectedStandardSet"
        :lessons="JSON.parse(props.lessons)"
        :selectedLesson="props.selectedLesson"
        :programId="parseInt(props.programId)"
        :courseId="parseInt(props.courseId)"
        :sectionId="parseInt(props.sectionId)"
        :previouslySelectedActivityIdStrings="props.previouslySelectedActivityIdStrings === '' ?
          [] :
          props.previouslySelectedActivityIdStrings"
        :validFilters="validFiltersRef"
        :standardsExportCsvBaseUrl="props.standardsExportCsvBaseUrl"
        :sectionReportPath="props.sectionReportPath"
        :gradebookStandardsStudentsCsvPath="props.gradebookStandardsStudentsCsvPath"
        :pmrStandardReportsAllowed="props.pmrStandardReportsAllowed"
        @getSectionFilterData="getSectionFilterData($event)"
        @hideFiltersSection="showFilters = $event" />
      <AssessmentItemsModal
        v-show="showAssessmentItems"
        :assessmentItemModalConfig="assessmentItemModalConfig"
        :reviewPath="reviewPathRef"
        :standardDetails="standardDetails"
        :errorIconPath="errorIconPath"
        :successIconPath="successIconPath"
        @toggle-assessment-items-modal-visibility="toggleAssessmentItemsModalVisibility()" />
      <template v-if="sectionReportData !== null">
        <SectionReportApp
          v-if="!isPMRReports"
          :sectionReportData="sectionReportData"
          :filtersData="filtersData"
          :standardsAssigningUrl="props.standardsAssigningUrl"
          :newInstructorEnrollmentPath="props.newInstructorEnrollmentPath"
          :studentReportDataPath="props.studentReportDataPath"
          :sortReportPath="props.sectionReportPath"
          :standardsLandingPagePath="props.standardsLandingPagePath"
          @showFiltersSection="showFiltersSection($event)"
          @openReviewItems="openReviewItemsModal($event)" />
        <PMRSectionReportApp
          v-else
          :filtersData="filtersData"
          :standardsAssigningUrl="props.standardsAssigningUrl"
          :sortReportPath="props.sectionReportPath"
          :sectionReportPath="props.sectionReportPath"
          :sectionReportData="sectionReportData"
          :newInstructorEnrollmentPath="props.newInstructorEnrollmentPath"
          :programId="parseInt(props.programId)"
          :courseId="parseInt(props.courseId)"
          :sectionId="parseInt(props.sectionId)"
          @showFiltersSection="showFiltersSection($event)"
          @openReviewItems="openReviewItemsModal($event)" />
      </template>
      <div
        v-else
        class="standards-report  u-bg-white  u-mar-lt-neg-16  u-mar-rt-neg-16  u-pad-top-16  u-pad-bot-64"
        :class="testClass('standards-getting-started')">
        <div class="u-mar-top-16  u-mar-bot-32">
          <div class="u-start-image-container">
            <div class="u-pad-top-32">
              <ChooseFiltersStart />
            </div>
            <div class="text  u-txt-gray-6  u-mar-top-8">
              <h2 class="u-mar-rt-24">
                How to Start
              </h2>
              <p>
                Please make the required selections and<br>click "Go" to display report results.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      class="u-bg-white  u-pad-bot-24"
      :class="[
        'l-col-12',
        {'u-dis-none': currentTab === 'section' || !props.studentId},
        testClass('show-student-report-content')
      ]">
      <StudentDetailReportApp
        v-if="props.studentId"
        :availableSets="props.availableSets"
        :config="props.config"
        :errorIconPath="errorIconPath"
        :gradeCategoriesUrl="props.gradeCategoriesUrl"
        :reviewPath="props.reviewPath"
        :rosterPath="props.rosterPath"
        :rosterStudentList="props.rosterStudentList"
        :selectedStandardGuid="props.selectedStandardGuid"
        :standardsAssigningUrl="props.standardsAssigningUrl"
        :standardSet="props.standardSet"
        :standardsLandingPagePath="props.standardsLandingPagePath"
        :studentId="props.studentId"
        :successIconPath="successIconPath"
        :unitSelected="props.unitSelected" />
    </div>
  </div>
</template>
<script setup>
  import { getCsvFile, metaTagContent, StandardButton, testClass } from 'music';
  import { computed, nextTick, ref } from 'vue';
  import StudentDetailReportApp from '../student_detail_report/StudentDetailReportApp';
  import SectionReportFiltersApp
    from '../section_report_filters/components/SectionReportFiltersApp';
  import AssessmentItemsModal from 'features/gradebook/share_feature/AssessmentItemsModal';
  import ChooseFiltersStart from './ChooseFiltersStart';
  import ExportIcon from './components/ExportIcon';
  import HowToUse from './components/HowToUse';
  import PMRSectionReportApp from '../section_report/PMRSectionReportApp';
  import SectionReportApp from '../section_report/SectionReportApp';
  import useSectionReportFilterStore from
  'features/gradebook/standards/section_report_filters/stores/use_section_report_filter_store';
  import useStudentDetailReportStore from '../student_detail_report/stores/use_student_detail_report_store';

  const props = defineProps({
    // SectionReportFiltersApp
    availableSets: { required: true, type: String },
    config: { required: true, type: String },
    gradeCategoriesUrl: { default: '', type: String },
    reviewPath: { default: '', type: String },
    rosterPath: { default: '', type: String },
    rosterStudentList: { required: true, type: String },
    selectedStandardGuid: { default: '', type: String },
    standardsAssigningUrl: { required: true, type: String },
    standardSet: { required: true, type: String },
    standardsLandingPagePath: { default: '', type: String },
    studentId: { required: true, type: String },
    unitSelected: { required: false, type: String, default: null },
    newInstructorEnrollmentPath: { required: true, type: String },
    gradebookStandardsStudentsCsvPath: { required: true, type: String },
    // StudentDetailReportApp
    standardSets: { type: String, required: true },
    selectedStandardSet: { type: String, default: '' },
    lessons: { type: String, required: true },
    selectedLesson: { type: String, default: '' },
    programId: { type: String, required: true },
    courseId: { type: String, required: true },
    sectionId: { type: String, required: true },
    previouslySelectedActivityIdStrings: { type: String, default: null },
    validFilters: { type: String, default: 'false' },
    standardsExportCsvBaseUrl: { type: String, required: true },
    pmrStandardReportsAllowed: { type: String, required: true },
    sectionReportPath: { type: String, required: true },
    studentReportDataPath: { type: String, required: true },
    // AssessmentItemsModal
    // TODO: Remove icon paths and change it by web components into the modal component
    errorIconPath: { required: true, type: String },
    successIconPath: { required: true, type: String },
  });

  const NO_STUDENTS_WARNING =
    'No students enrolled in this section yet. Go to enroll in order to see this report.';

  // TODO: add method doc here
  /**
   * Open review items modal.
   * @param {Object} event
   */
  async function openReviewItemsModal(event) {
    const studentId = event.studentId;
    const standardSetId = event.standardSetId;
    reviewPathRef.value = reviewPathRef.value.replace(
      'student-id',
      `${studentId}`
    ).replace('set-id', `${standardSetId}`);
    await nextTick();
    assessmentItemModalConfig.value.itemGuids = event.itemGuids;
    assessmentItemModalConfig.value.isModalOpen = true;
    assessmentItemModalConfig.value.standardLabel = event.standardLabel;
  }

  const store = useSectionReportFilterStore();
  const studentDetailReportStore = useStudentDetailReportStore();
  const currentTab = ref(sessionStorage.getItem('reportTabActive') || 'section');

  const reviewPathRef = ref(props.reviewPath);
  const showAssessmentItems = ref(false);
  const standardDetails = ref({});
  const assessmentItemModalConfig = ref({
    isModalOpen: false,
    itemGuids: [],
    standardLabel: '',
  });
  const sectionReportData = ref(null);
  const filtersData = ref(null);
  const showFilters = ref({ is_active: true, standard_id: null });
  const validFiltersRef = ref(false);
  const currentProgram = ref(metaTagContent('VHL.program_id') || null);
  const sectionReportFiltersData = JSON.parse(
    sessionStorage.getItem('sectionReportFiltersData')
  ) || {};
  const isPMRReportsFn = (assessmentType) => {
    return assessmentType === 'progress_monitoring';
  };
  const isPMRReports = ref(isPMRReportsFn());

  const reportTitle = computed(() => {
    if (currentTab.value === 'section') {
      return getSectionReportTitle();
    }
    return getStudentReportTitle();
  });

  const isExportButtonDisabled = computed(() => {
    const isStudentTab = currentTab.value === 'student';

    if (isStudentTab) {
      const {
        selectedStandardSetRef,
        selectedUnitId,
        selectedStandardId,
        selectedAssessmentIDs,
      } = studentDetailReportStore;

      return ![
        selectedStandardSetRef,
        selectedUnitId,
        selectedStandardId,
        selectedAssessmentIDs
      ].every(Boolean);
    }

    const {
      selectedStandardSetRef,
      selectedLessonId,
      selectedAssessmentIdsString,
      isCategoryChecked
    } = store;
  
    const baseRequirements = 
      validFiltersRef.value && selectedStandardSetRef && selectedLessonId;

    if (isPMRReports.value) {
      return !(
        baseRequirements &&
        Object.values(isCategoryChecked || {}).some((isChecked) => isChecked)
      );
    }

    return !(baseRequirements && selectedAssessmentIdsString);
  });

  const exportButtonTitle = computed(() => {
    if (isExportButtonDisabled.value) {
      return currentTab.value === 'student'
        ? 'Please select a Standard from the Units breakdown to enable export.'
        : 'Please select Standard Set, Unit, and Assessment to enable export.';
    }
    return 'Export the current report as a CSV file.';
  });

  /**
   * Get the title of the section report.
   * @return {String} The title of the section report.
   */
  function getSectionReportTitle() {
    if (!filtersData.value) return '';

    return filtersData.value?.assessment_type === 'proficiency'
      ? 'Proficiency Reports'
      : 'Progress Monitoring Reports';
  }

  /**
   * Get the title of the student report.
   * @return {String} The title of the student report.
   */
  function getStudentReportTitle() {
    try {
      const students = JSON.parse(props.rosterStudentList);
      const selectedStudent = students.find((student) => student.id === Number(props.studentId));
      return selectedStudent
        ? `${selectedStudent.first_name} ${selectedStudent.last_name} Overview`
        : 'Student Overview';
    } catch {
      return 'Student Overview';
    }
  }

  /**
   * Toggle the assessment items visibility
   */
  function toggleAssessmentItemsModalVisibility() {
    assessmentItemModalConfig.value.isModalOpen = false;
    showAssessmentItems.value = !showAssessmentItems.value;
  }

  /**
   * Set active tab in report menu
   * @param {String} tabName
   */
  function setActiveTab(tabName) {
    currentTab.value = tabName;
    sessionStorage.setItem('reportTabActive', tabName);
  }

  /**
   * Get section report data and.
   * @param {Object} params
   */
  function getSectionFilterData(params) {
    sectionReportData.value = {};
    sectionReportData.value = params.assessments;
    validFiltersRef.value = params.assessments?.valid_filters;
    filtersData.value = params.filters_data;
    addFilterInfoByProgram(params.filters_data);
    isPMRReports.value = isPMRReportsFn(params.filters_data?.assessment_type);
  }

  /**
   * Save Filters data by program in session storage.
   * @param {Object} filtersData
   */
  function addFilterInfoByProgram(filtersData) {
    const sectionReportFiltersData = JSON.parse(
      sessionStorage.getItem('sectionReportFiltersData')
    ) || {};
    sectionReportFiltersData[currentProgram.value] = filtersData;
    sessionStorage.setItem('sectionReportFiltersData', JSON.stringify(sectionReportFiltersData));
  }

  /**
   * Set data to show Filter section.
   * @param {Object} data
   */
  function showFiltersSection(data) {
    showFilters.value = data;
  }

  function buildQueryParams(params) {
    const search = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') {
        search.append(k, v);
      }
    });
    const q = search.toString();
    return q ? `?${q}` : '';
  }

  function sanitizeFilenamePart(part = '') {
    return String(part)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
      .join('_')
      .replace(/\s+/g, '_')
      .replace(/[^A-Za-z0-9_.-]/g, '')
      .slice(0, 120);
  }

  async function exportStandardReportCSV() {
    if (currentTab.value === 'section') {
      await exportSectionReportCsv();
    } else {
      await exportStudentReportCsv();
    }
  }

  async function exportSectionReportCsv() {
    const { selectedStandardSetRef, selectedLessonId, selectedAssessmentIdsString } = store;

    if (!selectedStandardSetRef || !selectedLessonId) {
      console.warn('Missing required parameters: Standard Set or Lesson ID');
      return;
    }

    const standardSet = selectedStandardSetRef;
    const lessonId = selectedLessonId;

    if (isPMRReports.value) {
      const categories = store.appliedFilterState?.selectedCategories || [];
      const pmrAssessmentIds = store.pmrAssessmentIds || [];

      if (categories.length === 0 && pmrAssessmentIds.length === 0) {
        console.warn('Missing parameters for PMR CSV export: No categories or assessment IDs selected');
        return;
      }

      const baseQueryParams = {
        standard_set_display_name: standardSet,
        lesson_id: lessonId,
      };

      if (categories.length) baseQueryParams.categories = categories.join(',');
      if (pmrAssessmentIds.length) baseQueryParams.assessment_ids = pmrAssessmentIds.join(',');

      const filenameSuffix = sanitizeFilenamePart(categories.join('_') || 'pmr');
      const csvFilename = `csv_standards_by_categories_${filenameSuffix}.csv`;

      await downloadCsvFile(props.standardsExportCsvBaseUrl, baseQueryParams, csvFilename);
    } else {
      if (!selectedAssessmentIdsString) {
        console.warn('Missing parameters for section CSV export: Assessment IDs required');
        return;
      }

      const baseQueryParams = {
        standard_set_display_name: standardSet,
        lesson_id: lessonId,
        assessment_ids: selectedAssessmentIdsString,
      };

      const filenameSuffix = sanitizeFilenamePart(selectedAssessmentIdsString);
      const csvFilename = `csv_standards_by_assessment_${filenameSuffix}.csv`;

      await downloadCsvFile(props.standardsExportCsvBaseUrl, baseQueryParams, csvFilename);
    }
  }

  /**
   * Export student report CSV.
   */
  async function exportStudentReportCsv() {
    const {
      selectedStandardSetRef,
      selectedUnitId,
      selectedStandardId,
      selectedAssessmentIDs,
    } = studentDetailReportStore;

    if (!selectedStandardSetRef || !selectedUnitId || !selectedStandardId || !selectedAssessmentIDs) {
      console.warn('Missing parameters for student CSV export');
      return;
    }

    const params = {
      standard_set_display_name: selectedStandardSetRef,
      unit_id: selectedUnitId,
      standard_id: selectedStandardId,
      assessment_ids: selectedAssessmentIDs,
    };
    const filenamePart = sanitizeFilenamePart(selectedAssessmentIDs);
    const csvFilename = `export_student_csv_${filenamePart}.csv`;

    await downloadCsvFile(props.gradebookStandardsStudentsCsvPath, params, csvFilename);
  }

  /**
   * Helper to fetch and save CSV file.
   */
  async function downloadCsvFile(baseUrl, params, filename) {
    const url = baseUrl + buildQueryParams(params);
    try {
      const err = await getCsvFile(url, filename);
      if (err) console.error(`Failed to export CSV: ${filename}`, err);
    } catch (err) {
      console.error(`Error exporting CSV: ${filename}`, err);
    }
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .export-btn-text {
    font-size: rpx(16);
    margin-left: rpx(6);
    text-transform: none;
  }

  .report-header {
    background-color: $gray-f5;
    margin: 0 rpx(16);
    border-bottom: rpx(1) solid #ddd;
  }

  .report-header-ol {
    border-bottom: 0;
    display: flex;
    justify-content: space-between;
  }

  .report-tab {
    margin-right: 0;
    padding-left: 0;
  }

  .filter-app-wrapper {
    border: rpx(1) solid #ddd;
    border-bottom: 0;
    box-shadow: rpx(0) rpx(4) rpx(6) rgba(0, 0, 0, 0.1);
    background-color: #fff;
    margin-left: 0;
    padding-left: 0;
  }

  .export-how-to-use {
    align-items: center;
    display: flex;
    justify-content: center;
  }

  .export-how-to-use .export-btn {
    background: none;
    margin-right: rpx(16);
  }

  .pmr-section-report-wrapper {
    width: 84%;
  }

  .standards-report {
    width: 66%;
  }
</style>
