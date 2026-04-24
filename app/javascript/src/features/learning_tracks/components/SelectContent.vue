<template>
  <VhlPanel
    class="select-content__main"
    :class="testClass('select-content-main')"
    featureVariant="learning-tracks"
    :hideFooter="true"
    :hideBodyPadding="!learningTrackData.store.expandSelectContentStep"
    :state="learningTrackData.state(1)">
    <template #header>
      <span
        class="select-content__selected-track"
        :class="testClass('select-content-header')">
        Step 2: Set the content available to assign
      </span>
    </template>

    <template #body>
      <Expandable :expand="learningTrackData.store.expandSelectContentStep">
        <div>
          <h3 class="select-content__course-track-substep  mar-4">
            Lessons
          </h3>
          <div class="select-content__track-settings">
            <div class="select-content__tracks">
              <label
                class="select-content__dropdown-label"
                for="dropdown-step2-lesson-start">
                From lesson
              </label>
              <!-- eslint-disable vue/no-v-model-argument -->
              <BasicSelect
                id="dropdown-step2-lesson-start"
                v-model:modelValue="learningTrackData.parentDataStore.unitRange.firstUnitIndex"
                class="select-content__dropdown"
                testSelector="range-start"
                :options="prepareSelectOptions(
                  { value: '', text: 'Choose a Lesson' },
                  learningTrackData.store.units
                )"
                :isDisabled="learningTrackData.parentDataStore.disableAllControls" />
              <!-- eslint-enable vue/no-v-model-argument -->

              <label
                class="select-content__dropdown"
                for="dropdown-step2-lesson-end">
                to
              </label>
              <!-- eslint-disable vue/no-v-model-argument -->
              <BasicSelect
                id="dropdown-step2-lesson-end"
                v-model:modelValue="learningTrackData.parentDataStore.unitRange.lastUnitIndex"
                class="select-content__dropdown"
                testSelector="range-end"
                :options="prepareSelectOptions(
                  { value: '-1', text: 'Choose a Lesson' },
                  learningTrackData.store.units
                )"
                :isDisabled="learningTrackData.parentDataStore.disableAllControls" />
              <!-- eslint-enable vue/no-v-model-argument -->
            </div>
          </div>
        </div>

        <Expandable :expand="localStore.showLessonOptions">
          <div
            :class="testClass('lesson-options')">
            <div class="select-content__lesson-options">
              <div class="select-content__included-sections">
                <h4
                  class="select-content__course-track-substep"
                  :class="testClass('track-substep')">
                  Strands included
                </h4>
                <div
                  class="select-content__strand-container"
                  :class="testClass('strand-names')">
                  <div
                    v-for="(strand, index) in orderStrandsByName"
                    :key="index"
                    class="select-content__strand  mar-bot-4">
                    <!-- eslint-disable vue/no-v-model-argument -->
                    <VhlCheckbox
                      :id="`strand${index}`"
                      v-model:checked="strand.selected"
                      :testSelectorLabel="`strand-${index}`"
                      :disabled="learningTrackData.parentDataStore.disableAllControls">
                      <span
                        class="select-content__strand-block"
                        :style="`border-color: ${strand.color}`">
                        &nbsp;
                      </span>
                      <!-- eslint-disable vue/no-v-html -->
                      <span
                        class="u-pad-rt-16"
                        :class="testClass('strand-name')"
                        v-html="removeBrTags(strand.name)" />
                      <!-- eslint-enable vue/no-v-html -->
                    </VhlCheckbox>
                    <!-- eslint-enable vue/no-v-model-argument -->
                  </div>
                </div>
              </div>

              <div class="select-content__included-activity-type">
                <h4 class="select-content__course-track-substep">
                  Activity types included
                </h4>

                <div class="mar-bot-4" :class="testClass('activity-type')">
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <VhlCheckbox
                    id="include_instructor_graded_activities"
                    v-model:checked="
                      learningTrackData.parentDataStore.includeInstructorGradedActivities"
                    testSelectorLabel="instructor-graded-activities"
                    :disabled="learningTrackData.parentDataStore.disableAllControls">
                    Instructor-graded
                  </VhlCheckbox>
                  <!-- eslint-enable vue/no-v-model-argument -->
                </div>

                <div class="mar-bot-4" :class="testClass('activity-type')">
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <VhlCheckbox
                    id="include_microphone_activities"
                    v-model:checked="learningTrackData.parentDataStore.includeMicrophoneActivities"
                    testSelectorLabel="include-microphone-activities"
                    :disabled="learningTrackData.parentDataStore.disableAllControls">
                    Microphone required
                  </VhlCheckbox>
                  <!-- eslint-enable vue/no-v-model-argument -->
                </div>

                <div class="mar-bot-4" :class="testClass('activity-type')">
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <VhlCheckbox
                    id="include_partner_activities"
                    v-model:checked="learningTrackData.parentDataStore.includePartnerActivities"
                    testSelectorLabel="include-partner-activities"
                    :disabled="learningTrackData.parentDataStore.disableAllControls">
                    Partner required
                  </VhlCheckbox>
                  <!-- eslint-enable vue/no-v-model-argument -->
                </div>
              </div>
            </div>
          </div>
        </Expandable>

        <div class="select-content__display-lesson">
          <VhlLink
            href="javascript://"
            featureVariant="learning-tracks"
            testSelector="toggle-lesson-options"
            @click="toggleShowLessonOptions()">
            {{ localStore.showLessonOptions ? 'Hide options' : 'Show options' }}
          </VhlLink>
        </div>
      </Expandable>
    </template>
  </VhlPanel>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { slice } from 'lodash';
  import { testClass } from 'music';
  import Expandable from './Expandable';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import VhlPanel from 'features/learning_tracks/components/VhlPanel';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';

  export default {
    name: 'SelectContent',
    components: { Expandable, VhlCheckbox, VhlLink, VhlPanel, BasicSelect },
    setup() {
      const localStore = reactive({
        showLessonOptions: false,
      });
      const learningTrackData = inject('learningTrackData');

      /**
       * @typeDef {defaultOptionObject}
       * @property {string} value - value for the default option tag.
       * @property {string} text - text for the default option tag.
       */

      /**
       * Prepare options data for the select tag.
       * @param {defaultOptionObject} defaultOption
       * @param {Array} existingData - This can be any type of data which is used to transform
       * to the required format.
       * @return {Array.<defaultOptionObject>} options
       */
      function prepareSelectOptions(defaultOption, existingData) {
        const options = [{ value: defaultOption.value, text: defaultOption.text }];
        existingData?.forEach((data) => {
          options.push({ value: data.index, text: data.label });
        });
        return options;
      }

      const toggleShowLessonOptions = () => {
        localStore.showLessonOptions = !localStore.showLessonOptions;
      };

      return {
        learningTrackData,
        localStore,
        prepareSelectOptions,
        testClass,
        toggleShowLessonOptions,
      };
    },
    computed: {
      orderStrandsByName() {
        return slice(this.learningTrackData.parentDataStore.strands).sort(this.alphaNumSort);
      },
    },
    methods: {
      alphaNumSort(a, b) {
        return a.name.localeCompare(b.name, undefined, { numeric: true });
      },
      removeBrTags(value) {
        if (!value) return '';
        value = value.toString();
        return value.replace(/<br\s*\/?>/g, '');
      },
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .select-content__course-track-substep {
    color: #333;
    font-size: 0.875rem;
    font-weight: bold;
    margin-bottom: 0.5rem;
  }

  .select-content__display-lesson {
    margin: rpx(4);
    text-align: right;
  }

  .select-content__dropdown {
    margin-right: 0.5rem;
  }

  .select-content__dropdown-label {
    border: 0;
    clip: rect(0 0 0 0);
    height: 0.06rem;
    margin: -0.06rem;
    margin-right: 0.5rem;
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: 0.06rem;
  }

  .select-content__included-activity-type {
    border-left: 0.06rem dashed #999;
    box-sizing: border-box;
    float: none;
    padding: 0;
    padding-left: 1rem;
    width: column-width(4);
  }

  .select-content__included-sections {
    box-sizing: border-box;
    float: none;
    padding: 0;
    width: column-width(8);
  }

  .select-content__lesson-options {
    align-items: stretch;
    box-sizing: border-box;
    display: flex;
    margin: rpx(4);
  }

  .select-content__main {
    color: #666;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .select-content__selected-track {
    font-size: 1.125rem;
    font-weight: normal;
  }

  .select-content__strand {
    line-height: 1.5;
    white-space: nowrap;
  }

  .select-content__strand-block {
    border: 0;
    border-left-width: 0.313rem;
    border-style: solid;
    display: inline-block;
  }

  .select-content__strand-container {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap;
  }

  .select-content__tracks {
    align-items: center;
    display: flex;
    justify-content: flex-start;
    margin-bottom: 1.5rem;
  }

  .select-content__track-settings {
    margin: rpx(4);
    vertical-align: bottom;
  }

  .mar-4 {
    margin: rpx(4);
  }

  .mar-bot-4 {
    margin-bottom: rpx(4);
  }
</style>
