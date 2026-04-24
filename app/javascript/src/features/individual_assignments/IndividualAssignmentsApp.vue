<template>
  <div>
    <form :action="submitUrl" accept-charset="UTF-8" method="POST">
      <input type="hidden" name="_method" value="put">
      <input
        v-once
        type="hidden"
        name="authenticity_token"
        :value="csrfToken">
      <input
        type="hidden"
        name="only_individual"
        :value="store.state.showOnlyIndividuallyAssignable">

      <div class="c-gradebook-wrapper  js-gb-wrapper  js-main-content">
        <FilterBar
          :exportUrl="exportUrl"
          :lessonOptions="JSON.parse(lessonOptions)"
          :weekOptions="JSON.parse(weekOptions)"
          @selectLesson="handleLessonSelect"
          @selectWeek="handleWeekSelect" />

        <template v-if="store.hasEntries">
          <Table chunk="full" />
          <Table chunk="top" />
          <Table chunk="side" />
          <Table chunk="corner" />
        </template>
        <template v-else>
          <div class="u-txt-quiet  u-txt-ctr  u-txt-24  u-mar-top-64">
            There are no assignments for the selected filter options.
          </div>
        </template>
      </div>
    </form>
    <StateEditingModal :programId="programId" />
  </div>
</template>

<script setup>
  import { metaTagContent } from 'shared/utils';
  import { provide } from 'vue';
  import Datastore from './models/datastore';
  import StateEditingModal from './StateEditingModal';
  import FilterBar from './FilterBar';
  import Table from './Table';
  import useIndividualAssignmentsStore from './stores/use_individual_assignments_store';

  const props = defineProps({
    entries: { required: true, type: String },
    exportUrl: { required: true, type: String },
    filterUrl: { required: true, type: String },
    lessonOptions: { required: true, type: String },
    maxDueDate: { required: true, type: String },
    minDueDate: { required: true, type: String },
    onlyIndividual: { required: true, type: String },
    submitUrl: { required: true, type: String },
    weekOptions: { required: true, type: String },
  });

  const csrfToken = metaTagContent('csrfToken');
  const programId = metaTagContent('VHL.program_id');

  const store = new Datastore(
    JSON.parse(props.entries),
    props.onlyIndividual
  );
  provide('store', store);

  const individualAssignmentsStore = useIndividualAssignmentsStore();
  individualAssignmentsStore.init(
    {
      minDueDate: props.minDueDate,
      maxDueDate: props.maxDueDate,
    }
  );

  /**
   * Set the window location to the current url plus a query parameter
   * for the selected lesson id.
   * @param {Event} event - The change event from the lesson dropdown
   */
  function handleLessonSelect(event) {
    const lessonId = event.target.value;
    window.location.href = `${baseFilterUrl()}&lesson_id=${lessonId}`;
  }

  /**
   * Set the window location to the current url plus a query parameter
   * for the selected week.
   * @param {Event} event - The change event from the week dropdown
   */
  function handleWeekSelect(event) {
    const week = event.target.value;
    window.location.href = `${baseFilterUrl()}&week=${week}`;
  }

  /**
   * @private
   * @return {string} Base URL for applying new filter options.
   */
  function baseFilterUrl() {
    // Converts boolean true/false to string.
    const onlyIndividual = String(
      store.state.showOnlyIndividuallyAssignable
    );
    return `${props.filterUrl}?only_individual=${onlyIndividual}`;
  }
</script>

<style scoped>
  .ns-gradebook .c-gradebook-wrapper {
    top: 136px;
  }

  .ns-gradebook .c-gradebook-wrapper::after {
    left: 12rem;
    top: 102px;
  }

  .ns-gradebook .c-gradebook-wrapper::before {
    margin-left: -112px;
    top: 102px;
  }
</style>
