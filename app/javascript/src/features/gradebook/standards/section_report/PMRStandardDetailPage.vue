<template>
  <!-- eslint-disable vue/no-multiple-template-root -->
  <div class="lesson-title">
    <h2
      :class="['u-unit-name','u-txt-ctr', 'u-txt-gray-6', 'u-mar-bot-4', testClass('unit-name')]">
      {{ props.lessonName }}
    </h2>
  </div>
  <SectionSummaryTable
    v-if="singlePmrStandardData"
    ref="refSingleStandard"
    class="pmr-single-standard"
    :class="testClass('pmr-single-standard')"
    tableMode="pmrSingleStandard"
    :isSingleRow="true"
    :isPmrSingleRow="true"
    :standardsAssigningUrl="props.standardsAssigningUrl"
    tableCaption="standardTableCaption"
    :tableData="singlePmrStandardData"
    :unitId="props.unitId" />
  <!--
    Following v-if studentCount check needs correction/swap once backend is updated,
    because in existing reports' implementations, studentCount is a boolean
    which is true when student count is zero.
  -->
  <GoToEnroll
    v-if="props.zeroStudentCount"
    :newInstructorEnrollmentPath="newInstructorEnrollmentPath" />
  <template v-else>
    <div class="individual-performance">
      <hr>
      <h3> Individual Performance </h3>
    </div>
    <SectionSummaryTable
      v-if="studentReportData"
      ref="refStudentPerformance"
      class="pmr-students-performance"
      :class="testClass('pmr-students-performance')"
      tableMode="pmrStudents"
      :standardsLandingPagePath="props.standardsLandingPagePath"
      :standardId="standardIdForDetailPage"
      :studentReportDataPath="props.studentReportDataPath"
      :tableData="studentReportData"
      tableType="student"
      :unitId="unitId"
      :courseId="courseId.toString()"
      :programId="programId.toString()"
      :sectionId="sectionId.toString()" />
  </template>
  <!-- eslint-enable vue/no-multiple-template-root -->
</template>

<script setup>
  import { ref } from 'vue';
  import { testClass } from 'music';
  import SectionSummaryTable from './SectionSummaryTable';
  import GoToEnroll from './GoToEnroll';

  const props = defineProps({
    courseId: { required: true, type: Number },
    newInstructorEnrollmentPath: { required: true, type: String },
    programId: { required: true, type: Number },
    lessonName: { required: true, type: String },
    sectionId: { required: true, type: Number },
    singlePmrStandardData: { default: () => {}, type: Object },
    standardIdForDetailPage: { required: true, type: Number },
    standardsAssigningUrl: { required: true, type: String },
    studentReportData: { default: () => {}, type: Object },
    unitId: { default: 0, type: Number },
    zeroStudentCount: { default: false, type: Boolean },
  });

  const refSingleStandard = ref(null);
  const refStudentPerformance = ref(null);
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .individual-performance {
    width: 100%;
    text-align: center;
  }

  .pmr-students-performance {
    width: 55%;
  }

  .pmr-single-standard {
    width: 70%;
  }

  .lesson-title {
    align-self: flex-start;
    left: 0;
    margin-bottom: rpx(30);
    margin-top: rpx(18);
  }

</style>

