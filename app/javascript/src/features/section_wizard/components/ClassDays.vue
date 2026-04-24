<template>
  <div class="l-grid  u-clearfix  u-pad-top-24">
    <h2 class="c-heading--sm  l-col-12  u-pad-bot-12">
      Select the days your section meets
    </h2>
    <div
      v-for="(classDay, index) in datastore.section.possibleClassDays"
      :key="classDay"
      class="l-col-1  u-mar-lt-8  u-mar-rt-20">
      <input
        :id="`section_days_${classDay}`"
        v-model="datastore.section.classDays[index]"
        class="c-form-item__checkbox"
        :class="testClass(`section-days-${classDay}`)"
        :data-js-day-name="classDay"
        type="checkbox">
      <label
        class="c-form-item__label  u-txt-16  u-txt-gray-3"
        :class="testClass(`week-days-${classDay}`)"
        :for="`section_days_${classDay}`">
        {{ classDay }}
      </label>
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'ClassDays',
    setup() {
      const datastore = inject('datastore');
      return { datastore, testClass };
    },
  };
</script>
