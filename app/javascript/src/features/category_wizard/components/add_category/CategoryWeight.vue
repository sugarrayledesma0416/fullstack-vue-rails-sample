<template>
  <fieldset class="category-weight">
    <legend class="category-weight__legend">
      Category weight
    </legend>

    <div class="category-weight__body">
      <div class="category-weight__input-container">
        <label
          for="weighting_percent"
          class="category-weight__label"
          :class="testClass('category-weight-label')">
          Weight
        </label>
        <input
          v-model.number="category.weightingPercent"
          class="category-weight__input  js-modal-a11y__first-focus-element"
          :class="[
            {'category-weight__invalid': localstore.weightChanged && weightInvalid.value },
            {'category-weight__valid': localstore.weightChanged && !weightInvalid.value },
            testClass('category-weight-input')
          ]"
          name="weighting_percent"
          type="number"
          required
          @input="localstore.weightChanged = true"> %
        <div
          v-if="localstore.weightChanged && weightInvalid.value"
          class="category__validation-error"
          :class="testClass('category-weight-error')">
          {{ weightInvalid.msg }}
        </div>
      </div>

      <div class="category-weight__examples">
        <div>
          A weighted category is the average of a set of grades, where each category
          carries a different amount of importance.
        </div>
        <div>
          For example, you might choose to create many categories or just one.
        </div>
        <div class="category-example-type">
          <div class="one-category">
            <h3 class="category-example-heading">
              One Category
            </h3>
            <ul>
              <li>Homework: 100%</li>
            </ul>
          </div>
          <div class="many-categories">
            <h3 class="category-example-heading">
              Many Categories
            </h3>
            <ul>
              <li>Homework: 40%</li>
              <li>Quizzes: 20%</li>
              <li>Essays: 20%</li>
              <li>Midterm: 10%</li>
              <li>Final: 10%</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </fieldset>
</template>

<script>
  import { computed, inject, reactive } from 'vue';
  import { testClass } from 'music';
  export default {
    name: 'CategoryWeight',
    setup() {
      const category = inject('category');
      const categoryValidator = inject('categoryValidator');
      const localstore = reactive({
        weightChanged: false,
      });

      const weightInvalid = computed(() => {
        return categoryValidator.hasErrorInCategoryWeight();
      });

      return { category, weightInvalid, localstore, testClass };
    },
  };
</script>

<style scoped>
  .category-weight {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.625rem 0;
    position: relative;
  }

  .category-weight__legend {
    display: none;
  }

  .category-weight__input-container {
    margin-bottom: 1.25rem;
  }

  .category-weight__label {
    color: #565656;
    display: block;
    font-size: 0.6875rem;
    font-weight: bold;
    margin-bottom: 0.1875rem;
    padding: 0
  }

  .category-weight__input {
    border: 0.0625rem solid #ccc;
    box-shadow: 0 0 0.5rem #ccc;
    border-radius: 0.1875rem;
    color: #969696;
    height: 0.9375rem;
    margin-right: 0.3125rem;
    padding: 0.5rem 0.9375rem;
    width: 11.25rem;
  }

  .category-example__heading {
    color: #565656;
    font-size: 0.6875rem;
    padding: 0;
    margin: 0;
    margin-bottom: 0.1875rem;
  }

  .category-weight__examples-list {
    list-style: none;
    padding: 0 1rem;
  }

  .category__validation-error {
    color: #ec4040;
    font-size: 0.75rem;
    margin-top: 0.3125rem;
  }

  .category-example-heading {
    color: #565656;
    font-size: 0.6875rem;
    margin: 0;
    margin-bottom: 0.1875rem;
    padding: 0;
  }

  .one-category {
    padding-right: 1.875rem;
  }

  .category-example-type {
    display: flex;
    margin-top: 1.25rem;
  }

  .category-weight__invalid {
    border: 0.125rem solid #d12209;
  }

  .category-weight__valid {
    border: 0.125rem solid #01AA4D;
  }
</style>
