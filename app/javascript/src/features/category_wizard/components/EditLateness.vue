<template>
  <div class="lateness__main">
    <div class="lateness__detail">
      <label class="lateness__label" :class="testClass('accept-late-work-category')">
        Choose whether to accept late work in this category:
      </label>
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        id="accept_late_work"
        v-model:modelValue="category.acceptLateWork"
        class="lateness__radio-btn"
        name="accept_late_work"
        testSelectorInput="accept-late-work"
        text="Students can submit overdue/late assignments for credit."
        :value="true" />
      <VhlRadioButton
        id="do_not_accept_late_work"
        v-model:modelValue="category.acceptLateWork"
        class="lateness__radio-btn"
        name="do_not_accept_late_work"
        testSelectorInput="accept-no-late-work"
        text="Students cannot submit overdue/late assignments for credit."
        :value="false" />
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
    <div
      v-if="category.acceptLateWork"
      class="lateness__detail"
      :class="testClass('late-work-penalty-category')">
      <label class="lateness__label">
        How should overdue submissions be penalized:
      </label>
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        id="late_work_penalty_none"
        v-model:modelValue="category.lateWorkPenalty"
        class="lateness__radio-btn"
        name="late_work_penalty_none"
        testSelectorInput="late-work-penalty-none"
        text="No penalty"
        value="none" />
      <VhlRadioButton
        id="late_work_penalty_day"
        v-model:modelValue="category.lateWorkPenalty"
        class="lateness__radio-btn"
        name="late_work_penalty_day"
        testSelectorInput="late-work-penalty-day"
        text="% per day"
        value="percent_per_day" />
      <VhlRadioButton
        id="late_work_penalty_flat"
        v-model:modelValue="category.lateWorkPenalty"
        class="lateness__radio-btn  u-mar-bot-5"
        name="late_work_penalty_flat"
        testSelectorInput="late-work-penalty-flat"
        text="% (flat)"
        value="flat_percent" />
      <!-- eslint-enable vue/no-v-model-argument -->
      <div v-if="category.lateWorkPenalty !== 'none'" :class="testClass('penalty-percent-detail')">
        <label class="lateness__penalty-label" for="late_work_penalty_percent">
          <input
            id="late_work_penalty_percent"
            v-model.number="category.penaltyPercent"
            type="number"
            class="lateness__penalty-percent"
            :class="{'u-error': penaltyPercentInvalid.value}"
            name="penalty_percent"
            :required="category.lateWorkPenalty !== 'none'"> %
        </label>
        <div
          v-show="penaltyPercentInvalid.value"
          class="input_error name">
          {{ penaltyPercentInvalid.msg }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { computed, inject } from 'vue';
  import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';

  export default {
    name: 'EditLateness',
    components: { VhlRadioButton },
    setup() {
      const category = inject('category');
      const categoryValidator = inject('categoryValidator');
      const penaltyPercentInvalid = computed(() => {
        return categoryValidator.hasErrorInPenaltyPercent();
      });

      return { category, penaltyPercentInvalid, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  .lateness__detail {
    margin-bottom: 0.875rem;
  }

  .lateness__label {
    display: block;
    font-size: 0.85rem;
    margin: 0;
    margin-bottom: 0.188rem;
    padding: 0;
  }

  .lateness__main{
    padding: 0rem 0.8rem;
  }

  .lateness__penalty-label {
    color: #9f9c9c;
  }

  .lateness__penalty-percent {
    border: 0.0625rem solid #ccc;
    box-shadow: 0 0 0.5rem #ccc;
    border-radius: 0.1875rem;
    color: #707070;
    padding: 0.25rem 0 0.25rem 0.25rem;
    margin-right: 0.3125rem;
    margin-bottom: 0;
    width: 3rem;
  }

  .lateness__radio-btn {
    display: block;
  }

  .u-mar-bot-5 {
    margin-bottom: 0.313rem;
  }

  .u-error {
    border: 0.125rem solid #d12209 !important;
  }
</style>
