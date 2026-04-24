<template>
  <label
    :for="id"
    class="radio-button-label"
    :class="testClass('radio-button-label')">
    <input
      :id="id"
      :name="name"
      :checked="isChecked"
      class="radio-button-input"
      :class="testClass(testSelectorInput)"
      :disabled="disabled"
      type="radio"
      :value="value"
      @change="$emit('update:modelValue', value);">
    {{ text }}
  </label>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'VhlRadioButton',
    props: {
      disabled: { default: false, type: Boolean },
      id: { default: '', type: String },
      modelValue: { default: '', type: [Boolean, Number, String] },
      name: { default: '', type: String },
      testSelectorInput: { default: '', type: String },
      text: { default: '', type: String },
      value: { required: true, type: [Boolean, Number, String] },
    },
    emits: ['update:modelValue'],
    setup(props) {
      const isChecked = computed(function() {
        return props.modelValue === props.value;
      });
      return { isChecked, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .radio-button-label {
    color: #565656;
    font-size: 0.875rem;
    font-weight: normal;
    padding: 0 1em 0 0;
  }

  .radio-button-input {
    font-size: 0.875rem;
    margin-right: rpx(2);
    outline: 0.125rem solid transparent;
    outline-offset: 0.125rem;
  }

  .radio-button-input:focus {
    outline-color: #0091eb;
  }
</style>
