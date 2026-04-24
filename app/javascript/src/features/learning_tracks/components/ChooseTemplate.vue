<template>
  <VhlPanel
    class="choose-template__main"
    :class="testClass('choose-template-main')"
    featureVariant="learning-tracks"
    :hideFooter="true"
    :state="learningTrackData.state(0)">
    <template #header>
      <div class="choose-template__step-heading">
        Step 1: Choose an existing course and section
      </div>
    </template>

    <template #body>
      <div class="choose-template">
        <img
          v-if="learningTrackData.parentDataStore.loadingLearningTracks ||
            learningTrackData.store.loadingPreviousTrack"
          :src="loadingIconPath"
          class="choose-template__spinner-tracks"
          :class="testClass('loading-spinner-tracks')">
        <Expandable :expand="learningTrackData.store.expandChooseTemplateAltContent">
          <div class="choose-template__content">
            <div class="choose-template__col-8">
              <p
                class="choose-template__selected-track"
                :class="testClass('selected-track')">
                {{ learningTrackData.parentDataStore.selectedTrackName }}
              </p>
              <p
                v-if="learningTrackData.store.insufficientLicenseGroups"
                class="choose-template__insufficient-license"
                :class="testClass('insufficient-license-grp')">
                Some activities have been filtered out because this course does not
                have the same access levels as the previous one you chose.
              </p>
            </div>
            <div class="choose-template__col-4">
              <p class="choose-template__apply-new-template">
                <VhlLink
                  href="javascript://"
                  featureVariant="learning-tracks"
                  testSelector="template-chooser"
                  :title="learningTrackData.isTemplateChooserDisabled ?
                    templateChangeDisabledMessage : ''"
                  :isDisabled="learningTrackData.isTemplateChooserDisabled"
                  @click="learningTrackData.clickTemplateChooser()">
                  Change course template
                </VhlLink>
              </p>
            </div>
          </div>
        </Expandable>
        <Expandable :expand="learningTrackData.store.expandChooseTemplateStep">
          <div
            v-if="!learningTrackData.parentDataStore.loadingLearningTracks"
            class="mar-4">
            <div>
              <div class="choose-template__select-section">
                <InfoMessage
                  v-show="config.instAdmin"
                  iconVariant="info-blue"
                  message="For the best results, choose a course with the same meeting days and number 
                    of weeks as the current course to align assignment due dates."
                />
                <div
                  v-if="learningTrackData.sectionSourceType === 'section'"
                  class="choose-template__select-section-child"
                  :class="testClass('source-section')">
                  <label
                    class="choose-template__dropdown-label"
                    for="dropdown-step1-choose-course">
                    Choose course
                  </label>
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <BasicSelect
                    id="dropdown-step1-choose-course"
                    v-model:modelValue="learningTrackData.store.selectedCourse"
                    class="choose-template__custom-select"
                    testSelector="previous-courses"
                    :options="prepareSelectOptions(
                      { value: '', text: 'Course' },
                      learningTrackData.config.previous_courses
                    )" />
                  <!-- eslint-enable vue/no-v-model-argument -->

                  <label
                    id="dropdown-step1-choose-section"
                    class="choose-template__dropdown-label">
                    Choose section
                  </label>
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <BasicSelect
                    v-show="learningTrackData.store.selectedCourseIsEnterprise === false"
                    id="dropdown-step1-choose-section"
                    v-model:modelValue="learningTrackData.store.selectedSection"
                    testSelector="previous-sections"
                    :options="prepareSelectOptions(
                      { value: '', text: 'Section' },
                      learningTrackData.store.availableSections
                    )" />
                  <!-- eslint-enable vue/no-v-model-argument -->
                </div>

                <div
                  v-else-if="learningTrackData.sectionSourceType === 'section_template'"
                  class="choose-template__select-section-child"
                  :class="testClass('source-section-template')">
                  <label
                    class="choose-template__dropdown-label"
                    for="dropdown-step1-choose-course-template">
                    Choose course template
                  </label>
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <BasicSelect
                    id="dropdown-step1-choose-course-template"
                    v-model:modelValue="learningTrackData.store.selectedCourse"
                    class="choose-template__custom-select"
                    testSelector="previous-courses"
                    :options="prepareSelectOptions(
                      { value: '', text: 'Course' },
                      learningTrackData.config.previous_course_templates
                    )" />
                  <!-- eslint-enable vue/no-v-model-argument -->

                  <label
                    id="dropdown-step1-choose-section-template"
                    class="choose-template__dropdown-label">
                    Choose section template
                  </label>
                  <!-- eslint-disable vue/no-v-model-argument -->
                  <BasicSelect
                    id="dropdown-step1-choose-section-template"
                    v-model:modelValue="learningTrackData.store.selectedSection"
                    testSelector="previous-sections"
                    :options="prepareSelectOptions(
                      { value: '', text: 'Section' },
                      learningTrackData.store.availableSections
                    )" />
                  <!-- eslint-enable vue/no-v-model-argument -->
                </div>

                <!-- eslint-disable vue/no-v-model-argument -->
                <div class="u-mar-top-10  u-width-full">
                  <div>
                    <VhlCheckbox
                      id="copy_igc"
                      ref="ref-copy-igc"
                      @update:checked="updateCopyIgcState($event)">
                      Copy Instructor-created Activities and Items
                    </VhlCheckbox>
                  </div>
                  <div>
                    <VhlCheckbox
                      id="copy_indiv_assignable"
                      ref="ref-indiv-assignable"
                      @update:checked="updateCopyIacState($event)">
                      Copy Individually Assigned Activities
                      <VhlButton
                        :class="testClass('show-individual-assignment-information-modal')"
                        class="button--individual-assignment-information"
                        featureVariant="learning-tracks"
                        variant="circle"
                        @click="localstore.showIndividualAssignmentInformationModal = true">
                        <MusicIcon variant="info-blue" />
                      </VhlButton>
                    </VhlCheckbox>
                    <ModalComponent
                      v-if="localstore.showIndividualAssignmentInformationModal"
                      title="Individual Assignment Information"
                      @close="localstore.showIndividualAssignmentInformationModal = false">
                      <template #body>
                        <div :class="testClass('show-individual-assignment-information-text')">
                          <p>
                            When copying individually assigned activities to a new section,
                            all students in the section will receive these assignments.
                          </p>
                          <p class="mar-top-16">
                            Copying Group Chat activities will also copy over their settings.
                          </p>
                        </div>
                      </template>
                    </ModalComponent>
                    <!-- eslint-enable vue/no-v-model-argument -->
                  </div>
                  <div
                    v-if="learningTrackData.parentDataStore.showWarningMessage &&
                      learningTrackData.store.selectedSection !== ''"
                    class="u-mar-top-20">
                    <p class="u-txt-red">
                      {{ learningTrackData.parentDataStore.showWarningMessage }}
                    </p>
                  </div>
                  <VhlButton
                    class="u-mar-top-20"
                    :class="testClass('select-existing-section')"
                    :disabled="learningTrackData.store.selectedSection === ''"
                    featureVariant="learning-tracks"
                    @click="learningTrackData.useSectionTrack(
                      assignmentCalendar, config.programId
                    )">
                    Select
                  </VhlButton>
                </div>
              </div>
            </div>

            <div class="choose-template__flush-content">
              <div v-if="learningTrackData.store.VOL" class="choose-template__divider">
                <div class="choose-template__divider-inner">
                  or
                </div>
              </div>
            </div>
            <PreDefinedTracks
              v-if="learningTrackData.store.learningTracks &&
                learningTrackData.store.VOL" />
          </div>
        </Expandable>
      </div>
    </template>
  </VhlPanel>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { isObjEmpty } from 'shared/utils';
  import { testClass } from 'music';
  import PreDefinedTracks from './PreDefinedTracks';
  import InfoMessage from './InfoMessage';
  import Expandable from './Expandable';
  import ModalComponent from 'features/modal/ModalComponent';
  import MusicIcon from 'shared/vue/MusicIcon';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';
  import VhlPanel from 'features/learning_tracks/components/VhlPanel';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import VhlButton from 'features/learning_tracks/components/VhlButton';

  export default {
    name: 'ChooseTemplate',
    components: {
      Expandable,
      InfoMessage,
      PreDefinedTracks,
      ModalComponent,
      MusicIcon,
      VhlCheckbox,
      VhlButton,
      VhlLink,
      VhlPanel,
      BasicSelect,
    },
    props: {
      loadingIconPath: { required: true, type: String },
    },
    setup() {
      const assignmentCalendar = inject('assignmentCalendar');
      const learningTrackData = inject('learningTrackData');
      const config = inject('config');
      const localstore = reactive({
        showIndividualAssignmentInformationModal: false,
      });

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
          const text = data.weeks ? `${data.name} (${data.weeks})` : data.name;
          if (data.enterprise) {
            options.push({ value: data.id, text: `Enterprise: ${text}` });
          } else if (data.template) {
            options.push({ value: data.id, text: `Template: ${text}` });
          } else {
            options.push({ value: data.id, text });
          }
        });
        return options;
      }

      /**
       * @private
       * @param {boolean} event - the value of the checkbox
       * which will be used to decide if IGC is included.
       */
      function updateCopyIgcState(event) {
        assignmentCalendar.copyIgc = event;
      }

      /**
       * @private
       * @param {boolean} event - the value of the checkbox
       * which will be used to decide if IAC is included.
       */
      function updateCopyIacState(event) {
        assignmentCalendar.copyIac = event;
      }
      const templateChangeDisabledMessage =
        'Course template may not be changed if due dates are locked ' +
        'or there are existing assignments.';

      return {
        assignmentCalendar,
        config,
        isObjEmpty,
        learningTrackData,
        localstore,
        prepareSelectOptions,
        templateChangeDisabledMessage,
        testClass,
        updateCopyIgcState,
        updateCopyIacState,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $panel-side-padding: 0.5rem;

  .choose-template {
    padding-bottom: 0rem;
  }

  .choose-template__apply-new-template {
    margin-top: -0.0625rem;
    text-align: right;
  }

  .choose-template__col-8 {
    width: column-width(8);
  }

  .choose-template__col-4 {
    width: column-width(4);
  }

  .choose-template__content {
    align-items: stretch;
    box-sizing: border-box;
    display: flex;
    margin: rpx(4);
  }

  .choose-template__custom-select {
    margin-right: 0.5rem;
  }

  .choose-template__divider {
    background: #ccc;
    height: 0.1875rem;
    margin: 2rem 0;
    text-align: center;
  }

  .choose-template__divider-inner {
    background-color: #fff;
    color: #333;
    display: inline-block;
    font-size: 1.25rem;
    line-height: 1.25rem;
    padding: 0 0.5rem;
    text-transform: uppercase;
    transform: translateY(-50%);
  }

  .choose-template__dropdown-label {
    border: 0;
    clip: rect(0 0 0 0);
    height: 0.0625rem;
    margin: -0.0625rem;
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: 0.0625rem;
  }

  .choose-template__flush-content {
    margin-left: 0 - $panel-side-padding;
    margin-right: 0 - $panel-side-padding;
  }

  .choose-template__insufficient-license {
    margin-bottom: 1rem;
  }

  .choose-template__main {
    color: #666;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .choose-template__section {
    margin-left: 1rem;
  }

  .choose-template__section-template {
    margin-bottom: 1.5rem;
    margin-top: 0.625rem;
  }

  .choose-template__select-section {
    align-items: center;
    display: flex;
    justify-content: flex-start;
    flex-flow: row wrap;
  }

  .choose-template__select-section-child {
    margin-bottom: 0;
    margin-right: 0.5rem;
  }

  .choose-template__selected-track {
    font-size: 1rem;
    text-transform: uppercase;
  }

  .choose-template__spinner-tracks {
    display: block;
    margin: 0 auto 1rem;
  }

  .choose-template__step-heading {
    font-size: 1.125rem;
    font-weight: normal;
  }

  .mar-lt-16 {
    margin-left: 16px;
  }

  .mar-top-16 {
    margin-top: 1rem;
  }

  .mar-4 {
    margin: rpx(4);
  }

  /*
    This rule is overriding the following rule .button--learning-tracks.button--circle
  */
  .button--individual-assignment-information {
    height: 1rem !important;
    width: 1rem !important;
  }
</style>