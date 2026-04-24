<template>
  <!--
    Note: Most of vue refs below are used for test cases to
    identify specific custom components eg Expandable/ VhlCheckbox etc.
  -->
  <div class="due-dates-step">
    <VhlPanel
      :class="testClass('due-dates-step-panel')"
      featureVariant="learning-tracks"
      :hideFooter="true"
      :hideBodyPadding="!learningTrackData.store.expandDueDatesStep"
      :state="learningTrackData.state(2)">
      <template #header>
        <span
          class="due-dates-step__header"
          :class="testClass('due-dates-step-header')">
          Step 3: Set assignment due dates and settings
        </span>
      </template>
      <template #body>
        <Expandable
          ref="ref-expandable-step-content"
          :expand="learningTrackData.store.expandDueDatesStep">
          <img
            v-show="parentDataStore.loadingLearningTracks"
            :src="SpinnerImage"
            class="due-dates-step__loading-spinner"
            :class="testClass('loading-spinner-tracks')">
          <div :class="testClass('due-dates-step-content')">
            <div class="basic-settings-container">
              <h3 class="basic-settings__heading">
                Due Dates
              </h3>
              <p class="mar-bot-24">
                <!-- eslint-disable vue/no-v-model-argument -->
                <VhlCheckbox
                  v-for="(day, index) in parentDataStore.daysOfWeek"
                  :id="`dueDay${index}`"
                  :key="day.name"
                  :ref="`ref-due-day-${index}`"
                  v-model:checked="day.selected"
                  class="due-day-checkbox"
                  :testSelectorLabel="`due-day-label-${index}`"
                  :disabled="parentDataStore.disableAllControls">
                  {{ day.name }}
                </VhlCheckbox>
                <!-- eslint-enable vue/no-v-model-argument -->
              </p>
            </div>
            <InfoMessage
              v-show="config.instAdmin"
              v-if="selectedDaysCount !== learningTrackData.store.selectedSectionClassDaysCount && !learningTrackData.store.VOL"
              iconVariant="c-flash-banner__icon--warning"
              message="The selected due days will result in fewer due dates than the course selected. 
                  To continue, select a different course in Step 1, select different due days above, 
                  or select how you want the assignments distributed below."
              backgroundColor="rgba(255, 235, 203, 0.50)"
            />
            <Expandable
              ref="ref-expandable-advanced-settings"
              :expand="localStore.showDueDateOptions">
              <div
                class="advanced-settings-container"
                :class="testClass('due-dates-options')">
                <div class="advanced-settings__heading">
                  <h3 class="advanced-settings__heading-text">
                    Assignment Distribution Options
                  </h3>
                  <VhlButton
                    variant="circle"
                    featureVariant="learning-tracks"
                    :class="testClass('more-information')"
                    title="More information"
                    @click="localStore.showOptionsInfoModal = true">
                    <span class="no-visual">
                      More Information
                    </span>
                    ?
                  </VhlButton>
                  <ModalComponent
                    v-if="localStore.showOptionsInfoModal"
                    :hideHeader="true"
                    :hideFooter="true"
                    @close="localStore.showOptionsInfoModal = false">
                    <template #body>
                      <p>
                        Selecting these options ensures that assignment content
                        is distributed as evenly as possible across due dates.
                      </p>
                    </template>
                  </ModalComponent>
                </div>
                <!-- eslint-disable vue/no-v-model-argument -->
                <div class="mar-bot-4" v-if="!parentDataStore.usingPredefinedTrack">
                  <VhlCheckbox
                    id="respect_due_dates"
                    ref="ref-respect-due-dates"
                    v-model:checked="parentDataStore.respectDueDates"
                    :disabled="parentDataStore.usingPredefinedTrack ||
                      parentDataStore.disableAllControls">
                    Keep assignments grouped as they were in my existing course.
                  </VhlCheckbox>
                </div>
                <div class="mar-bot-4">
                  <VhlCheckbox
                    id="allow_multiple_lessons_on_dates"
                    ref="ref-multiple-lessons-on-same-date"
                    v-model:checked="learningTrackData.store.allowMultipleLessonsOnDates"
                    :disabled="parentDataStore.respectDueDates ||
                      parentDataStore.disableAllControls">
                    Allow assignments from more than one lesson to occur
                    on the same due date.
                  </VhlCheckbox>
                </div>
                <div class="mar-bot-4">
                  <VhlCheckbox
                    id="break_strand_across_dates"
                    ref="ref-break-strand-across-dates"
                    v-model:checked="learningTrackData.store.breakStrandAcrossDates"
                    :disabled="parentDataStore.disableAllControls ||
                      parentDataStore.respectDueDates">
                    Allow assignments from one section within a lesson
                    to be split across multiple due dates.
                  </VhlCheckbox>
                </div>
                <div class="mar-bot-4">
                  <VhlCheckbox
                    id="break_group_across_dates"
                    ref="ref-break-group-across-dates"
                    v-model:checked="learningTrackData.store.breakGroupAcrossDates"
                    :disabled="!learningTrackData.store.breakStrandAcrossDates ||
                      parentDataStore.disableAllControls ||
                      parentDataStore.respectDueDates">
                    Allow assignments from one learning group within
                    a section of a lesson to be split across multiple due dates.
                  </VhlCheckbox>
                </div>
                <!-- eslint-enable vue/no-v-model-argument -->
              </div>
            </Expandable>
            <p class="options-toggler-container">
              <VhlLink
                href="javascript://"
                featureVariant="learning-tracks"
                :class="testClass('toggle-due-dates-options')"
                @click="toggleShowDueDateOptions()">
                {{ localStore.showDueDateOptions ? 'Hide Options' : 'Show Options' }}
              </VhlLink>
            </p>
          </div>
        </Expandable>
      </template>
    </VhlPanel>
  </div>
</template>

<script>
  import { inject, reactive, computed } from 'vue';
  import InfoMessage from './InfoMessage';
  import { testClass } from 'music';
  import SpinnerImage from 'images/loading_32.gif';
  import ModalComponent from 'features/modal/ModalComponent';
  import VhlPanel from 'features/learning_tracks/components/VhlPanel';
  import VhlButton from 'features/learning_tracks/components/VhlButton';
  import Expandable from './Expandable';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';

  export default {
    name: 'DueDatesStep',
    components: { Expandable, InfoMessage, ModalComponent, VhlButton, VhlCheckbox, VhlLink, VhlPanel },
    setup() {
      const config = inject('config');
      const localStore = reactive({
        showDueDateOptions: config.instAdmin ? true : false,
        showOptionsInfoModal: false,
      });
      const learningTrackData = inject('learningTrackData');

      const parentDataStore = learningTrackData.parentDataStore;

      const selectedDaysCount = computed(() => {
        return Array.isArray(parentDataStore.daysOfWeek)
        ? parentDataStore.daysOfWeek.filter(day => day.selected).length
        : 0;
      })

      const toggleShowDueDateOptions = () => {
        localStore.showDueDateOptions = !localStore.showDueDateOptions;
      };

      return {
        config,
        learningTrackData,
        localStore,
        parentDataStore,
        selectedDaysCount,
        SpinnerImage,
        testClass,
        toggleShowDueDateOptions,
      };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $font-size-sm: 0.875rem;
  $font-size-step-heading: 1.125rem;
  $grey-threes: #333;

  .due-dates-step {
    color: #666;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .due-dates-step__header {
    font-size: $font-size-step-heading;
    font-weight: normal;
  }

  .due-dates-step__loading-spinner {
    margin-left:30px;
  }

  .basic-settings-container {
    margin: rpx(4);
  }

  .basic-settings__heading {
    color: $grey-threes;
    font-size: $font-size-sm;
    font-weight: bold;
    margin-bottom: mod(0.5);
  }

  .due-day-checkbox {
    margin-right: rpx(16);
  }

  .advanced-settings-container {
    margin: rpx(4);
    margin-bottom: rpx(6);
    margin-top: rpx(20);
  }

  .options-toggler-container{
    margin: rpx(4);
    text-align: right;
  }

  .advanced-settings__heading {
    align-items: center;
    display: flex;
    justify-content: flex-start;
  }

  .advanced-settings__heading-text {
    color: $grey-threes;
    font-size: $font-size-sm;
    font-weight: bold;
    margin-bottom: 0rem;
    margin-right: rpx(16);
  }

  .more-information-button {
    margin-bottom: 0rem;
    margin-right: rpx(16);
  }

  .mar-bot-4 {
    margin-bottom: rpx(4);
  }

  .mar-bot-24 {
    margin-bottom: rpx(24);
  }

  .no-visual {
    @include screen-reader-only();
  }
</style>
