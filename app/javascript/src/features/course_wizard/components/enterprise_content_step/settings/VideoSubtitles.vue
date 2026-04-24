<template>
  <div>
    <div class="u-mar-bot-16  u-txt-body-1">
      Select a language for subtitles and closed captions (CC), and transcripts in activities.
    </div>

    <div class="dropdown-group">
      <div class="language-group">
        <music-select-field-v3>
          <label for="video_subtitle_languages">
            Subtitles and CC
          </label>
          <select
            id="video_subtitle_languages"
            v-model="courseDataStore.store.course.videoSubtitleLanguages">
            <option
              v-for="language in videoLanguagesOptions"
              :key="language.value"
              :value="language.value">
              {{ language.text }}
            </option>
          </select>
        </music-select-field-v3>

        <a
          href="javascript://"
          class="screenshot-link"
          @click="localStore.showSubtitleScreenshot = true">See Example</a>

        <Screenshot
          v-if="localStore.showSubtitleScreenshot"
          title="Subtitle Sample Screenshot"
          mode="subtitle"
          @close="localStore.showSubtitleScreenshot = false" />
      </div>

      <div class="language-group">
        <music-select-field-v3>
          <label for="video_transcript_languages">
            Video Transcripts
          </label>
          <select
            id="video_transcript_languages"
            v-model="courseDataStore.store.course.videoTranscriptLanguages">
            <option
              v-for="language in videoLanguagesOptions"
              :key="language.value"
              :value="language.value">
              {{ language.text }}
            </option>
          </select>
        </music-select-field-v3>

        <a
          href="javascript://"
          class="screenshot-link"
          @click="localStore.showTranscriptScreenshot = true">See Example</a>

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
      </div>
    </div>
  </div>
</template>

<script setup>
  import { computed, inject, reactive } from 'vue';
  import Screenshot from '../../Screenshot';

  const courseDataStore = inject('courseDataStore');

  const localStore = reactive({
    showSubtitleScreenshot: false,
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

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .dropdown-group {
    display: flex;
    flex-wrap: wrap;
    gap: 5rem;
  }

  .language-group {
    align-items: center;
    display: flex;
    gap: 2rem;
  }

  .screenshot-link {
    color: #000000;
    font-size: music.rpx(16);
    font-weight: 700;
    line-height: music.rpx(20);
    text-decoration: underline;
  }
</style>
