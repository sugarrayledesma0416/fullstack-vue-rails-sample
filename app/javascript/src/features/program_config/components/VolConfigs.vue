<template>
  <div>
    <div class="c-panel  u-bord-2  u-bord-gray-e">
      <div class="c-panel__header">
        <h3 class="c-heading--panel">Course setup descriptions (Explanation in course/assignment wizard)</h3>
      </div>
      <div class="c-panel__body">
        <div class="c-form-item">
          <label
            for="datastore_course_setup_descriptions_express_course"
            class="c-form-item__label"
            :class="testClass('express-course')">
            Express Course
          </label>
          <DescriptionField
            id="datastore_course_setup_descriptions_express_course"
            name="datastore[course_setup_descriptions][express_course]"
            :value="volConfigs.descriptions.express_course"
            type="express_course" />
        </div>
        <div class="c-form-item">
          <label
            for="datastore_course_setup_descriptions_advanced_course"
            class="c-form-item__label"
            :class="testClass('advanced-course')">
            Advanced Course
          </label>
          <DescriptionField
            id="datastore_course_setup_descriptions_advanced_course"
            name="datastore[course_setup_descriptions][advanced_course]"
            :value="volConfigs.descriptions.advanced_course"
            type="advanced_course" />
        </div>
      </div>
    </div>

    <div class="c-panel  u-bord-2  u-bord-gray-e">
      <div class="c-panel__header">
        <h3 class="c-heading--panel">Learning tracks descriptions (Explanation in course/assignment wizard)</h3>
      </div>
      <div class="c-panel__body">
        <div class="c-form-item">
          <label
            for="datastore_course_setup_descriptions_learning_tracks_header"
            class="c-form-item__label"
            :class="testClass('learning-tracks-header')">
            Header
          </label>
          <DescriptionField
            id="datastore_course_setup_descriptions_learning_tracks_header"
            name="datastore[course_setup_descriptions][learning_tracks][header]"
            :value="volConfigs.descriptions.header"
            type="learning_tracks.header" />
        </div>
        <div class="c-form-item">
          <label
            for="datastore_course_setup_descriptions_learning_tracks_general"
            class="c-form-item__label"
            :class="testClass('learning-tracks-general')">
            Overview
          </label>
          <DescriptionField
            id="datastore_course_setup_descriptions_learning_tracks_general"
            name="datastore[course_setup_descriptions][learning_tracks][general]"
            :value="volConfigs.descriptions.general"
            type="learning_tracks.general" />
        </div>
      </div>
    </div>

    <div class="c-panel  u-bord-2  u-bord-gray-e">
      <div class="c-panel__header">
        <h3 class="c-heading--panel">Learning track options (i.e. Essentials/Complete)</h3>
      </div>
      <div class="c-panel__body">
        <div class="c-form-item">
          <label
            for="datastore_course_setup_descriptions_learning_tracks_options_overall"
            class="c-form-item__label"
            :class="testClass('learning-tracks-options-overview')">
            Overview
          </label>
          <DescriptionField
            id="datastore_course_setup_descriptions_learning_tracks_options_overall"
            name="datastore[course_setup_descriptions][learning_tracks][options_overall]"
            :value="volConfigs.descriptions.options_overall"
            type="learning_tracks.options_overall" />
        </div>
        <div v-for="(option, index) in volConfigs.learning_tracks_options" :key="index">
          <fieldset class="u-mar-top-16">
            <h4>Option {{ index + 1 }}</h4>
              <div class="c-form-item">
              <label
                :for="`learning_track_option_${index + 1}_label`"
                class="c-form-item__label">
                Label
              </label>
              <input
                :id="`learning_track_option_${index + 1}_label`"
                type="text"
                class="c-form-item__input  u-width-full"
                name="datastore[course_setup_descriptions][learning_tracks][options][][label]"
                :value="option.label">
            </div>
            <div class="c-form-item">
              <label
                :for="`learning_track_option_${index + 1}_explanation`"
                class="c-form-item__label">
                Explanation
              </label>
              <DescriptionField
                :id="`learning_track_option_${index + 1}_explanation`"
                name="datastore[course_setup_descriptions][learning_tracks][options][][explanation]"
                :value="option.explanation"
                :type="`explanation_${index + 1}`" />
            </div>
          </fieldset>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import DescriptionField from './DescriptionField';

  export default {
    name: 'VolConfigs',
    components: { DescriptionField },
    props: {
      volConfigs: { required: true, type: Object },
    },
    setup() {
      return { testClass };
    },
  };
</script>
