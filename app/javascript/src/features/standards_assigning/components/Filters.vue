<template>
  <section class="c-panel  c-panel--filters  u-width-full">
    <div
      class="c-panel__header  standard-header">
      <h3 class="c-heading--panel  u-txt-gray-6">
        Find by Standards
      </h3>
    </div>
    <div class="c-panel__body  u-pad-0">
      <div class="standard-container">
        <div class="standard-button-container">
          <button
            class="browse-button  standard-button"
            :class="[{ active: selectedButton === 'browse' }, testClass('browse-button')]"
            @click="selectBrowse">
            <div
              class="icon-container">
              <Icon
                class="c-embedded-icon--md-lg  u-pad-2"
                :svg="sortFilter" />
            </div>
            <span>Browse Standards</span>
          </button>
          <button
            class="search-button  standard-button"
            :class="[{ active: selectedButton === 'search' }, testClass('search-button')]"
            @click="selectFindStandardResult">
            <div
              class="icon-container search-icon">
              <Icon
                class="u-pad-2"
                :svg="searchIcon" />
            </div>
            <span>Search Keywords</span>
          </button>
        </div>
      </div>
      <div class="filter-header-container">
        <h3 class="filter-header">
          Filter by Content
        </h3>
        <div class="reset-main-container">
          <ButtonDefault
            class="c-no-button  u-pad-0"
            type="button"
            :class="testClass('reset-filters')"
            @click="resetFilters">
            <div class="reset-btn-container">
              <span class="c-embedded-icon">
                <ResetIcon alt="Reset Button" />
              </span>
              <span class="u-pad-lt-8  capitalize-text">Reset</span>
            </div>
          </ButtonDefault>
        </div>
      </div>
      <div class="u-pad-20">
        <SkillRefinementDropdown
          v-if="showSkillsAndRefinementFilters === 'true'"
          @applyFilter="$emit('applyFilter', $event)" />
        <TocSelector
          :tocItems="store.tocItems"
          :programTocType="programTocType"
          @applyFilter="$emit('applyFilter', $event)" />
        <div class="u-mar-bot-20  u-mar-top-20">
          <h3 class="content-filter">
            Content Type
          </h3>
          <select
            v-model="availableContentType"
            class="c-select  u-txt-16  u-width-full"
            :class="testClass('standard-set-content-type')">
            <option
              v-for="contentType in availableContentTypeList"
              :key="contentType"
              :value="contentType"
              :selected="contentType == availableContentTypeList[0]"
              class="u-txt-16">
              {{ contentType }}
            </option>
          </select>
        </div>
        <div class="u-mar-bot-20">
          <h3 class="content-filter">
            Status
          </h3>
          <select
            v-model="availableStatus"
            class="c-select  u-txt-16  u-width-full"
            :class="testClass('standard-set-status')"
            :disabled="isTeacherEditionSelected()">
            <option
              v-for="status in availableStatusList"
              :key="status"
              :value="status"
              :selected="status == availableStatusList[0]"
              class="u-txt-16">
              {{ status }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
  import { inject, onMounted, ref, watch } from 'vue';
  import { testClass } from 'music';
  import { storeToRefs } from 'pinia';
  import Icon from 'features/shared/Icon';
  import ResetIcon from '../icons/ResetIcon';
  import sortFilter from '!!raw-loader!MusicAssets/images/music/icons/sort-filter.svg';
  import searchIcon from '!!raw-loader!MusicAssets/images/music/icons/search-icon.svg';
  import SkillRefinementDropdown from './SkillRefinementDropdown.vue';
  import TocSelector from './TocSelector';
  import useStandardsAssigningStore from '../models/use_standards_assigning_store.js';
  import ButtonDefault from
  'music/app/javascript/src/components/button_default/v1.0/ButtonDefault';
  import { handleFilterChange } from '../models/filters_helper.js';

  const props = defineProps({
    preloadStandardsFilter: { required: true, type: String },
    programTocType: { required: true, type: String },
  });

  const availableStatusList = ['All', 'Assigned', 'Unassigned'];
  const availableStatus = ref(availableStatusList[0]);
  const availableContentTypeList = ['All', 'Activity', 'Assessment', 'Teacher Edition'];
  const availableContentType = ref(availableContentTypeList[0]);
  const selectedStandardsFilter = ref(0);
  const selectedButton = ref('browse');
  const store = useStandardsAssigningStore();
  const { selectedStandards } = storeToRefs(store);
  const showSkillsAndRefinementFilters = inject('showSkillsAndRefinementFilters');

  const emit = defineEmits(['applyFilter', 'showBrowseStandardResult', 'showFindStandardResult']);

  watch(availableContentType, (newContentType) => {
    store.setSelectedContentType(newContentType);
    emit('applyFilter');
  });

  watch(availableStatus, (newStatus) => {
    store.setSelectedStatus(newStatus);
    handleFilterChange(newStatus, store.selectedContentType);
  });

  watch(selectedStandards, (newValue) => {
    selectedStandardsFilter.value = newValue.length;
  });

  const isTeacherEditionSelected = () => {
    return store.selectedContentType === 'Teacher Edition';
  };

  /**
   * Returns TOC selection to show all Units/Lessons
   */
  function resetFilters() {
    store.selectedTocItems = [];
    availableStatus.value = availableStatusList[0];
    store.setSelectedStatus(availableStatus);
    availableContentType.value = availableContentTypeList[0];
    store.setSelectedContentType(availableContentType);
    store.setSelectedSkills([]);
    store.setSelectedRefinements([]);
    store.setVisibleRefinements({});
    store.resetAllFilters = true;
  }

  /**
   * Reset standard search related flags
   */
  function resetStandardVars() {
    store.setShowBrowseTree(false);
    store.selectedStandards = [];
    store.matchedStandards = null;
    store.selectedStandardSet = null;
    store.isFirstSearch = true;
  }

  /**
   * Handles the selection of the "Browse Standards" button.
   * - Sets the selected button to "browse".
   * - Updates the store to hide the browse tree.
   * - Emits the `showBrowseStandardResult` event to notify the parent component.
   */
  function selectBrowse() {
    selectedButton.value = 'browse';
    resetStandardVars();
    emit('showBrowseStandardResult');
  }

  /**
   * Handles the selection of the "Search Key Words" button.
   * - Sets the selected button to "search".
   * - Updates the store to hide the browse tree.
   * - Emits the `showFindStandardResult` event to notify the parent component.
   */
  function selectFindStandardResult() {
    selectedButton.value = 'search';
    resetStandardVars();
    emit('showFindStandardResult');
  }

  onMounted(() => {
    store.setSelectedStatus(availableStatus);
    store.setSelectedContentType(availableContentType);
    if (JSON.parse(props.preloadStandardsFilter).length > 0) {
      store.matchedStandards = props.preloadStandardsFilter;
      store.updateMatchedStandards(props.preloadStandardsFilter);
      store.isFirstSearch = true;
      selectedStandardsFilter.value = selectedStandards.value.length;
    }
  });

</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .c-panel {
    border-radius: unset;
  }

  .c-panel--filters {
    box-shadow: rpx(0.4) rpx(0.4) rgba(187, 187, 187, 1);
    height: 100%;
    min-width: rpx(275);
    width: 80%;
  }

  .c-heading--panel {
    font-size: rpx(16);
    font-weight: 600;
    padding-left: rpx(10);
    padding-top: rpx(10);
  }

  .capitalize-text {
    text-transform: capitalize;
  }

  .content-filter {
    color: $lightest-text;
    font-size: rpx(16);
    font-weight: normal;
    letter-spacing: rpx(1);
    margin-bottom: rpx(5);
    text-transform: uppercase;
  }

  .filter-header-container {
    align-items: center;
    border-bottom: rpx(2) solid $base-orange;
    display: flex;
    justify-content: space-between;
  }

  .filter-header {
    align-items: center;
    background-color: $white;
    color: $gray-6;
    display: flex;
    font-size: rpx(16);
    font-weight: 600;
    margin: 0;
    padding: rpx(20) rpx(2) rpx(12) rpx(32);
  }

  .icon-container {
    align-items: center;
    display: flex;
    flex-shrink: 0;
    justify-content: center;
    margin-right: rpx(8);
    width: rpx(24);
  }

  .reset-btn-container {
    align-items: center;
    display: flex;
    justify-content: center;
    padding-top: rpx(6);
  }

  .reset-btn {
    padding-left: rpx(8);
    padding-top: rpx(3);
  }

  .reset-main-container {
    align-items: center;
    display: flex;
    margin-right: rpx(18);
  }

  .standard-button {
    align-items: center;
    background: none;
    border: none;
    cursor: pointer;
    display: flex;
    font-size: rpx(14);
    font-weight: 400;
    letter-spacing: rpx(0.5);
    line-height: rpx(20);
    padding: rpx(8);
    text-align: left;
  }

  .standard-button.focus,
  .standard-button:hover {
    background-color: $gray-f5;
  }

  .standard-button.active {
    border-radius: rpx(8);
    box-shadow: rpx(1) rpx(1) rpx(3) rgba(0, 0, 0, 0.4);
    outline: none;
  }

  .standard-button-container {
    display: flex;
    flex-direction: column;
    gap: rpx(10);
    margin-bottom: rpx(10);
    position: relative;
    width: 85%;
  }

  .standard-container {
    border-bottom: rpx(2) solid #eee;
    padding: rpx(20) rpx(20) rpx(5) rpx(20);
    padding-left: rpx(26);
  }

  .standard-header {
    background-color: $white;
    border-bottom: rpx(2) solid $base-orange;
    display: flex;
    justify-content: space-between;
    padding: rpx(4) rpx(2) rpx(12) rpx(25);
  }

  .standards-filter {
    letter-spacing: rpx(1);
  }
</style>
