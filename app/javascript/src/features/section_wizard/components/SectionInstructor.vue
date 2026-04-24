<template>
  <div>
    <div class="u-pad-top-16" data-container="instructor_full_name">
      <h2 class="c-heading--sm  u-dis-inline  u-txt-bold">
        Instructor
      </h2>
      <button
        type="button"
        class="c-no-button  u-txt-16  u-pad-2"
        :class="testClass('show-instructor-role-modal')"
        @click="showInstructorRolesModal">
        <MusicIcon variant="help" />
      </button>
      <InstructorRolesModal
        v-if="localstore.showInstructorRolesModal"
        @close="hideInstructorRolesModal" />
    </div>

    <!-- Start Instructors List -->
    <table class="u-mar-top-10  c-table">
      <thead>
        <tr class="u-bg-white  c-header-row">
          <th scope="col">Can Create Content</th>
          <th scope="col">Role</th>
          <th scope="col">Name</th>
          <th scope="col">Email</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="instructor in sortedInstructorList"
          :key="instructor.id"
          class="c-row"
          :class="testClass('instructor-detail')">
          <td>
            <span
              class="allow-content-editing">
              <input
                v-if="instructor.role === 'Instructor'"
                :id="`section_instructor_allow_editing_${instructor.user_id}`"
                checked
                disabled
                type="checkbox"
                class="c-form-item__checkbox"
                :class="testClass('allowed-to-edit-content-checkbox')">
              <input
                v-if="instructor.role === 'Co-instructor'"
                :id="`section_instructor_allow_editing_${instructor.user_id}`"
                v-model="instructor.allowed_to_edit_content"
                type="checkbox"
                class="c-form-item__checkbox"
                :class="testClass('allowed-to-edit-content-checkbox')">
              <input
                v-if="instructor.role === 'Assistant'"
                :id="`section_instructor_allow_editing_${instructor.user_id}`"
                type="checkbox"
                disabled
                class="c-form-item__checkbox"
                :class="testClass('allowed-to-edit-content-checkbox')">
              <label
                :for="`section_instructor_allow_editing_${instructor.user_id}`"
                class="u-pad-bot-24  c-form-item__label">
              </label>
            </span>
          </td>
          <td>
            <span :class="testClass('instructor-role')">
              {{ instructor.role }}
            </span>
          </td>
          <td>
            <span :class="testClass('instructor-fullname')">
              {{ instructor.full_name }}
            </span>
            <button
              v-if="instructor.role !== 'Co-instructor'"
              :id="`${instructor.role.toLowerCase()}_tooltip_${sortedInstructorList.indexOf(instructor)}`"
              class="u-pad-lt-4  c-no-button  preview-table__moreinfo"
              type="button">
              <span class="c-embedded-icon">
                <IconInfo alt="More information" rel="" />
              </span>
            </button>
          </td>
          <td>
            <span :class="testClass('instructor-email')">
              {{ instructor.email ? `${instructor.email}` : '' }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
    <!-- End Instructors List -->

    <!-- Add/ Edit Additional Instructor -->
    <AdditionalInstructor v-if="!datastore.section.autorosteringLinked" />
  </div>
</template>

<script>
  import { computed, inject, nextTick, onMounted, reactive, watch } from 'vue';
  import { testClass } from 'music';
  import AdditionalInstructor from './AdditionalInstructor';
  import InstructorRolesModal from './InstructorRolesModal';
  import MusicIcon from 'shared/vue/MusicIcon';
  import IconInfo from '../../course_wizard/components/IconInfo';
  import tippy from 'tippy.js';

  const useInstructor = function(localstore) {
    /**
     * This method updates localstore to hide InstructorRolesModal
     */
    function hideInstructorRolesModal() {
      localstore.showInstructorRolesModal = false;
    }

    /**
     * This method updates localstore to show InstructorRolesModal
     */
    function showInstructorRolesModal() {
      localstore.showInstructorRolesModal = true;
    }

    return { hideInstructorRolesModal, showInstructorRolesModal };
  };

  export default {
    name: 'SectionInstructor',
    components: { AdditionalInstructor, IconInfo, InstructorRolesModal, MusicIcon },
    setup() {
      const localstore = reactive({
        showInstructorRolesModal: false,
      });
      const datastore = inject('datastore');
      const config = inject('config');
      const section = datastore.section;

      const sortedInstructorList = computed(() => {
        const instructors = section.sectionInstructorsWithRoles(
          section.sectionInstructors
        );

        return section.descendingByRole(instructors);
      });

      const {
        hideInstructorRolesModal, showInstructorRolesModal,
      } = useInstructor(localstore);

      /**
       * @private
       * @param {string} sectionInstructorList - the list of section instructors
       * for the section
       */
      async function createTippyTooltips(sectionInstructorList) {
        sortedInstructorList.value.forEach((item, index) => {
          tippy('#instructor_tooltip_' + index,
                { content: "Cannot disable content creation for course owners" }
          );
          tippy('#assistant_tooltip_' + index,
                { content: "Assistants cannot create content" }
          );
        });
      }

      watch(
        sortedInstructorList,
        (newValue) => createTippyTooltips(newValue),
        { flush: 'post' }
      );

      onMounted(() => {
        createTippyTooltips(sortedInstructorList);
      });

      return {
        config,
        datastore,
        sortedInstructorList,
        hideInstructorRolesModal,
        localstore,
        showInstructorRolesModal,
        testClass,
      };
    },
  };
</script>

<style lang="css">
  @import 'tippy.js/dist/tippy';
</style>
