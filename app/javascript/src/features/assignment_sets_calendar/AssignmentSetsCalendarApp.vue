<template>
  <div class="assignment-sets">
    <div class="assignment-sets__header">
      <div>
        <h1 class="assignment-sets__main-header">
          Assignment Reordering
        </h1>
        <h2 class="assignment-sets__sub-header">
          Order your assignments for a due date.
        </h2>
      </div>
      <div class="assignment-sets__export-link-container">
        <a
          :href="store.csvExportUrl"
          target="_blank"
          class="c-button  c-button--border  assignment-sets__export-link">
          Export CSV
        </a>
      </div>
    </div>
    <div class="assignment-sets__body">
      <div class="assignment-sets__body-container">
        <div class="assignment-sets__calendar-datepicker-container  l-span-4  u-mar-rt-12">
          <div class="assignment-sets__calendar-datepicker">
            <DatePicker
              :key="datePickerKey"
              v-model="store.calendar.dateRange"
              :minDate="store.calendar.courseStartDate.toDateString()"
              :maxDate="store.calendar.courseEndDate.toDateString()"
              :attributes="store.calendar.attributes"
              isRange
              isInline
              class="u-bord-none">
              <template #footer>
                <div class="u-dis-flex  flex-justify-between">
                  <label class="u-screen-reader-only" for="start-date-input">
                    Assignment Reorder start date
                  </label>
                  <input
                    id="start-date-input"
                    class="manual-date-input"
                    :class="testClass('start-date-input')"
                    name="start"
                    type="text"
                    :value="inputDates[0]"
                    @blur="handleDateInputEvent($event)"
                    @focus="clearInputErrors">
                  <label class="u-screen-reader-only" for="end-date-input">
                    Assignment Reorder end date
                  </label>
                  <span>to</span>
                  <input
                    id="end-date-input"
                    class="manual-date-input"
                    :class="testClass('end-date-input')"
                    name="end"
                    type="text"
                    :value="inputDates[1]"
                    @blur="handleDateInputEvent($event)"
                    @focus="clearInputErrors">
                </div>
                <div v-show="inputErrors.format" :class="testClass('pattern-msg')">
                  Enter date in "MM/DD/YYYY" format.
                </div>
                <div v-show="inputErrors.range" :class="testClass('range-msg')">
                  Dates are not in course range.
                </div>
                <div class="u-mar-8  u-pad-top-10  l-stack">
                  <StandardButton
                    variant="border"
                    class="u-txt-plain  u-mar-2"
                    :class="testClass('pre-set-seven-days-button')"
                    @click="handleDateButtonEvent($event, 7)">
                    <span class="u-txt-blue">Next 7 Days</span>
                  </StandardButton>
                  <StandardButton
                    variant="border"
                    class="u-txt-plain  u-mar-2"
                    :class="testClass('pre-set-thirty-days-button')"
                    @click="handleDateButtonEvent($event, 30)">
                    <span class="u-txt-blue">Next 30 Days</span>
                  </StandardButton>
                  <StandardButton
                    variant="border"
                    class="u-txt-plain  u-mar-2"
                    :class="testClass('pre-set-show-all-button')"
                    @click="handleDateButtonEvent($event, 'show all')">
                    <span class="u-txt-blue">Show All</span>
                  </StandardButton>
                </div>
              </template>
            </DatePicker>
            <div class="c-box  c-box--outlined">
              <div class="u-pad-bot-10">
                Date selection must be within course start and end dates.
              </div>
              <div>
                <div>
                  Start: {{ databaseDateToFriendlyDate(courseStartDate) }}
                </div>
                <div>
                  End: {{ databaseDateToFriendlyDate(courseEndDate) }}
                </div>
              </div>
            </div>
            <div class="u-mar-bot-24">
              <VhlCheckbox
                id="custom-ordered"
                @update:checked="toggleCustomOrderedCheckboxState($event)">
                  Custom Ordered( {{store.customOrderedCount}} )
              </VhlCheckbox>
            </div>
          </div>
        </div>
        <AssignmentSetList />
      </div>
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { computed, onMounted, reactive, ref, watch } from 'vue';
  import { parse, format } from 'date-fns';
  import { DatePicker } from 'v-calendar';
  import {
    handleDateInputEvent as _handleDateInputEvent,
  } from './models/manual_date_input_handling';

  import AssignmentSetList from './AssignmentSetList';
  import VhlCheckbox from './../../shared/activity_editing/VhlCheckbox';
  import useAssignmentSetStore from './models/use_assignment_set_store';
  import { StandardButton } from 'music';

  const props = defineProps({
    assignments: { required: true, type: String },
    courseStartDate: { default: '', type: String },
    courseEndDate: { default: '', type: String },
    csvUrl: { required: true, type: String },
    endpointUrl: { required: true, type: String },
  });

  const store = useAssignmentSetStore();
  const datePickerKey = ref(0);
  const courseStartDateObj = dateFromDateString(props.courseStartDate);
  const courseEndDateObj = dateFromDateString(props.courseEndDate);

  const inputErrors = reactive(
    {
      format: false,
      range: false,
    }
  );

  const inputDates = computed(stringForDateInput);
  const assignmentsData = JSON.parse(props.assignments);

  store.init(
    assignmentsData.custom_order,
    assignmentsData.default_order,
    props.endpointUrl,
    props.csvUrl,
    props.courseStartDate,
    props.courseEndDate
  );
  /**
   * @param {string} preSelectionRange - pre selection date
   * @return {[string, string]} - [startDate, endDate] in MM-DD-YYYY
   * Formatted for pre-select date display.
   */
  function preSetRange(preSelectionRange) {
    let startDatePreSet = new Date();
    let endDatePreSet = new Date();
    if(preSelectionRange  === 'show all') {
      /**
       * Set calendar date range with course start and end date.
       */
      startDatePreSet = courseStartDateObj.toJSON().slice(0, 10).split('-');
      endDatePreSet = courseEndDateObj.toJSON().slice(0, 10).split('-');
    } else {
      /**
       * Set calendar date range with pre selection range defined.
       */
      startDatePreSet = startDatePreSet.toJSON().slice(0, 10).split('-');
      // Add to current date pre selection day to set the end date range
      endDatePreSet = new Date(new Date().setDate(new Date().getDate() + preSelectionRange));
      endDatePreSet = endDatePreSet.toJSON().slice(0, 10).split('-');
    }
    const startStr = startDatePreSet[1] + '/' + startDatePreSet[2] + '/' + startDatePreSet[0];
    const endStr = endDatePreSet[1] + '/' + endDatePreSet[2] + '/' + endDatePreSet[0];
    return [startStr, endStr];
  }

  /**
   * clears manual date input validation errors.
   */
  function clearInputErrors() {
    inputErrors.format = false;
    inputErrors.range = false;
  }

  /**
   * @param {string} dbDateString - in format YYYY-MM-DD
   * @return {string} e.g. Mar 06, 2022
  */
  function databaseDateToFriendlyDate(dbDateString) {
    return format(parse(dbDateString, 'yyyy-MM-dd', new Date()), 'MMM dd, yyyy');
  }

  /**
   * @param {string} dateString - in format 'YYYY, MM, DD'
   * @return {Date} date object.
   */
  function dateFromDateString(dateString) {
    const arr = dateString.split('-');
    return new Date(arr[0], arr[1]-1, arr[2]);
  }

  /**
   * @param {event} event - date input blur event
   * Provides 'handleDateinputEvent'
   * with environmental context via opts param:
   */
  function handleDateInputEvent(event) {
    const opts = {
      store: store,
      courseStartDateObj,
      courseEndDateObj,
      inputErrors,
      datePickerKey,
    };
    _handleDateInputEvent(event, opts);
  }

  /**
   * @return {[string, string]} - [startDate, endDate] in MM-DD-YYYY
   * Formatted for manual date input display.
   */
  function stringForDateInput() {
    const startArr = store.calendar.dateRange.start.toJSON().slice(0, 10).split('-');
    const endArr = store.calendar.dateRange.end.toJSON().slice(0, 10).split('-');
    const startStr = startArr[1] + '/' + startArr[2] + '/' + startArr[0];
    const endStr = endArr[1] + '/' + endArr[2] + '/' + endArr[0];
    return [startStr, endStr];
  }
  
  /**
   * @param {event} event - date button click event
   * @param {string} preSelectionRange - pre selection date
   * Provides 'handleDateinputEvent'
   * with environmental context via opts param:
   */
  function handleDateButtonEvent(event, preSelectionRange) {
    const opts = {
      store: store,
      courseStartDateObj,
      courseEndDateObj,
      inputErrors,
      datePickerKey,
    };

    const rangeSet = preSetRange(preSelectionRange);
    
    event.target.name = 'start';
    event.target.value = rangeSet[0];
    _handleDateInputEvent(event, opts);
    
    event.target.name = 'end';
    event.target.value = rangeSet[1];
    _handleDateInputEvent(event, opts);
  }

  /**
   * @private
   * @param {event} event - checkbox click event
   * Toggles the showOnlyCustomOrderedAssignments flag status
   */
  function toggleCustomOrderedCheckboxState(event) {
    store.showOnlyCustomOrderedAssignments = event;
  }

  /**
   * @private
   * Counts the AssignmentSets custom ordered
   * in the selected dates.
   */
  function countCustomOrderedSets() {
    store.customOrderedCount = 0;
    store.assignmentSets.forEach((set) => {
      if (set.hasCustomOrder && store.inDateRange(set)) {
        store.customOrderedCount++;
      }
    });
  }

  watch(inputDates, countCustomOrderedSets);

  onMounted(countCustomOrderedSets);
</script>

<style>
  @import 'v-calendar/dist/style.css';
</style>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .manual-date-input {
    border: rpx(1) solid $gray-a;
    padding: rpx(3);
    text-align: center;
    width: rpx(100);
  }

  .assignment-sets {
    display: flex;
    flex-direction: column;

    &__body-container {
      display: flex;
      flex-direction: row;
      flex-basis: fill;
    }

    &_calendar-datepicker {
      flex: 1 1 auto;
    }

    &__calendar-datepicker-container {
      display: flex;
      flex-direction: column;
    }

    &__export-link-container {
      padding-top: rpx(6);
    }

    &__export-link {
      align-items: center;
      display: flex;
      flex-wrap: nowrap;
      gap: 0.5rem;
      white-space: nowrap;

      svg {
        width: mod(1);
        height: mod(1);
      }
    }

    &__header {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      margin-top: rpx(24);
    }

    &__main-header {
      margin-top: 0;
      margin-bottom: rpx(5);
      color: $gray-6;
      font-size: mod(1.25);
      font-weight: normal;
    }

    &__sub-header {
      font-size: mod(0.875);
      color: $gray-c;
      font-weight: normal;
    }
  }
</style>
