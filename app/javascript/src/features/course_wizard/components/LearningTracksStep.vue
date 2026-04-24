<template>
  <div class="learning-tracks-step">
    <StepHeader headingLevel="1" />
    <div class="learning-tracks-step__tracks-container">
      <LearningTrackApp
        :loadingIconPath="loadingIconPath"
        :parentModel="learningTracksStepDataStore" />
      <SetupControls
        :isSaveDisabled="!learningTracksStepDataStore.store.allDueDates ||
          learningTracksStepDataStore.store.allDueDates.length === 0"
        previousStep="express-course-step"
        :showSaveBtn="true"
        @save="learningTracksStepDataStore.expressCreate()" />
    </div>
    <SaveCourseModal
      v-if="learningTracksStepDataStore.jobProgress.shouldShow"
      :jobCompleteMsg="jobCompleteMsg"
      :jobInprogressMsg="jobInprogressMsg"
      :parentModel="learningTracksStepDataStore" />
  </div>
</template>

<script setup>
  import { inject, onMounted, provide } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import LearningTrackApp from 'features/learning_tracks/LearningTrackApp';
  import LearningTracksStepDataStore
    from 'features/course_wizard/models/learning_tracks_step_data_store';
  import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
  import SaveCourseModal from 'features/assignment_wizard/components/SaveCourseModal';
  import SetupControls from './SetupControls';
  import StepHeader from './StepHeader';

  defineProps({
    loadingIconPath: {
      default: '',
      type: String,
    },
  });

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
  const assignmentCalendar = new AssignmentCalendar();

  // LearningTracksStepDataStore shares store and course with courseDataStore
  const learningTracksStepDataStore = new LearningTracksStepDataStore(
    courseDataStore,
    assignmentCalendar,
    config.instAdmin,
    config.programId,
    config.schoolId
  );

  const sectionsCount = learningTracksStepDataStore.store.course.sections?.length;
  const pluralizeSectionText = sectionsCount > 1 ? 'sections' : 'section';
  const jobInprogressMsg = 'Setting up assignments for ' +
    `${sectionsCount} ${pluralizeSectionText}.`;
  const jobCompleteMsg = 'Assignments successfully created for ' +
    `${sectionsCount} ${pluralizeSectionText}`;

  onMounted(() => {
    scrollToTopOfPage();
  });

  provide('assignmentCalendar', assignmentCalendar);
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .learning-tracks-step {
    color: $grey-6;
    font-size: 0.875rem;
    line-height: 1.5;
    text-align: left;
  }
</style>
