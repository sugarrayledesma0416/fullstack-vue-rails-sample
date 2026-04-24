<template>
  <div class="l-grid  u-pad-top-16">
    <div class="u-mar-bot-8  l-col-12  u-txt-body-1  u-dis-flex">
      Select the days of the week this course meets.
      <music-icon-asterisk-v3 class="icon u-fill-util-error c-icon-v3" size="md" />
    </div>
    <div
      v-for="(classDay, index) in courseDataStore.store.course.possibleClassDays"
      :key="classDay"
      class="l-col-1  u-mar-lt-8  u-mar-rt-20">
      <input
        :id="`course_days_${classDay}`"
        v-model="courseDataStore.store.course.classDays[index]"
        class="c-form-item__checkbox"
        :class="testClass(`course-days-${classDay}`)"
        :data-js-day-name="classDay"
        type="checkbox">
      <label
        class="c-form-item__label  u-txt-16  u-txt-gray-3"
        :class="testClass(`week-days-${classDay}`)"
        :for="`course_days_${classDay}`">
        {{ classDay }}
      </label>
    </div>
  </div>
  <FormFeedback
    v-if="disableNextButton === false && courseDataStore.courseValidator.hasErrorInEnterpriseSectionClassDays().value"
    type="error"
    :class="testClass('course-date-validation-error')">
    {{ courseDataStore.courseValidator.hasErrorInEnterpriseSectionClassDays().msg }}
  </FormFeedback>
</template>

<script setup>
  import { FormFeedback } from 'features/shared/FormElements';
  import { inject, onBeforeMount } from 'vue';
  import { testClass } from 'music';
  import { defineProps } from 'vue';

  defineProps({
    disableNextButton: { type: Boolean, required: true },
  });

  const courseDataStore = inject('courseDataStore');

  onBeforeMount(() => {
    if (typeof courseDataStore.store.course.classDays === 'string') {
      const selectedIndexes = courseDataStore.store.course.classDays.split(',').map(Number);
      const totalDays = courseDataStore.store.course.possibleClassDays.length;

      courseDataStore.store.course.classDays = Array.from({ length: totalDays }, (_, index) =>
        selectedIndexes.includes(index)
      );
    }
  });
</script>
