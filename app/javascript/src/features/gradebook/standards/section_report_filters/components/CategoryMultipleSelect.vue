<template>
  <BasicDisclosure
    variant="end"
    class="category-multi-select"
    :class="[testClass('category-multi-select'), { 'is-disabled': disabled }]"
    :disabled="disabled"
    :expanded="isExpanded"
    :float="true"
    :headerTextClosed="dropdownText"
    :headerTextOpen="dropdownText"
    @disclosureClick="toggleExpanded">
    <template #caret>
      <span class="triangle-icon"><TriangleIcon /></span>
    </template>
    <template #default>
      <div ref="categoryOptions" class="category-options">
        <div
          v-for="(category, index) in categories"
          :id="`category-option-${index}`"
          :key="index"
          class="category-option  u-pad-lt-3"
          :class="[
            { 'selected-row': store.isCategoryChecked[index] },
            index === 0 ? 'u-pad-top-8' : '',
            testClass('category-option')
          ]"
          :style="{ borderLeft: `3px solid ${borderColors[category]}` }">
          <input
            :id="`category-id-${index}`"
            class="c-form-item__checkbox"
            :class="testClass(`category-checkbox-${index}`)"
            :value="index"
            type="checkbox"
            :checked="store.isCategoryChecked[index]"
            @change="handleCheck">
          <label
            class="c-form-item__label  category-label  u-txt-16  u-txt-gray-3"
            :class="testClass('category-label')"
            :for="`category-id-${index}`">
            {{ category }}
          </label>
        </div>
      </div>
    </template>
  </BasicDisclosure>
</template>

<script setup>
  import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
  import { testClass } from 'music';
  import useSectionReportFilterStore from '../stores/use_section_report_filter_store';
  import BasicDisclosure
    from 'music/app/javascript/src/components/basic_disclosure/v1.1/BasicDisclosure';
  import TriangleIcon from './TriangleIcon';

  const props = defineProps({
    categories: { type: Array, default: () => [] },
  });

  const borderColors = {
    'Quizzes': '#EF2121',
    'Unit Test': '#5570FE',
    'Speaking and Writing Tests': '#FEE355',
  };
  const isExpanded = ref(false);
  const disabled = computed(() => props.categories.length === 0);
  const categoryOptions = ref(null);
  const store = useSectionReportFilterStore();

  const dropdownText = computed(() => {
    const selectedCount = Object.values(store.isCategoryChecked).filter(Boolean).length;
    return selectedCount === 0 ? 'Select Categories' : `${selectedCount} Selected`;
  });

  /**
   * Toggles the isExpanded value for opening or closing the disclosure.
   */
  function toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  /**
   * Collapses the category multi-select by setting the `isExpanded` state to false.
   */
  function collapse() {
    isExpanded.value = false;
  }

  /**
   * Handles the change event for a category checkbox. Updates the checked state for the
   * corresponding category and emits a toggle event with the category ID and its checked status.
   *
   * @param {Event} event - The change event triggered by the checkbox input.
   */
  function handleCheck(event) {
    const categoryId = parseInt(event.target.value, 10);
    store.isCategoryChecked[categoryId] = event.target.checked;
  }

  /**
   * Handles clicks outside of the category multi-select component. If a click is detected
   * outside the component and it is currently expanded, it collapses the multi-select.
   *
   * @param {MouseEvent} event - The click event triggered by user interaction.
   */
  function handleClickOutside(event) {
    if (!event.target.closest('.category-multi-select') && isExpanded.value) {
      collapse();
    }
  }

  watch(() => props.categories, async (newValue, oldValue) => {
    props.categories.forEach((category, index) => {
      store.isCategoryChecked[index] = true;
    });
  });

  onMounted(() => {
    props.categories.forEach((category, index) => {
      store.isCategoryChecked[index] = true;
    });
    document.addEventListener('click', handleClickOutside);
  });

  onBeforeUnmount(() => {
    document.removeEventListener('click', handleClickOutside);
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .category-options .category-option {
    &:hover {
      background-color: $gray-f5;
    }
    &:not(:first-child) {
      padding-top: rpx(6);
    }
  }

  [class]:deep(.disclosure__button) {
    border: rpx(1) solid $gray-d;
    border-radius: rpx(3);
    font-family: inherit;
    font-size: $font-size-16;
    line-height: rpx(36);
    padding: rpx(4);

    &:not([disabled]):hover {
      background-color: $gray-f8;
    }

    & .embedded-icon .triangle-icon svg {
      --fill: #8e8e8e;
    }

    &:hover .embedded-icon .triangle-icon svg {
      --fill: #8e8e8e;
    }

    &[disabled] .embedded-icon .triangle-icon svg {
      --fill: var(--embedded-icon-disabled-color);
    }
  }

  [class]:deep(.disclosure__button .disclosure-header-text) {
    --disclosure-header-text-color: $black;
    --disclosure-header-text-style: none;
    --disclosure-header-text-case: capitalize;
    padding-left: rpx(8);
  }

  [class]:deep(.disclosure__button[disabled]) {
    cursor: not-allowed;
  }

  [class]:deep(.disclosure__button[disabled] .disclosure-header-text) {
    color: $link-disabled-color;
  }

  [class]:deep(.embedded-icon .triangle-icon svg) {
    bottom: rpx(3);
    display: block;
    left: rpx(16);
    width: rpx(10);
    position: relative;
  }

  :deep(.is-expanded .embedded-icon .triangle-icon svg) {
    left: rpx(-10);
  }

  .category-multi-select .category-label::after {
    background-image: url('/images/checkmark-black.svg');
    height: 1rem;
    left: 0.5rem;
    top: 0.5rem;
    width: 1rem;
  }

  [class]:deep(.disclosure__image) {
    margin-right: 0.75rem;
    rotate: 0deg;
  }

  [class]:deep(.is-floater) {
    min-width: 100%;
    padding: 0;
  }

  [class]:deep(.disclosure__button-content) {
    justify-content: space-between;
  }

  [class]:deep(.is-expanded .disclosure__image) {
    rotate: 180deg;
  }
</style>
