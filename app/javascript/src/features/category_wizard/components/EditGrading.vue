<template>
  <div
    class="edit-grading__main"
    role="tabpanel"
    aria-hidden="false"
    aria-label="Grading">
    <div class="edit-grading__detail">
      <label
        :class="testClass('max-attempts')"
        class="edit-grading__label"
        for="category_max_attempts">
        Maximum attempts*
      </label>
      <div>
        <BasicSelect
          id="max_attempts"
          v-model.number="category.maxAttempts"
          testSelector="max-attempts"
          :options="attemptOptions" />
      </div>
      <VhlLink
        href="javascript://"
        class="edit-grading__link"
        :class="testClass('applicable-details')"
        @click="localstore.showApplicableDetails = !localstore.showApplicableDetails">
        * when applicable (see details)
      </VhlLink>
      <span v-if="localstore.showApplicableDetails" :class="testClass('attempts-details')">
        <ul>
          <li>The following are always limited to 1 attempt:</li>
          <li>True/false activities</li>
          <li>Other multiple choice activities with only 2 choices</li>
          <li>Open ended activities</li>
          <li>Recording activities</li>
          <li>Assessments</li>
        </ul>
      </span>
    </div>
    <div class="edit-grading__detail">
      <label :class="testClass('grading-strictness')" class="edit-grading__label">
        Grading Strictness
      </label>
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlCheckbox
        v-if="category.langHasAccents"
        :id="`grading-accents`"
        v-model:checked="category.currentScoringRuleset.mustMatchAccents"
        name="must_match_accents"
        class="edit-grading__checkbox-span"
        :testSelectorInput="`grading-accents-input`"
        :testSelectorLabel="`grading-accents-label`">
        Accent marks count
      </VhlCheckbox>
      <!-- eslint-enable vue/no-v-model-argument -->

      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlCheckbox
        v-if="category.langHasCases"
        :id="`grading-capitalization`"
        v-model:checked="category.currentScoringRuleset.mustMatchCapitalization"
        name="must_match_capitalization"
        class="edit-grading__checkbox-span"
        :testSelectorInput="`grading-capitalization-input`"
        :testSelectorLabel="`grading-capitalization-label`">
        Capitalization counts
      </VhlCheckbox>
      <!-- eslint-enable vue/no-v-model-argument -->

      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlCheckbox
        :id="`grading-punctuation`"
        v-model:checked="category.currentScoringRuleset.mustMatchPunctuation"
        name="must_match_punctuation"
        class="edit-grading__checkbox-span"
        :testSelectorInput="`grading-punctuation-input`"
        :testSelectorLabel="`grading-punctuation-label`">
        Punctuation counts
      </VhlCheckbox>
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
    <div class="edit-grading__detail">
      <label class="edit-grading__label">
        For fill-in-the-blank activities in this category:
      </label>
      <VhlLink
        href="javascript://"
        class="edit-grading__link"
        :class="testClass('fib-details')"
        @click="localstore.fibDetails = !localstore.fibDetails">
        (see details)
      </VhlLink>
      <span v-if="localstore.fibDetails" class="edit-grading__fib-detail">
        Detailed feedback is provided to students on fill-in-the-blank responses
        when capitalization, punctuation, and accents are misused or when there
        are missing or extra words.
      </span>
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        id="enhanced_feedback_enabled"
        v-model:modelValue="category.enhancedFeedbackDisabled"
        class="edit-grading__radio-btn"
        name="enhanced_feedback_enabled"
        testSelectorInput="enhanced-feedback-enabled"
        text="Provide students with enhanced feedback"
        :value="false" />
      <VhlRadioButton
        id="enhanced_feedback_disabled"
        v-model:modelValue="category.enhancedFeedbackDisabled"
        class="edit-grading__radio-btn"
        name="enhanced_feedback_disabled"
        testSelectorInput="enhanced-feedback-disabled"
        text="Don't provide students with enhanced feedback"
        :value="true"
        @change="localstore.isFeedbackWarningVisible = true" />
      <!-- eslint-enable vue/no-v-model-argument -->
      <FeedbackDisableModal
        v-if="localstore.isFeedbackWarningVisible"
        @close="localstore.isFeedbackWarningVisible = false" />
    </div>
    <div class="edit-grading__detail">
      <label :class="testClass('assignment-category')" class="edit-grading__label">
        Assignments in this category will be:
      </label>
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        id="for_a_grade"
        v-model:modelValue="category.creditOnly"
        class="edit-grading__radio-btn"
        name="for_a_grade"
        testSelectorInput="for-a-grade"
        text="For a grade"
        :value="false" />
      <VhlRadioButton
        id="new_credit_only"
        v-model:modelValue="category.creditOnly"
        class="edit-grading__radio-btn"
        name="credit_only"
        testSelectorInput="new-credit-only"
        text="Credit/no credit"
        :value="true" />
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
    <div class="edit-grading__detail">
      <label :class="testClass('lowest-grades')" class="edit-grading__label">
        Number of lowest grades dropped:
      </label>
      <BasicSelect
        id="drop_lowest_scores"
        v-model.number="category.dropLowScores"
        class="js-modal-a11y__last-focus-element"
        testSelector="drop-low-scores"
        :options="dropScoreOptions" />
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { inject, reactive } from 'vue';
  import {
    attemptOptions, dropScoreOptions,
  } from 'features/category_wizard/models/category_data';
  import FeedbackDisableModal from './FeedbackDisableModal';
  import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';

  const category = inject('category');

  const localstore = reactive({
    fibDetails: false,
    isFeedbackWarningVisible: false,
    showApplicableDetails: false,
  });
</script>

<style lang="scss" scoped>
  .edit-grading__checkbox-span {
    color: #565656;
    display: block;
    font-weight: normal;
    font-size: 0.75rem;
    margin-bottom: 0.313rem;
    margin-left: 0.125rem;
  }

  .edit-grading__detail {
    margin-bottom: 0.313rem;
  }

  .edit-grading__fib-detail {
    display: block;
    margin-top: 0.375rem;
  }

  .edit-grading__label {
    display: block;
    font-size: 0.85rem;
    margin: 0;
    margin-bottom: 0.188rem;
    padding: 0;
  }

  .edit-grading__main {
    overflow: auto;
    max-height: 25.188rem;
    padding: 0rem 0.8rem;
  }

  .edit-grading__radio-btn {
    display: block;
  }
</style>
