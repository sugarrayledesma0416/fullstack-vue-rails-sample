<template>
  <div
    ref="modalElm"
    :class="testClass('edit-category-modal')">
    <div class="edit-category__main">
      <div class="edit-category__titlebar">
        <span :class="testClass('edit-category-title')" class="edit-category__title">
          Edit Category
        </span>
        <button
          class="edit-category__close-btn  js-modal-a11y__first-focus-element"
          type="button"
          title="Close"
          @click="$emit('closeEdit', $event)">
          <span class="edit-category__close">X</span>
        </button>
      </div>
      <div class="edit-category__body">
        <div :class="testClass('name-weight-container')">
          <label for="name" class="edit-category__label">Name</label>
          <input
            ref="nameInputElm"
            v-model="category.name"
            class="edit-category__input"
            :class="[
              {'edit-category__invalid-input': nameInvalid.value},
              testClass('edit-category-name')
            ]"
            type="text"
            name="name"
            maxlength="15"
            required>
          <div
            v-if="nameInvalid.value"
            class="edit-category__error-validation"
            :class="testClass('edit-category-name-error')">
            {{ nameInvalid.msg }}
          </div>
          <span class="edit-category__size-limit">(15 character maximum)</span>
          <label for="weighting_percent" class="edit-category__label">Weight</label>
          <input
            v-model.number="category.weightingPercent"
            name="weighting_percent"
            type="number"
            class="edit-category__input  edit-category__weight-percent"
            :class="[
              {'edit-category__invalid-input': weightInvalid.value},
              testClass('edit-category-weight')
            ]"
            min="1"
            max="100"
            required> %
          <div
            v-if="weightInvalid.value"
            class="edit-category__error-validation"
            :class="testClass('edit-category-weight-error')">
            {{ weightInvalid.msg }}
          </div>
        </div>
        <TabSet class="tabset-category" label="category tools tabs">
          <TabSetTab label="Grading">
            <EditGrading />
          </TabSetTab>
          <TabSetTab label="Lateness">
            <EditLateness />
          </TabSetTab>
        </TabSet>
        <div>
          <VhlButton
            variant="primary"
            class="edit-category__done-btn  js-modal-a11y__last-focus-element"
            :class="testClass('edit-category-done')"
            :disabled="category.penaltyPercent === '' ||
              nameInvalid.value || weightInvalid.value ||
              penaltyPercentInvalid.value"
            @click="saveAndCloseEditCatgeory($event)">
            Done
          </VhlButton>
        </div>
      </div>
    </div>
    <div class="edit-category__overlay" />
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { computed, inject, onMounted, provide, reactive, ref } from 'vue';
  import { cloneObject } from 'shared/utils';
  import useModal from './use_modal';
  import CategoryValidator from 'features/category_wizard/models/category_validator';
  import EditGrading from './EditGrading';
  import EditLateness from './EditLateness';
  import TabSet from 'shared/vue/TabSet';
  import TabSetTab from 'shared/vue/TabSetTab';
  import VhlButton from 'features/learning_tracks/components/VhlButton';

  export default {
    name: 'EditCategory',
    components: { EditGrading, EditLateness, TabSet, TabSetTab, VhlButton },
    props: {
      categoryIndex: { required: true, type: Number },
    },
    emits: ['closeEdit'],
    setup(props, { emit }) {
      const courseDataStore = inject('courseDataStore');
      const category = reactive(
        cloneObject(courseDataStore.store.course.categories[props.categoryIndex])
      );
      const remainingCategories = courseDataStore.store.course.categories.filter(
        (cat) => cat.name !== category.name
      );
      const categoryValidator = new CategoryValidator(category);
      const tabs = reactive(
        [
          { label: 'Grading', selected: true },
          { label: 'Lateness', selected: false },
        ]
      );
      const nameInvalid = computed(() => {
        return categoryValidator.hasErrorInCategoryName(remainingCategories);
      });
      const penaltyPercentInvalid = computed(() => {
        return categoryValidator.hasErrorInPenaltyPercent();
      });
      const weightInvalid = computed(() => {
        return categoryValidator.hasErrorInCategoryWeight();
      });
      const nameInputElm = ref(null);
      const modalElm = ref(null);
      const { addCircularNavigation } = useModal();

      const saveAndCloseEditCatgeory = (evt) => {
        Object.assign(
          courseDataStore.store.course.categories[props.categoryIndex],
          category
        );
        emit('closeEdit', evt);
      };

      onMounted(() => {
        nameInputElm.value.focus();
        addCircularNavigation(modalElm.value);
      });

      provide('tabs', tabs);
      provide('category', category);
      provide('categoryValidator', categoryValidator);

      return {
        category,
        categoryValidator,
        courseDataStore,
        modalElm,
        nameInputElm,
        nameInvalid,
        penaltyPercentInvalid,
        remainingCategories,
        saveAndCloseEditCatgeory,
        testClass,
        weightInvalid,
      };
    },
  };
</script>

<style lang="scss" scoped>
  .edit-category__body {
    background: none;
    border: 0;
    clear: both;
    color: #333333;
    font-size: 0.75rem;
    height: auto;
    max-height: none;
    min-height: 0rem;
    overflow: visible;
    padding: 0.625rem 1rem;
    position: relative;
    width: auto;
    zoom: 1;
  }

  .edit-category__close {
    font-weight: bold;
    display: block;
    text-indent: 6249.938rem;
  }

  .edit-category__close-btn {
    background: transparent url(/images/dialog_vol.png) 0.375rem 0rem no-repeat;
    border: 0rem;
    cursor: pointer;
    display: inline-block;
    margin: -0.625rem 0 0 0;
    padding: 0.063rem;
    position: absolute;
    right: 0.3rem;
    text-align: center;
    top: 50%;
    width: 1.188rem;
    zoom: 1;
  }

  .edit-category__done-btn {
    margin-top: 0.5rem;
    min-width: 5rem;
    line-height: 1.1rem;
  }

  .edit-category__input {
    border: 0.063rem solid #ccc;
    border-radius: 0.188rem;
    box-shadow: 0 0 0.5rem #ccc;
    color: #969696;
    height: 0.938rem;
    width: 11.25rem;
    padding: 0.5rem 0.938rem;
  }

  .edit-category__invalid-input {
    border: 0.125rem solid #d12209;
  }

  .edit-category__label {
    display: block;
    font-size: 0.688rem;
    margin: 0;
    margin-bottom: 0.188rem;
    padding: 0;
  }

  .edit-category__main {
    background: #ffffff url(/images/ui-bg_flat_75_ffffff_40x100.png) 50% 50% repeat-x;
    border: 0.063rem solid #394551;
    border-radius: 0rem;
    color: #333333;
    display: block;
    font-family: Open Sans, Helvetica Neue, Helvetica, Arial, Sans-serif;
    font-size: 1.2em;
    height: auto;
    left: 50%;
    padding: 0rem;
    position: fixed;
    overflow: hidden;
    text-align: left;
    top: 50%;
    transform: translateX(-50%) translateY(-50%);
    width: 25rem;
    z-index: 9999;
  }

  .edit-category__error-validation {
    color: 0.125rem solid #d12209;
    margin-top: 0.313rem;
  }

  .edit-category__overlay {
    background: #000;
    height: 100%;
    left: 0;
    opacity: .50;
    position: fixed;
    top: 0;
    width: 100%;
    z-index: 9998;
  }

  .edit-category__size-limit {
    display: block;
    font-size: 0.625rem;
    font-style: italic;
  }

  .edit-category__title {
    letter-spacing: .01rem;
    float: left;
  }

  .edit-category__titlebar {
    background-color: #394551;
    border: none;
    border-radius: 0rem;
    color: #ffffff;
    cursor: move;
    display: block;
    font-weight: bold;
    padding: 0.7rem 0.1rem 1.7rem 0.7rem;
    position: relative;
    margin: 0;
  }

  .edit-category__weight-percent {
    margin-bottom: 0.5rem;
  }

  .tabset-category {
    border: 0.063rem solid #eeeeee;
  }
</style>
