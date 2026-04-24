<template>
  <fieldset class="category-strictness">
    <legend class="category-strictness__legend">
      Category strictness
    </legend>

    <div class="category-strictness__body">
      <span class="category-strictness__label">
        This category will have the following grading strictness:
      </span>
      <div class="category-strictness__input-container">
        <!-- eslint-disable vue/no-v-model-argument -->
        <VhlCheckbox
          v-if="category.langHasAccents"
          :id="`new_must_match_accents`"
          v-model:checked="category.currentScoringRuleset.mustMatchAccents"
          name="new_must_match_accents"
          :testSelectorInput="`grading-accents-input`"
          :testSelectorLabel="`grading-accents-label`">
          Accent marks will be taken into account.
        </VhlCheckbox>
        <!-- eslint-enable vue/no-v-model-argument -->
      </div>

      <div class="category-strictness__input-container">
        <!-- eslint-disable vue/no-v-model-argument -->
        <VhlCheckbox
          v-if="category.langHasCases"
          :id="`new_must_match_capitalization`"
          v-model:checked="category.currentScoringRuleset.mustMatchCapitalization"
          name="new_must_match_capitalization"
          :testSelectorInput="`grading-capitalization-input`"
          :testSelectorLabel="`grading-capitalization-label`">
          Capitalization will be taken into account.
        </VhlCheckbox>
        <!-- eslint-enable vue/no-v-model-argument -->
      </div>

      <div class="category-strictness__input-container">
        <!-- eslint-disable vue/no-v-model-argument -->
        <VhlCheckbox
          :id="`new_must_match_punctuation`"
          v-model:checked="category.currentScoringRuleset.mustMatchPunctuation"
          name="new_must_match_punctuation"
          :testSelectorInput="`grading-punctuation-input`"
          :testSelectorLabel="`grading-punctuation-label`">
          Punctuation will be taken into account.
        </VhlCheckbox>
        <!-- eslint-enable vue/no-v-model-argument -->
      </div>
    </div>
  </fieldset>
</template>

<script setup>
  import { inject } from 'vue';
  import { metaTagContent, testClass } from 'music';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';

  const category = inject('category');
</script>

<style scoped>
  .category-strictness {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-strictness__legend {
    display: none;
  }

  .category-strictness__input-container {
    margin-bottom: 0.3125rem;
  }

  .category-strictness__label {
    color: #565656;
    display: block;
    font-size: 0.625rem;
    font-weight: bold;
    margin-bottom: 0.5rem;
    padding: 0
  }
</style>
