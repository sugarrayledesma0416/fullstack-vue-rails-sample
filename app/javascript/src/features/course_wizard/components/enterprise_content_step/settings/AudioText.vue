<template>
  <div>
    <input
      id="audio_transcripts"
      v-model="courseDataStore.store.course.allowAudioTranscripts"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="audio_transcripts">
      Allow students to see transcripts of recorded audio.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
