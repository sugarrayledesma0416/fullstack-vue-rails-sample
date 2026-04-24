<template>
  <div ref="dateRangeRef">
    <div class="c-form-item">
      <label class="c-form-item__label" for="start_date">From</label>
      <input
        id="start_date"
        name="start_date"
        type="text"
        class="c-form-item__input  date-field__input">
    </div>
    <div class="c-form-item">
      <label class="c-form-item__label" for="end_date">To</label>
      <input
        id="end_date"
        name="end_date"
        type="text"
        class="c-form-item__input  date-field__input">
    </div>
  </div>
</template>

<script setup>
  import { ref, onMounted, reactive } from 'vue';
  import { DateRangePicker } from 'vanillajs-datepicker';

  const props = defineProps(
    {
      startDate: {
        required: true,
        type: String,
      },
      endDate: {
        required: true,
        type: String,
      },
    }
  );

  const dateRangeRef = ref();
    
  onMounted(() => {
    const datepickerElm = dateRangeRef.value;
    const rangePicker = new DateRangePicker(datepickerElm, {
      autohide: true,
      orientation: 'bottom',
    });
    rangePicker.setDates(props.startDate, props.endDate);
  });
</script>

<style lang="scss">
  @import 'vanillajs-datepicker/sass/datepicker';
</style>

<style lang="scss" scoped>
  @import 'features/shared/form_element_settings';

  .date-field__input {
    background: url(/images/input_calendar_course_setup.png) no-repeat 0.5rem center;
    padding: 0.5rem 0.5rem 0.5rem 2.5rem;
  }
</style>
