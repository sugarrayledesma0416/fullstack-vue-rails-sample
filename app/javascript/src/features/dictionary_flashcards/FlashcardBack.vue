<template>
  <div class="flashcard__terms-back  js-flashcard-back">
    <FlashcardBackContent
      class="flashcard__terms-words"
      :screenReaderText="screenReaderText">
      <template #translation>
        <div
          class="c-flashcard__translation-word"
          :class="testClass('flashcard-word')"
          lang="en">
          <span class="u-screen-reader-only">English word:</span>
          {{ flashcardState.card.word.translation }}
        </div>
      </template>

      <template #target>
        <span class="u-screen-reader-only">
          {{ screenReaderText }}:
        </span>
        <div class="c-flashcard__target-wrapper">
          <div
            :lang="flashcardState.card.languageCode"
            class="c-flashcard__target-word  u-dis-flex  flex-justify-ctr"
            :class="testClass('flashcard-word')">
            <FlashcardAudio v-if="hasAudio" :class="testClass('flashcard-audio')" />
            {{ flashcardState.card.word.target }}
          </div>

          <div
            v-if="flashcardState.card.word.pinyin"
            class="u-dis-flex  flex-justify-ctr">
            <span class="u-screen-reader-only" lang="en">
              Pinyin word:
            </span>
            <div
              lang="zh-Latn"
              class="c-flashcard__pinyin">
              {{ flashcardState.card.word.pinyin }}
            </div>
          </div>
        </div>
      </template>

      <template #definition>
        <div
          class="c-flashcard__definition"
          :class="testClass('flashcard-word')"
          lang="en">
          {{ flashcardState.card.word.definition }}
        </div>
      </template>
    </FlashcardBackContent>

    <div class="flashcard__review-buttons">
      <div class="c-button-group  c-button-group--ctr">
        <button
          lang="en"
          type="button"
          aria-label="I know it."
          class="c-button  c-button--border  c-know-it"
          :class="testClass('flashcard-knew-it')"
          @click.stop="flashcard.moveToNextCard('knewIt')">
          I know it
        </button>
        <button
          lang="en"
          type="button"
          aria-label="Not yet."
          class="c-button  c-button--border"
          :class="testClass('flashcard-not-yet')"
          @click.stop="flashcard.moveToNextCard('notYet')">
          Not yet
        </button>
      </div>
    </div>
    <span class="u-screen-reader-only">
      {{ flashcardState.index + 1 }} out of {{ flashcardState.deck.flashcards.length }}
    </span>
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import FlashcardBackContent from './FlashcardBackContent';
  import FlashcardAudio from './FlashcardAudio';

  export default {
    name: 'FlashcardBack',
    components: { FlashcardAudio, FlashcardBackContent },
    setup() {
      const flashcard = inject('flashcard');
      const flashcardState = inject('flashcardState');
      const hasAudio = inject('hasAudio');
      const screenReaderText = flashcardState.languageCode === 'en' ? 'English word' : 'Foreign word';

      return {
        flashcard,
        flashcardState,
        hasAudio,
        screenReaderText,
        testClass,
      };
    },
  };
</script>
