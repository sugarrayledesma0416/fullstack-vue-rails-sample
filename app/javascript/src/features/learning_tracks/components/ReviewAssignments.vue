<template>
  <div class="review-assignment">
    <VhlPanel
      :class="testClass('review-assignment-panel')"
      featureVariant="learning-tracks"
      :hideFooter="true"
      :hideBodyPadding="!learningTrackData.store.expandReviewAssignmentsStep"
      :state="learningTrackData.state(3)">
      <template #header>
        <div class="review-assignment__header">
          <span class="review-assignment__heading">
            Step 4: Review, modify, and generate assignments
          </span>
        </div>
      </template>

      <template #body>
        <Expandable :expand="learningTrackData.store.expandReviewAssignmentsStep">
          <img
            v-show="learningTrackData.parentDataStore.loadingLearningTracks"
            :src="loadingIconPath"
            class="review-assignment__loading-spinner"
            :class="testClass('loading-spinner')">

          <div class="review-assignment__summary">
            <div
              v-if="learningTrackData.store.learningTracks"
              class="summary-hours  mar-lt-0  mar-rt-8"
              :class="testClass('activities-per-lesson')">
              {{ learningTrackData.activitiesPerLesson }}
            </div>
            <div class="summary-label  mar-lt-0  mar-rt-8">
              Average assignments <br>per lesson
            </div>
            <div
              v-if="learningTrackData.store.learningTracks"
              class="summary-hours  mar-lt-16  mar-rt-8"
              :class="testClass('assignments-per-lesson')">
              {{ learningTrackData.averageWorkHoursPerLesson }}
            </div>
            <div class="summary-label  mar-lt-0  mar-rt-0">
              Average hours of <br>work per due date
            </div>
          </div>
          <div
            v-if="learningTrackData.workLoad"
            v-work-load-graph="learningTrackData.workLoad"
            class="review-assignment__work-load-graph"
            :class="testClass('work-load-graph')" />

          <div
            v-for="(date, index) in learningTrackData.parentDataStore.allDueDates"
            :key="date.label"
            class="review-assignment__due-dates"
            :class="getTestClassesForDueDate(date)">
            <span
              v-if="date.locked"
              class="locked-due-date"
              :class="[
                testClass('due-date-lock'),
                testClass('locked-due-date'),
              ]"
              :title="learningTrackData.isPrevious(date) ? 'Due dates in the past may not ' +
                'be unlocked.' : 'Due date is locked.'"
              @click="learningTrackData.unlockDueDate(date)" />
            <span
              v-if="!date.locked"
              class="unlocked-due-date"
              :class="[
                testClass('due-date-lock'),
                testClass('unlocked-due-date'),
              ]"
              title="Due dates are unlocked."
              @click="learningTrackData.lockDueDate(date)" />
            <!-- eslint-disable vue/no-v-model-argument -->
            <VhlCheckbox
              :id="`due_date_cb_${index}`"
              v-model:checked="date.selected"
              :disabled="date.locked"
              featureVariant="learning-track-due-dates"
              :testSelectorInput="`due-date-cb-${index}`"
              :testSelectorLabel="`due-date-label`">
              {{ date.dayOfWeek }} {{ date.label }}
            </VhlCheckbox>
            <!-- eslint-enable vue/no-v-model-argument -->
            <DueDateGraphComponent
              v-if="learningTrackData.parentDataStore.calendar"
              :calendarObj="learningTrackData.parentDataStore.calendar"
              :date="date"
              :unitLabel="learningTrackData.unitLabel" />
          </div>
          <div
            v-if="showExternalItems()"
            class="u-mar-top-32"
            :class="testClass('external-items')">
            <h1> External Items </h1>
            <div v-for="externalItem in externalItems" :key="externalItem.id" class="u-mar-6">
              {{ externalItem.name }} {{ externalItem.day_id }}
            </div>
          </div>
        </Expandable>
      </template>
    </VhlPanel>
  </div>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';
  import workLoadGraph from '../directives/work_load_graph';
  import DueDateGraphComponent from './DueDateGraphComponent';
  import Expandable from './Expandable';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import VhlPanel from 'features/learning_tracks/components/VhlPanel';

  /**
   * @typedef {
   *  import('features/learning_tracks/models/due_date_updater.js').DueDateType
   * } DueDateType
   */

  export default {
    name: 'ReviewAssignments',
    components: { DueDateGraphComponent, Expandable, VhlCheckbox, VhlPanel },
    directives: { 'work-load-graph': workLoadGraph },
    props: {
      loadingIconPath: { required: true, type: String },
    },
    setup() {
      const learningTrackData = inject('learningTrackData');
      const externalItems = computed(() => {
        return learningTrackData.parentModel.store.externalItems;
      });

      /**
       * @private
       * @return {boolean} whether there are external items to show or not
       */
      function showExternalItems() {
        return externalItems.value && externalItems.value.length > 0;
      }

      /**
       * Return list of test classes for due date wrapper element
       * @param {DueDateType} date
       * @return {Array.<string>} - List of test classes
       */
      function getTestClassesForDueDate(date) {
        const classes = [testClass('due-dates')];
        if (!date.locked) {
          classes.push(testClass('unlocked-due-date-wrapper'));
        }
        return classes;
      }

      return {
        externalItems,
        getTestClassesForDueDate,
        learningTrackData,
        showExternalItems,
        testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>
  .review-assignment {
    color: #666;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .review-assignment__heading {
    font-size: 1.125rem;
    font-weight: normal;
  }

  .review-assignment__loading-spinner {
    display: block;
    margin: 0 auto 1rem;
  }

  .review-assignment__summary {
    align-items: center;
    display: flex;
    justify-content: flex-start;
  }

  .review-assignment__summary .summary-hours {
    font-size: 2.625rem;
    margin-bottom: 0;
  }

  .review-assignment__summary .summary-label {
    display: inline-block;
  }

  .review-assignment__work-load-graph {
    margin-bottom: 0.3125rem;
    margin-left: 8.125rem;
    margin-top: 0.9375rem;
    overflow: hidden;
    position: relative;
  }

  .review-assignment__due-dates {
    margin-bottom: 0.4375rem;
    position: relative;
  }

  .locked-due-date, .unlocked-due-date {
    background: url(/images/lock.png) no-repeat 0 0.0625rem;
    cursor: pointer;
    display: inline-block;
    height: 0.9375rem;
    margin-right: 0.125rem;
    vertical-align: middle;
    width: 0.625rem;
  }

  .unlocked-due-date {
    background-position: 0 -1rem;
  }

  .mar-rt-0 {
    margin-right: 0;
  }

  .mar-rt-8 {
    margin-right: 0.5rem;
  }

  .mar-lt-0 {
    margin-left: 0;
  }

  .mar-lt-16 {
    margin-left: 1rem;
  }

  .warn-changes-button {
    float: right;
    margin-bottom: 0.625rem;
  }

  .review-assignment::v-deep(.cw-axis) {
    text {
      color: #A6A6A6;
      font-size: 0.625rem;
      text-anchor: end !important;
    }

    path, line {
      fill: none;
      shape-rendering: crispEdges;
      stroke: #a6a6a6;
    }
  }
</style>

