<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="content-step">
      <StepHeader headingLevel="1" />

      <SettingCategory
        v-if="hasAvailableCoursePackages || courseDataStore.newCourseMode === true"
        class="u-mar-bot-32  with-divider">
        <AccessLevelMessage v-if="hasAvailableCoursePackages" />
        <CopySettings
          v-if="courseDataStore.newCourseMode === true ||
            (courseDataStore.editCourseMode && courseDataStore.store.courseOptions.allow_copy)" />
      </SettingCategory>

      <SettingCategory
        v-if="hasAvailableCoursePackages === false"
        title="Access Level"
        class="u-mar-bot-32  with-divider"
        :class="testClass('access-level')">
        <Levels :class="{'u-mar-bot-16': courseDataStore.store.courseOptions.components.length}" />
        <Components v-if="courseDataStore.store.courseOptions.components.length" />
      </SettingCategory>

      <SettingCategory
        v-if="courseDataStore.store.courseOptions.supported_standard_sets.length"
        title="Standards"
        class="u-mar-bot-32  with-divider">
        <Standards class="u-mar-bot-16" />
        <FormFeedback
          v-if="courseDataStore.courseValidator.hasCourseError('standards').value"
          :class="testClass('standards-validation-error')"
          type="error">
          {{ courseDataStore.courseValidator.hasCourseError('standards').msg }}
        </FormFeedback>
      </SettingCategory>

      <SettingCategory title="Assignment Settings" class="u-mar-bot-32  with-divider">
        <SettingFieldset legend="Assignment Settings" hideLegend>
          <Lessons class="u-mar-bot-16" />
          <Translations
            v-if="config.languageCode !== 'en' && config.hasVocabTutorials"
            class="u-mar-bot-16" />
          <EstimatedTime />
        </SettingFieldset>
      </SettingCategory>

      <SettingCategory title="Assigning Tools" class="u-mar-bot-32  with-divider">
        <SettingFieldset legend="Assigning Tools" hideLegend>
          <IndividualizedAssigning
            :class="{'u-mar-bot-16' : config.canShareToGoogleClassroomForSchool}" />
          <GoogleClassroom
            v-if="config.canShareToGoogleClassroomForSchool" />
        </SettingFieldset>
      </SettingCategory>

      <SettingCategory title="Media Settings" class="u-mar-bot-32  u-pad-bot-0  with-divider">
        Changes can be made in the <b>Student Interaction Settings page</b> after section are created and students are enrolled.
        <ContentSetting title="Defaults" class="u-mar-top-16"></ContentSetting>

        <table class="c-table  c-table--content  u-section-table  u-width-half">
          <tr>
            <td>Video Subtitles and<br>Closed Captions (CC)</td>
            <td>{{ defaultVideoLanguage }}</td>
            <td>
              <VhlLink
                href="javascript://"
                class="u-mar-lt-8"
                testSelector="subtitle-screenshot-link"
                @click="localStore.showSubtitleScreenshot = true">
                See Example
              </VhlLink>
              <Screenshot
                v-if="localStore.showSubtitleScreenshot"
                title="Subtitle Sample Screenshot"
                mode="subtitle"
                @close="localStore.showSubtitleScreenshot = false" />
            </td>
          </tr>
          <tr>
            <td class="u-pad-top-16">Video Transcripts</td>
            <td class="u-pad-top-16">{{ defaultVideoTranscript }}</td>
            <td class="u-pad-top-16">
              <VhlLink
                href="javascript://"
                class="u-mar-lt-8"
                testSelector="transcript-screenshot-link"
                @click="localStore.showTranscriptScreenshot = true">
                See Example
              </VhlLink>
              <Screenshot
                v-if="localStore.showTranscriptScreenshot"
                title="Transcript Sample Screenshot"
                mode="transcript"
                @close="localStore.showTranscriptScreenshot = false" />
            </td>
          </tr>
          <tr>
            <td class="u-pad-top-16">Audio Transcripts</td>
            <td class="u-pad-top-16">{{ allowAudioTranscript }}</td>
            <td class="u-pad-top-16">
              <VhlLink
                href="javascript://"
                class="u-mar-lt-8"
                testSelector="transcript-screenshot-link"
                @click="localStore.showTranscriptScreenshot = true">
                See Example
              </VhlLink>
              <Screenshot
                v-if="localStore.showTranscriptScreenshot"
                title="Transcript Sample Screenshot"
                mode="transcript"
                @close="localStore.showTranscriptScreenshot = false" />
            </td>
          </tr>
        </table>
      </SettingCategory>

      <SettingCategory
        v-if="!config.isCurrentProgramSupersiteJunior"
        title="Student Support Requests"
        class="u-mar-bot-32  with-divider">
        <SettingFieldset
          legend="Settings for which option students may use for support requests."
          hideLegend>
          <HelpRequests class="u-mar-bot-16" />
          <ScoreReviews />
        </SettingFieldset>
      </SettingCategory>

      <SettingCategory
        v-if="!config.isCurrentProgramSupersiteJunior"
        title="Chats"
        class="u-mar-bot-32  with-divider">
        <SettingFieldset
          legend="Settings for how students are able to use the chat feature."
          hideLegend>
          <ChatAvailability />
        </SettingFieldset>
        <SettingFieldset v-if="config.hasAiVirtualChatActivities" legend="AI Chat" hideLegend>
          <VirtualChatAvailability />
        </SettingFieldset>
      </SettingCategory>
    </div>

    <img
      v-if="courseDataStore.store.saving"
      :src="spinnerImage"
      class="save-spinner"
      :class="testClass('save-spinner')">
    <SetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isNextDisabled="isNextButtonDisabled()"
      nextStep="gradebook-step"
      previousStep="advanced-course-step" />
  </div>
</template>

<script setup>
  import { computed, inject, onMounted, onUnmounted, ref, reactive } from 'vue';
  import { testClass } from 'music';
  import { scrollToTopOfPage } from 'shared/utils';
  import { FormFeedback } from 'features/shared/FormElements';
  import SetupControls from '../SetupControls';
  import spinnerImage from 'images/loading_32.gif';
  import StepHeader from '../StepHeader';
  import SettingCategory from './SettingCategory';
  import SettingFieldset from './SettingFieldset';
  import CopySettings from './settings/CopySettings';
  import EstimatedTime from './settings/EstimatedTime';
  import GoogleClassroom from './settings/GoogleClassroom';
  import IndividualizedAssigning from './settings/IndividualizedAssigning';
  import Levels from './settings/Levels';
  import Components from './settings/Components';
  import Lessons from './settings/Lessons';
  import Translations from './settings/Translations';
  import VideoSubtitles from './settings/VideoSubtitles';
  import VideoTranscripts from './settings/VideoTranscripts';
  import HelpRequests from './settings/HelpRequests';
  import ScoreReviews from './settings/ScoreReviews';
  import ChatAvailability from './settings/ChatAvailability';
  import VirtualChatAvailability from './settings/VirtualChatAvailability';
  import AccessLevelMessage from './AccessLevelMessage';
  import Standards from './settings/Standards';
  import ContentSetting from './ContentSetting';
  import VhlLink from '../VhlLink';
  import Screenshot from '../Screenshot';

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
  const disableNextButton = ref(true);

  const localStore = reactive({
    showSubtitleScreenshot: false,
    showTranscriptScreenshot: false,
  });

  const hasAvailableCoursePackages = computed(() => {
    return courseDataStore.store.courseOptions.available_course_packages !== null;
  });

  const defaultVideoLanguage = Object.entries(courseDataStore?.store?.courseOptions?.video_languages || {}).find(([key, value]) => value === "foreign")?.[0];

  const allowAudioTranscript = computed(() => {
    if(courseDataStore?.store?.settingsCourses?.dateSettingsCourse?.allow_audio_transcripts == false){
      return "Off"
    } else {
      return "On"
    }
  });

  const defaultVideoTranscript = computed(() => {
    if(courseDataStore?.store?.courseOptions?.course?.video_transcript_languages == "none"){
      return "Off"
    } else {
      const language = courseDataStore?.store?.courseOptions?.course?.video_transcript_languages;
      const video_languages = Object.entries(courseDataStore?.store?.courseOptions?.video_languages || {});
      return video_languages.find(([key, value]) => value === language)?.[0];
    }
  });

  /**
   * This method returns the number of standard sets selected
   * @return {number}
   */
  function standardSetsSelectedCount() {
    return courseDataStore.store.course.standardSetIds.length;
  }

  /**
   * Sets a variable that indicates that the user scrolled near the
   * bottom of the page.
   * @param {event} event - The scroll event of the window.
   */
  function nextButtonEnableWithScroll(event) {
    if (
      (window.innerHeight + Math.ceil(window.pageYOffset + 120) ) >= document.body.offsetHeight
    ) {
      disableNextButton.value = false;
    }
  }

  function isNextButtonDisabled() {
    return courseDataStore.courseValidator.hasErrorInStandards().value || disableNextButton.value;
  }

  onMounted(() => {
    scrollToTopOfPage();
    nextButtonEnableWithScroll();
    window.addEventListener('scroll', nextButtonEnableWithScroll);
  });

  onUnmounted(() => {
    window.removeEventListener('scroll', nextButtonEnableWithScroll);
  });
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .content-step {
    background-color: #fff;
    clear: both;
    font-size: 1.3em;
    min-height: music.rpx(480);
    overflow: auto;
    padding: 0.25rem;
    position: relative;
    text-align: left;
  }

  .edit-course .content-step {
    border: music.$grey-b solid 0.625rem;
    padding: 0.9375rem;
  }

  .with-divider {
    border-bottom: music.rpx(1) solid music.$grey-d;
  }

  .save-spinner {
    position: absolute;
    right: 6.625rem;
  }
</style>
