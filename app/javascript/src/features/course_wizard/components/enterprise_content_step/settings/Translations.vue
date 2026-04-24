<template>
  <div>
    <input
      id="enable_vocab_tutorial_translations"
      v-model="courseDataStore.store.course.enableVocabTutorialTranslations"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="enable_vocab_tutorial_translations">
      Allow students to view English translations for terms in the Vocabulary Tutorials.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
