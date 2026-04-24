<template>
  <ContentSetting title="Video Transcripts" :class="testClass('video-transcripts')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <BasicSelect
      v-model:modelValue="courseDataStore.store.course.videoTranscriptLanguages"
      :options="videoLanguagesOptions"
      testSelector="video-transcripts-dropdown"
      name="video_transcript_languages" />
    <!-- eslint-enable vue/no-v-model-argument -->
    <VhlLink
      href="javascript://"
      class="u-mar-lt-8"
      testSelector="transcript-screenshot-link"
      @click="localStore.showTranscriptScreenshot = true">
      See Example
    </VhlLink>
    <Screenshot
      v-if="localStore.showTranscriptScreenshot"
      title="Video Transcript Sample Screenshot"
      mode="transcript"
      @close="localStore.showTranscriptScreenshot = false" />
    <input
      id="allow_video_popup_translation"
      v-model="courseDataStore.store.course.allowVideoPopupTranslation"
      type="hidden"
      name="allow_video_popup_translation">
  </ContentSetting>
</template>

<script setup>
  import { computed, inject, reactive } from 'vue';
  import ContentSetting from '../ContentSetting';
  import { testClass } from 'music';
  import Screenshot from '../../Screenshot';
  import VhlLink from '../../VhlLink';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';

  const courseDataStore = inject('courseDataStore');

  const localStore = reactive({
    showTranscriptScreenshot: false,
  });

  /**
   * This gets options for video subtitle languages dropdown in the required format
   * @return {Array.<VhlSelectOptionType>}
   */
  const videoLanguagesOptions = computed(() => {
    const videoLanguages = courseDataStore.store.courseOptions.video_languages;
    return Object.keys(videoLanguages)?.map(
      (langKey, index) => ({
        text: langKey,
        value: courseDataStore.store.courseOptions.video_languages[langKey],
      })
    );
  });
</script>
