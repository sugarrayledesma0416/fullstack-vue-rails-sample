<template>
  <div
    role="region"
    class="c-filter-bar  u-dis-md-flex"
    aria-label="Toolbar to filter table">
    <span class="c-filter-bar__item">
      <label
        class="c-filter-bar__label  u-screen-reader-only"
        for="lesson_id">Lesson</label>
      <select
        class="c-select  c-select--scores"
        name="lesson_id"
        :class="testClass('lesson-filter-menu')"
        @change="$emit('selectLesson', $event)">
        <option
          v-for="option in lessonOptions"
          :key="option.value"
          :selected="option.selected"
          :value="option.value">
          {{ option.name }}
        </option>
      </select>
    </span>

    <span class="c-filter-bar__item">
      <label
        class="c-filter-bar__label  u-screen-reader-only"
        for="week">Week</label>
      <select
        class="c-select  c-select--scores"
        name="week"
        :class="testClass('week-filter-menu')"
        @change="$emit('selectWeek', $event)">
        <option
          v-for="option in weekOptions"
          :key="option.value"
          :selected="option.selected"
          :value="option.value">
          {{ option.name }}
        </option>
      </select>
    </span>

    <div class="c-filter-bar__item">
      <div class="c-form-item">
        <input
          id="only-individual-toggle"
          v-model="store.state.showOnlyIndividuallyAssignable"
          type="checkbox"
          class="c-toggle"
          @change="refreshMenus">
        <label
          for="only-individual-toggle"
          class="c-label">
          Individually Assigned Only
        </label>
      </div>
    </div>

    <span class="c-filter-bar__item  u-flex-spacer  u-txt-rt  u-pad-rt-16">
      <input
        type="submit"
        name="commit"
        value="Save Changes"
        class="c-button  c-button--primary"
        data-disable-with="Save Changes">
    </span>

    <span class="c-filter-bar__item">
      <a
        :href="csvUrl"
        target="_blank"
        class="c-button"
        @click="handleExportClick">
        <span class="c-icon  c-icon--gb-export" />
        Export
      </a>
    </span>

    <span class="c-filter-bar__item  u-txt-rt">
      <button
        type="button"
        class="c-button  js-maxmin-btn  u-pad-8"
        title="Maximize table">
        <span class="c-icon  c-icon--lg  c-icon--maximize  js-maxmin-icon  u-mar-0" />
        <span class="u-screen-reader-only  js-maxmin-label">
          Maximize table
        </span>
      </button>
    </span>

    <ModalComponent
      v-show="state.showExportWarning"
      title="Warning"
      @close="handleWarningClose">
      <template #body>
        You must save changes before exporting
      </template>
      <template #footer>
        <div class="c-button-group  u-mar-0  u-txt-rt">
          <button
            type="button"
            class="c-button  c-button--primary"
            @click="handleWarningClose">
            OK
          </button>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { computed, inject, reactive } from 'vue';
  import ModalComponent from 'features/modal/ModalComponent';

  export default {
    name: 'FilterBar',
    components: { ModalComponent },
    props: {
      exportUrl: { required: true, type: String },
      lessonOptions: { required: true, type: Array },
      weekOptions: { required: true, type: Array },
    },
    emits: ['selectLesson', 'selectWeek'],
    setup(props) {
      const store = inject('store');

      const state = reactive({ showExportWarning: false });

      const csvUrl = computed(
        () => {
          // Converts boolean true/false to string.
          const onlyIndividual = String(
            store.state.showOnlyIndividuallyAssignable
          );

          if (props.exportUrl.includes('?')) {
            return `${props.exportUrl}&only_individual=${onlyIndividual}`;
          } else {
            return `${props.exportUrl}?only_individual=${onlyIndividual}`;
          }
        }
      );

      /**
       * Prevent exporting if there are unsaved changes.
       * @param {Event} event - click event from export button
       */
      function handleExportClick(event) {
        if (store.hasChanges) {
          event.preventDefault();
          state.showExportWarning = true;
        }
      }

      /**
       * Hide the export warning modal.
       * Prevent default so clicking on the close button doesn't
       * submit the save changes form.
       * @param {Event} event - click event from close/ok button
       */
      function handleWarningClose(event) {
        event.preventDefault();
        state.showExportWarning = false;
      }

      /**
       * The events for opening the column-header menus are bound on
       * initial page load. When displaying only individually-assigned
       * assignments, the columns for the assignments assigned to all
       * students are not in the DOM, and therefore do not get the events
       * bound to them. To fix this, reinitialie the menus when toggling
       * between viewing individually-assigned only and viewing all
       * assignments.
       */
      function refreshMenus() {
        // Safety check to avoid errors if the globals aren't defined, e.g.
        // when running jest unit tests.
        VHL?.GradebookTable?.init();
      }

      return {
        csvUrl,
        handleExportClick,
        handleWarningClose,
        refreshMenus,
        state,
        store,
        testClass,
      };
    },
  };
</script>
