<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="content-step">
      <EnterpriseStepHeader headingLevel="1" :isEditable="courseDataStore.editCourseMode" />

      <h1 class="step-title">
        Course Settings
      </h1>

      <EnterpriseSettingsSection class="with-divider">
        <CopySettings />
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection class="with-divider" title="Access Level">
        <Fieldset
          v-if="hasAvailableCoursePackages === false"
          title="Access Level">
          <div class="u-mar-bot-8  u-txt-body-1">
            Select the access level and components students need for this course.
          </div>

          <div
            class="options"
            :class="{'u-mar-bot-16': courseDataStore.store.courseOptions.components.length}">
            <!-- eslint-disable vue/no-v-model-argument -->
            <VhlRadioButton
              v-for="level in courseDataStore.store.courseOptions.levels"
              :id="`access_level_${level.name}`"
              :key="level.name"
              v-model:modelValue="courseDataStore.store.course.level"
              name="level"
              testSelectorInput="access-level-rb"
              :text="level.name"
              :value="level.id"
              @update:modelValue="maybeWarnAccessChange()" />
            <!-- eslint-enable vue/no-v-model-argument -->
          </div>

          <div v-if="courseDataStore.store.courseOptions.components.length">
            <div
              v-for="component in allowedComponents"
              :key="component.name"
              class="mar-bot-10">
              <VhlCheckbox
                v-if="!isPortfolio(component)"
                :id="`component_${component.name}`"
                :checked="isComponentSelected(component)"
                name="component"
                testSelectorInput="component-checkbox"
                @update:checked="toggleComponent(component);">
                {{ component.name }}
              </VhlCheckbox>
              <Portfolio 
                v-else-if="isPortfolio(component)"
                :class="testClass('portfolio-comp')"
                :component="component"
                :is_enterprise="true"/>
            </div>
          </div>
        </Fieldset>
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection class="with-divider" title="Assignment Settings">
        <Lessons class="u-mar-bot-16" />

        <Translations
          v-if="config.languageCode !== 'en' && config.hasVocabTutorials" />

        <EstimatedTime />
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection class="with-divider" title="Assigning Tools">
        <IndividualizedAssigning />

        <GoogleClassroom v-if="config.canShareToGoogleClassroomForSchool" />
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection title="Media Settings" class="with-divider">
        Changes cannot be made in Enterprise. To manage media settings, go to
        the <b>Student Interaction Settings</b> page in the Instructor Dashboard after
        sections are created and students are enrolled.

        <p class="u-mar-top-24">Defaults</p>

        <table class="c-table  c-table--content  u-section-table  u-width-half  u-txt-16  u-txt-gray-3  u-mar-bot-0">
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
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection
        v-if="!config.isCurrentProgramSupersiteJunior"
        title="Student Support Requests"
        class="with-divider">
        <HelpRequests class="u-mar-bot-16" />
        <ScoreReviews />
      </EnterpriseSettingsSection>

      <EnterpriseSettingsSection
        v-if="!config.isCurrentProgramSupersiteJunior"
        title="Text and Video Chat Availability">
        <ChatAvailability />
      </EnterpriseSettingsSection>
    </div>

    <img
      v-if="courseDataStore.store.saving"
      :src="spinnerImage"
      class="save-spinner"
      :class="testClass('save-spinner')">

    <EnterpriseSetupControls
      :isUpdateDisabled="courseDataStore.isUpdateDisabled"
      :isNextDisabled="isNextButtonDisabled()"
      nextStep="enterprise-gradebook-step"
      previousStep="enterprise-course-step" />
  </div>
</template>

<script setup>
  import { computed, inject, onMounted, onUnmounted, ref, reactive } from 'vue';
  import { testClass } from 'music';
  import { scrollToTopOfPage } from 'shared/utils';
  import { Fieldset } from 'features/shared/FormElements';
  import EnterpriseSetupControls from './EnterpriseSetupControls';
  import spinnerImage from 'images/loading_32.gif';
  import EnterpriseStepHeader from './EnterpriseStepHeader';
  import EnterpriseSettingsSection from './EnterpriseSettingsSection';
  import CopySettings from './enterprise_content_step/settings/CopySettings';
  import EstimatedTime from './enterprise_content_step/settings/EstimatedTime';
  import GoogleClassroom from './enterprise_content_step/settings/GoogleClassroom';
  import IndividualizedAssigning from './enterprise_content_step/settings/IndividualizedAssigning';
  import Lessons from './enterprise_content_step/settings/Lessons';
  import Translations from './enterprise_content_step/settings/Translations';
  import HelpRequests from './enterprise_content_step/settings/HelpRequests';
  import ScoreReviews from './enterprise_content_step/settings/ScoreReviews';
  import ChatAvailability from './enterprise_content_step/settings/ChatAvailability';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import Screenshot from 'features/course_wizard/components/Screenshot';
  import ContentSetting from 'features/course_wizard/components/content_step/ContentSetting';
  import Portfolio from './content_step/settings/Portfolio';
  import SettingFieldset from './content_step/SettingFieldset';
  import VhlCheckbox from './VhlCheckbox';
  import VhlRadioButton from './VhlRadioButton';

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
  const disableNextButton = ref(true);

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

  const localStore = reactive({
    showSubtitleScreenshot: false,
    showTranscriptScreenshot: false,
  });

  const defaultVideoLanguage = Object.entries(
    courseDataStore.store.courseOptions.video_languages
  ).find(([key, value]) => value === 'foreign')?.[0];

  const allowAudioTranscript = computed(() => {
    if(courseDataStore.store.settingsCourses.dateSettingsCourse.allow_audio_transcripts == false){
      return 'Off'
    } else {
      return 'On'
    }
  });

  const defaultVideoTranscript = computed(() => {
    if(courseDataStore.store.courseOptions.course.video_transcript_languages === 'none') {
      return 'Off'
    } else {
      return courseDataStore.store.courseOptions.course.video_transcript_languages
    }
  });

  const hasAvailableCoursePackages = computed(() => {
    return courseDataStore.store.courseOptions.available_course_packages !== null;
  });
  
  /**
   * This method updates components in the course data
   * and shows warning for access change
   * @param {ComponentInResponseDataType} component
   */
  function toggleComponent(component) {
    const index = courseDataStore.store.course.components.indexOf(component.id);
    if (index > -1) {
      courseDataStore.store.course.components.splice(index, 1);
    } else {
      courseDataStore.store.course.components.push(component.id);
    }
    maybeWarnAccessChange();
  }

  /**
   * This method shows warning for access change
   */
  function maybeWarnAccessChange() {
    if (!courseDataStore.newCourseMode) {
      window.alert(
        'This new access level may prevent students from ' +
          'completing work you have already assigned.'
      );
    }
  }

  /**
   * This method returns whether a component is selected based on course data
   * @param {ComponentInResponseDataType} component
   * @return {boolean}
   */
  function isComponentSelected(component) {
    return courseDataStore.store.course.components.indexOf(component.id) > -1;
  }

  onMounted(() => {
    scrollToTopOfPage();
    nextButtonEnableWithScroll();
    window.addEventListener('scroll', nextButtonEnableWithScroll);
  });

  onUnmounted(() => {
    window.removeEventListener('scroll', nextButtonEnableWithScroll);
  });

  function isPortfolio(component) {
    return component.license_groups.some(
      (licenseGroup) => licenseGroup.name == 'Portfolio'
    );
  }

  const allowedComponents = computed(() => {
    if (courseDataStore.store.course.canShareToPortfolio) {
      return courseDataStore.store.courseOptions.components;
    } else {
      return courseDataStore.store.courseOptions.components.filter(
        (component) => !component.license_groups.some(
          (licenseGroup) => licenseGroup.name === 'Portfolio'
        )
      );
    }
  });
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;
  @import 'features/shared/form_element_settings';

  .content-step {
    background-color: var(--music-true-gray-50, #f5f5f5);
    clear: both;
    font-size: 1.3em;
    min-height: music.rpx(480);
    overflow: auto;
    padding: 0.25rem;
    position: relative;
    text-align: left;
    margin-bottom: 3rem;
  }

  .edit-course .content-step {
    padding: 0.9375rem;
  }

  .with-divider {
    border-bottom: music.rpx(1) solid music.$grey-d;
  }

  .save-spinner {
    position: absolute;
    right: 6.625rem;
  }

  .step-title {
    color: #595959;
    font-size: music.rpx(38);
    font-weight: 300;
    line-height: music.rpx(46);
    margin-bottom: music.rpx(28);
    margin-top: music.rpx(32);
  }
</style>
