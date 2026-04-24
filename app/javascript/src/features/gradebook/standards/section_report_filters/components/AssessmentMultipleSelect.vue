<template>
  <BasicDisclosure
    variant="end"
    class="assessment-multi-select"
    :class="[testClass('assessment-multi-select'), { 'is-disabled': disabled }]"
    :disabled="disabled"
    :expanded="isExpanded"
    :float="true"
    :headerTextClosed="dropdownText"
    :headerTextOpen="dropdownText"
    @disclosureClick="toggleExpanded()">
    <template #caret>
      <span class="triangle-icon"><TriangleIcon /></span>
    </template>
    <template #default>
      <div ref="assessmentOptions" class="assessment-options">
        <div
          v-for="([assessmentTitle, assessmentId], index) in assessments"
          :id="`assessment-option-${index}`"
          :key="`assessment-id-${assessmentId}`"
          class="assessment-option"
          :class="{ 'selected-row': isChecked[assessmentId] }"
          @click="store.userHasChangedAssessmentSelection = true">
          <input
            :id="`assessment-id-${assessmentId}`"
            class="c-form-item__checkbox"
            :class="testClass('assessment-checkbox')"
            :value="assessmentId"
            :checked="isChecked[parseInt(assessmentId, 10)]"
            type="checkbox"
            @change="handleCheck">
          <label
            class="c-form-item__label  u-txt-16  u-txt-gray-3"
            :class="testClass('assessment-label')"
            :for="`assessment-id-${assessmentId}`">
            {{ assessmentTitle }}
          </label>
        </div>
      </div>
    </template>
  </BasicDisclosure>
</template>

<script setup>
  import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
  import useSectionReportFilterStore from '../stores/use_section_report_filter_store';
  import BasicDisclosure from
  'music/app/javascript/src/components/basic_disclosure/v1.1/BasicDisclosure';
  import TriangleIcon from './TriangleIcon';
  import { testClass } from 'music';

  /** @typedef {[string, number]} AssessmentTuple */
  const props = defineProps({
    assessments: {
      /** @type import('vue').PropType<AssessmentTuple[]> */
      type: Array,
      default: () => [],
    },
    previouslySelectedActivityIdStrings: {
      type: Array,
      default: () => [],
    },
  });

  const emit = defineEmits(['toggleAssessment']);
  const isExpanded = ref(false);
  const isChecked = reactive({});
  const disabled = ref(true);
  const assessmentOptions = ref(null);
  const assessmentIds = computed(() => props.assessments.map((assessment) => parseInt(assessment[1], 10)));
  const previouslySelectedActivityIntIds = computed(() => (props.previouslySelectedActivityIdStrings || []).map((id) => parseInt(id, 10)));
  const store = useSectionReportFilterStore();

  const dropdownText = computed(() => {
    const selectedCount = Object.values(isChecked).filter(Boolean).length;
    return selectedCount === 0 ? 'Select Assessments' : `${selectedCount} Selected`;
  });

  watch(() => props.assessments, async (newValue, oldValue) => {
    disabled.value = newValue.length === 0;

    oldValue.forEach((assessment) => {
      delete isChecked[parseInt(assessment[1], 10)];
    });

    newValue.forEach((assessment) => {
      isChecked[parseInt(assessment[1], 10)] = false;
    });

    await nextTick();

    previouslySelectedActivityIntIds.value.filter(
      (id) => assessmentIds.value.includes(id)
    ).forEach((assessmentId) => {
      handleCheck({ target: { value: assessmentId, checked: true }});
    });
  });

  /**
   * Toggles the isExpanded value for opening or closing the disclosure.
   */
  function toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  /**
   * Collapses the disclosure by setting the `isExpanded` value to `false`.
   * This closes the dropdown or panel.
   */
  function collapse() {
    isExpanded.value = false;
  }

  /**
   * Handles the checkbox change event for the assessments.
   * Calls `updateIsChecked` to update the checkbox state and
   * `emitToggleAssessment` to emit the selection event.
   *
   * @param {Event} event - The checkbox change event.
   */
  function handleCheck(event) {
    updateIsChecked(event);
    emitToggleAssessment(event);
  }

  /**
   * Updates the `isChecked` reactive object with the state of the checkbox.
   *
   * @param {Event} event - The checkbox change event.
   *        event.target.value is the assessment ID.
   *        event.target.checked is the new checked state of the checkbox.
   */
  function updateIsChecked(event) {
    const assessmentId = event.target.value;
    const checked = event.target.checked;

    isChecked[assessmentId] = checked;
  }

  /**
   * Emits the `toggleAssessment` event with the assessment ID and the checked state.
   *
   * @param {Event} event - The checkbox change event.
   *        event.target.value is the assessment ID.
   *        event.target.checked is the new checked state of the checkbox.
   */
  function emitToggleAssessment(event) {
    const eventDetails = {
      assessmentId: parseInt(event.target.value, 10),
      checked: event.target.checked,
    };

    emit('toggleAssessment', eventDetails);
  }

  defineExpose({
    collapse,
  });

  onMounted(() => {
    document.addEventListener('disclosureClick', () => {
      isExpanded.value = false;
    });
  });
</script>

<style lang="scss" scoped>
  @use 'music/app/styles/library/base';

  .selected-row {
    background-color: #{base.$gray-f5};
  }

  .assessment-options .assessment-option {
    &:hover {
      background-color: #{base.$gray-f5};
    }

    &:not(:first-child) {
      padding-top: #{base.rpx(4)};
    }

    &:not(:last-child) {
      border-bottom: #{base.rpx(1)} solid #{base.$gray-d};
    }
  }

  [class] :deep(.disclosure__button) {
    border-radius: #{base.rpx(3)};
    border: #{base.rpx(1)} solid #{base.$gray-d};
    font-family: inherit;
    font-size: #{base.$font-size-16};
    line-height: #{base.rpx(36)};
    padding: #{base.rpx(4)};

    &:not([disabled]) {
      &:hover {
        background-color: #{base.$gray-f8};
      }
    }

    & .embedded-icon .triangle-icon svg {
      --fill: #{base.$lightest-graphic};
    }

    &:hover .embedded-icon .triangle-icon svg {
      --fill: #{base.$blue};
    }

    &[disabled] .embedded-icon .triangle-icon svg {
      --fill: var(--embedded-icon-disabled-color);
    }
  }

  [class] :deep(.disclosure__button .disclosure-header-text) {
    --disclosure-header-text-color: #{base.$black};
    --disclosure-header-text-style: none;
    --disclosure-header-text-case: capitalize;
    padding-left: 0.5rem;
  }

  [class] :deep(.disclosure__button[disabled]) {
     cursor: not-allowed;
  }

  [class] :deep(.disclosure__button[disabled] .disclosure-header-text) {
     color: #{base.$link-disabled-color};
  }

  :deep(.embedded-icon .triangle-icon svg) {
    display: block;
    width: 0.625rem;
    position: relative;
    bottom: 0.14rem;
    left: 1rem;
  }

  :deep(.is-expanded .embedded-icon .triangle-icon svg) {
    left: -0.625rem;
  }

  /**
   * The `rotate` settings here override settings in the BasicDisclosure component
   * that change the orientation of a different icon to 90 and 270 degrees.
   */

  [class] :deep(.disclosure__image) {
    margin-right: #{base.rpx(12)};
    rotate: 0deg;
  }
  [class] :deep(.disclosure__button-content) { justify-content: space-between; }
  [class] :deep(.is-expanded .disclosure__image) { rotate: 180deg }
</style>
