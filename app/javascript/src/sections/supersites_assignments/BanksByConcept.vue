<template>
  <div
    class="c-assignment-group  assignments"
    :class="testClass('assignment-group')"
    v-for="assignment_group in assignmentDay.assignment_groups"
    v-show="assignmentDay.expanded">
    <ul class="c-plain-list  banks  u-mar-bot-4">
      <li
        v-for="assignment_bank in assignment_group.assignment_banks"
        class="u-dis-flex  flex-justify-between"
        :class="testClass('assignment-bank')">
        <div class="c-lesson-link-container">
          <span
            class="lesson_link  u-pad-lt-8"
            :class="testClass('lesson-link')"
            :style="lessonLinkStyle(assignment_bank)">
            <!-- eslint-disable vue/no-v-html -->
            <span v-html="assignment_bank.lesson_label" /> |
            <span v-html="assignment_bank.concept_name" />
            <!-- eslint-enable vue/no-v-html -->
          </span>
        </div>
        <div
          class="is-unavailable"
          :class="testClass('availability-message')"
          v-show="assignment_bank.assessment_id && !(assignment_group.can_be_started)"
          data-assessment-hover-container="{{assignment_bank.assessment_id}}">
          <span class="release_date">
            {{assignment_bank.availability_message}}
          </span>
        </div>
        <span
          class="c-assignments-count"
          :class="testClass('activity-count')"
          v-show="assignment_bank.activity_count_text">
          {{ assignment_bank.activity_count_text }}
        </span>
      </li>
    </ul>
    <hr class="u-mar-top-0" />
    <div class="c-activity-start-container">
      <div
        data-total-time="1"
        class="c-time-estimate"
        :class="testClass('estimated-time')"
        v-show="assignmentDay.course_show_estimated_times">
        <span>{{assignment_group.estimate_time}}</span>
        <span
          :class="testClass('not-released')"
          v-show="!assignment_group.can_be_started">Not Released
        </span>
        <div :class="testClass('due-time')">{{assignment_group.due_time}}</div>
      </div>
      <div data-start-link="">
        <button
          class="c-button  c-button--primary  u-no-width  u-dis-inline-block"
          :class="testClass('start-button')"
          v-show="assignment_group.can_be_started"
          @click="window.location.assign(assignment_group.url)">start</button>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';

  const lessonLinkStyle = (assignmentBank) => {
    if (assignmentBank.background_color === '') {
      return {};
    }

    return { 'border-left': `0.25rem solid ${assignmentBank.background_color}` };
  };

  export default {
    props: {
      assignmentDay: Object
    },
    setup() {
      /**
       * Make window available to template.
       * This helps make the spec work: when I don't return window here,
       * I get an error in the spec indicating that window is undefined.
       */
      return { lessonLinkStyle, testClass, window };
    }
  };
</script>
