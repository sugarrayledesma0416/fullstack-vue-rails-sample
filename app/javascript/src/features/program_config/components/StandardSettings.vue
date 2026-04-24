<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">Standards</h3>
    </div>
    <div class="c-panel__body">
      <label class="c-form-item__label">
        Supported Standard Sets
      </label>
      <div 
        v-for="(option, optionIndex) in standardsSettingsData.standard_sets_array"
        :key="optionIndex"
        class="c-form-item"
        :class="testClass('supported-standard-set-ids')">
        <input
          :id="option.ids"
          type="checkbox"
          name="datastore[standards_settings][supported_standard_set_ids][]"
          :value="option.ids"
          v-model="dataStore.supportedStandardSetIds"
          :class="['c-form-item__checkbox', testClass('supported-standard-set-ids')]">
        <label :for="option.ids" class="c-form-item__label">
          {{ option.name }}
        </label>
      </div>
      <h1 class="c-heading u-mar-top-32">
        Grade Ranges
      </h1>
      <GradeRange
        class="u-mar-top-16"
        :minGradeStored="standardsSettingsData.min_grade"
        :maxGradeStored="standardsSettingsData.max_grade"
        :standardDataStore="dataStore" />
    </div>
  </div>
</template>

<script setup>
  import { reactive } from 'vue';
  import { testClass } from 'music';
  import GradeRange from './GradeRange';

  const props = defineProps({
    supportedStandardSetIds: { required: true, type: Array },
    standardsSettingsData: { required: true, type: Object },
  });

  const dataStore = reactive({
    supportedStandardSetIds: props.supportedStandardSetIds,
    standardsSettingsData: props.standardsSettingsData,
  });
</script>
