<template>
  <div
    ref="graphElm"
    class="due-date-graph-container"
    :class="testClass('due-date-graph-container')">
    <div
      v-show="localstore.showGroupInfoElm"
      ref="groupInfoElm"
      class="c-group-info-elm"
      :class="testClass('group-info-elm')">
      <div class="c-group-info-data" :class="testClass('group-info-heading')">
        {{ localstore.groupInfoData.strandHeading }}
      </div>
      <div class="c-group-info-data" :class="testClass('activity-count')">
        Number of activities: {{ localstore.groupInfoData.activityCount }}
      </div>
      <div class="c-group-info-data" :class="testClass('average-completion-time')">
        Average Completion Time: {{ localstore.groupInfoData.totalMinutes }} hours
      </div>
    </div>
  </div>
</template>

<script>
  import { ref, onMounted, reactive } from 'vue';
  import { testClass } from 'music';
  import DueDateGraph from '../models/due_date_graph';

  export default {
    name: 'DueDateGraphComponent',
    components: { },
    props: {
      calendarObj: { required: true, type: Object },
      date: { required: true, type: Object },
      unitLabel: { default: 'Lesson', type: String },
    },
    setup(props) {
      const calendar = props.calendarObj.calendar || {};
      const localstore = reactive({
        workLoad: props.calendarObj.workLoad,
        dueDate: props.date,
        groups: calendar[props.date.name],
        unitLabel: props.unitLabel || 'Lesson',
        showGroupInfoElm: false,
        groupInfoData: {
          activityCount: 0,
          strandHeading: '',
          totalMinutes: 0,
        },
      });
      const graphElm = ref(null);
      const groupInfoElm = ref(null);
      const dueDateGraph = new DueDateGraph(graphElm, groupInfoElm, localstore);

      onMounted(
        () => {
          if (localstore.groups != undefined) {
            dueDateGraph.drawGraph();
          }
        });
      return {
        graphElm, groupInfoElm, localstore, testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>
  .due-date-graph-container {
    margin-left: 8.125rem;
    position: absolute;
    top: 0.0625rem;
  }

  .c-group-info-elm {
    background-color: #e5f19f;
    border: 0.0625rem solid #ddd;
    border-left: none;
    border-radius: 0.1875rem;
    border-top: none;
    margin-bottom: 0.625rem;
    padding: 0.3125rem;
    position: absolute;
    width: 7.5rem;
  }

  .c-group-info-elm .c-group-info-data {
    font-size: 0.58rem;
    margin: 0;
    padding: 0.0625rem 0.3125rem;
  }

  .due-date-graph-container::v-deep(.date-end-label) {
    font-size: 0.5625rem;
  }
</style>
