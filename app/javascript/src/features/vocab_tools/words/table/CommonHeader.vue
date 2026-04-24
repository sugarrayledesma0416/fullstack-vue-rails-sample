<template>
  <table
    class="c-table  c-header-table"
    aria-hidden="true">
    <ColumnsLayout :totalColumns="totalColumns" />
    <thead>
      <HeaderRow
        :isTranslationHidden="isTranslationHidden"
        :targetLanguage="targetLanguage"
        :vocabHasDefinition="vocabHasDefinition" />
    </thead>
  </table>
</template>

<script>
  import ColumnsLayout from 'features/vocab_tools/words/table/ColumnsLayout';
  import HeaderRow from 'features/vocab_tools/words/table/HeaderRow';

  export default {
    name: 'CommonHeader',
    components: { ColumnsLayout, HeaderRow },
    props: {
      isTranslationHidden: { default: false, type: Boolean },
      ssjrStudent: { default: false, type: Boolean },
      targetLanguage: { required: true, type: String },
      totalColumns: { default: 3, type: Number },
      vocabHasDefinition: { required: true, type: Boolean },
    },
  };
</script>
