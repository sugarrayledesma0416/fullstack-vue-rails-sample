<template>
  <ModalComponent
    :class="testClass('instructor-information')"
    title="Instructor Roles"
    @close="onCloseClick($event)">
    <template #body>
      <p class="u-txt-16  u-txt-bold  u-txt-gray-6">
        Co-instructors may:
      </p>
      <ul :class="testClass('co-instructor-role-info')">
        <li>create, modify and grade assignments and assessments</li>
        <li>respond to help requests</li>
        <li>utilize all communication features</li>
      </ul>
      <p>
        This role cannot edit overall course and section settings
        (gradebook categories, video preferences, due-time, etc.)
      </p>
      <hr>
      <p class="u-txt-16  u-txt-bold  u-txt-gray-6">
        Assistants may:
      </p>
      <ul :class="testClass('assistant-role-info')">
        <li>grade assignments and assessments</li>
        <li>respond to help requests</li>
        <li>utilize all communication features</li>
      </ul>
      <p>
        This role cannot create or change assignments or assessments,
        or edit overall course and section settings
        (gradebook categories, video preferences, due-time, etc.)
      </p>
    </template>
  </ModalComponent>
</template>

<script>
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';

  export default {
    name: 'InstructorRolesModal',
    components: { ModalComponent },
    setup(props, { emit }) {
      /**
       * This is handler for close event from ModalComponent
       * @param {Event} event
       */
      function onCloseClick(event) {
        emit('close', event);
      }

      return { onCloseClick, testClass };
    },
  };
</script>
