<template>
  <input
    ref="datepickerElm"
    type="text"
    :class="[testClass(testSelector), { 'custom-date-populated': customDateIsPopulated }]"
    :disabled="isDisabled"
    :placeholder="placeholderFormatted"
    @click.stop
    @blur="onBlur"
    @focus="onFocus"
    @keydown.enter.prevent>
</template>

<script setup>
  import { computed, onMounted, ref } from 'vue';
  import { testClass } from 'music';
  import { Datepicker } from 'vanillajs-datepicker';
  import { format as dateFnsFormat } from 'date-fns';
  import useIndividualAssignmentsStore
    from '../stores/use_individual_assignments_store';

  const store = useIndividualAssignmentsStore();

  const props = defineProps({
    isDisabled: { default: false, type: Boolean },
    modelValue: { default: '', type: String },
    placeholder: { default: '', type: String },
    testSelector: { default: '', type: String },
  });

  const emit = defineEmits([
    'update:focused',
    'update:modelValue',
  ]);

  // Accepts either m/d/yyyy string or empty string.
  const REGEX_MDYYYY = /^((0?[1-9]|1[012])[- /.](0?[1-9]|[12][0-9]|3[01])[- /.](19|20)[0-9]{2})*$/;

  /**
   * Reactive string value: maintains the date we want to submit.
   * The datepicker mutates the input element's value unpredictably, especially
   * when changing the date format on focus and blur. Elevating this value to
   * the parent provides a single source of truth.
   */
  const dateToSubmit = ref('');

  /**
   * Reactive boolean value: maintains the input element's focused state.
   * Controls format of displayed date in input element.
   */
  const inEditMode = ref(false);

  const datepicker = ref(null);
  const datepickerElm = ref(null);

  // Timestamp for the default due date
  const placeholderTimestamp = Datepicker.parseDate(props.placeholder, 'm/d/yyyy');

  /**
   * @param {string} date - Date string.
   * @return {boolean} True if date is truthy, false otherwise.
   */
  function isPopulated(date) {
    return Boolean(date);
  }

  /**
   * Focus on default due date if given date is empty.
   * Also clear any previously selected date.
   * @param {string} date - Date string
   * @return {boolean} True if focused on default date, false otherwise
   */
  function focusOnDefaultDate(date) {
    if (!isPopulated(date)) {
      // Passing an empty array of dates clears the previous selection.
      datepicker.value.setDate([], { autohide: false, clear: true, });

      datepicker.value.picker.changeFocus(placeholderTimestamp).render();
      return true;
    }

    return false;
  }

  /**
   * Reactive boolean state: true if a custom date is set for the assignment.
   */
  const customDateIsPopulated = ref(isPopulated(props.modelValue));

  const yearStringLength = '/yyyy'.length;

  const placeholderFormatted = computed(
    /**
     * Return default due date for input element's placeholder text.
     * If in edit mode, format should be m/d/yyyy; if not, it should be m/d.
     * @return {string} formatted date
     */
    () => {
      if (inEditMode.value) {
        return props.placeholder;
      }

      return props.placeholder.slice(0, 0 - yearStringLength);
    }
  );

  const dateToSubmitAsMonthDay = computed(
    () => {
      const timestamp = Datepicker.parseDate(dateToSubmit.value, 'm/d/yyyy');
      return Datepicker.formatDate(timestamp, 'm/d');
    }
  );

  /**
   * Callback that runs when input receives focus.
   *
   * Switches to edit mode and either
   * - focuses datepicker dropdown on default due date if no custom date set, or
   * - sets input's value to the custom date
   */
  function onFocus() {
    inEditMode.value = true;
    emit('update:focused', true);
    if (!focusOnDefaultDate(dateToSubmit.value)) {
      datepickerElm.value.value = dateToSubmit.value;
    }
  }

  /**
   * Callback that runs when input loses focus.
   *
   * Switches out of edit mode and changes input element text to m/d format.
   *
   * If the user has edited the text input and erased the contents, emit an
   * update event so that the student cell will know to hide the text field.
   *
   * NOTE: if custom date is not set, the datepicker handles the formatting
   * gracefully. `parseDate` returns a value of `undefined`, which `formatDate`
   * then formats as an empty string.
   */
  function onBlur() {
    inEditMode.value = false;
    emit('update:focused', false);

    if (datepickerElm.value) {
      datepickerElm.value.value = dateToSubmitAsMonthDay.value;
    }

    if (!isPopulated(dateToSubmit.value)) {
      emit('update:modelValue', dateToSubmit.value);
    }
  }

  /* expected: string in m/d/yyyy format */
  dateToSubmit.value = props.modelValue;

  onMounted(() => {
    datepicker.value = new Datepicker(datepickerElm.value, {
      autohide: true,
      format: {
        /**
         * Return the string to set as the value of the input element.
         * This should always be the value of the "source of truth" variable.
         * @return {string} the date string to set as the value
         */
        toValue(date, format, locale) {
          return date;
        },
        /**
         * Return the string to display in the input element.
         * Note that this is _not_ the same as the element's value.
         * Format should be m/d/yyyy if element is focused, otherwise m/d.
         * @return {string} the date to display in the element
         */
        toDisplay(date, format, locale) {
          if (date === undefined) {
            return '';
          }

          if (inEditMode.value) {
            return dateFnsFormat(date, 'M/d/yyyy');
          }

          return dateFnsFormat(date, 'M/d');
        },
      },
      maxDate: store.maxDueDate,
      minDate: store.minDueDate,
      orientation: 'bottom',
    });

    // Either focus on default due date, or set selection to custom due date
    if (!(focusOnDefaultDate(props.modelValue))) {
      const customTimestamp = Datepicker.parseDate(props.modelValue, 'm/d/yyyy');
      datepicker.value.setDate(customTimestamp);
    }

    /**
     * If the user selects a date via the datepicker dropdown,
     * - assign new date-to-submit value
     * - notify parent component that date has changed
     */
    datepickerElm.value.addEventListener('changeDate', (event) => {
      // Assign value for form, and change custom-date-is-set state to true.
      customDateIsPopulated.value = event.detail.date !== undefined;
      dateToSubmit.value = Datepicker.formatDate(event.detail.date, 'm/d/yyyy');

      // Update date in text input
      datepickerElm.value.value = dateToSubmit.value;

      // Let parent StudentCell know that date has changed
      emit('update:modelValue', dateToSubmit.value);
    });

    /**
     * If the user enters a date via the text input element,
     * - validate it, returning early if invalid
     * - assign new date-to-submit value
     * - update dropdown state
     * - notify parent component that date has changed
     */
    datepickerElm.value.addEventListener('keyup', (event) => {
      // Bail if keyboard interaction is arrow navigation on dropdown
      if (['ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowUp'].includes(event.key)) {
        return;
      }

      const enteredDateString = event.target.value;

      // Bail if date is invalid
      if (!REGEX_MDYYYY.test(enteredDateString)) {
        return;
      }

      const enteredDate = new Date(enteredDateString);

      // Bail if date is outside of course date range
      if (enteredDate < store.minDueDate || enteredDate > store.maxDueDate) {
        return;
      }

      // Assign value for form, and change custom-date-is-set state to true.
      customDateIsPopulated.value = event.target.value !== '';
      dateToSubmit.value = event.target.value;

      /**
       * - clear dropdown visual state and focus on default due date, OR
       * - update dropdown visual state with new date
       */
      if (!focusOnDefaultDate(dateToSubmit.value)) {
        const customTimestamp = Datepicker.parseDate(dateToSubmit.value, 'm/d/yyyy');
        datepicker.value.setDate(customTimestamp, { autohide: false, clear: true });
      }

      if (dateToSubmit.value === '') {
        datepicker.value.hide();
      }

      // Use event to let parent StudentCell know that date has changed
      emit('update:modelValue', dateToSubmit.value);
    });

    /**
     * If user clicks on the calendar, don't propagate the click up to the
     * student cell: a click on the student cell would toggle the
     * individually-assigned status for the student.
     */
    datepicker.value.pickerElement.addEventListener('click', (event) => {
      event.stopPropagation();
    });
  });
</script>

<style lang="scss">
  @import 'vanillajs-datepicker/sass/datepicker';
</style>

<style lang="scss" scoped>
  .custom-date-populated {
    font-weight: bold;
  }
</style>
