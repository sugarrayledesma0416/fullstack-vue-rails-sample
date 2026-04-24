<template>
  <div
    class="js-flashcard-front">
    <div class="c-flashcard__front target-language">
      <!-- Target To Translation  || Target To Definition   -->
      <template v-if="flashcard.isSourceLangTarget">
        <span
          class="u-screen-reader-only">
          {{ screenReaderText }}:
        </span>
        <div
          :lang="flashcardState.card.languageCode"
          class="c-flashcard__target-word  u-dis-flex"
          :class="testClass('flashcard__word')">
          <FlashcardAudio v-if="hasAudio" />
          {{ flashcardState.card.word.target }}
        </div>
      </template>

      <!-- Translation To Target         -->
      <div
        v-if="flashcard.isModeTranslationToTarget"
        :class="testClass('flashcard__word')"
        lang="en">
        <span class="u-screen-reader-only">English word:</span>
        {{ flashcardState.card.word.translation }}
      </div>

      <!-- Definition To Target         -->
      <span
        v-if="flashcard.isModeDefinitionToTarget"
        class="c-definition-to-target"
        :class="testClass('flashcard__word')">
        {{ flashcardState.card.word.definition }}
      </span>
    </div> <!-- .c-flashcard__front target-language -->
    <span class="u-screen-reader-only">
      {{ flashcardState.index + 1 }} out of {{ flashcardState.deck.flashcards.length }}
    </span>

    <button v-if="flashcardState.ssjrStudent" type="button" class="c-jr-flipper">
      <span class="u-screen-reader-only">Flip card</span>
      <img :src="flipIconPath">
      <span class="c-flip-text">Flip</span>
    </button>

    <button v-else type="button" class="c-flipper">
      <span class="u-screen-reader-only">Flip card</span>
    </button>
  </div> <!-- .js-flashcard-front -->
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import FlashcardAudio from './FlashcardAudio';

  export default {
    name: 'FlashcardFront',
    components: { FlashcardAudio },
    setup() {
      const flashcard = inject('flashcard');
      const flashcardState = inject('flashcardState');
      const flipIconPath = flashcardState.ssjrStudent ? inject('flipIconPath') : null;
      const hasAudio = inject('hasAudio');
      const screenReaderText = flashcardState.languageCode === 'en' ? 'English word' : 'Foreign word';

      return {
        flashcard,
        flashcardState,
        flipIconPath,
        hasAudio,
        screenReaderText,
        testClass,
      };
    },
  };
</script>
