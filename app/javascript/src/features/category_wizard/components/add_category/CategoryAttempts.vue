<template>
  <fieldset class="category-attempts">
    <legend class="category-attempts__legend">
      Category attempts
    </legend>
    <div class="category-attempts__body">
      <div class="category-attempts__description">
        <span>
          Assignments in this category will have the following maximum
          of attempts, with some exceptions:
        </span>
        <VhlLink
          href="javascript://"
          :class="testClass('show-attempts-details')"
          @click="localstore.showAttemptsDetails = !localstore.showAttemptsDetails">
          (see details)
        </VhlLink>
        <div
          v-show="localstore.showAttemptsDetails"
          class="attempts-details"
          :class="testClass('attempts-details')">
          <span>The following are always limited to 1 attempt:</span>
          <ul class="attempts-details__list">
            <li class="attempts-details__list-item">
              True/false activities
            </li>
            <li class="attempts-details__list-item">
              Other multiple choice activities with only 2 choices
            </li>
            <li class="attempts-details__list-item">
              Open ended activities
            </li>
            <li class="attempts-details__list-item">
              Recording activities
            </li>
            <li class="attempts-details__list-item">
              Assessments
            </li>
          </ul>
        </div>
      </div>
      <BasicSelect
        id="max_attempts"
        v-model.number="category.maxAttempts"
        class="js-modal-a11y__first-focus-element"
        testSelector="max-attempts"
        :options="attemptOptions" />
    </div>
  </fieldset>
</template>

<script>
  import { inject, reactive } from 'vue';
  import { testClass } from 'music';
  import { attemptOptions } from 'features/category_wizard/models/category_data';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';

  export default {
    name: 'CategoryAttempts',
    components: { VhlLink, BasicSelect },
    setup() {
      const category = inject('category');
      const localstore = reactive({
        showAttemptsDetails: false,
      });

      return { attemptOptions, category, localstore, testClass };
    },
  };
</script>

<style scoped>
  .category-attempts {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-attempts__legend {
    display: none;
  }

  .category-attempts__description {
    margin-bottom: 0.5rem;
  }

  .attempts-details {
    margin-top: 0.625rem;
  }

  .attempts-details__list {
    margin-left: 1rem;
    margin-top: 0.125rem;
  }

  .attempts-details__list-item {
    font-weight: bold;
    list-style-type: disc;
  }
</style>
