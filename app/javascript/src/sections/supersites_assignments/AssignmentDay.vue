<template>
<div
  class="c-assignment-day  u-sp"
  :class="{
    [testClass('assignment-day')]: true,
    expanded: assignmentDay.expanded,
    overdue: assignmentDay.overdue}">

  <div class="l-grid  l-grid--half-gutter">
    <div class="l-col-12  l-col-sm-4  l-col-md-5">

      <button
        :id="`current_${index}_header`"
        class="c-due-date  c-no-button  u-pad-8  u-width-full"
        :class="`${testClass(`assignment-day-header-${index}`)}`"
        @click="toggleExpanded(assignmentDay)"
        v-show="!assignmentDay.all_assignments_completed"
        :aria-expanded="assignmentDay.expanded">

        <div class="c-date-information">
          <div class="c-collapse">
            <span
              :class="testClass(`minus-icon-${index}`)"
              v-show="assignmentDay.expanded">
              <Icon :svg="minusSquareSVG"/>
            </span>
            <span
              :class="testClass(`plus-icon-${index}`)"
              v-show="!assignmentDay.expanded">
              <Icon :svg="plusSquareSVG"/>
            </span>
          </div>

          <span class="c-assignment-date" :class="testClass('assignment-day-label')">
            {{ assignmentDay.label }}
            <div
              v-show="assignmentDay.expanded"
              class="c-assignment-counts"
              :class="testClass('assignment-count-expanded')">
              {{assignmentDay.due_date_sub_heading}}
            </div>
            <div
              v-show="!assignmentDay.expanded"
              class="c-assignment-counts"
              :class="testClass('assignment-count-not-expanded')">
              {{assignmentDay.total_assignments}} {{assignmentDay.total_assignments_label}}
            </div>
          </span>
        </div>
      </button>
    </div> <!-- /left column -->

    <div class="l-col-12  l-col-sm-8  l-col-md-7">
      <div
        class="c-assignment-box expanded"
        :class="testClass('banks-by-concept')"
        :id="`current_${index}`"
        v-show="!assignmentDay.all_assignments_completed">
        <BanksByConcept :assignmentDay="assignmentDay">
        </BanksByConcept>
      </div>

      <div
        :id="`current_${index}`"
        class="c-no-due-date"
        :class="testClass('no-due-date')"
        v-show="assignmentDay.all_assignments_completed">
        <div class="date_information">
          <span
            :class="testClass('day-label')"
            :data-assignment-day="index">
            {{assignmentDay.label}}
          </span>
          <div
            class="asg_calendar"
            :class="testClass('month-day')"
            v-show="assignmentDay.expanded">
            <span class="asg_cal_month">
              {{formatDueDate(assignmentDay.due_date, 'MMM')}}
            </span>
            <span class="asg_cal_day">
              {{formatDueDate(assignmentDay.due_date, 'dd')}}
            </span>
          </div>
        </div>
      </div>

      <div
        class="c-assignment-box expanded"
        :class="testClass('zero-activities')"
        v-show="assignmentDay.all_assignments_completed">
        <div class="act_count_container">
          <div class="act_count">0</div>
          <div class="act_count_label">activities</div>
        </div>
        <div class="act_lessons hollowed_div">
          <p class="action">All assignments completed</p>
        </div>
      </div>
    </div> <!-- end right column -->
  </div> <!-- end l-grid -->

</div> <!-- end assignment-day -->
</template>

<script>
import { testClass } from 'music';
import { inject } from 'vue';
import useFormatDueDate from './use_format_due_date';
import BanksByConcept from 'sections/supersites_assignments/BanksByConcept';
import Icon from 'features/shared/Icon';
import minusSquareSVG from '!!raw-loader!MusicAssets/images/music/icons/student-dashboard/minus-square.svg';
import plusSquareSVG from '!!raw-loader!MusicAssets/images/music/icons/student-dashboard/plus-square.svg';

export default {
  props: {
    index: Number,
    assignmentDay: Object
  },
  components: {
    BanksByConcept,
    Icon
  },
  setup() {
    const toggleExpanded = inject('toggleExpanded');
    const { formatDueDate } = useFormatDueDate();
    return { formatDueDate, minusSquareSVG, plusSquareSVG, testClass, toggleExpanded };
  }
};
</script>
