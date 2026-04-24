<template>
  <!-- start additional instructors -->
  <div
    ref="disclosureElm"
    class="c-disclosure  c-disclosure--end"
    :class="testClass('additional-instructor-disclosure')">
    <div
      class="c-disclosure__header"
      role="button"
      aria-expanded="false"
      aria-controls="instructor-disclosure-body">
      <h2 class="c-heading--sm  u-txt-link-color  u-dis-inline">
        Add/Edit Additional Instructors
      </h2>
      <div
        class="c-disclosure__marker"
        :class="testClass('instructor-names-disclosure')" />
    </div>
    <div id="instructor-disclosure-body" class="c-disclosure__body  c-form-item  u-pad-0  u-mar-0">
      <input
        id="hide_owner_name"
        v-model="datastore.section.hideOwnerName"
        type="checkbox"
        class="c-form-item__checkbox"
        :class="testClass('hide-owner-name')"
        :title="noCoInstructorMessage"
        :disabled="!datastore.section.anyCoInstructorOrAssistant">

      <label for="hide_owner_name" class="c-form-item__label u-inline">
        Do not show my name to students
      </label>

      <div
        v-for="instructor in sortedInstructorList"
        :key="instructor.id">
        <div v-if="instructor.user_id !== datastore.section.instructor.id">
          <div
            class="additional_instructor  instructor_team_row  u-clearfix  u-pad-top-12"
            :class="testClass('additional-instructor')">
            <div
              class="instructor_name  u-mar-top-4"
              :class="testClass('additional-instructor-name')">
              {{ instructor.full_name }} {{ instructor.email ? `(${instructor.email})` : '' }}
            </div>

            <div class="instructor_role">
              <select
                :id="`section_instructor_roles_${instructor.user_id}`"
                v-model="instructor.role"
                class="c-select"
                :class="testClass('section-instructor-roles')"
                @change="onRoleChange(instructor)">
                <option
                  v-for="(role, index) in datastore.section.instructorRoles"
                  :key="index"
                  :value="role">
                  {{ role }}
                </option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <!-- end additional instructors -->
</template>

<script>
  import { computed, inject, onMounted, ref } from 'vue';
  import { sort } from 'shared/utils';
  import { testClass } from 'music';

  export default {
    name: 'AdditionalInstructor',
    setup() {
      const disclosureElm = ref(null);
      const datastore = inject('datastore');

      const noCoInstructorMessage = computed(
        () => {
          if (datastore.section.anyCoInstructorOrAssistant) {
            return '';
          } else {
            return 'If no other instructors are selected, your name ' +
              'must be shown to students.';
          }
        }
      );

      const sortedInstructorList = computed(() => {
        return sort(datastore.section.sectionInstructors, 'last_name', 'asc');
      });

      /**
       * On Section Instructor role change handler
       * @param {Object} instructor
       * @param {boolean} instructor.allowed_to_edit_content
       * @param {string} instructor.role
       */
      function onRoleChange(instructor) {
        if (instructor.role === 'Assistant') {
          instructor.allowed_to_edit_content = false;
        } else if (instructor.role === 'Co-instructor') {
          instructor.allowed_to_edit_content = true;
        }

        if (!datastore.section.anyCoInstructorOrAssistant) {
          datastore.section.hideOwnerName = false;
        }
      }

      onMounted(() => {
        new VHL.Music.V1.Disclosure(disclosureElm.value);
      });

      return {
        datastore,
        disclosureElm,
        noCoInstructorMessage,
        onRoleChange,
        sortedInstructorList,
        testClass,
      };
    },
  };
</script>
