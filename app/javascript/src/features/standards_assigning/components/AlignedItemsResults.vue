<template>
  <div
    class="u-mar-top-20  aligned-items-results"
    :class="testClass('aligned-items-results')">
    <!-- Setting the key to "unit.unitIdStr + store.selectedTocItems"
       forces a re-render each time store.selectedTocItems is changed,
         keeping the template up to date with selected Units/Lessons  -->
    <div
      v-show="displayStandardTags"
      :class="testClass('standard-tags-wrapper')"
      class="u-mar-lt-16  u-mar-bot-48">
      <StandardTags
        :cartItems="store.selectedStandards"
        @removeItem="removeStandardItem" />
    </div>
    <div
      v-show="displayNoResultsMsg"
      class="u-pad-lt-16"
      :class="testClass('empty-aligned-items')">
      Your search did not produce results. Please try again.
    </div>
    <div
      v-show="displayNoUnitLessonSelectedMsg"
      :class="testClass('no-unit-lesson-selected-msg')">
      You need to select at least one Unit/Lesson.
    </div>
    <div
      v-show="displayMatchingContentCount"
      :class="testClass('matching-content-count')"
      class="u-mar-lt-16  u-mar-bot-48">
      <h3>
        <span class="matching-content-txt">
          Matching Content ({{ matchingContentCount }})
        </span>
      </h3>
    </div>
    <ul
      v-for="unit in store.alignedItems"
      :key="unit.unitIdStr + store.selectedTocItems"
      class="c-plain-list"
      :class="testClass(`results-for-${unit.unitIdStr}`)">
      <li>
        <ul
          v-if="unit.isUnitVisible(store.selectedTocItems)"
          :class="testClass(`unit-${unit.unitIdStr}`)"
          class="c-plain-list  u-pad-lt-0">
          <li v-for="(concept, lesson_key) in unit.items" :key="lesson_key">
            <ul :class="testClass(`results-for-${lesson_key}`)" class="c-plain-list  u-pad-lt-0">
              <li
                v-for="(items, concept_key) in concept"
                :key="concept_key"
                class="c-unit  u-pad-bot-20">
                <div
                  :class="testClass(`results-section-label-${lesson_key}-${concept_key}`)"
                  class="l-line  u-mar-lt-16  u-pad-bot-8">
                  <div
                    v-if="unit.conceptBackgroundColor(concept_key, lesson_key)"
                    :style="{
                      backgroundColor: unit.conceptBackgroundColor(concept_key, lesson_key)
                    }"
                    class="u-dis-block  u-mar-rt-5  u-pad-2"
                    :class="testClass(`strand-color-${lesson_key}-${concept_key}`)" />
                  <h3 class="u-txt-16  u-txt-gray-6  u-txt-bold">
                    <span v-if="programTocType == 'Unit'">
                      {{ store.tocUnitNames[unit.unitId] }}:
                    </span>
                    <span v-if="programTocType == 'Lesson'">
                      {{ lesson_key }}:
                    </span>
                    <span class="u-txt-plain">{{ store.tocConceptNames[concept_key] }}</span>
                  </h3>
                </div>
                <ul>
                  <li
                    v-for="item in items"
                    :key="item.activityId"
                    :class="[
                      item.assigned ? 'c-assigned-item' : 'c-unassigned-item',
                      {'c-activity-item': item.referenceType === 'Activity'},
                      {'c-assessment-item': item.referenceType === 'AssessmentItem'},
                      {'c-ereader-item': item.referenceType === 'EReaderItem'}
                    ]"
                    class="aligned-items  u-clearfix  u-mar-bot-20">
                    <div class="l-container-fluid">
                      <div>
                        <details class="expand" @toggle="showAssignmentsInfo($event, item)">
                          <summary
                            class="l-grid  main-summary  u-mar-lt-4  u-mar-rt-3"
                            :class="{[testClass(`expand-content-${item.activityId}`)]: true}">
                            <div class="l-col-9  l-line">
                              <span class="item-icon">
                                <Activities v-if="item.referenceType == 'Activity'" />
                                <Assessments v-if="item.referenceType == 'AssessmentItem'" />
                                <EReaderIcon v-if="item.referenceType == 'EReaderItem'" />
                              </span>
                              <div>
                                <a
                                  v-if="item.referenceType !== 'EReaderItem'"
                                  class="u-txt-bold  u-txt-16"
                                  :href="`${item.activityUrl}?popup=1`"
                                  @click="openPopUp($event)">
                                  <!-- item titles come from our database, not user input -->
                                  <!-- eslint-disable-next-line vue/no-v-html -->
                                  <span v-html="itemTitle(item)" />
                                </a>
                                <span v-else class="u-txt-bold  u-txt-16  u-txt-under">
                                  {{ itemTitle(item) }}
                                </span><br>
                                <span
                                  class="u-txt-16  u-txt-bold  u-txt-gray-6"
                                  :class="testClass(`standard-count-${item.activityId}`)">
                                  {{ getStandardCount(item) }}
                                </span>
                                <div class="content-extra-info">
                                  <ButtonDefault
                                    class="view-all-standards  c-button  c-no-button  is-navigable"
                                    :class="testClass(`view-all-standards-${item.activityId}`)"
                                    :disabled="false"
                                    @click="showStandardModal(unit.unitIdStr, item)">
                                    View All
                                  </ButtonDefault>
                                  <span
                                    v-if="item.activityIcons.length > 0"
                                    class="u-txt-gray-e">
                                    |
                                  </span>
                                  <span
                                    v-for="icon in item.activityIcons"
                                    :key="icon"
                                    class="activity-attribute-icon  c-embedded-icon--md-lg">
                                    <Icon :name="icon" />
                                  </span>
                                </div>
                                <div>
                                  <a
                                    v-if="item.referenceType === 'EReaderItem'"
                                    class="u-txt-bold  u-txt-under  u-txt-14"
                                    :class="testClass(`te-url-${item.activityId}`)"
                                    :href="item.activityUrl"
                                    @click="openPopUp($event)">
                                    See {{ item.pageSection }} on page {{ item.pageNumber }}
                                  </a>
                                </div>
                                <div
                                  v-if="item.referenceType === 'EReaderItem'"
                                  class="u-txt-16  u-txt-plain"
                                  :class="testClass(`te-descriptor-${item.activityId}`)">
                                  {{ item.te_descriptor }}
                                </div>
                              </div>
                            </div>
                            <div class="l-col-3  c-item-dinamic-info  u-pad-0">
                              <div class="c-item-action-buttons  c-button-group  c-button-group--rt">
                                <div v-if="item.referenceType !== 'EReaderItem'">
                                  <ButtonSecondary
                                    v-if="item.isAssignable && !item.assigned"
                                    title="Set due date"
                                    aria-haspopup="true"
                                    aria-expanded="false"
                                    class="c-menu__title  u-txt-14  u-pad-12  u-pad-bot-32  u-bg-white
                                          js-nav-system__link  set_date_link  activity_set_date_link"
                                    :class="testClass(`assign-content-${item.activityId}`)"
                                    @click="assignActivity($event, item)">
                                    <span class="c-embedded-icon">
                                      <CalendarIcon
                                        alt="Assign Button"
                                        :disabled="false" />
                                    </span>
                                    <span class="u-pad-lt-8">assign</span>
                                  </ButtonSecondary>
                                  <a
                                    v-if="!item.isAssignable"
                                    class="c-no-assignable-item  js-unassignable-msg-link"
                                    :class="testClass(`not-assignable-link-${item.activityId}`)"
                                    :js-data-unassignable-reason="item.unassignableReason">
                                    Non-Assignable
                                    <span class="c-embedded-icon  u-mar-rt-8">
                                      <QuestionIcon alt="Assign Button" />
                                    </span>
                                  </a>
                                </div>
                                <a
                                  v-else
                                  class="c-no-assignable-item  js-unassignable-msg-link"
                                  :class="testClass(`te-not-assignable-link-${item.activityId}`)"
                                  :js-data-unassignable-reason="item.unassignableReason">
                                  Non-Assignable
                                  <span class="c-embedded-icon  u-mar-rt-8">
                                    <QuestionIcon alt="Assign Button" />
                                  </span>
                                </a>
                              </div>
                              <div class="c-item-summary-expand-icon">
                                <music-icon-caret
                                  class="music-icon-caret"
                                  label="Expand"
                                  size="lg"
                                  rotate="1" />
                              </div>
                              <div
                                v-if="item.assigned && !item.assignmentsDueDate"
                                class="c-assign-due-date  u-txt-gray-3"
                                :class="testClass(`assign-due-date-${item.activityId}`)">
                                <span
                                  v-if="item.isIndividuallyAssigned"
                                  class="u-pad-rt-6"
                                  :class="testClass(`individually-assigned-${item.activityId}`)">
                                  <a
                                    :href="`${individualAssigningUrl}?activity_ids[]=${item.activityId}`"
                                    @click="openPopUp($event)">
                                    <Icon name="person_icon" />
                                  </a>
                                </span>
                                Assigned
                              </div>
                              <div
                                v-if="item.assignmentsDueDate"
                                class="c-assign-due-date  u-txt-gray-3"
                                :class="testClass(`assign-due-date-${item.activityId}`)">
                                <span
                                  v-if="item.isIndividuallyAssigned"
                                  class="u-pad-rt-6"
                                  :class="testClass(`individually-assigned-${item.activityId}`)">
                                  <a
                                    :href="`${individualAssigningUrl}?activity_ids[]=${item.activityId}`"
                                    @click="openPopUp($event)">
                                    <Icon name="person_icon" />
                                  </a>
                                </span>
                                Due {{ item.assignmentsDueDate }}
                              </div>
                              <ButtonDefault
                                v-if="item.referenceType !== 'EReaderItem' && item.assignmentsDueDate"
                                title="Change Due date"
                                aria-haspopup="true"
                                aria-expanded="false"
                                class="change-due-date-button  c-button  c-no-button  is-navigable
                                        js-nav-system__link  set_date_link  activity_set_date_link"
                                :class="testClass(`assign-content-${item.activityId}`)"
                                :disabled="!item.isAssignable"
                                @click="assignActivity($event, item)">
                                Change Due date
                              </ButtonDefault>
                            </div>
                          </summary>
                          <div class="summary-border" @click="collapseContentItem($event)" />
                          <div
                            v-for="(standards, displayName) in item.standardAlignments"
                            :key="displayName"
                            class="c-clickable-area"
                            @click="collapseContentItem($event)">
                            <div v-for="standard in standards" :key="standard.standardGuid">
                              <div
                                v-if="store.isStandardSelected(standard.standardGuid)"
                                class="c-standard-list  u-txt-20  u-txt-bold  u-mar-bot-0"
                                :class="testClass(`standard-number-${standard.standardGuid}`)">
                                <p
                                  class="u-mar-bot-6  u-txt-16  u-txt-bold">
                                  {{ standardInfo(standard.standardGuid)?.display_number }}
                                </p>
                                <p class="u-mar-bot-6  u-txt-16  u-txt-plain  u-txt-black">
                                  {{ standardInfo(standard.standardGuid)?.description }}
                                </p>
                              </div>
                            </div>
                          </div>
                          <div
                            v-if="item.referenceType == 'AssessmentItem' && item.assignmentsDueDate"
                            class="summary-footer"
                            :class="testClass(`availability-${item.activityId}`)">
                            <span>Availability</span>
                            <span
                              :id="`release_date_time_for_assessment_${item.activityId}`"
                              class="release_date_time">
                              <span
                                :id="`available_specifics_${item.activityId}`"
                                class="assess_available_time
                                       u-pad-lt-8  u-pad-rt-8">
                                {{ item.assessmentAvailability }}
                              </span>
                              <span v-if="item.showReleaseLink">|</span>
                              <a
                                v-if="item.showReleaseLink"
                                :id="`release_hide_link_${item.activityId}`"
                                :data-js-assignable-id="item.activityId"
                                class="c-link  u-pad-lt-8  u-txt-16"
                                :title="item.hoverText"
                                data-js-assess-link="assessment_release"
                                @click.prevent="handleReleaseClick(item.activityId)">
                                {{ item.releaseLinkText }}
                              </a>
                              <input
                                :id="`assessments_ids_for_activity_${item.activityId}`"
                                type="hidden"
                                :name="`assessments_ids_for_activity_${item.activityId}`"
                                :value="item.assignmentIds"
                                autocomplete="off">
                            </span>
                          </div>
                        </details>
                      </div>
                    </div>
                  </li>
                </ul>
              </li>
            </ul>
          </li>
        </ul>
      </li>
    </ul>
    <StandardsListModal
      v-if="standardModal.status"
      :standardsList="standardsList"
      :unitId="unitId"
      :instructorStandardsAssigningPath="instructorStandardsAssigningPath"
      @close="standardModal.status = false" />
  </div>
</template>

<script setup>
  import { getFromEndpoint, postToEndpoint, testClass } from 'music';
  import { computed, onUpdated, inject, ref, reactive } from 'vue';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';
  import {
    handleFilterChange,
    matchingContentCount,
    updateMatchingContentCount,
  } from './../models/filters_helper.js';
  import CalendarIcon from './../icons/CalendarIcon';
  import QuestionIcon from './../icons/QuestionIcon';
  import EReaderIcon from './../icons/EReaderIcon';
  /* eslint-disable-next-line max-len*/
  import ButtonSecondary from
  'music/app/javascript/src/components/button_secondary/v1.1/ButtonSecondary';
  import ButtonDefault from
  'music/app/javascript/src/components/button_default/v1.0/ButtonDefault';
  import Activities from
  'music/app/javascript/src/components/menu_icons/activities/v1.0/Activities';
  import Assessments from
  'music/app/javascript/src/components/menu_icons/assessments/v1.0/Assessments';
  import Icon from './../Icon.vue';
  import StandardsListModal from '../../shared/standards/StandardsListModal';
  import StandardTags from './StandardTags';

  const store = useStandardsAssigningStore();

  const props = defineProps({
    contentLibrary: { required: true, type: Object },
    dueDateLinkBaseUrl: { required: true, type: String },
    instructorStandardsAssigningPath: { required: true, type: String },
    instructorSearchStandardsByAssetPath: { required: true, type: String },
    programTocType: { required: true, type: String },
    vhlCommon: { required: true, type: Object },
    dataForAssignedItemEndpoint: { required: true, type: String },
  });

  const emit = defineEmits(['applyFilter']);

  const displayEmptyResults = inject('displayEmptyResults');
  const isSearchLoading = inject('isSearchLoading');
  const individualAssigningUrl = inject('individualAssigningUrl');
  const vhlAssessments = inject('vhlAssessments');
  const standardsList = ref({});
  const standardModal = reactive({ status: false });
  const unitId = ref({});
  let assignedActivityId = null;
  let newAssignments = null;
  let standardSetGuids = null;
  let standardAssetIds = null;

  /**
   * Collpses the content item box.
   * @param {Event} event - Button click event
   */
  function collapseContentItem(event) {
    event.target.closest('.expand').removeAttribute('open');
  }

  /**
   * Assigns the current activity.
   * @param {Event} event - Button click event
   */
  function assignActivity(event, item) {
    const urlWithActivityId = `${props.dueDateLinkBaseUrl}&selected_activities=${item.activityId}`;
    event.currentTarget.setAttribute('href', urlWithActivityId);
    props.contentLibrary.assignment_wizard(event.currentTarget);
    document.addEventListener('assignmentUpdate', () => {
      // call endpoint to fetch updated data for assigned item
      fetchDataForAssignedItem(item);
    });
  }

  /**
   * Fetch data for assigned item
   @param {Nuber} assignedActivityId
   */
  function fetchDataForAssignedItem(item) {
    standardSetGuids = Object.values(
      item.standardAlignments
    ).flat().map((aln)=> aln.standardSetGuid);
    standardAssetIds = item.standardAssetIds;
    assignedActivityId = [item.activityId];
    postToEndpoint(
      `${props.dataForAssignedItemEndpoint}${assignedActivityId}`,
      {
        standard_asset_ids: standardAssetIds,
        standard_set_guids: standardSetGuids,
      },
      (result)=> {
        newAssignments = result.data_for_assigned_item;
        store.alignedItems.forEach( (unit, index) => {
          for (const concept in unit.items) {
            if (Reflect.has(unit.items, concept)) {
              for (const items in unit.items[concept]) {
                if ( Reflect.has(unit.items[concept], items)) {
                  const actInd = store.alignedItems[index].items[concept][items].findIndex(
                    (a)=>a.activityId == assignedActivityId[0]
                  );
                  if (actInd !== -1) {
                    store.alignedItems[index].items[concept][items][actInd] = newAssignments;
                  }
                }
              }
            }
          }
        });
      }
    );
  }

  /**
   * Returns the total count of standards per aligned item, across issuers (displayName)
   * @param {Object} item - Hash of issuer diplay names to arrays of aligned standards.
   * @return {Number} - standards count.
   */
  function getStandardCount(item) {
    const keys = Object.keys(item.standardAlignments);
    const standardsCount = keys.map(
      (key) => item.standardAlignments[key].length
    ).reduce(
      (acc, val) => {
        return acc + val;
      }, 0
    );
    return standardsCount > 1 ? standardsCount + ' standards' : standardsCount + ' standard';
  }

  /**
   * releases or hides assessments availability.
   * @param {Number} activityId - the assessment id to release/hide.
   */
  function handleReleaseClick(activityId) {
    vhlAssessments.update_assessment(activityId, 'assessment_release');
  }

  /**
   * Fetches the assignment info for the specific item.
   * @param {Event} event - Button click event
   * @param {Object} item - the item that is being shown.
   */
  function showAssignmentsInfo(event, item) {
    const isGettingOpened = event.currentTarget.closest('.expand').hasAttribute('open');
    if (isGettingOpened && item.assigned) {
      fetchDataForAssignedItem(item);
    }
  }

  const displayNoResultsMsg = computed(() => {
    return (store.alignedItems.length < 1 &&
      displayEmptyResults.value &&
      !isSearchLoading.value);
  });

  const displayNoUnitLessonSelectedMsg = computed(() => {
    return (store.alignedItems.length > 1 &&
      store.selectedTocItems.length < 1 &&
      !displayEmptyResults.value &&
      !isSearchLoading.value);
  });

  const displayMatchingContentCount = computed(() => {
    return (store.alignedItems.length > 0 &&
      !displayNoUnitLessonSelectedMsg.value &&
      !displayEmptyResults.value &&
      !isSearchLoading.value);
  });

  const displayStandardTags = computed(() => {
    return !displayNoUnitLessonSelectedMsg.value &&
      !isSearchLoading.value;
  });

  /**
   * Returns the standard info for the passed guid.
   * @param {String} standardGuid
   * @return {Object}
   */
  function standardInfo(standardGuid) {
    return store.standardsInfo['standards'][standardGuid];
  }

  onUpdated(() => {
    props.vhlCommon.unassignable_dialog();
    updateMatchingContentCount(matchingContentCount);
    handleFilterChange(store.selectedStatus, store.selectedContentType);
  });

  /**
   * Returns the title prefixed with the reference type.
   * @param {Object} item
   * @return {String}
   */
  function itemTitle(item) {
    let title;
    if (item.referenceType === 'Activity') {
      title = 'Activity: ' + item.activityTitle;
    } else if (item.referenceType === 'AssessmentItem') {
      title = 'Assessment: ' + item.activityTitle;
    } else if (item.referenceType === 'EReaderItem') {
      title = 'Teacher´s Edition: ' + item.activityTitle;
    } else {
      title = item.referenceType;
    }
    return title;
  }

  /**
   * Opens a link in a new popup window,
   * with the same windowFeatures string
   * as the Activities TOC.
   * @param {Object} event
   */
  function openPopUp(event) {
    event.preventDefault();
    const url = event.currentTarget.getAttribute('href');
    /* eslint-disable-next-line max-len*/
    const tocPopUpParams = 'directories=no,height=600,location=no,menubar=no,resizable=yes,scrollbars=yes,status=yes,toolbar=no,width=1000';
    const actWindow = window.open(url, '_blank', tocPopUpParams);
    actWindow.focus;
  }

  /**
   * Get Standars by asset path.
   * @param {Number} unitIdValue
   * @param {Number} item
   */
  function showStandardModal(unitIdValue, item) {
    getFromEndpoint(
      `${props.instructorSearchStandardsByAssetPath}${item.activityId}?item_type=${item.referenceType}`,
      (response) => {
        standardsList.value = response.mapped_standards;
        unitId.value = unitIdValue;
        standardModal.status = true;
      }
    );
  }

  /**
   * Remove standard from the selected standards for the search,
   * and emit the event to trigger the search again.
   * @param {Number} vendorGuid - vendor guid for the standard
   */
  function removeStandardItem(vendorGuid) {
    store.removeStandardFromList(vendorGuid);
    emit('applyFilter');
  }
</script>

<style lang="scss" scoped>
  @use 'features/shared/icon_styles' as *;

  .unassignable-draft {
    color: #{$gray-6};
  }

  .aligned-items {
    border: rpx(1) solid rgb(207,216,220);
    border-radius: rpx(10);
  }

  .item-icon {
    width: rpx(60);
    display: block;
    margin-left: rpx(16);
  }

  .expand summary::-webkit-details-marker {
     display: none;
  }

  .c-unit:not(:has(.aligned-items:not(.u-hidden))) {
    display: none;
  }

  .expand summary {
    list-style: none;
    cursor: default;
    position: relative;

    &::before {
      content: '';
      border-right: rpx(4) solid;
      border-bottom: rpx(4) solid;
      position: absolute;
      left: rpx(28);
      top: rpx(13);
      height: .75em;
      width: .75em;
      transform: rotate(45deg) translatey(-.1em);
    }
  }

  .expand .main-summary {
    cursor: pointer;

    &::before {
      content: none;
    }
  }

  .alignment summary::before {
    left: rpx(2);
    top: rpx(20);
    color: #006bae;
  }

   details[open].expand > summary::before {
     transform: rotate(-135deg) translatey(-.3em);
     left: rpx(33);
     top: rpx(15);
   }

   details[open].alignment > summary::before {
     transform: rotate(-135deg) translatey(-.3em);
     left: rpx(8);
     top: rpx(22);
     color: #006bae;
   }

  .c-expand-width {
    width: 9.5rem;
  }

  a.c-no-assignable-item:link,
  a.c-no-assignable-item:visited,
  a.c-no-assignable-item:hover,
  a.c-no-assignable-item:active,
  a.c-no-assignable-item {
    color: $gray-3;
    font-size: rpx(14);
    text-decoration: none;
    text-transform: uppercase;
  }

  .c-activity-item,
  .c-assessment-item,
  .c-ereader-item {
    --item-border-color: #BCCBFF;
    --item-background-color: #F6FBFF;
    --item-standard-list-bg: #FFFDF4;

    max-width: rpx(800);

    .c-item-summary-expand-icon {
      display: none;
      justify-content: flex-end;
    }

    .c-item-dinamic-info {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      justify-content: center;
    }

    .c-item-action-buttons {
        margin-bottom: 0;
      }

    .music-icon-caret :deep(.c-svg-icon > svg) {
        fill: $link-color;
    }

    .c-standard-list:last-child {
      border-radius: 0 0 rpx(10) rpx(10);
    }

    .content-extra-info {
      display: none;
    }

    &:hover {
      border-color: var(--item-border-color);
      background-color: var(--item-background-color);

      .c-item-summary-expand-icon {
        display: flex;
      }

      details.expand[open] summary,
      .c-standard-list {
        background-color: transparent;
      }
    }

    details.expand summary {
      border-radius: rpx(10) rpx(10) 0 0;
      margin-top: rpx(4);
      padding: rpx(14) rpx(34) rpx(18) rpx(2);

      .c-item-action-buttons {
        display: none;
      }
    }

    details.expand[open] summary {
      .c-item-action-buttons {
        display: block;
      }

      .c-item-summary-expand-icon {
        display: none;
      }

      .content-extra-info {
        display: inline-block;
      }
    }

    .summary-border {
      cursor: pointer;
      border-bottom: solid rpx(1) $gray-e;
      margin: 0 3rem;

    }

    .c-clickable-area {
      cursor: pointer;
    }

    .c-standard-list {
      background-color: var(--item-standard-list-bg);
      padding: rpx(15) rpx(28);
    }

    .view-all-standards {
      text-transform: capitalize;
      padding: 0.2rem 0.5rem;
      border-radius: rpx(5);

      &:hover:not([disabled]) {
        background-color: var(--item-background-color);
        text-decoration: none;
      }
    }
  }

  .c-assigned-item {
    --item-assigned-border-color: #CFD8DC;
    --item-assigned-bg-hover: #F6FBFF;

    background-color: rgba($gray-f5, 0.75);
    border-color: var(--item-assigned-border-color);
    box-shadow: rpx(2) rpx(1) rpx(3) 0 rgba($gray-3, 0.2) inset;

    .c-item-summary-expand-icon {
      display: none;
    }

    .c-assign-due-date {
      font-size: rpx(16);
      color: $gray-6;
    }

    details.expand summary {
      .change-due-date-button {
        display: none;
        font-size: 1rem;
        text-transform: capitalize;
        padding: 0;
      }
    }

    details.expand[open] summary {
      background-color: $white;
      margin-bottom: 0;

      .c-item-action-buttons {
        display: none;
      }

      .change-due-date-button {
        display: block;
      }
    }

    .c-standard-list {
      background-color: transparent;
      padding: rpx(15) rpx(28);
    }

    &:hover {
      background-color: var(--item-assigned-bg-hover);
      border-color: var(--item-assigned-border-color);

      .c-item-summary-expand-icon {
        display: none;
      }
    }

    .summary-footer {
      align-items: center;
      background-color: $white;
      border-radius: 0 0 rpx(10) rpx(10);
      border-top: rpx(1) solid $gray-e;
      display: flex;
      height: 2.5rem;
      justify-content: center;
      margin: rpx(3) rpx(5);
    }
  }

  .matching-content-txt {
    color: $lightest-text;
    font-size: rpx(16);
    font-weight: 600;
  }
</style>
