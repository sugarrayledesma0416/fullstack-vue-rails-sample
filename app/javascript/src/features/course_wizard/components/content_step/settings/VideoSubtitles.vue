<template>
  <ContentSetting
    title="Subtitles and closed captions (cc)"
    :class="testClass('video-subtitles')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <BasicSelect
      v-model:modelValue="courseDataStore.store.course.videoSubtitleLanguages"
      testSelector="video-subtitles-dropdown"
      :options="videoLanguagesOptions"
      name="video_subtitle_languages" />
    <!-- eslint-enable vue/no-v-model-argument -->
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
    showSubtitleScreenshot: false,
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
