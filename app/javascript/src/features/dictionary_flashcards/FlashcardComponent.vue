<template>
  <div>
    <div
      v-if="!localState.reviewMode"
      aria-live="polite"
      class="u-center-flex">
      <div
        ref="flashcardElm"
        aria-role="group"
        tabindex="0"
        class="c-card  c-card--stack  c-flashcard  u-z-1"
        :class="[
          { 'is-flipped': isFlipped },
          testClass('flashcard')
        ]"
        @click.stop="flashcard.flip()">
        <!-- u-z-1 class is added to remove the higher z-index
             when flashcard is focused. -->
        <div class="c-flashcard__content">
          <div class="c-flashcard__terms">
            <FlashcardFront v-if="!isFlipped" />

            <FlashcardBack v-else />
          </div> <!-- .c-flashcard__terms -->

          <FlashcardNumber />
        </div> <!-- .card-content -->
      </div> <!-- .flashcard -->
    </div>
    <FlashcardReview v-else />
  </div>
</template>
<script>
  import { computed, inject, onMounted, provide, reactive, ref } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import { testClass } from 'music';
  import FlashcardFront from './FlashcardFront';
  import FlashcardBack from './FlashcardBack';
  import FlashcardNumber from './FlashcardNumber';
  import FlashcardReview from './FlashcardReview';
  import Flashcard from 'models/vocab_tools/flashcard';

  export default {
    name: 'FlashcardComponent',
    components: { FlashcardBack, FlashcardFront, FlashcardNumber, FlashcardReview },
    props: {
      modes: { required: true, type: Object },
      mode: { required: true, type: Number },
      ssjrStudent: { default: false, type: Boolean },
    },
    setup(props) {
      const audioIconElm = ref(null);
      const flashcardElm = ref(null);
      const languageCode = metaTagContent('VHL.program_language');
      const localState = reactive(
        {
          card: {
            languageCode,
          },
          deck: inject('deck'),
          index: 0,
          reviewMode: false,
          ssjrStudent: props.ssjrStudent,
        }
      );
      const isFlipped = computed(() => localState.card.showFront === false );
      const hasAudio = computed(() => localState.card.word.audio_paths?.length > 0);
      const options = {
        audioIconElm,
        flashcardElm,
        localState,
        props,
        hasAudio,
        isFlipped,
      };

      const flashcard = new Flashcard(options);
      flashcard.resetCard();

      provide('audioIconElm', audioIconElm);
      provide('hasAudio', hasAudio);
      provide('flashcard', flashcard);
      provide('flashcardState', localState);

      onMounted(() => {
        flashcard.resetAudioFiles();
        flashcardElm.value?.focus();
      });

      return {
        flashcardElm,
        flashcard,
        isFlipped,
        localState,
        testClass,
      };
    },
  };
</script>
