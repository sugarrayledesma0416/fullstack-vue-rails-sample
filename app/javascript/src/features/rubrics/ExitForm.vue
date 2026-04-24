<template>
  <form :action="returnUrl" method="GET">
    <input
      type="hidden"
      name="display_lesson"
      :value="rubric.lessonId">
    <input
      type="hidden"
      name="start_unit"
      :value="rubric.startUnit">
    <input
      type="hidden"
      name="toc_location"
      :value="rubric.strandId">
    <button
      class="c-button"
      :class="classes"
      @click="handleClick($event)">
      Exit
    </button>
  </form>
</template>

<script>
  import { inject } from 'vue';
  import useRubricEditingStore from './use_rubric_editing_store';

  export default {
    name: 'ExitForm',
    props: {
      checkUnsavedChanges: { default: false, type: Boolean },
      classes: { default: '', type: String },
      returnUrl: { type: String, required: true },
    },
    setup(props) {
      const exitUnlessUnsavedChanges = inject('exitUnlessUnsavedChanges');
      const rubric = useRubricEditingStore();

      /**
       * If this instance needs to check for unsaved changes, call the
       * injected function, which will prevent the default behaviour of
       * the clickEvent if unsaved changes are found.
       * @param {Event} event - Button click event
       */
      function handleClick(event) {
        if (props.checkUnsavedChanges) {
          exitUnlessUnsavedChanges(event);
        }
      }

      return { handleClick, rubric };
    },
  };
</script>
