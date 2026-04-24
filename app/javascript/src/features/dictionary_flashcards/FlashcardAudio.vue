<template>
  <div
    class="c-flashcard__audio-ctrls"
    :class="testClass('flashcard-audio-controls')">
    <button
      ref="audioIconElm"
      type="button"
      class="c-no-button  u-line-height-1r"
      :class="testClass('flashcard-audio-play-button')"
      @click.stop="flashcard.play()">
      <div v-if="flashcardState.ssjrStudent" class="c-jr-audio-icon" />
      <MusicIcon
        v-else
        variant="audio"
        size="lg" />
      <span class="u-screen-reader-only">Replay</span>
    </button>
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import MusicIcon from 'shared/vue/MusicIcon';

  export default {
    name: 'FlashcardAudio',
    components: { MusicIcon },
    setup() {
      const audioIconElm = inject('audioIconElm');
      const flashcard = inject('flashcard');
      const flashcardState = inject('flashcardState');

      return {
        audioIconElm,
        flashcard,
        flashcardState,
        testClass,
      };
    },
  };
</script>
