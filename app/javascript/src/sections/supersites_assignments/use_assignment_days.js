import { reactive } from 'vue';
import * as ajaxUtils from 'shared/ajax_utils';

const useAssignmentDays = () => {
  const state = reactive({
    assignmentDays: [],
    dataLoaded: false
  });

  let targetUrl = '';
  if (location.pathname.search(/sections\/\d+$/) !== -1) {
    targetUrl = `${location.pathname}/`;
  }
  const assignmentDaysUrl = `${targetUrl}new_dashboard/assignments/`;

  const loadAssignmentDays = async () => {
    ajaxUtils.getFromEndpoint(assignmentDaysUrl, (response) => {
      state.assignmentDays = response;

      /**
       * If the only assignment day is overdue, expand it.
       */
      if (state.assignmentDays[0]?.overdue && state.assignmentDays.length === 1) {
        state.assignmentDays[0].expanded = true;
      }

      state.dataLoaded = true;
    });
  }

  const toggleExpanded = (assignmentDay) => {
    // Toggle the expanded due date button
    for (const day of state.assignmentDays) {
      if(day !== assignmentDay && day.expanded) {
        day.expanded = false;
      }
    }

    // Toggle the clicked due date button
    assignmentDay.expanded = !assignmentDay.expanded;
  }

  return { loadAssignmentDays, state, toggleExpanded };
};

export default useAssignmentDays;
