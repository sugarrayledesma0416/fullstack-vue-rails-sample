<template>
  <div class="junior-direction-line-icon">
    <span
      class="junior-direction-line-icon__penguin"
      :class="testClass('penguin')"
      role="presentation">
      <vhl-icon :path="juniorDirectionLineIconPath" />
    </span>
    <button
      v-if="hasAudio"
      class="junior-direction-line-icon__audio"
      :class="testClass('audio')"
      type="button"
      @click="isAudioPlaying ? pause() : play()">
      <vhl-icon :path="audioIcon" />
    </button>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import { useAutoPlayAudio } from 'shared/use_auto_play_audio.js';

  const props = defineProps({
    activeAudioIconPath: { default: '', type: String },
    audioIconPath: { required: true, type: String },
    audioPaths: { default: '[]', required: false, type: String },
    juniorDirectionLineIconPath: { required: true, type: String },
  });

  const {
    hasAudio,
    isAudioPlaying,
    play,
    pause,
  } = useAutoPlayAudio(JSON.parse(props.audioPaths));

  const audioIcon = computed(() =>
    isAudioPlaying.value && props.activeAudioIconPath ?
      props.activeAudioIconPath :
      props.audioIconPath
  );
</script>

<style lang="sass" scoped>
  /**
   * The icon div is a single-cell grid so that the penguin and audio elements
   *   can be layered in the same named area ("icon-grid").
   */
  .junior-direction-line-icon {
    display: grid;
    grid-template-areas: "icon-grid";

    /**
     * The audio icon is placed in the same grid area as the penguin. Because
     *   it follows the penguin in the DOM, its z-index is greater than the
     *   penguin's, so it is layered over the penguin.
     *
     * The align-self and justify-self place it at the lower left-hand corner
     *   of the penguin.
     */
    &__audio {
      align-self: end;
      background-color: transparent;
      border-color: transparent;
      grid-area: icon-grid;
      justify-self: end;
      margin-right: -0.5rem;
      --vhl-icon-size: 2.5rem;
    }

    &__penguin {
      grid-area: icon-grid;
      --vhl-icon-size: 7rem;
    }
  }
</style>
