<template>
  <div>
    <div class="course-details__heading-position">
      <StepHeader headingLevel="1" />
    </div>

    <div class="course-details__step-content">
      <VStack spacing="lg">
        <Fieldset>
          <FormItem
            inputId="course_name"
            label="Course Name">
            <input
              id="course_name"
              v-model="courseDataStore.store.course.name"
              type="text"
              required
              class="text-input"
              :class="testClass('course-name-input')"
              @input="courseDataStore.store.courseNameValidator = true">
            <div
              v-if="!config.instAdmin && courseDataStore.store.course.name !== 'New course'"
              class="course-details__dots" />
            <FormFeedback
              v-if="courseDataStore.store.courseNameValidator
                && courseDataStore.courseValidator.hasCourseError('name').value"
              :class="testClass('course-name-validation-error')"
              type="error">
              {{ courseDataStore.courseValidator.hasCourseError('name').msg }}
            </FormFeedback>
          </FormItem>
        </Fieldset>

        <Expander
          :expanded="previewVisibility"
          headerTextOpen="Hide Preview"
          headerTextClosed="Preview as Student"
          variant="end"
          class="c-expander--course-preview"
          :class="testClass('vhl-expander')"
          @click="() => previewVisibility = !previewVisibility">
          <PreviewTable
            courseType="express"
            class="u-mar-top-8" />
        </Expander>

        <Fieldset>
          <FormItem
            inputId="start_date"
            label="Start Date">
            <VhlDate
              inputId="start_date"
              testSelector="start-date"
              :modelValue="courseDataStore.store.course.startDate"
              @update:modelValue="courseDataStore.store.course.startDate = $event" />
          </FormItem>
          <FormItem
            inputId="end_date"
            label="End Date">
            <VhlDate
              inputId="end_date"
              testSelector="end-date"
              :modelValue="courseDataStore.store.course.endDate"
              @update:modelValue="courseDataStore.store.course.endDate = $event" />
            <FormFeedback
              v-if="courseDataStore.courseValidator.hasCourseError('endDate').value"
              :class="testClass('course-end-date-validation-error')">
              {{ courseDataStore.courseValidator.hasCourseError('endDate').msg }}
            </FormFeedback>
            <FormFeedback
              v-if="courseDataStore.courseValidator.hasCourseError('date').value"
              :class="testClass('course-date-validation-error')">
              {{ courseDataStore.courseValidator.hasCourseError('date').msg }}
            </FormFeedback>
          </FormItem>
        </Fieldset>

        <SectionComponent />
        <SettingCategory
          v-if="courseDataStore.store.courseOptions.supported_standard_sets.length"
          title="Standards"
          class="u-mar-bot-32  with-divider">
        <Standards class="u-mar-bot-16" />
        <FormFeedback
          v-if="courseDataStore.courseValidator.hasCourseError('standards').value"
          :class="testClass('standards-validation-error')"
          type="error">
          {{ courseDataStore.courseValidator.hasCourseError('standards').msg }}
        </FormFeedback>
      </SettingCategory>

      </VStack>
    </div>
    <SetupControls
      :isNextDisabled="isNextBtnDisable()"
      nextStep="learning-tracks-step"
      previousStep="path-selector-step" />
  </div>
</template>

<script setup>
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';
  import { testClass } from 'music';
  import { inject, onMounted, ref } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import PreviewTable from './PreviewTable';
  import SectionComponent from './SectionComponent';
  import SetupControls from './SetupControls';
  import StepHeader from './StepHeader';
  import VhlDate from './VhlDate';
  import VStack from 'features/shared/VStack';
  import { Fieldset, FormItem, FormFeedback }
    from 'features/shared/FormElements';
  import Expander from 'features/shared/expander/Expander';
  import Standards from './content_step/settings/Standards';

  const config = inject('config');
  const courseDataStore = inject('courseDataStore');
  const cancelLink = config.instAdmin ?
    `/institution_admin/templates/${config.programId}?school_id=${config.schoolId}` :
    `/instructor/dashboard/${config.programId}`;
  const previewVisibility = ref(false);

  /**
    * returns the condition is next button is disabled or not.
    * @return {boolean}
    */
  const isNextBtnDisable = function() {
    const sectionCheck = courseDataStore.store.course.sections.map((section) => {
      if (Object.keys(section).includes('name')) {
        return (section?.name.length > 75 || !section?.name);
      } else {
        return true;
      }
    });

    return courseDataStore.courseValidator.isCourseNameOrDatesInvalid() ||
      sectionCheck.includes(true);
  };

  onMounted(() => {
    scrollToTopOfPage();
  });
</script>

<style lang="scss" scoped>
  @import 'features/shared/form_element_settings';

  .c-expander--course-preview {
    width: 75%;
  }

  .course-details__step-content {
    margin-bottom: 14rem;
  }
</style>
