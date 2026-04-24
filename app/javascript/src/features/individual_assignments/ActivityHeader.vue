<template>
  <th
    v-if="!store.state.showOnlyIndividuallyAssignable || entry.individually_assignable"
    class="c-col-head--gb  c-col-head--gb-activity"
    :title="entry.activity_title">
    <ActionMenu
      :isActive="chunk === 'full'"
      titleClass="c-col-head-link--gb  c-col-head-link--gb-activity">
      <template #title>
        <span class="c-due-date--gb">{{ dueDateDisplay() }}</span>
        <br>
        <span :class="testClass('activity-column-activity-title')">
          {{ entry.activity_title }}
        </span>
      </template>
      <template #items>
        <ActionMenuItem
          :href="`/sections/0/activities/${entry.assignable_id}`"
          target="_blank">
          View {{ entry.activity_title }}
        </ActionMenuItem>

        <ActionMenuItem
          :itemClass="testClass('edit-status-menu-item')"
          @click="store.startEditing(entry.assignable_id)">
          <template v-if="entry.individually_assignable">
            Assign to Entire Section
          </template>
          <template v-else>
            Assign to Individual Students
          </template>
        </ActionMenuItem>

        <template v-if="entry.individually_assignable">
          <ActionMenuItem
            :itemClass="testClass('check-all-menu-item')"
            @click="store.checkAll(entry.assignable_id)">
            Select Column
          </ActionMenuItem>

          <ActionMenuItem
            :itemClass="testClass('uncheck-all-menu-item')"
            @click="store.uncheckAll(entry.assignable_id)">
            Deselect Column
          </ActionMenuItem>
        </template>
      </template>
    </ActionMenu>
  </th>
</template>

<script setup>
  import ActionMenu from './ActionMenu';
  import ActionMenuItem from './ActionMenuItem';
  import { inject } from 'vue';
  import { testClass } from 'music';

  const props = defineProps(
    {
      chunk: { required: true, type: String },
      entry: { required: true, type: Object },
    }
  );

  /**
   * The entry's due date is in m/d/yyyy format but needs to be displayed in
   * the header as m/d.
   */
  const yearStringLength = '/yyyy'.length;

  const store = inject('store');

  /**
   * @return {string} the due date in MM/DD format
   */
  function dueDateDisplay() {
    return props.entry.due_date.slice(0, 0 - yearStringLength);
  }
</script>
