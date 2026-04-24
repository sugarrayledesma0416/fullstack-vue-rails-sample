<template>
  <BasicSelect
    :id="id"
    :disabled="isDisabled"
    :featureVariant="featureVariant"
    :modelValue="selectedOptionValue"
    :options="formattedOptions"
    :testSelector="testSelector"
    @update:modelValue="onUpdateModelValue($event)" />
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';


  /** @template {Object} T */

  /**
   * An object in prop 'options' array
   * @typeDef VhlSelectDataWrapperOptionType
   * @property {string} text
   * @property {T} value
   */

  /**
   * @typeDef VhlSelectDataWrapperFormattedOptionType
   * @property {string} text
   * @property {number} value
   * @property {T} optionItem - value in item in the options array
   */

  export default {
    name: 'VhlSelectDataWrapper',
    components: { BasicSelect },
    props: {
      featureVariant: { default: '', type: String },
      id: { default: '', type: String },
      isDisabled: { default: false, type: Boolean },
      /* This props' type is 'T' as per defined in typedef VhlSelectDataWrapperOptionType */
      modelValue: { default: () => {}, type: Object },
      /* This props' type is Array.<VhlSelectDataWrapperOptionType> */
      options: { required: true, type: Array },
      testSelector: { default: 'select', type: String },
    },
    emits: ['update:modelValue'],
    setup(props, { emit }) {
      const onUpdateModelValue = (evt) => {
        emit('update:modelValue', getOptionItem(evt));
      };

      /**
       * This gets options for the dropdown in the the format such that
       * we can easily link item index with item object
       * @return {Array.<VhlSelectDataWrapperFormattedOptionType>}
       */
      const formattedOptions = computed(() => {
        return props.options?.map(
          (option, index) => ({
            optionItem: option.value,
            text: option.text,
            value: index,
          })
        );
      });

      /**
       * This returns the selected value ie index for the dropdown
       * @return {number}
       */
      const selectedOptionValue = computed(() => {
        const selectItem = props.options?.find((item) => item.value === props.modelValue);
        return props.options?.indexOf(selectItem);
      });

      /**
       * This gets the item object corresposning to the item index, on dropdown change
       * @param {string} itemIndexStr
       * @return {T}
       */
      function getOptionItem(itemIndexStr) {
        const itemIndex = parseInt(itemIndexStr);
        return formattedOptions.value[itemIndex].optionItem;
      }

      return { formattedOptions, onUpdateModelValue, selectedOptionValue, testClass };
    },
  };
</script>
