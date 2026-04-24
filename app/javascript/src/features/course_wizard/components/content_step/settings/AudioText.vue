<template>
  <ContentSetting title="Audio Transcript" :class="testClass('audio-text')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="audio-transcripts"
      v-model:checked="courseDataStore.store.course.allowAudioTranscripts"
      testSelectorInput="audio-transcripts-checkbox"
      name="allow_audio_transcripts">
      Allow students to see transcripts of recorded audio.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from '../../VhlCheckbox';
  const courseDataStore = inject('courseDataStore');
</script>
