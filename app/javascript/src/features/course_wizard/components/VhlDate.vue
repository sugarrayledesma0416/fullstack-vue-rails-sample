<template>
  <div class="date-field">
    <input
      :id="inputId"
      ref="datepickerElm"
      pattern="/^((0?[1-9]|1[012])[- /.](0?[1-9]|[12][0-9]|3[01])[- /.](19|20)?[0-9]{2})*$/"
      type="text"
      class="c-form-item__input  date-field__input"
      :class="testClass(testSelector)"
      :disabled="isDisabled"
      @input="$emit('update:modelValue', $event.target.value)">
  </div>
</template>

<script>
  import { onMounted, ref } from 'vue';
  import { testClass } from 'music';
  import { Datepicker } from 'vanillajs-datepicker';

  export default {
    name: 'VhlDate',
    props: {
      isDisabled: { default: false, type: Boolean },
      modelValue: { default: '', type: String },
      testSelector: { default: '', type: String },
      inputId: { default: '', type: String },
    },
    setup(props, { emit }) {
      const datepickerElm = ref(null);

      onMounted(() => {
        const datepicker = new Datepicker(datepickerElm.value, {
          autohide: true,
          orientation: 'bottom',
        });

        datepicker.setDate(props.modelValue);
        datepickerElm.value.addEventListener('changeDate', (event) => {
          emit('update:modelValue', event.target.value);
        });
      });
      return { datepickerElm, testClass };
    },
  };
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
