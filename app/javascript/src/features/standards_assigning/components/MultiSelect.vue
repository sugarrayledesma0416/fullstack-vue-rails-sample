<template>
  <div ref="disclosureContainer">
    <BasicDisclosure
      variant="end"
      class="multi-select"
      :class="[
        testClass(`${type}-multi-select`),
        testClass('multi-select'),
        `${type}-multi-select`
      ]"
      :expanded="isExpanded"
      :float="true"
      :headerTextClosed="dropdownText"
      :headerTextOpen="dropdownText"
      role="button"
      :aria-expanded="isExpanded"
      :aria-label="`Select ${type}`"
      @disclosureClick="toggleExpanded">
      <template #caret>
        <span class="triangle-icon" :class="testClass(`${type}-caret`)">
          <TriangleIcon />
        </span>
      </template>
      <template #default>
        <div v-if="resetAll" class="deselect-all-container">
          <button
            :disabled="!isAnyOptionSelected"
            class="deselect-all"
            :class="testClass('deselect-all-button')"
            @click.prevent="deselectAll">
            Deselect All
          </button>
        </div>
        <div ref="optionsType" :class="`${type}-options  options-container`">
          <div
            v-for="(category, index) in data"
            :id="`${type}-option-${index}`"
            :key="index"
            class="option  u-pad-lt-3"
            role="menuitemcheckbox"
            :aria-checked="selectedItems.includes(category.id)"
            tabindex="0">
            <input
              :id="`${type}-id-${index}`"
              v-model="selectedItems"
              class="c-form-item__checkbox"
              :class="testClass(`${type}-checkbox-${index}`)"
              :value="category.id"
              type="checkbox"
              :aria-labelledby="`${type}-label-${index}`"
              @change="handleCheck">
            <label
              :id="`${type}-label-${index}`"
              class="c-form-item__label  u-txt-16  u-txt-gray-3"
              :class="[testClass(`${type}-label`), `${type}-label`]"
              :for="`${type}-id-${index}`">
              {{ typeof category === 'string' ? category : category.name }}
            </label>
          </div>
        </div>
      </template>
    </BasicDisclosure>
  </div>
</template>

<script setup>
  import { computed, onMounted, onUnmounted, ref, watchEffect } from 'vue';
  import { testClass } from 'music';
  import BasicDisclosure
    from 'music/app/javascript/src/components/basic_disclosure/v1.1/BasicDisclosure';
  import TriangleIcon
    from '../../gradebook/standards/section_report_filters/components/TriangleIcon.vue';
  import useStandardsAssigningStore from '../models/use_standards_assigning_store.js';
  const props = defineProps({
    data: { type: Array, default: () => [] },
    resetAll: { type: Boolean, default: false },
    selectedOption: { type: [String, Number], default: null },
    type: { type: String, default: '' },
  });

  const emit = defineEmits(['update:selectedItems', 'update:deselectAll']);

  const optionsType = ref(null);
  const isExpanded = ref(false);
  const disclosureContainer = ref(null);
  const selectedItems = ref([]);
  const store = useStandardsAssigningStore();

  const isAnyOptionSelected = computed(() => selectedItems.value.length > 0);

  const dropdownText = computed(() => {
    const count = selectedItems.value.length;

    if (count === 0) return `Select ${props.type}`;
    return `${count} ${props.type} Selected`;
  });

  /**
   * Handles the change event for the checkboxes.
   *
   * @param {Event} event - The change event triggered by the checkbox.
   */
  function handleCheck(event) {
    const isChecked = event.target.checked;
    emit('update:selectedItems', { value: event.target.value, isChecked } );
  }

  /**
   * Deselects all selected items.
   */
  function deselectAll() {
    selectedItems.value = [];
    emit('update:deselectAll');
  }

  /**
   * Toggles the expanded state of the dropdown.
   */
  function toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  /**
   * Handles clicks outside the disclosure container to close the dropdown.
   *
   * @param {Event} event - The click event.
   */
  function handleClickOutside(event) {
    if (disclosureContainer.value && !disclosureContainer.value.contains(event.target)) {
      isExpanded.value = false;
    }
  }

  /**
   * Handles the `keydown` event and closes the dropdown when the `Escape` key is pressed.
   *
   * @param {KeyboardEvent} event - The keyboard event triggered by user input.
   */
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      isExpanded.value = false;
    }
  }

  /**
   * Stores and emits the selected item.
   * @param {number} itemId - The ID of the item to select.
   */
  function selectAndEmit(itemId) {
    selectedItems.value = [itemId];
    emit('update:selectedItems', {
      value: itemId,
      isChecked: true,
      defaultSelected: true,
    });
  }

  watchEffect(() => {
    if (store.resetAllFilters && props.data.length > 0) {
      deselectAll();
      store.resetAllFilters = false;
    }
  });

  onMounted(() => {
    if (
      props.type === 'unit' &&
      props.data.length > 0 &&
      props.selectedOption
    ) {
      selectAndEmit(Number(props.selectedOption));
    }

    document.addEventListener('click', handleClickOutside);
    document.addEventListener('keydown', handleKeydown);
  });

  onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside);
    document.removeEventListener('keydown', handleKeydown);
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .deselect-all-container {
    display: flex;
    justify-content: flex-end;
    font-size: $font-size-16;
  }

  .deselect-all {
    background: none;
    border: none;
    color: $blue;
    cursor: pointer;
    display: inline-block;
    letter-spacing: rpx(1);
    margin-top: rpx(10);
    padding-right: rpx(8);
    text-align: right;
    text-underline-offset: 0.5em;

    &:focus,
    &:active {
      border: none;
      outline: none;
    }

    &:hover {
      text-decoration: underline;
    }
    &:disabled {
      color: #ccc;
      cursor: not-allowed;
      text-decoration: none;
    }
  }

  .option {
    border-bottom: rpx(1) solid #ddd;
    margin-bottom: rpx(5);

    &:last-child {
      border-bottom: none;
    }
  }

  .options-container {
    overflow-y: auto;
    max-height: rpx(350);
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

  [class]:deep(.disclosure__image) {
    margin-right: rpx(12);
    rotate: 0deg;
  }

  [class]:deep(.disclosure__button-content) {
    justify-content: space-between;
  }

  [class]:deep(.is-expanded .disclosure__image) {
    rotate: 180deg;
  }

  [class] :deep(.is-floater) {
    left: 0;
    min-width: 0;
    position: relative;
    top: 0;
    width: 100%;
    z-index: 2;
  }
</style>
