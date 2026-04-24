<template>
  <div class="group-menu">
    <div v-if="!learningTrackData.groupMenu.store.noActivities">
      <table
        class="group-activities"
        :class="[
          {
            'move-first-hover': localStore.moveFirstHover,
            'move-last-hover': localStore.moveLastHover,
          },
          testClass('group-activities-table')
        ]">
        <tr>
          <th>Activity</th>
          <th>Activity Type</th>
          <th>Est. Time to Complete</th>
          <th />
        </tr>
        <tbody
          v-for="(group, groupIndex) in assignmentGroupsAtStrandPosition"
          :key="groupIndex">
          <tr>
            <td
              colspan="4"
              class="group-activities__group-name"
              :class="testClass('activity-group-name')">
              {{ group.name }}
            </td>
          </tr>
          <tr
            v-for="(activity, activityIndex) in group.activities"
            :key="activityIndex"
            :class="[
              {
                'highlight-on-move-first':
                  isFirstRowInGroupActivities(groupIndex, activityIndex),
                'highlight-on-move-last':
                  isLastRowInGroupActivities(group, groupIndex, activityIndex),
              },
              testClass('activity-row')
            ]">
            <td>
              <VhlLink
                :href="`/sections/0/activities/${activity.id}`"
                :htmlText="activity.title"
                :class="[
                  {
                    'js-modal-a11y__default-focus':
                      isFirstRowInGroupActivities(groupIndex, activityIndex),
                  },
                  testClass('activity-link')
                ]"
                target="_blank" />
            </td>
            <td :class="testClass('activity-type')">
              {{ activity.activity_type }}
            </td>
            <td :class="testClass('activity-minutes')">
              {{ activity.minutes_to_complete }} minutes
            </td>
            <td>
              <VhlLink
                href="javascript://"
                :class="[
                  {
                    'js-modal-a11y__last-focus-element':
                      isLastRowInGroupActivities(group, groupIndex, activityIndex),
                  },
                  testClass('delete-activity')
                ]"
                @click="learningTrackData.groupMenu.deleteActivity(groupIndex, activityIndex)">
                delete
              </VhlLink>
            </td>
          </tr>
        </tbody>
      </table>
      <VhlLink
        v-if="learningTrackData.groupMenu.store.showFirst"
        href="javascript://"
        class="group-menu__move-first  js-modal-a11y__last-focus-element"
        :class="testClass('move-first-activity')"
        @click="learningTrackData.groupMenu.moveFirstActivity()"
        @mouseover="localStore.moveFirstHover = true"
        @mouseleave="localStore.moveFirstHover = false">
        Move first activity to previous due date
      </VhlLink>
      <VhlLink
        v-if="learningTrackData.groupMenu.store.showLast"
        href="javascript://"
        class="group-menu__move-last  js-modal-a11y__last-focus-element"
        :class="testClass('move-last-activity')"
        @click="learningTrackData.groupMenu.moveLastActivity()"
        @mouseover="localStore.moveLastHover = true"
        @mouseleave="localStore.moveLastHover = false">
        Move last activity to next due date
      </VhlLink>
      <div
        class="group-menu__total-hours"
        :class="testClass('total-hours')">
        <div>
          Total hours: <span>{{ learningTrackData.groupMenu.hoursForStrandGroup() }} hours</span>
        </div>
      </div>
    </div>
    <div
      v-else
      class="group-menu__no-activities"
      :class="testClass('no-activities')">
      All activities have been moved.
    </div>
  </div>
</template>

<script>
  import { computed, inject, reactive } from 'vue';
  import { testClass } from 'music';
  import VhlLink from 'features/learning_tracks/components/VhlLink';

  export default {
    name: 'GroupMenu',
    components: { VhlLink },
    emits: ['close'],
    setup() {
      const localStore = reactive({
        moveFirstHover: false,
        moveLastHover: false,
      });
      const learningTrackData = inject('learningTrackData');

      /**
       * Computed property to return groups at the strand group position
       * @return {Array.<AssignmentGroup>}
       */
      const assignmentGroupsAtStrandPosition = computed(() => {
        const strandGroups = learningTrackData.groupMenu.strandGroups;
        const strandGroupPosition = learningTrackData.groupMenu.store.strandGroupPosition;
        return strandGroups[strandGroupPosition].groups;
      });

      /**
       * Return whether the element with given indexes are in first row
       * @param {number} groupIndex
       * @param {number} activityIndex
       * @return {boolean}
       */
      function isFirstRowInGroupActivities(groupIndex, activityIndex) {
        return activityIndex === 0 && groupIndex === 0;
      }

      /**
       * Return whether the element with given indexes are in last row in group activities table
       * @param {AssignmentGroup} group
       * @param {number} groupIndex
       * @param {number} activityIndex
       * @return {boolean}
       */
      function isLastRowInGroupActivities(group, groupIndex, activityIndex) {
        return activityIndex === group.activities.length - 1 &&
          groupIndex === assignmentGroupsAtStrandPosition.value.length - 1;
      }

      return {
        assignmentGroupsAtStrandPosition,
        isFirstRowInGroupActivities,
        isLastRowInGroupActivities,
        learningTrackData,
        localStore,
        testClass,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .group-menu {
    color: #666;
    font-family: Open Sans, Helvetica Neue, Helvetica, Arial, Sans-serif;
    font-size: rpx(11);
    line-height: 1.5;
  }

  .group-activities {
    border-collapse: separate;
    border-spacing: 0;
    font-size: rpx(11);
    margin: 0;
    width: 100%;
  }

  .group-activities th {
    background: #e7e7e7;
    border: 0;
    color: #565656;
    font-size: rpx(14);
    font-weight: bold;
    padding: rpx(3);
    text-align: left;
  }

  .group-activities tr {
    background-color: #f5f5f5;
    border-bottom: rpx(2) solid #ffffff;
  }

  .group-activities tr td {
    border: 0;
    border-bottom: rpx(2) solid #ffffff;
    padding: rpx(3);
    vertical-align: top;
  }

  .group-activities__group-name {
    color: #565656;
    font-weight: bold;
  }

  .group-menu__move-first {
    display: block;
    margin-top: rpx(20);
  }

  .group-menu__move-last {
    clear: both;
    float: right;
    margin-top: rpx(20);
  }

  .group-menu__total-hours {
    clear: both;
    float: right;
    margin-bottom: rpx(10);
    margin-top: rpx(10);
  }

  .group-menu__no-activities {
    font-size: 1rem;
    margin-top: rpx(20);
    text-align: center;
  }

  .move-first-hover .highlight-on-move-first,
  .move-last-hover .highlight-on-move-last {
    background-color: #DFF09F;
  }
</style>
