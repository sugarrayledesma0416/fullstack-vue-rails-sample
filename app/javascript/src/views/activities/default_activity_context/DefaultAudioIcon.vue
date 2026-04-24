<template>
  <div v-if="hasAudio" :class="testClass('default-audio-icon')">
    <MusicMediaButton
      :key="mediaBtnKey"
      :variant="btnVariant"
      toggle="stop"
      size="sm"
      :onActivate="play"
      :onDeactivate="pause"
      :state="isAudioPlaying ? 'active' : 'default'" />
  </div>
</template>

<script setup>
  import { computed, ref, watch } from 'vue';
  import { testClass } from 'music';
  import { useAutoPlayAudio } from 'shared/use_auto_play_audio.js';
  import MusicMediaButton from 'shared/vue/MusicMediaButton.vue';

  const props = defineProps({
    audioPaths: { default: '[]', type: String },
  });
  const mediaBtnKey = ref(0);

  const {
    hasAudio,
    isAudioPlaying,
    play,
    pause,
  } = useAutoPlayAudio(JSON.parse(props.audioPaths));

  const btnVariant = computed(() =>
    isAudioPlaying.value ? 'pause' : 'listen'
  );

  watch(() => isAudioPlaying.value, () => {
    mediaBtnKey.value += 1;
  });
</script>
