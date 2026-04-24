<template>
  <div>
    <div
      class="c-flashcard__front target-language"
      :class="testClass('flashcard-front')">
      <!-- Target To Translation  || Target To Definition   -->
      <template v-if="flashcard.isSourceLangTarget">
        <slot name="target" />
      </template>

      <!-- Translation To Target         -->
      <div v-else-if="flashcard.isModeTranslationToTarget">
        <slot v-if="flashcardState.ssjrStudent" name="target" />
        <slot v-else name="translation" />
      </div>

      <!-- Definition To Target         -->
      <div v-else-if="flashcard.isModeDefinitionToTarget">
        <slot v-if="flashcardState.ssjrStudent" name="target" />
        <slot v-else name="definition" />
      </div>
    </div> <!-- .c-flashcard__front target-language -->

    <div
      class="c-flashcard__back first-language"
      :class="testClass('flashcard-back')">
      <!-- Target To Translation       -->
      <div v-if="flashcard.isModeTargetToTranslation">
        <slot name="translation" />
      </div>

      <!-- Target To Definition       -->
      <div v-else-if="flashcard.isModeTargetToDefinition">
        <slot name="definition" />
      </div>

      <!-- Translation To Target       -->
      <div v-else-if="flashcard.isModeTranslationToTarget">
        <slot v-if="flashcardState.ssjrStudent" name="translation" />
        <slot v-else name="target" />
      </div>

      <!-- Definition To Target         -->
      <div v-else-if="flashcard.isModeDefinitionToTarget">
        <slot v-if="flashcardState.ssjrStudent" name="definition" />
        <slot v-else name="target" />
      </div>
    </div> <!-- .c-flashcard__back target-language -->
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'FlashcardBackContent',
    setup(props) {
      const flashcard = inject('flashcard');
      const flashcardState = inject('flashcardState');
      const screenReaderText = props.screenReaderText;

      return {
        flashcard,
        flashcardState,
        screenReaderText,
        testClass,
      };
    },
  };
</script>
