<template>
  <WordTableJr
    v-if="ssjrStudent"
    v-bind="$props"
    @addWord="$emit('addWord', $event)"
    @removeWord="$emit('removeWord', $event)"
    @updateWord="$emit('updateWord', $event)" />

  <WordTableSr
    v-else
    v-bind="$props"
    @addWord="$emit('addWord', $event)"
    @removeWord="$emit('removeWord', $event)"
    @updateWord="$emit('updateWord', $event)" />
</template>

<script>
  import { computed } from 'vue';
  import WordTableJr from './WordTableJr';
  import WordTableSr from './WordTableSr';

  export default {
    name: 'WordTable',
    components: { WordTableJr, WordTableSr },
    props: {
      isTranslationHidden: { default: false, type: Boolean },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      targetLanguageCode: { required: true, type: String },
      units: { required: true, type: Array },
      viewAllLessons: { default: false, type: Boolean },
      vocabHasDefinition: { required: true, type: Boolean },
    },
    emits: ['addWord', 'removeWord', 'updateWord'],
  };
</script>
