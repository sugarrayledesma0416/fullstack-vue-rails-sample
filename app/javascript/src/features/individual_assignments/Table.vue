<template>
  <div
    :role="a11yHidden ? 'presentation' : ''"
    :aria-hidden="a11yHidden ? 'true' : ''"
    class="c-table-wrapper  c-table-wrapper--gb"
    :class="[`c-table-wrapper--gb-${chunk}`, `js-gb-tablewrap-${chunk}`]">
    <table
      class="c-table  c-table--gradebook  js-gb-table"
      :class="[`c-table--gb-${chunk}`, `js-gb-table-${chunk}`]">
      <thead>
        <tr class="c-row  c-header-row  c-row--gradebook">
          <th class="c-gb-corner-cell" colspan="1" />
          <template v-if="showColumnHeaders">
            <StrandHeader
              v-for="(strand, index) in strandHeaders()"
              :key="`${strand.id}-${index}`"
              :strand="strand" />
          </template>
        </tr>

        <tr class="c-row  c-header-row  c-row--gradebook">
          <th class="c-col-head--gb  c-col-head--gb-student-name" scope="col">
            <div class="c-col-head-link--gb">
              Student
            </div>
          </th>
          <template v-if="showColumnHeaders">
            <ActivityHeader
              v-for="entry in store.firstUserEntries"
              :key="entry.assignable_id"
              :chunk="chunk"
              :entry="entry" />
          </template>
        </tr>
      </thead>
      <tbody v-if="showBody">
        <tr
          v-for="(assignments, userIdWithPrefix) in store.entries"
          :key="userIdWithPrefix"
          class="c-row  c-row--gradebook">
          <th
            :title="studentName(assignments[0])"
            class="c-row-head  c-row-head--gb  c-row-head--gb-student-name"
            scope="row">
            <span class="c-row-head-link--gb">
              {{ studentName(assignments[0]) }}
            </span>
          </th>
          <template v-if="chunk === 'full'">
            <StudentCell
              v-for="assignment in assignments"
              :key="assignment.assignable_id"
              :assignment="assignment"
              :userIdWithPrefix="userIdWithPrefix"
              @toggleCheckbox="handleCheckboxToggle(assignment, $event)" />
          </template>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
  /**
   * For details on how the gradebook table works, see the gradebook wiki:
   * https://github.com/vhl/gradebook/wiki/Front-end:-Gradebook-Table
   *
   * This component will generate any of the 4 table pieces, depending on the
   * value of the `chunk` prop : 'top', 'side', 'corner', or 'full'.
   */
  import { inject } from 'vue';
  import ActivityHeader from './ActivityHeader';
  import StrandHeader from './StrandHeader';
  import StudentCell from './StudentCell';

  const props = defineProps({ chunk: { required: true, type: String }});
  const store = inject('store');

  const showBody = ['full', 'side'].includes(props.chunk);
  const showColumnHeaders = ['full', 'top'].includes(props.chunk);
  const a11yHidden = ['corner', 'side', 'top'].includes(props.chunk);

  /**
   * @param {Object} assignment - Assignment record
   * @param {String} assignment.first_name - Student first name
   * @param {String} assignment.last_name - Student last name
   * @return {String} Student name, last-name first
   */
  function studentName(assignment) {
    return `${assignment.last_name}, ${assignment.first_name}`;
  }

  /**
   * @param {Object} assignment - Assignment record
   * @param {Event} event - Change event from assignment checkbox
   */
  function handleCheckboxToggle(assignment, event) {
    if (event.target.checked) {
      assignment.individually_assigned = true;
    } else {
      assignment.individually_assigned = false;
      assignment.individual_due_date = null;
    }
  }

  /**
   * @return {array} Copy of strand-header-object array from store.
   */
  function strandHeaders() {
    return store.strandHeaders.slice();
  }
</script>

<style scoped>
  .ns-gradebook .c-table-wrapper--gb-side {
    width: 12rem;
  }

  .ns-gradebook .c-table-wrapper--gb-corner {
    width: 12rem;
  }

  .ns-gradebook .c-table-wrapper--gb {
    top: 102px;
  }

  .ns-gradebook .c-gb-corner-cell {
    max-width: 12rem;
    min-width: 12rem;
    width: 12rem;
  }
</style>
