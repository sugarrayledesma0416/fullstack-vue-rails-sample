<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">
        AI Features
      </h3>
    </div>
    <div class="c-panel__body">
      <div class="c-form-item" :class="testClass('ai-settings-grading-suggestions')">
        <input
          id="datastore_ai_settings_grading_suggestions"
          type="checkbox"
          name="datastore[ai_settings][grading_suggestions]"
          class="c-form-item__checkbox"
          :checked="dataStore.gradingSuggestions"
          :class="testClass('datastore-ai-settings-grading-suggestions')">
        <label
          for="datastore_ai_settings_grading_suggestions"
          class="c-form-item__label">
          Enable Grading Suggestions
        </label>
      </div>
      <div class="c-form-item">
        <label for="datastore_ai_settings_program_level" class="c-form-item__label">
          Program Level
        </label>
        <select
          id="datastore_ai_settings_program_level"
          v-model="dataStore.programLevel"
          name="datastore[ai_settings][program_level]"
          :class="
            ['c-dropdown--button', 'c-select', testClass('datastore-ai-settings-program-level') ]">
          <option value="">
            Select Level
          </option>
          <option
            v-for="(option, index) in programOptions"
            :key="index"
            :value="option">
            {{ option }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>

<script>
  import { reactive } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'AISettings',
    props: {
      gradingSuggestions: { default: false, type: Boolean },
      programLevel: { default: '', type: String },
    },
    setup(props) {
      const dataStore = reactive({
        gradingSuggestions: props.gradingSuggestions,
        programLevel: props.programLevel,
      });
      const programOptions = ['introductory', 'intermediate', 'advanced'];

      return {
        dataStore,
        programOptions,
        testClass,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
</style>
