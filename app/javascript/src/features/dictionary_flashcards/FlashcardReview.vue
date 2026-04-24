<template>
  <div>
    <div v-if="deck.flashcards.length > 0" class="c-bigmetric  c-flashcard-review">
      <div class="c-bigmetric__graph--vocab-tools">
        <div class="c-radial-progress c-radial-progress--lg u-mbs">
          <div
            v-donut
            :percent-correct="deck.donutText" />
          <div class="c-radial-progress__label" />
        </div>
      </div>

      <div class="c-bigmetric__detail">
        <div
          id="live-region-container"
          aria-live="assertive"
          role="alert">
          <p
            class="c-bigmetric__heading"
            :class="testClass('knew-it-message')">
            {{ deck.knewItCount === deck.flashcards.length
              ? `You knew all ${deck.flashcards.length} words!`
              : `You got ${deck.knewItCount} out of ${deck.flashcards.length}.`
            }}
          </p>
        </div>
        <ul class="c-list">
          <li>
            <a
              href="javascript://"
              :class="testClass('review-all-words')"
              @click="flashcard.review(true)">
              Review all words.
            </a>
          </li>
          <li v-if="deck.knewItPercentage < 100">
            <a
              href="javascript://"
              :class="testClass('review-dont-know-words')"
              @click="flashcard.review(false)">
              Review words you don't know yet.
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import donut from 'directives/vocab_tools/donut';

  export default {
    name: 'FlashcardReview',
    directives: { donut },
    emits: ['reviewWords'],

    setup() {
      const flashcardState = inject('flashcardState');
      const flashcard = inject('flashcard');
      const deck = flashcardState.deck;

      return { deck, flashcard, testClass };
    },
  };
</script>
