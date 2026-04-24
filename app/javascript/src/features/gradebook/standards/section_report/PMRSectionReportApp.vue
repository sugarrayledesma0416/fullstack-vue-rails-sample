<template>
  <div
    class="pmr-section-report"
    :class="currentPageCls">
    <template
      v-if="currentPageType === PageTypes.pmrByAssessmentView ||
        currentPageType === PageTypes.pmrByStandardsView">
      <div class="subtab-wrapper">
        <span class="view-by-txt">VIEW BY</span>
        <ol
          class="c-subnav"
          :class="testClass('subtabs')">
          <li>
            <button
              class="c-no-button  c-subnav__link"
              :class="[
                {'is-current': currentTab === Tabs.byAssessment},
                testClass('tab-show-by-assessment-report')
              ]"
              type="button"
              data-tab-info="by-assessment-report"
              @click="setActiveTab(Tabs.byAssessment)">
              Assessment
            </button>
          </li>
          <li>
            <button
              class="c-no-button  c-subnav__link"
              :class="[
                {'is-current': currentTab === Tabs.byStandards},
                testClass('tab-show-by-standards-report')
              ]"
              type="button"
              data-tab-info="by-standards-report"
              @click="setActiveTab(Tabs.byStandards)">
              Standards
            </button>
          </li>
        </ol>
      </div>
      <div class="subtab-content">
        <div
          v-if="currentTab === Tabs.byAssessment"
          :class="testClass('show-by-assessment-report-content')">
          <PMRSectionSummaryTable
            :tableMode="TableModes.byPMRAssessment"
            :tableCaption="byAssessmentTableCaption"
            :tableData="tableDataByAssessments"
            @showStandardSingleRow="showStandardSingleRow" />
        </div>
        <div
          v-if="currentTab === Tabs.byStandards"
          :class="testClass('show-by-standard-report-content')">
          <PMRSectionSummaryTable
            :standardsAssigningUrl="props.standardsAssigningUrl"
            :unitId="sectionReportDataByStandards?.unit_id"
            :tableMode="TableModes.byPMRStandards"
            :tableCaption="byStandardsTableCaption"
            :tableData="tableDataByStandards"
            @showStandardSingleRow="showStandardSingleRow" />
        </div>
      </div>
    </template>
    <PMRStandardDetailPage
      v-if="currentPageType === PageTypes.pmrStandardDetailView"
      :standardsAssigningUrl="props.standardsAssigningUrl"
      :unitId="getUnitId"
      :zeroStudentCount="hasZeroStudentCount"
      :newInstructorEnrollmentPath="props.newInstructorEnrollmentPath"
      :standardIdForDetailPage="standardIdForDetailPage"
      :singlePmrStandardData="singlePmrStandardData"
      :studentReportData="studentReportData"
      :courseId="courseId"
      :programId="programId"
      :lessonName="props.sectionReportData?.lesson_name"
      :sectionId="sectionId" />
  </div>
</template>
<script setup>
  import { postToEndpoint, testClass } from 'music';
  import { computed, ref, watch } from 'vue';
  import { PageTypes, TableModes, Tabs } from 'features/gradebook/standards/section_report/consts';
  import PMRSectionSummaryTable from './PMRSectionSummaryTable';
  import PMRStandardDetailPage from './PMRStandardDetailPage';

  const props = defineProps({
    courseId: { required: true, type: Number },
    filtersData: { required: true, type: Object },
    newInstructorEnrollmentPath: { required: true, type: String },
    programId: { required: true, type: Number },
    sectionId: { required: true, type: Number },
    sectionReportData: { required: true, type: Object },
    sectionReportPath: { required: true, type: String },
    sortReportPath: { required: true, type: String },
    standardsAssigningUrl: { required: true, type: String },
  });

  const emit = defineEmits(['showFiltersSection']);

  const currentPageType = ref(PageTypes.pmrByAssessmentView);
  const currentTab = ref(Tabs.byAssessment);
  const standardIdForDetailPage = ref(null);
  const studentReportData = ref(null);
  const singlePmrStandardData = ref(null);

  const sectionReportDataByStandards = ref(null);
  const byAssessmentTableCaption = 'This table shows a section-level performance report ' +
    '"by assessments" for one or more progress monitoring assessments ' +
    'in your selected unit, section and standards.';
  const byStandardsTableCaption = 'This table shows a section-level performance report ' +
    '"by standards" for one or more progress monitoring assessments ' +
    'in your selected unit, section and standards.';

  /**
   * Get css class based on page type
   * @return {String}
   */
  const currentPageCls = computed(() => {
    const clsMap = {};
    clsMap[PageTypes.pmrByAssessmentView] = 'pmr-section-report--by-assessment';
    clsMap[PageTypes.pmrByStandardsView] = 'pmr-section-report--by-standards';
    clsMap[PageTypes.pmrStandardDetailView] = 'pmr-section-report--standard-detail';
    return clsMap[currentPageType.value] ?? '';
  });

  /**
   * Set active tab in report menu
   * @param {String} tabName
   */
  function setActiveTab(tabName) {
    if (tabName === Tabs.byAssessment) {
      currentTab.value = tabName;
      currentPageType.value = PageTypes.pmrByAssessmentView;
    } else if (tabName === Tabs.byStandards) {
      getDataForByStandardsView();
      currentPageType.value = PageTypes.pmrByStandardsView;
    } else {
      currentTab.value = tabName;
    }
    sessionStorage.setItem('reportSubTabActive', tabName);
  }

  const hasZeroStudentCount = computed(() => {
    return props.sectionReportData?.student_count;
  });

  const getUnitId = computed(() => {
    return props.sectionReportData?.unit_id;
  });

  /**
   * Fetch table data for by-standards view based on current filtering parameters.
   * Fetch it only once for a filter state.
   */
  function getDataForByStandardsView() {
    if (sectionReportDataByStandards.value) {
      currentTab.value = Tabs.byStandards;
      return;
    }

    const assessmentIds = props.filtersData.assessment_ids;
    const assessmentType = props.filtersData.assessment_type;
    const categories = props.filtersData.categories;
    const lessonId = props.filtersData.lesson_id;
    const standardSetDisplayName = props.filtersData.standard_set_display_name;
    const url = `${props.sectionReportPath}&assessment_type=${assessmentType}` +
      `&lesson_id=${ lessonId }&standard_set_display_name=${ standardSetDisplayName }` +
      '&view_by=standards';

    postToEndpoint(
      url,
      { assessment_ids: assessmentIds, categories },
      (response) => {
        sectionReportDataByStandards.value = response.assessments;
        currentTab.value = Tabs.byStandards;
      }
    );
  }

  /**
   * Show standard selected standard data and hide filters section.
   * @param {number} standardId
   */
  function showStandardSingleRow(standardId) {
    currentPageType.value = PageTypes.pmrStandardDetailView;
    standardIdForDetailPage.value = standardId;
    getStudentData(standardId);
    emit('showFiltersSection', {
      is_active: false,
      standard_id: standardId,
    });
  }

  /**
   * Get students info by standard.
   * @param {String} standardId
   */
  function getStudentData(standardId) {
    const simpleSortReportPath = props.sortReportPath.split('?')[0];
    postToEndpoint(
      simpleSortReportPath,
      {
        assessment_ids: props.filtersData?.assessment_ids,
        assessment_type: props.filtersData?.assessment_type,
        direction: 'asc',
        lesson_id: props.filtersData?.lesson_id,
        sort: 'student',
        standard_id: standardId,
        standard_set_display_name: props.filtersData?.standard_set_display_name,
      },
      (response) => {
        console.log('getStudentData: response:', response);
        studentReportData.value = response.assessments?.individual_performance_data;
        singlePmrStandardData.value = response.assessments;
      }
    );
  }

  watch(() => props.sectionReportData, (newValue) => {
    sectionReportDataByStandards.value = null;
    currentPageType.value = PageTypes.pmrByAssessmentView;
    currentTab.value = Tabs.byAssessment;
    studentReportData.value = null;
    standardIdForDetailPage.value = null;
    singlePmrStandardData.value = null;
  });


  /**
   * Data in required format for the table component for by-assessments view.
   */
  const tableDataByAssessments = computed(() => {
    return props.sectionReportData?.report_rows.data;
  });

  /**
   * Data in required format for the table component for by-standards view.
   */
  const tableDataByStandards = computed(() => {
    return sectionReportDataByStandards.value?.report_rows?.data;
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .pmr-section-report--by-assessment,
  .pmr-section-report--by-standards {
    width: 84%;

    .subtab-content {
      margin-left: 0;
      margin-right: 0;
      padding-left: rpx(48);
      padding-right: rpx(16);
    }
  }

  .pmr-section-report--standard-detail {
    align-items: center;
    display: flex;
    flex-direction: column;
    position: relative;
    width: 90%;
  }

  .c-subnav {
    border-bottom: 0;
    padding-top: 0;
  }

  .subtab-wrapper {
    align-items: center;
    display: flex;
    justify-content: flex-start;
    padding-bottom: rpx(24);
    padding-left: rpx(88);
    padding-top: rpx(24);
    text-align: center;
    width: 100%;
  }

  .view-by-txt {
    font-size: 1rem;
    font-weight: bold;
    margin-right: rpx(32);
  }

  .c-subnav__link {
    font-size: 1rem;
    padding: rpx(8) 0;
    text-transform: none;

    &:hover {
      text-decoration: none;
    }

    &[disabled]:hover {
      background-color: transparent;
      border-color: transparent;
      color: $gray-c;
      outline: 0;
    }
  }

  .c-subnav__link.is-current {
    border-bottom: rpx(4) solid #FF6028;
  }
</style>
