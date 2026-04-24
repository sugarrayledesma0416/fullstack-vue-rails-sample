<template>
  <div
    v-if="availableSets.length < 1"
    class="u-txt-ctr"
    :class="testClass('warning-icon')">
    <WarningIcon />
    <span class="u-screen-reader-only">warning</span>
    <div class="u-bg-white  u-mar-lt-neg-16  u-mar-rt-neg-16  u-pad-top-16  u-pad-bot-64">
      <div class="u-mar-top-16  u-mar-bot-32">
        <div class="u-start-image-container">
          <div class="text  u-txt-gray-6  u-mar-top-8">
            <p>
              Please select one or more standards in the Content tab of your
              <a :href="`${courseSettingsUrl}`">
                course settings
              </a> to use standards-based reporting.
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="standard-assigning-cnt  l-grid">
    <div class="l-col-3  u-pad-rt-0">
      <Filters
        class="u-pad-bot-32"
        :preloadStandardsFilter="preloadStandardsFilter"
        :programTocType="programTocType"
        @applyFilter="getAlignedItems"
        @showFindStandardResult="showFindStandardResult"
        @showBrowseStandardResult="showBrowseStandardResult" />
    </div>
    <div class="l-col-9  col-content  u-pad-lt-0">
      <div v-if="viewMode === 'FIND'">
        <FindStandards
          class="search-standard"
          :availableSets="availableBrowseStdSets"
          :searchStandardsEndpoint="searchStandardsEndpoint"
          @applyFilter="getAlignedItems"
          @showFilterResult="showFilterResult" />
      </div>
      <div v-if="viewMode === 'BROWSE'" class="c-standards-view">
        <BrowseStandards
          :availableBrowseStdSets="availableBrowseStdSets"
          :availableGradeLevels="availableGradeLevels"
          :browseStandardUrl="browseStandardUrl"
          @findcontent="getAlignedItemsAndShowResult" />
      </div>
      <div class="u-pad-lt-24">
        <AlignedItemsResults
          v-if="viewMode === 'RESULTS'"
          :dataForAssignedItemEndpoint="dataForAssignedItemEndpoint"
          :programTocType="programTocType"
          :vhlCommon="vhlCommon"
          :contentLibrary="contentLibrary"
          :dueDateLinkBaseUrl="dueDateLinkBaseUrl"
          :instructorSearchStandardsByAssetPath="instructorSearchStandardsByAssetPath"
          :instructorStandardsAssigningPath="instructorStandardsAssigningPath"
          @applyFilter="getAlignedItems" />
        <div>
          <div
            v-if="isSearchLoading"
            class="u-dis-flex  flex-justify-ctr  u-mar-top-24">
            <img
              :src="spinnerImage"
              class="c-search-spinner"
              :class="testClass('search-spinner')">
            <div class="u-mar-lt-20  u-mar-top-2">
              Results are loading...
            </div>
          </div>
          <div v-if="searchErrorMsg">
            <div
              class="u-mar-top-10  u-pad-lt-16"
              :class="testClass('search-error')">
              {{ searchErrorMsg }}
            </div>
          </div>
        </div>
      </div>
      <div class="filler" />
      <StandardsResultsFooter
        v-if="viewMode === 'FIND' || viewMode === 'BROWSE'"
        @click="getAlignedItemsAndShowResult" />
    </div>
  </div>
</template>

<script setup>
  import { computed, ref, provide, onMounted, onUnmounted } from 'vue';
  import Filters from './components/Filters';
  import FindStandards from './FindStandards';
  import AlignedItemsResults from './components/AlignedItemsResults';
  import BrowseStandards from './components/BrowseStandards';
  import spinnerImage from 'images/loading_32.gif';
  import StandardsResultsFooter from './components/StandardsResultsFooter.vue';
  import { putToEndpoint } from 'shared/ajax_utils';
  import useStandardsAssigningStore from './models/use_standards_assigning_store.js';
  import WarningIcon from './icons/WarningIcon';
  import { testClass } from 'music';

  const props = defineProps({
    availableSetsJson: { required: true, type: String },
    availableBrowseStandardSets: { required: true, type: String },
    availableGradeLevels: { required: true, type: String },
    browseStandardUrl: { required: true, type: String },
    contentLibrary: { required: true, type: Object },
    courseSettingsUrl: { required: true, type: String },
    dataForAssignedItemEndpoint: { required: true, type: String },
    dueDateLinkBaseUrl: { required: true, type: String },
    individualAssigningUrl: { required: true, type: String },
    instructorSearchStandardsByAssetPath: { required: true, type: String },
    instructorStandardsAssigningPath: { required: true, type: String },
    preloadStandardsFilter: { required: true, type: String },
    programTocType: { required: true, type: String },
    searchAssetsEndpoint: { required: true, type: String },
    searchStandardsEndpoint: { required: true, type: String },
    selectedUnit: { type: String, default: '' },
    standardsForInit: { type: String, default: JSON.stringify([]) },
    showSkillsAndRefinementFilters: { required: true, type: String },
    tocJson: { required: true, type: String },
    vhlAssessments: { required: true, type: Object },
    vhlCommon: { required: true, type: Object },
  });

  const ajaxErrorMsg = `There was a problem processing your search. Please try again.
                        If this problem continues, please contact technical support.`;
  const store = useStandardsAssigningStore();
  store.initToc(props.tocJson);
  const availableSets = JSON.parse(props.availableSetsJson);
  const availableBrowseStdSets = JSON.parse(props.availableBrowseStandardSets);
  const availableGradeLevels = JSON.parse(props.availableGradeLevels);
  const isSearchLoading = ref(false);
  const nextKey = ref('');
  const searchErrorMsg = ref(null);
  const initStandards = JSON.parse(props.standardsForInit);
  let observer;
  const isObserverConnected = ref(false);

  const viewMode = ref('BROWSE');

  if (initStandards.length) {
    store.selectedStandards = initStandards;
    switchView('RESULTS');
    getAlignedItems();
  }

  const isEmptySearch = computed(
    () => {
      return !isSearchLoading.value && !searchErrorMsg.value && store.alignedItems.length === 0;
    }
  );

  provide('displayEmptyResults', isEmptySearch);
  provide('isSearchLoading', isSearchLoading);
  provide('individualAssigningUrl', props.individualAssigningUrl);
  provide('vhlAssessments', props.vhlAssessments);
  provide('selectedUnit', props.selectedUnit);
  provide('showSkillsAndRefinementFilters', props.showSkillsAndRefinementFilters);

  /**
   * Fetch search results and show them.
   */
  function getAlignedItemsAndShowResult() {
    showFilterResult();
    getAlignedItems();
  }

  /**
   * Performs ajax request to StandardsAssigning#search_standards endpoint
   *
   * @param {Array} selectedUnitsCheckbox - Array of selected units from checkboxes.
   * @param {boolean|null} paginatedRequest - Indicates if the request is paginated.
   * @param {Array} selectedSkills - Array of selected skills.
   * @param {Array} selectedRefinements - Array of selected refinements.
   */
  function getAlignedItems(
    selectedUnitsCheckbox = [],
    paginatedRequest = null,
    selectedSkills = [],
    selectedRefinements = []
  ) {
    if (viewMode.value !== 'RESULTS') return;

    const selectedUnits = resolveSelectedUnits(selectedUnitsCheckbox);
    selectedSkills = store.selectedSkills;
    selectedRefinements = store.selectedRefinements;

    if (!paginatedRequest) initializeSearch();

    const requestPayload = buildRequestPayload(selectedUnits, selectedSkills, selectedRefinements);
    putToEndpoint(
      props.searchAssetsEndpoint,
      requestPayload,
      handleSearchResponse(paginatedRequest)
    );
  }

  /**
   * Return selected units, based on fallback from store or props.
   *
   * @param {Array<string>} units
   * @return {Array<string>}
   */
  function resolveSelectedUnits(units) {
    if (units.length > 0) return units;
    if (store.selectedTocItems.length > 0) return store.selectedTocItems;
    if (props.selectedUnit) return [props.selectedUnit];
    return [];
  }

  /**
   * Set variables for initializing search.
   */
  function initializeSearch() {
    nextKey.value = '';
    isSearchLoading.value = true;
    searchErrorMsg.value = null;
    store.updateAlignedItems(JSON.stringify({}));
    store.standardsInfo = {};
  }

  /**
   * Prepare request payload for searching assets.
   *
   * @param {Array<string>} units
   * @param {Array<string>} skills
   * @param {Array<string>} refinements
   * @return {Object<string, object>}
   */
  function buildRequestPayload(units, skills, refinements) {
    return {
      selected_standards: store.selectedStandards,
      selected_units: units,
      selected_skills: skills,
      selected_refinements: refinements,
      selected_content_type: store.selectedContentType,
      ...(nextKey.value && { next_key: nextKey.value }),
    };
  }

  /**
   * Return handler for request to StandardsAssigning#search_standards endpoint
   *
   * @param {boolean|null} paginatedRequest - Indicates if the request is paginated.
   * @return {Function} handler function
   */
  function handleSearchResponse(paginatedRequest) {
    return (result) => {
      isSearchLoading.value = false;

      if (result.error_message) {
        searchErrorMsg.value = ajaxErrorMsg;
        nextKey.value = null;
        console.error(result.error_message);
        return;
      }

      const alignedData = result.assets_and_standards;
      if (alignedData) {
        store.updateAlignedItems(alignedData.aligned_items, paginatedRequest);
        store.updateStandardsInfo(alignedData.standards_info);
        nextKey.value = JSON.parse(alignedData.next_key);
        if (!isObserverConnected.value) initializeObserver();
      } else {
        searchErrorMsg.value = store.anyRequiredFiltersSelected ?
          ajaxErrorMsg :
          'Please select at least one standard, skill, or refinement.';
        nextKey.value = null;
      }
    };
  }

  /**
   * Switches the current view mode to the specified mode.
   *
   * @param {string} mode - The view mode to switch to.
   *                        Possible values: 'BROWSE', 'FIND', 'RESULTS'.
   */
  function switchView(mode) {
    searchErrorMsg.value = null;
    viewMode.value = mode;

    if (mode === 'FIND' || mode === 'BROWSE') {
      isSearchLoading.value = false;
    }
  }

  /**
   * Shows the filter results view.
   * Sets the view mode to 'RESULTS' to display aligned items.
   */
  function showFilterResult() {
    switchView('RESULTS');
  }

  /**
   * Shows the browse standards view.
   * Sets the view mode to 'BROWSE'.
   */
  function showBrowseStandardResult() {
    switchView('BROWSE');
  }

  /**
   * Shows the find standards view.
   * Sets the view mode to 'FIND'.
   */
  function showFindStandardResult() {
    switchView('FIND');
  }

  /**
   * Loads more data if there is a next key available.
   * If no further data is available, disconnects the observer.
   */
  function loadMoreData() {
    if ((nextKey.value !== null && nextKey.value !== '') && viewMode.value === 'RESULTS') {
      isSearchLoading.value = true;
      getAlignedItems([], true);
    } else {
      if (observer) {
        observer.disconnect();
        isObserverConnected.value = false;
      }
    }
  }

  /**
   * Initializes the IntersectionObserver to load more data when the target element is in view.
   * Creates a target element, sets up the observer, and starts observing the target.
   */
  function initializeObserver() {
    const observerTarget = document.createElement('div');
    observerTarget.style.height = '20px';
    observerTarget.style.background = 'transparent';
    document.body.appendChild(observerTarget);

    observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          loadMoreData();
        }
      },
      { rootMargin: '0px' }
    );

    observer.observe(observerTarget);
    isObserverConnected.value = true;
  }

  onMounted(() => {
    initializeObserver();
  });

  onUnmounted(() => {
    if (observer) {
      observer.disconnect();
      isObserverConnected.value = false;
    }
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .standard-assigning-cnt {
    align-items: stretch;
    display: flex;
  }

  .c-standards-view {
    padding-right: 0;
  }

  .c-standard-sets__unavailable {
    margin-left: 30px;
  }

  .c-search-spinner {
    display: block;
  }

  .search-standard {
    margin: rpx(25) rpx(50) 0;
  }

  .col-content {
    display: flex;
    flex: 1;
    flex-direction: column;
    padding-right: 0;
  }

  .filler {
    flex-grow: 1;
  }
</style>
<style>
  /*
    Override global css coming from outside of vue js app
    so that column separator reaches till bottom .
  */

  #page_container > #column_wrapper {
    padding-bottom: 0;
  }

  .ns-music-v1 .standards-assign-search.c-panel {
    background-color: #FFFFFF;
    font-family: "Open Sans",sans-serif;
    margin-bottom: 0;
  }

  .ns-music-v1 .standards-assign-search.c-panel--padded > .l-container-fluid {
    padding-bottom: 0;
  }
</style>
