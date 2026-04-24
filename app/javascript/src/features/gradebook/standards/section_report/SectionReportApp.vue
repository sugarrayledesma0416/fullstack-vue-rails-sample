<template>
  <div
    :class="{
      'section-report': !singleRowStandardData,
      'section-standard-detail-report': singleRowStandardData
    }">
    <div class="report-container  container-fluid  u-mar-top-24">
      <template v-if="singleRowStandardData === null">
        <SectionSummaryTable
          :filtersData="props.filtersData"
          :sortReportPath="props.sortReportPath"
          :standardsAssigningUrl="props.standardsAssigningUrl"
          :tableCaption="standardTableCaption"
          :tableData="props.sectionReportData"
          :unitId="props.sectionReportData?.unit_id"
          @showStandardSingleRow="showStandardSingleRow($event)" />
      </template>
      <template v-else>
        <SectionSummaryTable
          :isSingleRow="true"
          :standardsAssigningUrl="props.standardsAssigningUrl"
          :tableCaption="standardTableCaption"
          :tableData="singleRowStandardData"
          :unitId="props.sectionReportData?.unit_id" />
        <div
          v-if="props.sectionReportData?.student_count"
          class="container-fluid  u-bg-white u-pad-top-16">
          <h1 class="u-students-heading  u-txt-ctr">
            Students
          </h1>
          <p class="u-txt-ctr  u-mar-bot-24  u-txt-gray-6">
            No students enrolled in this section yet. Go <br>
            to Enroll to see your student data below.
          </p>
          <div class="c-button-group  c-button-group--ctr  u-pad-bot-24">
            <a
              id="go-to-enroll"
              :class="[
                'go-to-enrroll-button',
                testClass('go-to-enroll-link')]"
              :href="props.newInstructorEnrollmentPath">
              Go to Enroll
            </a>
          </div>
        </div>
        <template v-else>
          <SectionSummaryTable
            v-if="studentReportData"
            :filtersData="props.filtersData"
            :sortReportPath="props.sortReportPath"
            :standardsLandingPagePath="props.standardsLandingPagePath"
            :standardId="singleRowStandardData?.report_rows.data[0].id"
            :studentReportDataPath="props.studentReportDataPath"
            :tableCaption="studentTableCaption"
            :tableData="studentReportData"
            :unitId="props.sectionReportData?.unit_id"
            tableType="student"
            class="student-report-summary-table"
            @openReviewItems="$emit('openReviewItems',$event)" />
        </template>
      </template>
    </div>
  </div>
</template>
<script setup>
  import { testClass } from 'music';
  import { ref, watch } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import SectionSummaryTable from './SectionSummaryTable';
  import useSectionReportFilterStore from './../section_report_filters/stores/use_section_report_filter_store';

  const props = defineProps({
    filtersData: {
      require: true,
      type: Object,
      default: function() {
        return {};
      },
    },
    newInstructorEnrollmentPath: { required: true, type: String },
    sectionReportData: {
      require: true,
      type: Object,
      default: function() {
        return {};
      },
    },
    standardsAssigningUrl: { required: true, type: String },
    studentReportDataPath: { type: String, required: true },
    sortReportPath: { type: String, required: true },
    standardsLandingPagePath: { type: String, required: false, default: '' },
  });

  const store = useSectionReportFilterStore();
  const singleRowStandardData = ref(null);
  const studentReportData = ref(null);
  const standardTableCaption = 'This table shows a section-level performance report for one or more standards in your selected assessment, unit, section and standards.';
  const studentTableCaption = 'This table shows a student-level performance report for a standard in your selected assessment, unit, section and standards.';
  const emit = defineEmits(['showFiltersSection']);

  watch(() => props.sectionReportData, (newValue) => {
    singleRowStandardData.value = null;
    studentReportData.value = null;
  });

  /**
   * Show standard selected standard data and hide filters section.
   * @param {Object} standardData
   */
  function showStandardSingleRow(standardData) {
    singleRowStandardData.value = standardData;
    getStudentData(standardData?.report_rows.data[0].id);
    emit(
      'showFiltersSection',
      { is_active: false, standard_id: singleRowStandardData.value?.report_rows.data[0].id }
    );
  }

  /**
   * Get students info by standard.
   * @param {String} standardId
   */
  function getStudentData(standardId) {
    const simpleSortReportPath = props.sortReportPath.split('?')[0];
    ajaxUtils.postToEndpoint(
      simpleSortReportPath,
      {
        assessment_ids: props.filtersData?.assessment_ids,
        direction: 'desc',
        lesson_id: props.filtersData?.lesson_id,
        sort: 'student',
        standard_id: standardId,
        standard_set_display_name: props.filtersData?.standard_set_display_name,
        assessment_type: props.filtersData?.assessment_type,
      },
      (response) => {
        studentReportData.value = response.assessments;
      }
    );
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .go-to-enrroll-button {
    padding: rpx(10) rpx(24);
    border: rpx(1) solid $orange;
    color: $orange;
    font-weight: bold;
    text-transform: uppercase;
  }

  .report-container {
    margin-left: rpx(24);
  }


  .section-report {
    width: 84%;
  }

  .section-standard-detail-report {
    margin-left: auto;
    margin-right: auto;

    .report-container {
      margin-left: 0;
      padding-right: rpx(160);
    }
  }

  .student-report-summary-table{
    margin: 2rem auto 0;
  }
</style>
