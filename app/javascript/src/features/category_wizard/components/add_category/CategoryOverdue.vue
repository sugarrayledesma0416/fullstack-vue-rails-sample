<template>
  <fieldset class="category-overdue">
    <legend class="category-overdue__legend">
      Category overdue policy
    </legend>
    <div class="category-overdue__body">
      <div v-show="categoryValidator.isStepInValid(6, [])" class="category__validation-error">
        There are invalid fields. Please review all inputs before saving.
      </div>
      <div class="category-overdue__accept-late-work">
        <h3 class="category-overdue__heading">
          Choose whether to accept late work in this category:
        </h3>
        <!-- eslint-disable vue/no-v-model-argument -->
        <div class="categoty-overdue__input-container">
          <VhlRadioButton
            id="new_accept_late_work"
            v-model:modelValue="category.acceptLateWork"
            name="new_accept_late_work"
            class="js-modal-a11y__first-focus-element"
            :class="testClass('accept-late-work-label')"
            testSelectorInput="accept-late-work-input"
            text="Students can submit overdue/late assignments for credit."
            :value="true" />
        </div>
        <div class="categoty-overdue__input-container">
          <VhlRadioButton
            id="new_do_not_accept_late_work"
            v-model:modelValue="category.acceptLateWork"
            name="new_do_not_accept_late_work"
            :class="testClass('accept-no-late-work-label')"
            testSelectorInput="accept-no-late-work-input"
            text="Students cannot submit overdue/late assignments for credit."
            :value="false" />
        </div>
        <!-- eslint-enable vue/no-v-model-argument -->
      </div>

      <div
        v-show="category.acceptLateWork"
        class="late-work-penalty"
        :class="testClass('late-work-penalty')">
        <h3 class="category-overdue__heading">
          How should overdue submissions be penalized:
        </h3>
        <!-- eslint-disable vue/no-v-model-argument -->
        <div class="categoty-overdue__input-container">
          <VhlRadioButton
            id="new_late_work_penalty_none"
            v-model:modelValue="category.lateWorkPenalty"
            name="new_late_work_penalty_none"
            :class="testClass('late-work-penalty-none-label')"
            testSelectorInput="late-work-penalty-none-input"
            text="No penalty"
            value="none" />
        </div>
        <div class="categoty-overdue__input-container">
          <VhlRadioButton
            id="new_late_work_penalty_day"
            v-model:modelValue="category.lateWorkPenalty"
            name="new_late_work_penalty_day"
            :class="testClass('percent-per-day-penalty-label')"
            testSelectorInput="percent-per-day-penalty-input"
            text="% per day"
            value="percent_per_day" />
        </div>
        <div class="categoty-overdue__input-container">
          <VhlRadioButton
            id="new_late_work_penalty_flat"
            v-model:modelValue="category.lateWorkPenalty"
            name="new_late_work_penalty_flat"
            :class="testClass('flat-percent-penalty-label')"
            testSelectorInput="flat-percent-penalty-input"
            text="% (flat)"
            value="flat_percent" />
        </div>
        <!-- eslint-enable vue/no-v-model-argument -->

        <div
          v-show="category.lateWorkPenalty !== 'none'"
          class="category-overdue__late-work-percent">
          <label
            for="new_late_work_penalty_percent"
            class="categoty-overdue__label">%
            <input
              id="new_late_work_penalty_percent"
              v-model.number="category.penaltyPercent"
              type="number"
              name="penalty_percent"
              :required="category.lateWorkPenalty !== 'none'"
              class="penalty-percent-input"
              :class="[
                {'penalty-percent__invalid': penaltyPercentInvalid.value },
                testClass('penalty-percent-input')
              ]">
          </label>
          <div
            v-show="penaltyPercentInvalid.value"
            class="category__validation-error  mar-top-5"
            :class="testClass('penalty-percent-error')">
            {{ penaltyPercentInvalid.msg }}
          </div>
        </div>
      </div>
    </div>
  </fieldset>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';
  import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';

  export default {
    name: 'CategoryOverdue',
    components: { VhlRadioButton },
    setup() {
      const category = inject('category');
      const categoryValidator = inject('categoryValidator');

      const penaltyPercentInvalid = computed(() => {
        return categoryValidator.hasErrorInPenaltyPercent();
      });

      return { category, categoryValidator, penaltyPercentInvalid, testClass };
    },
  };
</script>

<style scoped>
  .category-overdue {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-overdue__legend {
    display: none;
  }

  .category__validation-error {
    color: #ec4040;
    font-size: 0.75rem;
  }

  .mar-top-5 {
    margin-top: 0.3125rem;
  }

  .categoty-overdue__label {
    margin-top: 0.3125rem;
  }

  .categoty-overdue__input-container {
    margin-top: 0.1875rem;
  }

  .category-overdue__accept-late-work {
    margin-bottom: 1.25rem;
  }

  .category-overdue__heading {
    color: #565656;
    display: block;
    font-size: 0.625rem;
    font-weight: bold;
    margin: 0;
    padding: 0
  }

  .late-work-penalty {
    margin-bottom: 0.5rem;
  }

  .category-overdue__late-work-percent {
    margin-top: 0.5rem;
  }

  .categoty-overdue__label {
    color: #565656;
    margin-top: 0.3125rem;
  }

  .penalty-percent-input {
    border: 0.0625rem solid #ccc;
    box-shadow: 0 0 0.5rem #ccc;
    border-radius: 0.1875rem;
    color: #707070;
    padding: 0.25rem 0 0.25rem 0.25rem;
    margin-right: 0.3125rem;
    margin-bottom: 0;
    width: 3rem;
  }

  .penalty-percent__invalid {
    border: 0.125rem solid #d12209;
  }

</style>
