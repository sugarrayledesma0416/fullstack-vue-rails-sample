<template>
  <div class="save-course">
    <ModalComponent
      :class="testClass('save-course-modal')"
      :hideHeader="true"
      :hideFooter="true"
      :isConfirmationDialog="true">
      <template #body>
        <div>
          <div
            v-show="!parentModel.jobProgress.isJobComplete"
            class="job-inprogress-msg"
            :class="testClass('job-inprogress-msg')">
            <h3
              class="job-inprogress-msg__heading"
              :class="testClass('job-inprogress-msg__heading')">
              {{ jobInprogressMsg ? jobInprogressMsg : 'Setting up assignments for your course' }}
            </h3>
            <div class="job-inprogress-msg__text" :class="testClass('job-inprogress-msg__text')">
              This will take a few moments.
            </div>
          </div>
          <ProgressBar
            v-if="jobInProgress()"
            class="mar-top-20  width-300"
            :class="testClass('save-course__progressbar')"
            :value="localstore.progressBarValue"
            :label="localstore.progressBarLabel" />
          <div
            v-show="parentModel.jobProgress.isJobComplete"
            class="job-complete-msg"
            :class="testClass('job-complete-msg')">
            <h3 class="job-complete-msg__heading" :class="testClass('job-complete-msg__heading')">
              {{ jobCompleteMsg ? jobCompleteMsg : 'Assignments successfully created!' }}
            </h3>

            <VhlButton
              variant="primary"
              :class="testClass('job-complete-btn')"
              @click="parentModel.returnToDashboard()">
              OK
            </VhlButton>
          </div>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import { reactive, watch } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';
  import ProgressBar from './ProgressBar';
  import VhlButton from 'features/learning_tracks/components/VhlButton';

  /**
   * @typeDef {LocalstoreObject}
   * @type {Object}
   * @property {number} pingInterval
   * @property {number} progressBarValue
   * @property {string} progressBarLabel
   */

  /**
   * @typeDef {ParentModelObject}
   * @type {Object}
   * @property {Object} jobProgress - Job Progress modal instance to
   * store the current state of job.
   */

  /**
   * @typeDef {PropObject}
   * @type {Object}
   * @property {ParentModelObject} parentModel - Vue js reactive object to store parent
   * assignmentWizard model state.
   */

  /**
   * @typeDef {MonitorObject}
   * @type {Object}
   * @property {string} jobId - Id of the job to monitor.
   * @property {Function} status - returns the status of the job.
   */

  /**
   * This monitors the status of a job.
   * @param {LocalstoreObject} localstore - Vue js reactive object to store app state.
   * @param {PropObject} props - Vue js props object.
   */
  async function updateProgress(localstore, props) {
    const jobProgress = props.parentModel.jobProgress;
    const updatedProgress = await jobProgress.updateProgress(localstore.startingValue);
    localstore.progressBarValue = updatedProgress.value;
    localstore.startingValue = updatedProgress.value;
    localstore.progressBarLabel = updatedProgress.label;

    if (!jobProgress.isJobComplete) {
      await updateProgress(localstore, props);
    }
  }

  export default {
    name: 'SaveCourseModal',
    components: { ModalComponent, ProgressBar, VhlButton },
    props: {
      jobCompleteMsg: { default: '', type: String },
      jobInprogressMsg: { default: '', type: String },
      parentModel: { required: true, type: Object },
    },
    setup(props) {
      const localstore = reactive({
        pingInterval: 1000,
        progressBarValue: 0,
        progressBarLabel: '0%',
        startingValue: 0,
      });

      watch(
        () => props.parentModel.jobProgress.jobIds,
        (newValues) => updateProgress(localstore, props),
        { deep: true }
      );

      return { localstore, testClass };
    },
    methods: {
      jobInProgress: function() {
        return this.parentModel.jobProgress.jobIds.length > 0;
      },
    },
  };
</script>

<style scoped>
  .save-course {
    color: #333;
    font-size: 0.875rem;
    line-height: 1.5714285714;
  }

  .job-inprogress-msg__heading {
    color: #969696;
    font-size: 16px;
    font-weight: normal;
    margin: 0 0 1rem;
    padding: 0;
  }

  .job-inprogress-msg__text {
    margin: 0;
    padding: 0;
  }

  .job-complete-msg {
    margin-top: 1.125rem;
    text-align: center;
  }

  .job-complete-msg__heading {
    color: #969696;
    font-size: 1rem;
    font-weight: normal;
    margin-bottom: 50px;
  }

  .mar-top-20 {
    margin-top: 1.25rem;
  }

  .width-300 {
    width: 18.75rem;
  }
</style>
