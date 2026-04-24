<template>
  <div class="c-flashcard-start">
    <!-- Study Mode Select -->
    <div
      class="u-pad-0  u-mar-top-16  u-dis-flex  flex-justify-end"
      :class="ssjrStudent ? 'c-jr-study-mode-container' : 'u-txt-rt'">
      <label
        id="study_mode_select_id"
        for="study_mode_select"
        class="c-form-item__label  u-dis-flex  flex-align-ctr  u-pad-rt-5">
        Study by
      </label>
      <select
        v-model="studyOptions.mode"
        id="study_mode_select"
        name="study_mode_select"
        class="c-select  c-study-mode-select"
        :class="testClass('study-mode-select')">
        <option
          v-for="option in studyOptions.modeOptions"
          :key="option.label"
          :value="option.value">
          {{ option.label }}
        </option>
      </select>
    </div>

    <div v-if="ssjrStudent" class="u-txt-ctr">
      <img
        v-if="ssjrStudent"
        aria-hidden="true"
        :src="startIconPath">
    </div>

    <div class="u-txt-ctr">
      <!-- Start Activity Button -->
      <button
        v-if="ssjrStudent"
        type="button"
        class="c-no-button  c-jr-start-button  u-txt-bold"
        :class="testClass('start-activity')"
        @click="onStartClick()">
        Start
      </button>

      <button
        v-else
        type="button"
        class="c-no-button  c-start-graphic"
        :class="testClass('start-activity')"
        @click="onStartClick()">
        <span class="u-screen-reader-only">start</span>
      </button>
    </div>
  </div>
</template>
<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'FlashcardStart',
    emit: ['startActivity'],
    props: {
      ssjrStudent: { default: false, type: Boolean },
      studyOptions: { required: true, type: Object },
    },
    setup(props, { emit }) {
      const startIconPath = props.ssjrStudent ? inject('startIconPath') : null;
      const onStartClick = () => {
        emit('startActivity');
      };

      return {
        startIconPath,
        onStartClick,
        testClass,
      };
    },
  };
</script>
