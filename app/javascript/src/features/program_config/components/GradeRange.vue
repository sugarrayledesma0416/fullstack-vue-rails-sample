<template>
  <div class="c-form-item-group" data-test="grade-range-element">
    <div class="c-form-item">
      <label for="min-grade-range" class="c-form-item__label">
        Min Grade
      </label>
      <select
        id="min-grade-range"
        v-model="minGradeSelected"
        name="datastore[standards_settings][min_grade]"
        class="c-dropdown--button  c-select"
        :disabled="toggleGradeRangeSelect"
        @change="updateMaxGradeRange(minGradeSelected)">
        <option disabled value="">
          Select Grade
        </option>
        <option
          v-for="(option, index) in options"
          :key="index"
          :value="option.value">
          {{ option.text }}
        </option>
      </select>
    </div>

    <span class="range-separator-line">&horbar;</span>
    <span class="u-screen-reader-only">through</span>

    <div class="c-form-item">
      <label for="max-grade-range" class="c-form-item__label">
        Max Grade
      </label>
      <select
        id="max-grade-range"
        v-model="maxGradeSelected"
        name="datastore[standards_settings][max_grade]"
        class="c-dropdown--button  c-select"
        :disabled="toggleGradeRangeSelect">
        <option disabled value="">
          Select Grade
        </option>
        <option
          v-for="(option, index) in maxGradeRange"
          :key="index"
          :value="option.value">
          {{ option.text }}
        </option>
      </select>
    </div>
  </div>
</template>

<script setup>
  import { ref, watch, onMounted } from 'vue';

  const props = defineProps({
    minGradeStored: {
      type: String,
      default: '',
    },
    maxGradeStored: {
      type: String,
      default: '',
    },
    standardDataStore: {
      type: Object,
      default(rawProps) {
        return {};
      },
    },
  });

  const minGradeSelected = ref(props.minGradeStored || '');
  const maxGradeSelected = ref(props.maxGradeStored || '');
  const options = [
    { value: 'PK', text: 'Pre-Kindergarten' },
    { value: 'K', text: 'Kindergarten' },
    { value: '1', text: 'Grade 1' },
    { value: '2', text: 'Grade 2' },
    { value: '3', text: 'Grade 3' },
    { value: '4', text: 'Grade 4' },
    { value: '5', text: 'Grade 5' },
    { value: '6', text: 'Grade 6' },
    { value: '7', text: 'Grade 7' },
    { value: '8', text: 'Grade 8' },
    { value: '9', text: 'Grade 9' },
    { value: '10', text: 'Grade 10' },
    { value: '11', text: 'Grade 11' },
    { value: '12', text: 'Grade 12' },
  ];
  const initMaxRange = createMaxGradeRange(props.minGradeStored);
  const maxGradeRange = ref(initMaxRange);
  const toggleGradeRangeSelect = ref(true);

  onMounted(() => {
    if (props.standardDataStore.supportedStandardSetIds.length) {
      toggleGradeRangeSelect.value = false;
    }
  });

  watch(props.standardDataStore, (updatedStandardDataStore) => {
    if (!updatedStandardDataStore.supportedStandardSetIds.length) {
      toggleGradeRangeSelect.value = true;
    } else {
      toggleGradeRangeSelect.value = false;
    }
  });

  /**
   * Create the initial list of grade for the max grade range.
   * This method allows to create a valid max grade range when we already have values
   * comming from the database.
   *
   * @param {String} defaultGradeStored - an initial grade value to create the range
   * @return {Array} Array with a grade range
   */
  function createMaxGradeRange(defaultGradeStored) {
    const initGradeValue = defaultGradeStored || 'PK';
    const selectedIndex = options.findIndex((option) => option.value == initGradeValue);
    return options.slice(selectedIndex, options.length);
  }

  /**
   * Uptades the options for the max grade range dropdown
   * based on the option selected in the min grade range dropdown
   * @param {String} selectedOption - the value attribute selected in the
   * min grade range dropdown
   */
  function updateMaxGradeRange(selectedOption) {
    maxGradeRange.value = createMaxGradeRange(selectedOption);
    maxGradeSelected.value = minGradeSelected.value;
  }
</script>

<style scoped>
  .range-separator-line {
    margin-bottom: 0.5rem;
  }
</style>
