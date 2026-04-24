<template>
  <div class="u-mar-bot-24">
    <div class="u-pad-bot-12">
      <label
        for="section_name"
        class="c-form-item__label"
        :class="testClass('section-name-label')">
        New Section Name
      </label>
      <input
        id="section_name"
        v-model="datastore.section.name"
        type="text"
        class="c-form-item__input  u-width-half"
        :class="[
          {'invalid-section-detail': datastore.section.hasError.value },
          testClass('section-name')
        ]"
        name="section_name"
        :readonly="datastore.section.isNameReadonly"
        required
        @input="datastore.section.isValidatorEnabled = true">
    </div>

    <div
      v-show="datastore.section.hasError.value"
      :id="datastore.section.hasError.id"
      class="validation-error"
      :class="testClass('invalid-section')">
      {{ datastore.section.hasError.msg }}
    </div>

    <div>
      <label
        for="section_additional_info"
        class="c-form-item__label"
        :class="testClass('section-additional-info')">
        Additional section information (optional)
      </label>
      <input
        id="section_additional_info"
        v-model="datastore.section.additionalInfo"
        class="c-form-item__input  u-width-half"
        :class="testClass('section-additionalInfo')"
        name="section_additional_info"
        maxlength="255"
        type="text">
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'SectionNameAndInfo',
    setup() {
      const datastore = inject('datastore');
      return { datastore, testClass };
    },
  };
</script>
