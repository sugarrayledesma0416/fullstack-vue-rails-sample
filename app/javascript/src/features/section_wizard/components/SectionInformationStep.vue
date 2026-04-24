<template>
  <div>
    <FlashMessages
      :showError="flashMessageState.showError"
      :showNotice="flashMessageState.showNotice" />

    <div class="ns-music-v1  u-pos-rel">
      <AssignmentCopyAlertBox />
      <div class="l-grid">
        <div class="l-col-4">
          <h2 class="c-heading--sm  u-txt-bold">
            Course - {{ datastore.section.course.name }}
          </h2>
        </div>
      </div>

      <SectionNameAndInfo />
      <Expander
        v-if="!config.instAdmin"
        :expanded="datastore.section.showPreview"
        headerTextOpen="Hide Preview"
        headerTextClosed="Preview as Student"
        variant="end"
        class="l-col-9  u-mar-bot-10"
        :class="testClass('student-preview-link')"
        @click.stop="toggleStudentPreviewVisibility()">
        <div id="studentPreview">
          <StudentPreview />
        </div>
      </Expander>
      <SectionDetails />
      <Schedule
        :remainingTimeZones="remainingTimeZones"
        :timeZones="timeZones" />

      <ClassDays />

      <SectionInstructor v-if="!config.instAdmin" />

      <SaveAndCancel :loadingImg="loadingImg" />
    </div>
  </div>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import SectionInstructor from './SectionInstructor';
  import StudentPreview from './StudentPreview';
  import SectionDetails from './SectionDetails';
  import Schedule from './Schedule';
  import SaveAndCancel from './SaveAndCancel';
  import ClassDays from './ClassDays';
  import SectionNameAndInfo from './SectionNameAndInfo';
  import FlashMessages from './FlashMessages';
  import AssignmentCopyAlertBox from './AssignmentCopyAlertBox';
  import Expander from 'features/shared/expander/Expander';

  const props = defineProps({
    loadingImg: { required: true, type: String },
    remainingTimeZones: { required: true, type: Array },
    timeZones: { required: true, type: Array },
  });
  const datastore = inject('datastore');
  const config = inject('config');
  const flashMessageState = inject('flashMessageState');

  function toggleStudentPreviewVisibility() {
    datastore.section.showPreview = !datastore.section.showPreview;
    if (datastore.section.showPreview) {
      document.getElementById('studentPreview').focus();
    }
  }
</script>
