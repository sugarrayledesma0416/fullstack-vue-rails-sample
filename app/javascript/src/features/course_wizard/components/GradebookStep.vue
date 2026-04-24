<template>
  <div :class="{ 'edit-course': courseDataStore.editCourseMode }">
    <div class="gradebook-step">
      <div class="gradebook-step__content">
        <StepHeader headingLevel="1" />
        <VStack spacing="lg" class="u-mar-bot-20">
          <div
            v-if="courseDataStore.newCourseMode ||
              (courseDataStore.editCourseMode && courseDataStore.store.courseOptions.allow_copy)">
            <Fieldset
              v-if="config.instAdmin"
              legend="Use category settings from...">
              <div class="u-dis-flex">
                <FormItem
                  class="u-mar-rt-16"
                  inputId="copyFromCourse"
                  label="Course"
                  type="radio">
                  <input
                    id="copyFromCourse"
                    v-model="courseDataStore.store.course.categorySettingsCourseSource"
                    type="radio"
                    class="gradebook-step__input"
                    value="course">
                </FormItem>

                <FormItem
                  inputId="copyFromTemplate"
                  label="Template"
                  type="radio">
                  <input
                    id="copyFromTemplate"
                    v-model="courseDataStore.store.course.categorySettingsCourseSource"
                    type="radio"
                    class="form-item-radio"
                    value="template">
                </FormItem>
              </div>
            </Fieldset>

            <Fieldset
              :legend="!config.instAdmin ? 'Use category settings from...' : ''"
              :legendClasses="` ${testClass('copy-settings')} u-mar-bot-4 `">
              <FormItem
                v-if="courseDataStore.store.course.categorySettingsCourseSource === 'course'"
                hideLabel
                inputId="previous_course_id"
                label="Course">
                <!-- eslint-disable vue/no-v-model-argument -->
                <VhlSelectDataWrapper
                  id="previous_course_id"
                  v-model="courseDataStore.store.settingsCourses.categorySettingsCourse"
                  :options="prevCourseOptions" />
                <!-- eslint-enable vue/no-v-model-argument -->
              </FormItem>

              <FormItem
                v-if="courseDataStore.store.course.categorySettingsCourseSource === 'template'"
                hideLabel
                inputId="previous_course_template_id"
                label="Template">
                <!-- eslint-disable vue/no-v-model-argument -->
                <VhlSelectDataWrapper
                  id="previous_course_template_id"
                  v-model="courseDataStore.store.settingsCourses.categorySettingsCourse"
                  :options="prevCourseTemplateOptions" />
                <!-- eslint-enable vue/no-v-model-argument -->
              </FormItem>
            </FieldSet>
          </div>

          <div>
            <Heading
              level="2"
              variant="category"
              :class="testClass('category-heading')">
              <!-- eslint-disable vue/no-v-html -->
              Gradebook Categories <span v-html="config.gradebookCategories" />
              <!-- eslint-enable vue/no-v-html -->
            </Heading>
            <p>
              Here you will create categories and customize the layout and
              settings of your course gradebook.
            </p>

            <div key="1" class="gradebook-step__tutorial-link">
              <Expander
                key="2"
                class="u-mar-bot-32"
                headerTextOpen="Hide Tutorial"
                headerTextClosed="View Tutorial"
                :class="testClass('tutorial-disclosure')"
                :headerClass="testClass('tutorial-disclosure-text')"
                :expanded="tutorial.store.active"
                @expanderClick="tutorial.toggleTutorial()">
                <Tutorial />
              </Expander>
              <div key="3">
                <GradebookTableContainer
                  @openAddCategory="localStore.showAddCategory = true"
                  @openEditCategory="openEditCategory($event)" />
                <AddCategory
                  v-if="localStore.showAddCategory"
                  @closeAdd="localStore.showAddCategory = false" />
                <EditCategory
                  v-if="localStore.showEditCategory"
                  :categoryIndex="localStore.editCategoryIndex"
                  @closeEdit="closeEditCategory" />
              </div>
            </div>
          </div>

          <div v-if="courseDataStore.store.course.categorySettingsCourseSource === 'template'">
            <!-- eslint-disable vue/no-v-model-argument -->
            <VhlSelectDataWrapper
              id="previous_course_template_id"
              v-model="courseDataStore.store.settingsCourses.categorySettingsCourse"
              :options="prevCourseTemplateOptions" />
            <!-- eslint-enable vue/no-v-model-argument -->
          </div>
        </VStack>
      </div>

      <SetupControls
        :isUpdateDisabled="courseDataStore.isUpdateDisabled"
        :isNextDisabled="isNextButtonDisabled()"
        nextStep="summary-step"
        previousStep="content-step" />
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { computed, inject, onMounted, onUnmounted, provide, reactive, ref, toRef, watch } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import AddCategory from 'features/category_wizard/components/add_category/AddCategory';
  import EditCategory from 'features/category_wizard/components/EditCategory';
  import Expander from 'features/shared/expander/Expander';
  import GradebookTableContainer from 'features/category_wizard/components/GradebookTableContainer';
  import Tutorial from 'features/category_wizard/components/Tutorial';
  import TutorialStore from 'features/category_wizard/models/tutorial_store';
  import VhlSelectDataWrapper from './VhlSelectDataWrapper';
  import SetupControls from './SetupControls';
  import StepHeader from './StepHeader';
  import { Fieldset, FormItem } from 'features/shared/FormElements';
  import Heading from 'features/shared/Heading';
  import VStack from 'features/shared/VStack';

  /**
   * @typedef {
   *  import(
   *    'features/course_wizard/components/AdvancedCourseStep.vue'
   *  ).VhlSelectOptionForPrevCourse
   * } VhlSelectOptionForPrevCourse
   */

  /**
   * @typedef {
   *  import('features/course_wizard/services/course_serializer.js').CategoryObject
   * } CategoryObject
   */

  export default {
    name: 'GradebookStep',
    components: {
      AddCategory,
      EditCategory,
      GradebookTableContainer,
      SetupControls,
      StepHeader,
      Tutorial,
      VhlSelectDataWrapper,
      Expander,
      Fieldset,
      FormItem,
      Heading,
      VStack,
    },
    setup() {
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');
      const localStore = reactive({
        editCategoryIndex: -1,
        showAddCategory: false,
        showEditCategory: false,
      });
      const tutorial = new TutorialStore();
      const disableNextButton = ref(true);
      provide('tutorial', tutorial);

      const categoriesRef = toRef(courseDataStore.store.course, 'categories');
      watch(categoriesRef, () => {
        if (courseDataStore.store.course.categories.length > 0) {
          tutorial.closeTutorial();
        } else {
          tutorial.viewTutorial();
        }
      });

      /**
       * This gets options for Previous Courses dropdown in the required format
       * @return {Array.<VhlSelectOptionForPrevCourse>}
       */
      const prevCourseOptions = computed(() => {
        const courseOpts = courseDataStore.store.courseOptions.settings?.map(
          (prevCourse, index) => ({
            text: prevCourse.name,
            value: prevCourse,
          })
        ) ?? [];
        return [{ text: '', value: undefined }].concat(courseOpts);
      });

      /**
       * This gets options for Previous Course Templates dropdown in the required format
       * @return {Array.<VhlSelectOptionForPrevCourse>}
       */
      const prevCourseTemplateOptions = computed(() => {
        const courseOpts = courseDataStore.store.courseOptions.template_settings?.map(
          (prevCourseTemplate, index) => ({
            text: prevCourseTemplate.name,
            value: prevCourseTemplate,
          })
        ) ?? [];
        return [{ text: '', value: undefined }].concat(courseOpts);
      });

      /**
       * This method returns combined weight for all the categories
       * @return {number}
       */
      function totalWeight() {
        return courseDataStore.store.course.categories.reduce(function(memo, category) {
          // Undefined weights are zeroes instead.
          return memo + (category.weightingPercent || 0);
        }, 0);
      }

      /**
       * opens the edit category modal.
       * @param {CategoryObject} categoryObj - category object
       */
      function openEditCategory(categoryObj) {
        localStore.editCategoryIndex = courseDataStore.store.course.categories.findIndex(
          (category) => !category._destory && category.name === categoryObj.name
        );
        localStore.showEditCategory = true;
      }

      /**
       * closes the edit category modal.
       */
      function closeEditCategory() {
        localStore.editCategoryIndex = -1;
        localStore.showEditCategory = false;
      }

      /**
       * Sets a variable that indicates that the user scrolled near the
       * bottom of the page.
       * @param {event} event - The scroll event of the window.
       */
      function nextButtonEnableWithScroll(event) {
        if (
          (window.innerHeight + Math.ceil(window.pageYOffset + 120) ) >= document.body.offsetHeight
        ) {
          disableNextButton.value = false;
        }
      }

      /**
       * Should the next button be disabled. Based on the category weight sum
       * or if the user has scrolled to the end of the page or not.
       * @return {boolean}
       */
      function isNextButtonDisabled() {
        return !(totalWeight() === 100) || disableNextButton.value;
      }

      onMounted(() => {
        scrollToTopOfPage();
        nextButtonEnableWithScroll();
        window.addEventListener('scroll', nextButtonEnableWithScroll);
      });

      onUnmounted(() => {
        window.removeEventListener('scroll', nextButtonEnableWithScroll);
      });

      return {
        closeEditCategory,
        config,
        courseDataStore,
        isNextButtonDisabled,
        localStore,
        openEditCategory,
        prevCourseOptions,
        prevCourseTemplateOptions,
        testClass,
        tutorial,
        Expander,
        Fieldset,
        FormItem,
        Heading,
        VStack,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  @import '~MusicAssets/stylesheets/music/library/v1/parts/utilities';
  @import 'features/shared/form_element_settings';

  .expander {
    --expander-header-fill-color: #{$white};
    --expander-body-fill-color: #{$gray-e};
  }

  .fade-enter-active,
  .fade-leave-active {
    transition: opacity 0.5s ease;
  }

  .fade-enter-from,
  .fade-leave-to {
    opacity: 0;
  }

  .gradebook-step {
    position: relative;
  }

  .edit-course .gradebook-step {
    border: $gray-e solid 0.625rem;
    padding: 0.938rem;
  }

  .gradebook-step__content {
    clear: both;
    display: block;
    padding: 0.25rem;
    position: relative;
    overflow: visible;
  }

  .gradebook-step__copy-settings {
    display: block;
    font-size: 0.688rem;
    margin: 0;
    margin-bottom: 0.75rem;
    padding: 0;
  }

  .gradebook-step__input {
    margin-bottom: 0.75rem;
    margin-right: 0.125rem;
  }

  .u-mar-lt-12 {
    margin-left: 0.75rem;
  }
</style>

