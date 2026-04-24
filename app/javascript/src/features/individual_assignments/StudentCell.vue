<template>
  <td
    v-if="!store.state.showOnlyIndividuallyAssignable || assignment.individually_assignable"
    class="c-data-gb  u-txt-ctr"
    :class="cellClass"
    @click="checkCheckbox($event)">
    <LazyRender>
      <div
        v-if="assignment.individually_assignable"
        class="inline-controls  inline-controls--three-columns">
        <input
          :name="`${fieldName}[assigned]`"
          type="hidden"
          value="0">
        <input
          ref="checkbox"
          class="checkbox"
          :checked="assignment.individually_assigned"
          :name="`${fieldName}[assigned]`"
          type="checkbox"
          aria-label="Assigned"
          value="1"
          @keydown.enter.prevent="checkCheckbox($event)"
          @keyup.enter.prevent
          @change="handleCheck($event)">
        <input
          :class="testClass('due-date-hidden-field')"
          :name="`${fieldName}[due_date]`"
          type="hidden"
          :value="assignment.individual_due_date">
        <CustomDueDatePicker
          v-if="showDatepicker"
          ref="datepicker"
          :modelValue="assignment.individual_due_date"
          :placeholder="assignment.due_date"
          :testSelector="testSelector"
          @keydown.tab="datepickerBlurredByTab = true"
          @update:focused="updateFocused"
          @update:modelValue="updateCustomDueDate" />
        <span class="column-three">
          <button
            v-show="showDatepicker"
            ref="removeBtn"
            class="remove-custom-date  js-remove-custom-date"
            type="button"
            @keydown.enter.stop
            @keyup.enter.stop="updateCustomDueDate('');"
            @click.stop="updateCustomDueDate('');">
            &times;
          </button>
          <button
            v-show="!showDatepicker"
            ref="calendarBtn"
            class="calendar-icon  calendar-btn  js-calendar-icon"
            type="button"
            :disabled="!assignment.individually_assigned"
            :tabindex="assignment.individually_assigned ? 0 : -1"
            @keyup.enter.stop="showAndFocusDatepicker"
            @keydown.enter.stop
            @click.stop="showAndFocusDatepicker">
            <CalendarIcon
              :class="{ 'calendar-icon--disabled': !assignment.individually_assigned }" />
          </button>
        </span>
      </div>
      <div
        v-else>
        <input
          class="checkbox"
          checked
          disabled
          type="checkbox"
          aria-label="Assigned">
      </div>
    </LazyRender>
  </td>
</template>

<script setup>
  import { computed, inject, nextTick, ref, watch, watchEffect } from 'vue';
  import { testClass } from 'music';
  import CalendarIcon from './components/CalendarIcon';
  import CustomDueDatePicker from './components/CustomDueDatePicker';
  import tippy from 'tippy.js';
  import LazyRender from './LazyRender';

  const store = inject('store');

  const props = defineProps({
    assignment: { required: true, type: Object },
    testSelector: { type: String, default: '' },
    userIdWithPrefix: { required: true, type: String },
  });

  const emit = defineEmits(['toggleCheckbox']);

  const activityLabel = `activity_${props.assignment.assignable_id}`;
  const fieldName = `${activityLabel}[${props.userIdWithPrefix}]`;
  const checkbox = ref(null);
  const removeBtn = ref(null);
  const calendarBtn = ref(null);
  const showDatepicker = ref(props.assignment.individual_due_date !== null);
  const datepicker = ref(null);

  // state affecting whether to show datepicker
  const datepickerIsFocused = ref(false);
  const justBlurred = ref(false);
  const datepickerBlurredByTab = ref(false);

  const datepickerIsFocusedOrPopulated = computed(() => {
    if (datepickerIsFocused.value) {
      return true;
    }

    return props.assignment.individual_due_date?.match(/\d\d?\/\d\d?\/\d{4}/);
  });

  watchEffect(() => {
    showDatepicker.value = datepickerIsFocusedOrPopulated.value;
  });

  watch(checkbox, (newVal) => {
    if (newVal) {
      tippy(
        checkbox.value,
        {
          allowHTML: true,
          content: 'Individually assign to this student',
        }
      );
    }
  }, { flush: 'post' });

  watch(calendarBtn, (newVal) => {
    if (newVal) {
      tippy(
        calendarBtn.value,
        {
          allowHTML: true,
          content: 'Set custom due date',
        }
      );
    }
  }, { flush: 'post' });

  watch(removeBtn, (newVal) => {
    if (newVal) {
      tippy(
        removeBtn.value,
        {
          allowHTML: true,
          content: 'Remove custom due date',
        }
      );
    }
  }, { flush: 'post' });

  /**
   * @param {event} event - Change event from checkbox input.
   */
  function handleCheck(event) {
    if (!checkbox.value.checked) {
      updateCustomDueDate('');
    }

    emit('toggleCheckbox', event);
  }

  /**
   * The click() call should only be made if the event target is not
   * the checkbox itself (i.e. the click is on the table cell,
   * but not on the checkbox). Otherwise, two separate click events
   * fire, returning the checkbox to its original state instead of
   * toggling it.
   * @param {Event} event - The click event.
   */
  function checkCheckbox(event) {
    /**
     * Guard clause: if the checkbox ref is not present, then this assignment is
     * assigned to the whole section.
     */
    if (!checkbox.value) {
      return;
    }

    if (justBlurred.value) {
      justBlurred.value = false;

      if (event.type === 'click') {
        return;
      }

      /**
       * If the individual due date is non-null, don't check the checkbox on
       * clicking  outside of the checkbox. Otherwise, a click outside of the date
       * field to remove focus from it also unassigns the user and hides the date
       * field.
       */
      if (props.assignment.individual_due_date && event.target !== checkbox.value) {
        return;
      }
    }

    if (event.target !== checkbox.value || event.type === 'keydown') {
      checkbox.value.click();
    }
  }

  /**
   * @param {string} event - Synthetic event passed up from CustomDueDatePicker,
   *                         or a string passed directly as param.
   */
  async function updateCustomDueDate(event) {
    // eslint-disable-next-line vue/no-mutating-props
    props.assignment.individual_due_date = event;
    await nextTick();
  }

  /**
   * @param {boolean} event - Updated focused state of datepicker component.
   */
  function updateFocused(event) {
    datepickerIsFocused.value = event;
    if (!event && !datepickerBlurredByTab.value) {
      justBlurred.value = true;
    }
    datepickerBlurredByTab.value = false;
  }

  const cellClass = computed(
    () => {
      if (props.assignment.individually_assignable) {
        if (props.assignment.individually_assigned) {
          return 'individual-assignments-assigned-cell';
        } else {
          return 'individual-assignments-unassigned-cell';
        }
      } else {
        return 'individual-assignments-disabled-cell';
      }
    }
  );

  /**
   * @return {void}
   */
  async function showAndFocusDatepicker() {
    if (!props.assignment.individually_assigned) {
      return;
    }

    /**
     * This is a hack to get around a race condition.
     *
     * Without it, if we use keyboard navigation to "click" the calendar icon,
     * an extra click event is handled right after `keyup.enter` that causes
     * `updateCustomDueDate` to run, inadvertently hiding the calendar that just
     * opened here. Inserting a short pause before showing the datepicker seems
     * to introduce enough delay that the datepicker is not shown in time to
     * handle the extra click.
     */
    await new Promise((resolve) => {
      setTimeout(resolve, 250);
    });

    showDatepicker.value = true;
    await nextTick();
    datepicker.value.$el.focus();
  }
</script>

<style lang="css">
  @import 'tippy.js/dist/tippy';
</style>

<style scoped lang="sass">
  @use '~MusicAssets/stylesheets/music/library/v1/base/main' as base;

  .individual-assignments-assigned-cell {
    background-color: base.$lightest-blue;
  }

  .individual-assignments-unassigned-cell {
    background-color: base.$white;
  }

  .individual-assignments-disabled-cell {
    background-color: #fbfbfb;
  }

  .inline-controls {
    display: grid;
    align-items: center;
    position: relative;
  }

  .inline-controls--three-columns {
    grid-template-columns: 25% 50% 25%;
  }

  .checkbox {
    margin-left: 1rem;
    position: relative;
  }

  .ns-gradebook .c-data-gb:focus-within {
    background-color: base.$gray-e;
  }

  .c-data-gb .calendar-icon {
    display: none;
  }

  .c-data-gb:hover .calendar-icon {
    display: flex;
  }

  .c-data-gb:focus-within .calendar-icon {
    display: flex;
  }

  .column-three {
    grid-column: 3 / span 1;
    justify-self: right;
    margin-right: 0.75rem;
  }

  .remove-custom-date {
    @include base.plain-button();

    color: base.$base-blue;
    font-size: base.$font-size-20;
    padding: base.rpx(4);

    &:hover {
      color: base.$dark-blue;
      text-decoration: none;
    }
  }

  .calendar-btn {
    @include base.plain-button();
  }
</style>
