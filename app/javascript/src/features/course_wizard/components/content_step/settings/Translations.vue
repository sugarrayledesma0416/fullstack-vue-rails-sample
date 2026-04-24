<template>
  <ContentSetting
    title="Translations"
    :class="testClass('translations')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="vocab-translations"
      v-model:checked="courseDataStore.store.course.enableVocabTutorialTranslations"
      testSelectorInput="vocab-translations-checkbox"
      name="enable_vocab_tutorial_translations">
      Allow students to view English translations for terms in the Vocabulary Tutorials.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import ContentSetting from '../ContentSetting';

  const courseDataStore = inject('courseDataStore');
</script>
