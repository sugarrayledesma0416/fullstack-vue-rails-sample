<template>
  <fieldset class="category-name">
    <legend class="category-name__legend">
      Category name
    </legend>

    <div class="category-name__body">
      <div class="category-name__input-container">
        <label
          for="name"
          class="category-name__label"
          :class="testClass('category-name-label')">
          Name
        </label>
        <input
          ref="nameInputElm"
          v-model="category.name"
          class="category-name__input  js-modal-a11y__first-focus-element"
          :class="[
            {'category-name__invalid': localstore.nameChanged && nameInvalid.value },
            {'category-name__valid': !nameInvalid.value },
            testClass('category-name-input')
          ]"
          name="name"
          maxlength="15"
          type="text"
          required
          @input="localstore.nameChanged = true">
        <span>(15 character maximum)</span>
        <div
          v-if="localstore.nameChanged && nameInvalid.value"
          class="category__validation-error"
          :class="testClass('category-name-error')">
          {{ nameInvalid.msg }}
        </div>
      </div>

      <div class="category-name__examples">
        <h3 class="category-example__heading">
          Examples of categories:
        </h3>
        <ul class="category-name__examples-list" :class="testClass('category-examples')">
          <li>Homework</li>
          <li>Quizzes</li>
          <li>Essays</li>
          <li>Midterm</li>
          <li>Final</li>
          <li>Presentations</li>
        </ul>
      </div>
    </div>
  </fieldset>
</template>

<script>
  import { computed, inject, onMounted, reactive, ref } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'CategoryName',
    props: {
      course: { required: true, type: Object },
    },
    setup(props) {
      const category = inject('category');
      const categoryValidator = inject('categoryValidator');
      const localstore = reactive({
        nameChanged: false,
      });
      const nameInputElm = ref(null);

      const nameInvalid = computed(() => {
        return categoryValidator.hasErrorInCategoryName(props.course.categories);
      });

      onMounted(() => {
        nameInputElm.value.focus();
      });

      return { category, nameInputElm, nameInvalid, localstore, testClass };
    },
  };
</script>

<style scoped>
  .category-name {
    border: 0;
    font-size: 0.75rem;
    min-height: 15.625rem;
    padding: 0.75rem 0;
    position: relative;
  }

  .category-name__legend {
    display: none;
  }

  .category-name__input-container {
    margin-bottom: 1.25rem;
  }

  .category-name__label {
    color: #565656;
    display: block;
    font-size: 0.625rem;
    font-weight: bold;
    margin-bottom: 0.1875rem;
    padding: 0
  }

  .category-name__input {
    border: 0.0625rem solid #ccc;
    border-radius: 0.1875rem;
    box-shadow: 0 0 0.5rem #ccc;
    color: #969696;
    height: 0.9375rem;
    margin-right: 0.3125rem;
    padding: 0.5rem 0.9375rem;
    width: 11.25rem;
  }

  .category-name__invalid {
    border: 0.125rem solid #d12209;
  }

  .category-name__valid {
    border: 0.125rem solid #01AA4D;
  }

  .category-example__heading {
    color: #565656;
    display: block;
    font-size: 0.6875rem;
    font-weight: bold;
    margin: 0;
    margin-bottom: 0.1875rem;
    padding: 0;
  }

  .category-name__examples-list {
    list-style: none;
    padding: 0 1rem;
  }

  .category__validation-error {
    color: #ec4040;
    font-size: 0.75rem;
    margin-top: 0.3125rem;
  }
</style>
