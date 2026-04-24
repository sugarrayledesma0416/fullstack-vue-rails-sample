<template>
  <button
    class="c-no-button  how-to-use-btn"
    :class="testClass('how-to-use-btn')"
    type="button"
    onclick="$('.js-modal-how-to-use').vhlModal('open')">
    <HelpIcon />
    <span class="how-to-use-txt">How to Use</span>
  </button>

  <!-- eslint-disable vue/no-multiple-template-root -->
  <div
    class="c-modal  c-modal--md  custom-modal  js-modal  js-modal-how-to-use  u-hidden"
    :class="testClass('standard-report-info-modal')">
    <div role="dialog" aria-label="Dialog" class="c-modal__box  js-modal-box  l-span-10">
      <button
        class="c-modal__close-button  c-no-button  js-x-close  js-modal-close"
        :class="testClass('close-how-to-use-modal')">
        <span class="c-icon  c-icon--md  c-icon--close" />
        <span class="u-screen-reader-only">Close dialog</span>
      </button>
      <div role="document" class="js-modal-content">
        <div class="c-panel  c-panel--padded  u-mar-0">
          <div class="c-panel__header">
            <h3 class="c-heading--md">
              How to Use
            </h3>
          </div>
          <div class="c-panel__body">
            <div class="moda-body__container">
              <ul class="modal-options">
                <li
                  v-for="(howToUseTabButton, howToUseTabKey) in howToUseTabButtons.list"
                  :key="howToUseTabKey"
                  class="modal-options__item">
                  <button
                    :class="[
                      'modal-option-button',
                      {'is-active' : howToUseTabButton.isSelected }
                    ]"
                    @click="tabButtonIsSelectedHTU(howToUseTabKey)">
                    {{ howToUseTabButton.text }}
                  </button>
                </li>
              </ul>
              <div
                v-if="currentTab === 'section'"
                class="moda-option-content"
                :class="testClass('section-tab-information-modal')">
                <div v-if="howToUseTabButtons.list.overview.isSelected">
                  <p>
                    This report shows how students in your class or section are performing on
                    standards presented in each unit of the program.
                  </p>
                  <p>
                    <b>Proficiency Assessments</b> – These are assessments created specifically to
                    test the standards in each unit. Typically, each unit has two proficiency
                    assessment, which are a mid-unit and end-of-unit assessment. Additionally,
                    there is a mid-book and end-of book as well. Each assessment covers 7 to 10
                    standards.
                  </p>
                  <p>
                    <b>Progress Monitoring Assessments</b> - These assessments consist of quizzes,
                    speaking and writing tests and an overall unit test. Progress monitoring
                    assessments are shorter than proficiency assessments and typically cover
                    between two and four standards. Typically, a unit will have 12 to 15
                    assessments of this type.
                  </p>
                </div>
                <div v-if="howToUseTabButtons.list.proficiencyAssessments.isSelected">
                  <p>
                    When the section report first loads, the default view shows proficiency
                    assessments. In this view, each row represents a standard that was presented
                    in the unit, and each column represents an assessment.
                  </p>
                  <p>
                    You can view all of a unit's proficiency assessments side by side in this
                    report, allowing you to see student improvement within the unit. To enable
                    the side by side comparison, click the <b>ASSESSMENTS</b> drop-down and use
                    the checkboxes to show additional assessments.
                  </p>
                </div>
                <div v-if="howToUseTabButtons.list.progressMonitoringAssessments.isSelected">
                  <p>
                    To view the section report for progress monitoring assessments, click the
                    <b>ASSESSMENT TYPE</b> drop-down and select the <b>Progress Monitoring</b>
                    option and click <b>GO</b>.
                  </p>
                  <p>
                    In this view, each row represents a progress monitoring assessment in
                    the unit. The column to the right displays the average score that the
                    section achieved on each standard presented in the assessment.
                  </p>
                  <p>
                    Hovering the mouse over each individual score to displays the standard name
                    and description.
                  </p>
                </div>
                <div v-if="howToUseTabButtons.list.filterControls.isSelected">
                  <p>
                    The filter controls on the left side of the report allow you to set up and
                    refine the information presented in the report. The options are:
                  </p>
                  <ul class="modal-list">
                    <li>
                      <b>Standards</b> – if your course is set up to display multiple standard
                      authorities, you can use this drop-down list to choose the standards that
                      you would like to view in the report. For example, if your course is
                      configured to use both the Florida B.E.S.T. and WIDA standards, you can use
                      this filter to choose which of these standard sets are displayed in the
                      report.
                    </li>
                    <li>
                      <b>Assessment Type</b> – use this filter to show either proficiency or
                      progress monitoring assessment types.
                    </li>
                    <li>
                      <b>Unit</b> – use this filter to select the unit of the book that you want
                      to report on.
                    </li>
                    <li>
                      <b>Assessments</b> – this filter is specific to proficiency assessments;
                      you can use it to select an assessment to view or select multiple
                      assessments to view side-by-side.
                    </li>
                    <li>
                      <b>Category Type</b> – this filter is specific to progress monitoring
                      assessments; you can use it to select one or more types of progress
                      monitoring assessments to display. The options are <b>Quizzes</b>,
                      <b>Unit Test</b> and <b>Speaking and Writing Tests</b>.
                    </li>
                  </ul>
                  <p>
                    After setting the filters to the desired options, click the GO button to
                    generate the report.
                  </p>
                </div>
              </div>
              <div
                v-else-if="currentTab === 'student'"
                class="moda-option-content"
                :class="testClass('student-tab-information-modal')">
                <div v-if="howToUseTabButtons.list.overview.isSelected">
                  <h3>Using the Growth on Proficiency Assessment chart</h3>
                  <p>
                    The <b>Growth on Proficiency Assessment</b> chart tracks a student's
                    progress in acquiring English language skills throughout a specific
                    instructional unit or period. This report provides an overview of the
                    student's growth and overall performance by displaying their scores on
                    assessments conducted at various stages within that unit. It includes
                    the Mid-Unit, End-of-Unit, Mid-Book and End-of-Book Proficiency
                    Assessments.
                  </p>
                  <p>
                    Student assessment scores are plotted on the growth performance chart
                    by unit, starting with Unit 1 on the left and progressing to the later
                    units on the right.
                  </p>
                  <h3>To use the Chart: </h3>
                  <ul class="modal-list">
                    <li>
                      Hover over any point in the chart to see any of the student’s submitted
                      assessment scores.
                    </li>
                    <li>
                      Click on any unit along the bottom of the chart to see more information
                      about how the student performed on specific standards.
                    </li>
                  </ul>
                </div>
                <div v-if="howToUseTabButtons.list.abouttheChart.isSelected">
                  <p>
                    This chart represents a student's scores across the Proficiency Tests in
                    all units of the book. The chart allows you to:
                  </p>
                  <ul class="modal-list">
                    <li>
                      Track progress across a unit by allowing you to track the trends of
                      both the <b>Mid-Unit</b> and <b>End-of-Unit</b> assessments. Generally,
                      progress is shown when the End-of-Unit scores are higher than the Mid-Unit.
                    </li>
                    <li>
                      Easily compare the <b>Mid-Book</b> and <b>End-of-Book</b> are interim
                      benchmark assessments that test the standards presented in the first and
                      second halves of the book.
                    </li>
                    <li>
                      Drill into detailed student performance within a unit. Simply click the unit
                      name along the bottom of the chart to open the unit breakdown section of the
                      report.
                    </li>
                  </ul>
                  <h3>Chart Legend</h3>
                  <ul class="modal-list">
                    <li>The blue line represents all Mid-Unit tests.</li>
                    <li>The black line represents all End-of-Unit tests.</li>
                    <li>
                      The Mid-Book and End-of-Book tests are interim tests that cover
                      standards-based material in the preceding units, they are represented
                      by icons.
                    </li>
                    <li>The gaps in the chart represent tests not taken and scored.</li>
                  </ul>
                </div>
                <div v-if="howToUseTabButtons.list.aboutTheUnitBreakdown.isSelected">
                  <p>
                    The Unit Breakdown Chart, shows how a student has performed against each
                    standards that has been assessed in a given unit. It is broken down into
                    three sections.
                  </p>
                  <ul class="modal-list">
                    <li>
                      <b>Student Support level table</b> – this table runs along the left-side
                      of the chart and shows the support levels available and the number of
                      standards that fall into each level based on the student’s scores.
                    </li>
                    <li>
                      <b>Standards list</b> – when you click on any of the support levels, a
                      list of standards that fall into that level appear in the middle section
                      of the chart.
                    </li>
                    <li>
                      <b>Standards detail</b> – When you click on a standard in the Standards
                      List, the standard name and description appear in the right-side of the
                      chart. This also shows the student’s scores for that particular standard
                      for both the Mid-Unit and End-of-Unit assessments.
                    </li>
                  </ul>
                  <h3>To View Individual Answers</h3>
                  <p>
                    You can view how a student answered individual questions within the
                    proficiency assessments by standard.
                  </p>
                  <ol class="modal-list">
                    <li>
                      Click on the number next to the assessment scores in the standards detail
                      section. The question modal opens.
                    </li>
                    <li>
                      You can see the correct answer for the question, if the student answered
                      differently, you will also see the incorrected answer they selected.
                    </li>
                    <li>
                      Use the <b>Next</b> and <b>Previous</b> buttons to navigate through the
                      questions supporting the selected standard.
                    </li>
                  </ol>
                  <h3>To Find Support for a Student </h3>
                  <p>
                    In the case where a student is underperforming on a standard and needs
                    additional support you can quickly and easily find supporting content.
                    To do so:
                  </p>
                  <ol class="modal-list">
                    <li>
                      In the standards, click on the standard that the student needs supporting
                      content. The standards detail pane loads showing the standard description
                      and scores achieved by the student on that standard across the unit.
                    </li>
                    <li>
                      Click on the <b>Find Matching Content</b> link to search for additional
                      content that supports that particular standard. The system loads the search
                      window, and returns results for only the selected standard.
                    </li>
                    <li>Review the search results and assign as needed.</li>
                  </ol>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <button class="u-screen-reader-only" tabindex="-1">
        Dialog end
      </button>
    </div>
  </div>
  <!-- eslint-enable vue/no-multiple-template-root -->
</template>

<script setup>
  import { reactive, watch } from 'vue';
  import { testClass } from 'music';
  import HelpIcon from './HelpIcon';

  const props = defineProps({
    currentTab: {
      type: String,
      required: true,
    },
  });

  const howToUseTabButtons = reactive({
    list: {
      overview: { isSelected: true, text: 'Overview' },
      proficiencyAssessments: { isSelected: false, text: 'Proficiency Assessments' },
      progressMonitoringAssessments: { isSelected: false, text: 'Progress Monitoring Assessments' },
      filterControls: { isSelected: false, text: 'Filter Controls' },
    },
  });

  watch(
    () => props.currentTab,
    (newTab) => {
      if (newTab === 'section') {
        howToUseTabButtons.list = {
          overview: { isSelected: true, text: 'Overview' },
          proficiencyAssessments: { isSelected: false, text: 'Proficiency Assessments' },
          progressMonitoringAssessments: {
            isSelected: false,
            text: 'Progress Monitoring Assessments',
          },
          filterControls: { isSelected: false, text: 'Filter Controls' },
        };
      } else if (newTab === 'student') {
        howToUseTabButtons.list = {
          overview: { isSelected: true, text: 'Overview' },
          abouttheChart: { isSelected: false, text: 'About the Chart' },
          aboutTheUnitBreakdown: { isSelected: false, text: 'About the Unit Breakdown' },
        };
      }
    },
    { immediate: true }
  );

  /**
   * Set active status when clicked button and show content related.
   * @param {string} buttonKey
   */
  function tabButtonIsSelectedHTU(buttonKey) {
    Object.keys(howToUseTabButtons.list).forEach((button) => {
      howToUseTabButtons.list[button].isSelected = false;
    });
    howToUseTabButtons.list[buttonKey].isSelected = true;
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .how-to-use-btn {
    font-size: rpx(16);
    margin-left: rpx(16);
  }

  .custom-modal {
    --modal-item-button-bg: #FFE8E1;

    .modal-list {
      padding-left: rpx(32);
    }

    ul.modal-list {
      list-style: disc;
    }

    .c-modal__box {
      border-radius: rpx(6);

      .c-panel__header {
        border-radius: rpx(6) rpx(6) 0 0;
        h3 {
          font-weight: normal;
        }
      }
      .c-panel__body {
        padding: 0;

        .moda-body__container {
          display: flex;
          flex-direction: row;
          max-height: 80vh;

          .modal-options {
            box-shadow: rpx(3) 0 rpx(9) rgba(0, 0, 0, 0.1);
            list-style: none;
            max-width: 25%;
            padding: 0 rpx(16);
            margin: 0;

            &__item {
              border-bottom: rpx(1) solid $gray-f5;
              display: flex;
              flex-direction: column;
              padding: rpx(8) 0;

              .modal-option-button {
                background-color: $white;
                border-radius: rpx(8);
                border: 0;
                cursor: pointer;
                padding: rpx(5) rpx(18);
                text-align: left;

                &:hover{
                  background-color: var(--modal-item-button-bg);
                  font-weight: bold;
                }
              }

              .is-active {
                background-color: var(--modal-item-button-bg);
                font-weight: bold;
              }
            }
          }

          .moda-option-content {
            display: flex;
            flex-direction: column;
            width: 75%;
            padding: rpx(16) rpx(32);
            overflow-y: auto;
            text-align: justify;
          }
        }
      }
    }
  }

  .how-to-use-btn-wrapper {
    display: flex;
    margin-left: rpx(16);
  }

  .how-to-use-txt {
    bottom: rpx(2);
    font-size: rpx(16);
    position: relative;
  }
</style>
