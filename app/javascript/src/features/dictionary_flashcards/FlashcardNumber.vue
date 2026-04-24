<template>
  <div
    class="c-flashcard__number  quiet"
    :class="testClass('flashcard__number')">
    <span aria-hidden="true">
      {{ flashcardState.index + 1 }} / {{ flashcardState.deck.flashcards.length }}
    </span>
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'FlashcardNumber',
    setup() {
      const flashcardState = inject('flashcardState');

      return {
        flashcardState,
        testClass,
      };
    },
  };
</script>
