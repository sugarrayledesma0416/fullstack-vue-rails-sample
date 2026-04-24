<template>
  <fieldset class="category-grading">
    <legend class="category-grading__legend">
      Category grading
    </legend>

    <div class="category-grading__body">
      <div class="category-grading__credit_only">
        <span class="category-grading__label">Assignments in this category will be:</span>
        <!-- eslint-disable vue/no-v-model-argument -->
        <div>
          <VhlRadioButton
            id="new_for_a_grade"
            v-model:modelValue="category.creditOnly"
            class="js-modal-a11y__first-focus-element"
            :class="testClass('for-a-grade-label')"
            name="new_for_a_grade"
            testSelectorInput="new-for-a-grade"
            text="For a grade"
            :value="false" />
        </div>
        <div>
          <VhlRadioButton
            id="new_credit_only"
            v-model:modelValue="category.creditOnly"
            :class="testClass('credit-only-label')"
            name="new_credit_only"
            testSelectorInput="new-credit-only"
            text="Credit/no credit"
            :value="true" />
        </div>
        <!-- eslint-enable vue/no-v-model-argument -->
      </div>
      <div class="category-grading__drop-low-scores">
        <label class="category-grading__label" :class="testClass('drop-low-scores-label')">
          Number of lowest grades dropped:
        </label>
        <BasicSelect
          id="drop_lowest_scores"
          v-model.number="category.dropLowScores"
          testSelector="drop-low-scores"
          :options="dropScoreOptions" />
      </div>
    </div>
  </fieldset>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import { dropScoreOptions } from 'features/category_wizard/models/category_data';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';
  import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';

  export default {
    name: 'CategoryGrading',
    components: { VhlRadioButton, BasicSelect },
    setup() {
      const category = inject('category');

      return { category, dropScoreOptions, testClass };
    },
  };
</script>

<style scoped>
  .category-grading {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-grading__legend {
    display: none;
  }

  .category-grading__label {
    color: #565656;
    display: block;
    font-size: 0.625rem;
    font-weight: bold;
    margin-bottom: 0.1875rem;
    padding: 0
  }

  .category-grading__drop-low-scores {
    margin-top: 0.5rem;
  }
</style>
