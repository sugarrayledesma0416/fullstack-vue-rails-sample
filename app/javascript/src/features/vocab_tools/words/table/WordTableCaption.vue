<template>
  <caption :id="elmId" class="u-screen-reader-only">
    Table {{ tableNumber }} of total {{ tableCount }} word tables.
    This is a table of vocabulary words for the lesson {{ lessonName }}.
    Each row has a column with the word in {{ targetLanguage }}, and a column with
    {{ isTranslationHidden ? 'the word definition.' : 'the English translation.' }}
    <span v-if="!isTranslationHidden && vocabHasDefinition">
      A third column contains the definition.
    </span>
    You can add your own custom words and edit any words you have created.
  </caption>
</template>

<script>
  export default {
    name: 'WordTableCaption',
    props: {
      elmId: { default: '', type: String },
      isTranslationHidden: { default: false, type: Boolean },
      lessonName: { default: '', type: String },
      tableNumber: { default: 1, type: Number },
      tableCount: { default: 1, type: Number },
      targetLanguage: { default: '', type: String },
      vocabHasDefinition: { default: false, type: Boolean },
    },
  };
</script>
