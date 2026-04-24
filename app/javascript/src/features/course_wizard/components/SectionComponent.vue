<template>
  <Fieldset>
    <FormItem
      inputId="section-dropdown"
      label="Sections">
      <!-- eslint-disable vue/no-v-model-argument -->
      <BasicSelect
        id="section-dropdown"
        v-model:modelValue="courseDataStore.store.numSections.chosen"
        testSelector="section-dropdown"
        :options="prepareDropDownSelect()"
        @change="onSectionChange($event)" />
      <!-- eslint-enable vue/no-v-model-argument -->
    </FormItem>

    <div
      v-for="(section, index) in courseDataStore.store.course.sections"
      id="section_names"
      :key="section.id || `new_section_${index}`">
      <FormItem
        label="Section Name"
        :inputId="section.id || `new_section_${index}`">
        <input
          :id="section.id || `new_section_${index}`"
          v-model="section.name"
          type="text"
          class="text-input"
          :class="testClass('section-name-input')"
          required>
        <FormFeedback
          v-if="Object.keys(section).includes('name') && section.name.length > 16"
          :class="testClass('section-name-validation-error')"
          type="error">
          Your section name cannot be longer than 75 characters.
        </FormFeedback>
        <FormFeedback
          v-if="Object.keys(section).includes('name') && !section.name"
          :class="testClass('section-name-validation-error')"
          type="error">
          Section name is required.
        </FormFeedback>
      </FormItem>
    </div>
  </Fieldset>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import { Fieldset, FormItem, FormFeedback } from 'features/shared/FormElements';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';


  /**
   * @typeDef DefaultOption
   * @property {string} value - value for the default option tag.
   * @property {string} text - text for the default option tag.
   */

  const courseDataStore = inject('courseDataStore');

  /**
    * Handler for section count change
    * to the required format.
    * @param {Event} event - section change event.
    */
  const onSectionChange = function(event) {
    let sections = courseDataStore.store.course.sections;
    const arr = [];
    if (sections === undefined) {
      sections = [];
    }

    for (let i = 0; i < event.target.value; i++) {
      const section = sections.shift();
      section ? arr.push(section) : arr.push({});
    }
    courseDataStore.store.course.sections = arr;
  };

  /**
    * Prepare options data for the select tag.
    * to the required format.
    * @return {Array.<DefaultOption>} options
    */
  const prepareDropDownSelect = function() {
    let i = 1;
    const options = [];
    while (i <= 10) {
      options.push({ value: String(i), text: String(i) });
      i = i + 1;
    }
    return options;
  };
</script>

<style lang="scss" scoped>
   @import 'features/shared/form_element_settings';
</style>
