<template>
  <div class="u-clearfix">
    <h2 class="c-heading--sm  u-txt-bold">
      Section Details
    </h2>
    <div class="u-mar-top-8  u-mar-bot-8">
      <div v-if="datastore.section.canCopyAssignments">
        <label
           for="previous_section_id"
           class="c-form-item__label  u-dis-inline"
           :class="testClass('copy-assignment')">
          Copy assignments & due dates from another section
        </label>
        <button
           v-if="!datastore.section.copySectionHasExternalAssignments"
           type="button"
           class="c-no-button  u-txt-16  u-pad-2"
           :class="testClass('show-individual-assignment-information-modal')"
           @click="localstore.showIndividualAssignmentInformationModal = true">
          <MusicIcon variant="info-blue" />
        </button>
        <ModalComponent
           v-if="localstore.showIndividualAssignmentInformationModal"
           title="Individual Assignment Information"
           @close="localstore.showIndividualAssignmentInformationModal = false">
          <template #body>
            <div :class="testClass('show-individual-assignment-information-text')">
              <p>
                When copying individually assigned activities to a new section,
                all students in the section will receive these assignments.
              </p>
              <p>
                Copying Group Chat activities will also copy over their settings.
              </p>
            </div>
          </template>
        </ModalComponent>
        <div class="l-grid  u-pad-top-8">
          <div class="l-col-4">
            <select
               id="previous_section_id"
               v-model="datastore.section.assignmentCopySectionId"
               class="c-select"
               :class="testClass('previous-section')">
              <option value="" selected>None</option>
              <option
                v-for="section in datastore.section.courseSections"
                :key="section"
                :value="section.id">
              {{ section.name }}
              </option>
            </select>
          </div>
          <div
            v-show="datastore.section.copySectionHasExternalAssignments"
            class="l-col-3"
            :class="testClass('copy-ext-assignment')">
            <input
              id="copy_external_assignments"
              v-model="datastore.section.copyExternalAssignments"
              class="c-form-item__checkbox"
              type="checkbox"
              name="copy_external_assignments">
            <label for="copy_external_assignments" class="c-form-item__label">
              Copy external items
            </label>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="datastore.section.allowEnrollmentLock && !datastore.section.autorosteringLinked"
      data-container="open_to_students"
      class="u-mar-top-24  c-form-item">
      <input
        id="section_open_to_students"
        v-model="datastore.section.openToStudents"
        class="c-form-item__checkbox"
        :class="testClass('section-open-to-students')"
        type="checkbox"
        name="section_open_to_students">
      <label
        for="section_open_to_students"
        class="c-form-item__label"
        :class="testClass('allow-students')">
        Allow new students to enroll in this course section
      </label>
    </div>

    <div class="u-clearfix">
      <h3 class="c-heading--sm  c-heading--caps  u-pad-top-12">
        Assignment Availability
      </h3>
      <div
        ref="disclosureElm"
        class="c-disclosure  c-disclosure--end  js-disclosure-section">
        <p class="u-txt-16" :class="testClass('assignment-available-msg')">
          {{ datastore.section.assignmentAvailabilityMessage }}
        </p>
        <div
          class="c-disclosure__header"
          :class="testClass('assignment-availability')"
          role="button"
          aria-expanded="false"
          aria-controls="assign_avail">
          <span class="u-pad-lt-10  u-txt-16  u-txt-link-color">Change</span>
          <div class="c-disclosure__marker" />
        </div>
        <div
          id="assign_avail"
          class="c-disclosure__body">
          <div class="days_before_selector">
            <div class="c-form-item  u-float-lt">
              <select
                id="days_to_show_assignment_due_date"
                v-model="datastore.section.daysToShowAssignmentDueDate"
                class="c-select"
                :class="testClass('due-days-left-for-assignment')"
                name="days_to_show_assignment_due_date"
                tabindex="8">
                <optgroup
                  v-for="(group, name) in datastore.section.availableOptions"
                  :key="name"
                  :label="name">
                  <option
                    v-for="option in group"
                    :key="option"
                    :value="option.value">
                    {{ option.text }}
                  </option>
                </optgroup>
              </select>
            </div>
            <div class="u-float-lt  u-pad-lt-16  l-span-4">
              <label
                for="available_days_before"
                class="u-txt-16  u-txt-gray-9">
                Select when assignments will be available before the due date.
                This will not apply to assessments.
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, onMounted, reactive, ref } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';
  import MusicIcon from 'shared/vue/MusicIcon';

  export default {
    name: 'SectionDetails',
    components: { ModalComponent, MusicIcon },
    setup() {
      const disclosureElm = ref(null);
      const datastore = inject('datastore');
      const localstore = reactive({
        showIndividualAssignmentInformationModal: false,
      });

      onMounted(() => {
        new VHL.Music.V1.Disclosure(disclosureElm.value);
      });

      return {
        datastore,
        disclosureElm,
        localstore,
        testClass,
      };
    },
  };
</script>
