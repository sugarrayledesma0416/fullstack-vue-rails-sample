<template>
  <fieldset class="category-feedback">
    <legend class="category-feedback__legend">
      Category feedback
    </legend>
    <div class="category-feedback__body">
      <div>
        <h3 class="category-feedback__heading">
          For fill-in-the-blank activities in this category:
          <VhlLink
            href="javascript://"
            :class="testClass('show-feedback-details')"
            @click="localstore.feedbackDetails = !localstore.feedbackDetails">
            (see details)
          </VhlLink>
        </h3>

        <div
          v-show="localstore.feedbackDetails"
          class="category-feedback__details"
          :class="testClass('feedback-details')">
          Detailed feedback is provided to students on fill-in-the-blank responses when
          capitalization, punctuation, and accents are misused or when there are missing
          or extra words.
        </div>

        <!-- eslint-disable vue/no-v-model-argument -->
        <div>
          <VhlRadioButton
            id="new_enhanced_feedback_enabled"
            v-model:modelValue="category.enhancedFeedbackDisabled"
            name="enhanced_feedback_enabled"
            class="js-modal-a11y__first-focus-element"
            :class="testClass('enhanced-feedback-enabled-label')"
            testSelectorInput="enhanced-feedback-enabled"
            text="Provide students with enhanced feedback"
            :value="false" />
        </div>
        <div>
          <VhlRadioButton
            id="new_enhanced_feedback_disabled"
            v-model:modelValue="category.enhancedFeedbackDisabled"
            name="enhanced_feedback_disabled"
            :class="testClass('enhanced-feedback-disabled-label')"
            testSelectorInput="enhanced-feedback-disabled"
            text="Don't provide students with enhanced feedback"
            :value="true"
            @change="localstore.isFeedbackWarningVisible = true" />
          <!-- eslint-enable vue/no-v-model-argument -->
          <FeedbackDisableModal
            v-if="localstore.isFeedbackWarningVisible"
            @close="localstore.isFeedbackWarningVisible = false" />
        </div>
      </div>
    </div>
  </fieldset>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { testClass } from 'music';
  import FeedbackDisableModal from 'features/category_wizard/components/FeedbackDisableModal';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';

  export default {
    name: 'CategoryFeedback',
    components: { FeedbackDisableModal, VhlLink, VhlRadioButton },
    setup() {
      const category = inject('category');
      const localstore = reactive({
        feedbackDetails: false,
        isFeedbackWarningVisible: false,
      });

      return { category, localstore, testClass };
    },
  };
</script>


<style scoped>
  .category-feedback {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-feedback__legend {
    display: none;
  }

  .category-feedback__heading {
    color: #565656;
    display: block;
    font-size: 0.6875rem;
    font-weight: bold;
    margin-bottom: 0.1875rem;
    padding: 0
  }

  .category-feedback__details {
    margin-bottom: 0.625rem;
    margin-top: 0.625rem;
  }
</style>
