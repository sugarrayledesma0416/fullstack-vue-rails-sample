<template>
  <div class="predefined-tracks__main">
    <!-- eslint-disable vue/no-v-html -->
    <h3
      class="predefined-tracks__header"
      :class="testClass('setup-header')"
      v-html="learningTrackData.setupTracks.header" />

    <p
      class="predefined-tracks__setup-description"
      :class="testClass('setup-general')"
      v-html="learningTrackData.setupTracks.general" />
    <!-- eslint-enable vue/no-v-html -->

    <div class="predefined-tracks__flush-content">
      <VhlExpander
        v-for="(trackName, index) in learningTrackData.store.predefinedTrackNames"
        :key="trackName"
        class="predefined-tracks__track"
        :class="testClass(`predefined-track-${index}`)"
        :headerText="trackName">
        <div class="predefined-tracks__track-content">
          <div class="predefined-tracks__track-description">
            <!-- eslint-disable vue/no-v-html -->
            <div
              :class="testClass('template-description')"
              v-html="learningTrackData.store.predefinedTracks.tracks[trackName].description" />
            <!-- eslint-enable vue/no-v-html -->
          </div>
          <div class="predefined-tracks__select-buttons">
            <div
              class="predefined-tracks__select-track"
              :class="{
                'predefined-tracks__conditional':
                  learningTrackData.preDefinedSubtrackLength(trackName) < 2
              }">
              <VhlButton
                v-for="(subtrackName, btnIndex) in subtrackMenuObjs[trackName].subtrackNames"
                :key="btnIndex"
                class="predefined-tracks__button"
                :class="testClass(`select-${subtrackName}-${btnIndex}`)"
                featureVariant="learning-tracks"
                @click="subtrackMenuObjs[trackName].chooseSubtrack(
                  subtrackName, btnIndex, learningTrackData
                )">
                Select {{ subtrackName }}
              </VhlButton>
            </div>

            <div v-if="learningTrackData.preDefinedSubtrackLength(trackName) > 1">
              <VhlButton
                :class="testClass(`track-help-model-${index}`)"
                class="predefined-tracks__button"
                featureVariant="learning-tracks"
                title="More information"
                variant="circle"
                @click="showTrackHelpModal">
                <span class="predefined-tracks__more-info">
                  More Information
                </span>
                ?
              </VhlButton>
            </div>
          </div>
        </div>
      </VhlExpander>
      <ModalComponent
        v-if="localstore.showHelpModal"
        :title="`${learningTrackData.setupTracks.options[0].label}
          vs. ${learningTrackData.setupTracks.options[1].label}`"
        @close="hideTrackHelpModal">
        <template #body>
          <!-- eslint-disable vue/no-v-html -->
          <p
            class="predefined-tracks__overall-options"
            :class="testClass('setup-options-overall')"
            v-html="learningTrackData.setupTracks.options_overall" />
          <!-- eslint-enable vue/no-v-html -->
          <p
            v-for="option in learningTrackData.setupTracks.options"
            :key="option">
            <strong>
              {{ option.label }}
            </strong> &mdash;
            <!-- eslint-disable vue/no-v-html -->
            <span v-html="option.explanation" /><br>
            <!-- eslint-enable vue/no-v-html -->
          </p>
        </template>
      </ModalComponent>
    </div>
  </div>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';
  import SubtrackMenu from './../models/subtrack_menu';
  import VhlButton from 'features/learning_tracks/components/VhlButton';
  import VhlExpander from './VhlExpander';

  const usePredefinedTracks = function(localstore, learningTrackData) {
    /**
     * This method updates localstore to hide help modal
     */
    function hideTrackHelpModal() {
      localstore.showHelpModal = false;
    }

    /**
     * This method updates localstore to show help modal.
     */
    function showTrackHelpModal() {
      localstore.showHelpModal = true;
    }

    /**
     * It returns the subbtrack menu object associated with all track.
     * @return {object} subtrackMenu Object.
     */
    function fetchSubtrackMenuObjs() {
      const output = {};
      learningTrackData.store.predefinedTrackNames.forEach((trackName) => {
        output[trackName] = new SubtrackMenu(
          trackName,
          learningTrackData.store.predefinedTracks.tracks[trackName],
          learningTrackData.store.allStrands,
          learningTrackData.store.trackTabs
        );
      });

      return output;
    }

    return { fetchSubtrackMenuObjs, hideTrackHelpModal, showTrackHelpModal };
  };

  export default {
    name: 'PreDefinedTracks',
    components: { ModalComponent, VhlButton, VhlExpander },
    setup() {
      const localstore = reactive({
        showHelpModal: false,
      });
      const learningTrackData = inject('learningTrackData');
      const {
        fetchSubtrackMenuObjs, hideTrackHelpModal, showTrackHelpModal,
      } = usePredefinedTracks(localstore, learningTrackData);
      const subtrackMenuObjs = fetchSubtrackMenuObjs();

      return {
        hideTrackHelpModal,
        learningTrackData,
        localstore,
        showTrackHelpModal,
        subtrackMenuObjs,
        testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $panel-side-padding: 0.5rem;

  .predefined-tracks__button {
    letter-spacing: 0;
    margin-right: 0.5rem;
  }

  .predefined-tracks__flush-content {
    margin-left: 0 - $panel-side-padding;
    margin-right: 0 - $panel-side-padding;
  }

  .predefined-tracks__header {
    color: #333;
    font-size: 1.125rem;
    margin-bottom: 0.5rem;
  }

  .predefined-tracks__main {
    color: #666;
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .predefined-tracks__more-info {
    border: 0;
    clip: rect(0 0 0 0);
    height: 0.06rem;
    margin: -0.06rem;
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: 0.06rem;
  }

  .predefined-tracks__overall-options {
    margin-bottom: 1rem;
  }

  .predefined-tracks__select-buttons {
    align-items: center;
    background-color: #f4fafe;
    box-sizing: border-box;
    display: flex;
    float: none;
    justify-content: flex-end;
    padding: 0;
    padding-left: 0.5rem;
    width: column-width(4);
  }

  .predefined-tracks__setup-description {
    margin-bottom: 1.5rem;
  }

  .predefined-tracks__track-content {
    align-items: stretch;
    box-sizing: border-box;
    display: flex;
    margin: 0;
  }

  .predefined-tracks__track-description {
    box-sizing: border-box;
    float: none;
    padding: 1rem;
    width: column-width(8);
  }

  .predefined-tracks__track {
    margin-top: 0.125rem;
  }

  .predefined-tracks__select-track {
    justify-content: flex-end;
  }

  .predefined-tracks__conditional {
    margin-right: 0.5rem;
  }
</style>
