<template>

<div class="c-panel__header">
  <h2 class="c-heading--dashboard-panel">
    <Icon class="c-embedded-icon--lg" :svg="fileSVG" />
    Assignments
  </h2>
</div>
<div class="c-panel__body">
  <div class="u-txt-ctr" :class="testClass('spinner')" v-show="!state.dataLoaded">
    <span><img :src="SpinnerImage" /></span>
  </div>
  <div id="_current_assignments" v-show="state.dataLoaded">
    <div v-if="state.assignmentDays.length > 0">
      <AssignmentDay v-for="(assignmentDay, index) in state.assignmentDays" :assignmentDay="assignmentDay" :index="index">
      </AssignmentDay>
    </div>
    <div v-else>
      <p class="u-mar-top-16">You have no assignments.</p>
    </div>
  </div>
</div>
</template>

<script>
import { testClass } from 'music';
import { onMounted, provide } from 'vue';
import useAssignmentDays from './use_assignment_days';
import AssignmentDay from 'sections/supersites_assignments/AssignmentDay';
import Icon from 'features/shared/Icon';
import SpinnerImage from 'images/loading_32.gif';
import fileSVG from '!!raw-loader!MusicAssets/images/music/icons/student-dashboard/file.svg';

export default {
  name: 'AssignmentsApp',
  components: {
    AssignmentDay,
    Icon
  },
  setup() {
    const { loadAssignmentDays, state, toggleExpanded } = useAssignmentDays();
    onMounted(loadAssignmentDays);

    /**
     * Make method available to the AssignmentDay component instances
     *   that will call it.
     */
    provide('toggleExpanded', toggleExpanded);

    return { fileSVG, Icon, SpinnerImage, state, testClass };
  }
};
</script>
