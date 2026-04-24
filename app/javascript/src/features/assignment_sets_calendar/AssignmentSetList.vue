<template>
  <div class="assignment-sets__set-list">
    <div
      v-show="showNoAssignmentsMessage"
      class="u-txt-quiet  u-txt-ctr  u-txt-18"
      :class="testClass('no-assignments-message')">
      There are no assignments.
    </div>
    <div
      v-for="set in store.assignmentSets"
      v-show="store.inDateRange(set) && showCustomOrdered(set)"
      :key="set.due_date"
      :data-set-due-date="set.due_date"
      data-entry-index=""
      class="assignment-sets__set"
      @dragover.prevent="store.handleDragover($event)"
      @drop.prevent="store.handleDrop('set', $event)">
      <div class="assignment-sets__set-header">
        <div class="assignment-sets__set-header__date-and-message">
          <div class="assignment-sets__set-header__due-date">
            {{ set.due_date_string }}
          </div>
          <div
            v-if="set.message"
            class="assignment-sets__set-header__message">
            {{ set.message }}
          </div>
        </div>
        <div class="assignment-sets__set-header__menu">
          <select
            v-if="set.id"
            :id="`order-select-set-${set.id}`"
            :value="set.hasCustomOrder"
            @change="store.handleSetMenuChange(set, $event)">
            <option :value="true">
              Custom Order
            </option>
            <option :value="false">
              Default Order
            </option>
          </select>
        </div>
      </div>
      <div class="assignment-sets__activity-list">
        <div
          v-for="(activity, entryIndex) in set.activities"
          :key="activity.activity_id"
          :id="`draggable-${activity.activity_id}`"
          :data-set-due-date="set.due_date"
          :data-entry-index="entryIndex"
          class="assignment-sets__activity"
          :class="{
            'assignment-sets__activity-hovered-above': (
              store.dragState.setDueDate === set.due_date &&
              store.dragState.originalSetDueDate === set.due_date &&
              store.dragState.entryIndex === entryIndex &&
              store.dragState.hoverPosition === 'above'
            ),
            'assignment-sets__activity-hovered-below': (
              store.dragState.setDueDate === set.due_date &&
              store.dragState.originalSetDueDate === set.due_date &&
              store.dragState.entryIndex === entryIndex &&
              store.dragState.hoverPosition === 'below'
            )
          }"
          draggable="true"
          @dragend="store.handleDragEnd"
          @dragstart="store.handleDragStart(activity, set.due_date, $event)"
          @dragover.prevent="store.handleDragover($event)"
          @drop.stop.prevent="store.handleDrop('activity', $event)">
          <!-- eslint-disable vue/no-v-html -->
          <StandardButton
            variant="link"
            class="assignment-sets__activity-drag-handle">
            <img src="./activity_drag_icon.svg">
          </StandardButton>
          <div
            v-if="activity.strand_color"
            :style="{ backgroundColor: activity.strand_color }"
            class="assignment-sets__activity-strand-color" />
          <div
            class="assignment-sets__activity-strand-title"
            v-html="`${activity.lesson_name} - ${activity.strand_name}: `" />
          <div class="assignment-sets__activity-title">
            <a
              :href="activity.url"
              target="_blank"
              title="Preview the activity"
              v-html="activity.activity_title" />
          </div>
          <!-- eslint-enable vue/no-v-html -->
        </div>
      </div>
    </div>
    <CustomOrderConfirmationDialog v-if="store.showCustomOrderConfirmation" />
    <DefaultOrderConfirmationDialog v-if="store.showDefaultOrderConfirmation" />
  </div>
</template>

<script setup>
  import { StandardButton, testClass } from 'music';
  import CustomOrderConfirmationDialog from './CustomOrderConfirmationDialog';
  import DefaultOrderConfirmationDialog from './DefaultOrderConfirmationDialog';
  import useAssignmentSetStore from './models/use_assignment_set_store';
  import { computed } from 'vue';

  const store = useAssignmentSetStore();
  
  const showNoAssignmentsMessage = computed(hasNoVisibleAssignmentSets);
  /**
  * Fetch only visible assignment sets based off of selected date range
  * @return {[AssignmentSet]}
  */
  function hasNoVisibleAssignmentSets() {
    const visibleAssignmentSets = store.assignmentSets.filter((assignmentSet) => {
      return store.calendar.dateRange.start <= assignmentSet.dueDateAsDate &&
        assignmentSet.dueDateAsDate <= store.calendar.dateRange.end;
    });

    return visibleAssignmentSets.length === 0 ||
      (store.showOnlyCustomOrderedAssignments && store.customOrderedCount === 0);
  }

  /**
   * @private
   * @param {AssignmentSet} - set.
   * @return {boolean} Whether the set is visible or not
   * based on the showOnlyCustomOrderedAssignments flag state.
   */
  function showCustomOrdered(set) {
    if (!store.showOnlyCustomOrderedAssignments) {
      return true;
    }

    return set.hasCustomOrder;
  }
</script>

<style scoped lang="sass">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .assignment-sets {
    &__set-list {
      background-color: $gray-f8;
      border: rpx(1) solid $gray-d;
      padding: mod(1);
      width: 100%;
    }

    &__set {
      background-color: $white;
      border: rpx(2) solid $gray-e;
      border-radius: rpx(3);
      margin-bottom: rpx(22);
    }

    &__set-header {
      align-items: center;
      background-color: $gray-f5;
      border-radius: rpx(3);
      display: flex;
      justify-content: space-between;
      line-height: rpx(27);
      padding: rpx(7) rpx(17);

      &__date-and-message {
        display: flex;
        font-size: mod(1);
        column-gap: mod(1);
      }

      &__due-date {
        color: $gray-3;
        font-weight: bold;
      }

      &__message {
        color: $success;
      }
    }

    &__activity-list {
      display: flex;
      flex-direction: column;
      padding: rpx(11);
    }

    &__activity-hovered-above {
      border-top: 1px dashed blue;
      padding-top: 4px;
    }

    &__activity-hovered-below {
      border-bottom: 1px dashed blue;
      padding-bottom: 4px;
    }

    &__activity {
      align-items: center;
      color: $gray-3;
      display: flex;
      flex-direction: row;
      font-size: mod(1);
      gap: rpx(6);
      min-height: rpx(35);
      padding-left: rpx(7);

      &-drag-handle {
        cursor: grab;
        height: rpx(18);
        width: rpx(6);

        img {
          height: rpx(18);
          width: rpx(6);
        }
      }

      &-strand-color {
        height: rpx(14);
        margin-left: rpx(3);
        min-width: rpx(14);
        width: rpx(14);
      }

      &-strand-title {
        font-weight: bold;
      }
    }
  }

  .activity-dragging {
     background-color: transparent;
     opacity: 0.5;
   }
</style>
