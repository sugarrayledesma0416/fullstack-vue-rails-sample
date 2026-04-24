<template>
  <div
    ref="modalElm"
    class="add-category-modal"
    :class="testClass('add-category-modal')">
    <div class="add-category__main">
      <div class="add-category__header">
        <span class="add-category__title"> {{ steps[currentStep]['title'] }} </span>
        <ul class="add-category__steps">
          <li
            v-for="(step, index) in steps"
            :key="step.id"
            class="add-category__step"
            :class="{ current: currentStep === index }" />
        </ul>
      </div>

      <form class="add-category__form">
        <CategoryName
          v-if="currentStep === 0"
          :course="courseDataStore.store.course"
          class="add_category__component" />
        <CategoryWeight
          v-else-if="currentStep === 1"
          class="add_category__component" />
        <CategoryGrading
          v-else-if="currentStep === 2"
          class="add_category__component" />
        <CategoryAttempts
          v-else-if="currentStep === 3"
          class="add_category__component" />
        <CategoryStrictness
          v-else-if="currentStep === 4"
          class="add_category__component" />
        <CategoryFeedback
          v-else-if="currentStep === 5"
          class="add_category__component" />
        <CategoryOverdue v-else class="add_category__component" />

        <div class="add-category__controls">
          <VhlLink
            class="add-category__cancel-link  js-modal-a11y__last-focus-element"
            testSelector="category-cancel-link"
            href="javascript://"
            @click="$emit('closeAdd', $event)">
            cancel
          </VhlLink>
          <div class="add-category__nav-items">
            <VhlLink
              v-if="currentStep > 0"
              href="javascript://"
              variant="button"
              featureVariant="learning-tracks"
              class="add-category__back-button  js-modal-a11y__last-focus-element"
              :class="testClass('category-back-button')"
              @click="goToPrevStep">
              Back
            </VhlLink>

            <VhlButton
              v-if="currentStep < 6"
              variant="primary"
              featureVariant="learning-tracks"
              type="button"
              class="js-modal-a11y__last-focus-element"
              :disabled="categoryValidator.isStepInValid(
                currentStep, courseDataStore.store.course.categories
              )"
              :class="testClass('category-next-button')"
              @click="goToNextStep">
              Next
            </VhlButton>

            <VhlButton
              v-if="currentStep === 6"
              variant="primary"
              featureVariant="learning-tracks"
              type="button"
              class="js-modal-a11y__last-focus-element"
              :disabled="categoryValidator.isStepInValid(6)"
              :class="testClass('category-save-button')"
              @click="saveCourseCategory()">
              Save
            </VhlButton>
          </div>
        </div>
      </form>
    </div>
    <div class="add-category__overlay" />
  </div>
</template>

<script>
  import { inject, onMounted, provide, reactive, ref } from 'vue';
  import Category from 'features/category_wizard/models/category';
  import CategoryAttempts from './CategoryAttempts';
  import CategoryGrading from './CategoryGrading';
  import CategoryFeedback from './CategoryFeedback';
  import CategoryName from './CategoryName';
  import CategoryOverdue from './CategoryOverdue';
  import CategoryStrictness from './CategoryStrictness';
  import CategoryValidator from 'features/category_wizard/models/category_validator';
  import CategoryWeight from './CategoryWeight';
  import useModal from './../use_modal';
  import VhlButton from 'features/learning_tracks/components/VhlButton';
  import VhlLink from 'features/learning_tracks/components/VhlLink';
  import { testClass } from 'music';

  export default {
    name: 'AddCategory',
    components: {
      CategoryAttempts,
      CategoryGrading,
      CategoryFeedback,
      CategoryName,
      CategoryOverdue,
      CategoryStrictness,
      CategoryWeight,
      VhlButton,
      VhlLink,
    },
    emits: ['closeAdd'],
    setup(props, { emit }) {
      const currentStep = ref(0);
      const steps = [
        { id: 0, name: 'name', title: 'Add Category' },
        { id: 2, name: 'weight', title: 'Category weight' },
        { id: 3, name: 'grading', title: 'Category grading' },
        { id: 4, name: 'attempts', title: 'Category attempts' },
        { id: 5, name: 'strictness', title: 'Category strictness' },
        { id: 6, name: 'feedback', title: 'Category feedback' },
        { id: 7, name: 'overdue policy', title: 'Category overdue policy' },
      ];

      const languageCode = inject('config').languageCode;
      const category = reactive(new Category({ languageCode: languageCode }));
      const categoryValidator = new CategoryValidator(category);
      const courseDataStore = inject('courseDataStore');
      const modalElm = ref(null);
      const { addCircularNavigation } = useModal();

      /**
       * go to next add category step.
       */
      function goToNextStep() {
        currentStep.value += 1;
      }

      /**
       * go to previous add category step.
       */
      function goToPrevStep() {
        currentStep.value -= 1;
      }

      /**
       * save the course category.
       */
      function saveCourseCategory() {
        courseDataStore.store.course.categories.push(category);
        courseDataStore.store.course.updateRank();
        emit('closeAdd');
      }

      onMounted(() => {
        addCircularNavigation(modalElm.value);
      });

      provide('category', category);
      provide('categoryValidator', categoryValidator);

      return {
        category,
        categoryValidator,
        courseDataStore,
        currentStep,
        goToPrevStep,
        goToNextStep,
        modalElm,
        saveCourseCategory,
        steps,
        testClass,
      };
    },
  };
</script>

<style scoped>
  .add-category__steps {
    float: right;
    margin-right: 0.3125rem;
    margin-top: 0.3125rem;
  }

  .add-category__step {
    background: rgb(238, 238, 238);
    border-radius: 0.625rem;
    display: inline-block;
    height: 0.625rem;
    margin: 0.0625rem;
    text-indent: -999em;
    width: 0.625rem;
  }

  .add-category__step.current {
    background-color: #FFC72E;
  }

  .add-category__overlay {
    background: #000;
    height: 100%;
    left: 0;
    opacity: .50;
    position: fixed;
    top: 0;
    width: 100%;
    z-index: 9998;
  }

  .add-category__main {
    background: #ffffff url(/images/ui-bg_flat_75_ffffff_40x100.png) 50% 50% repeat-x;
    border: 0.0625rem solid #394551;
    border-radius: 0;
    color: #333333;
    display: block;
    height: auto;
    left: 50%;
    overflow: hidden;
    padding: 0;
    position: fixed;
    text-align: left;
    transform: translateX(-50%) translateY(-50%);
    top: 50%;
    width: 25rem;
    z-index: 9999;
  }

  .add-category__header {
    background-color: #394551;
    color: #ffffff;
    cursor: move;
    display: flex;
    flex-direction: row;
    font-weight: bold;
    justify-content: space-between;
    padding: 0.5rem 0.5rem;
    position: relative;
  }

  .add-category__title {
    font-size: 0.9rem;
    letter-spacing: .01em;
    margin: 0.1em 1rem 0.1em 0;
  }

  .add-category__form {
    padding: 0.625rem 1rem;
  }

  .add_category__component {
    margin: 0;
  }

  .add-category__controls {
    align-items: center;
    display: flex;
    justify-content: space-between;
  }

  .add-category__back-button {
    margin-right: 1rem;
  }
</style>
