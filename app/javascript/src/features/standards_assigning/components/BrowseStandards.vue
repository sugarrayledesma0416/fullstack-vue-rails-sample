<template>
  <div class="browse-standards">
    <BrowseStandardFilters
      v-if="!store.showBrowseTree"
      :availableBrowseStdSets="availableBrowseStdSets"
      @next="onBrowseNext" />
    <template v-else>
      <Breadcrumb
        class="breadcrumb-wrapper"
        :class="testClass('breadcrumb-wrapper')"
        :availableGradeLevels="availableGradeLevels"
        @reset-from-breadcrumb="resetStandardSet" />
      <BrowseTree :browseTreeData="browseTreeData" />
    </template>
    <div
      v-if="isSearchLoading"
      class="c-spinner-wrapper"
      role="status"
      aria-live="polite">
      <img
        :src="spinnerImage"
        class="search-spinner"
        :class="testClass('loading-browse-standards')"
        alt="Loading">
    </div>
    <div v-if="searchErrorMsg">
      <div class="error-msg  u-mar-top-10" role="alert">
        {{ searchErrorMsg }}
      </div>
    </div>
    <div
      v-if="store.isFirstSearch"
      class="no-standards-shown">
      <vhl-icon-get-started
        class="magnifying-glass-icon"
        size="xxl" />
      <h3 class="no-standards-title">
        Begin Browse
      </h3>
    </div>
    <div
      v-if="store.matchedStandards?.length === 0"
      class="no-standards-shown">
      <vhl-icon-no-results-found
        class="magnifying-glass-icon"
        size="xxl" />
      <h3 class="no-standards-title">
        No Results Found
      </h3>
      <p
        class="u-txt-ctr"
        :class="testClass('empty-matching-standards')">
        Adjust your filters and try again
      </p>
    </div>
  </div>
</template>

<script setup>
  import { onMounted, ref } from 'vue';
  import { getFromEndpoint, testClass } from 'music';
  import Breadcrumb from './Breadcrumb';
  import BrowseStandardFilters from './BrowseStandardFilters';
  import BrowseTree from './BrowseTree';
  import spinnerImage from 'images/loading_32.gif';
  import useStandardsAssigningStore from
  'features/standards_assigning/models/use_standards_assigning_store';

  const props = defineProps({
    availableBrowseStdSets: { required: true, type: Array },
    availableGradeLevels: { required: true, type: Array },
    browseStandardUrl: { required: true, type: String },
  });

  const isSearchLoading = ref(false);
  const searchErrorMsg = ref(null);
  const browseTreeData = ref(null);
  const ajaxErrorMsg = `There was a problem processing your search. Please try again.
    If this problem continues, please contact technical support.`;
  const store = useStandardsAssigningStore();

  onMounted(() => {
    /**
     * If there is only one standard set available, automatically select it
     * and show the browse tree view.
     */
    if (props.availableBrowseStdSets?.length === 1) {
      const selectedSet = props.availableBrowseStdSets[0];
      store.setSelectedStandardSet({
        key: selectedSet.display_name,
        value: `${selectedSet.display_name} - ${selectedSet.name} (${selectedSet.adopt_year})`,
        vendor_guid: selectedSet.vendor_guid,
      });
      onBrowseNext();
    }
  });

  /**
   * Clear the previous search results and reset the search-related state in the store.
   */
  function clearStandardSearchResults() {
    store.selectedStandards = [];
    store.matchedStandards = null;
    searchErrorMsg.value = null;
  }

  /**
   * Hide browse tree view and reset the search-related state in the store.
   */
  function resetStandardSet() {
    store.setShowBrowseTree(false);
    clearStandardSearchResults();
    store.isFirstSearch = true;
  }

  /**
   * Get standards data based on standard set.
   * And update store with data and handle any errors.
   */
  function onBrowseNext() {
    isSearchLoading.value = true;
    store.isFirstSearch = false;
    clearStandardSearchResults();

    const standardSetGuid = store.selectedStandardSet?.vendor_guid;
    getFromEndpoint(
      `${props.browseStandardUrl}?standard_set_vendor_guid=${standardSetGuid}`,
      (data) => {
        isSearchLoading.value = false;
        loadBrowseTree(data);
      }
    );
  }

  /**
   * Update store with matched standards data based on
   * standard set and grade filters. And handle any errors.
   * @param {Object<string, object>} data Response from API
   */
  function loadBrowseTree(data) {
    if (data.error_message) {
      console.log(`Error in loadBrowseTree: ${data.error_message}`);
      searchErrorMsg.value = ajaxErrorMsg;
    } else if (data.matched_browse_standards) {
      let matchedStandards = data.matched_browse_standards;
      if (!matchedStandards) {
        console.log('Error: BrowseStandards API returns response without matched_browse_standards');
        matchedStandards = matchedStandards ?? [];
      }
      const matchedStandardsJson = JSON.stringify(matchedStandards);
      store.updateMatchedStandards(matchedStandardsJson, 'BROWSE');
      browseTreeData.value = matchedStandards;
      store.setShowBrowseTree(true);
    } else {
      searchErrorMsg.value = ajaxErrorMsg;
    }
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-spinner-wrapper {
    align-items: center;
    display: flex;
    justify-content: center;
    min-height: rpx(336);
  }

  .search-spinner {
    display: block;
  }

  .no-standards-shown {
    align-items: center;
    border-radius: rpx(16);
    display: flex;
    flex-direction: column;
    height: rpx(450);
    justify-content: center;
    margin-right: rpx(16);
    min-height: rpx(320);
    padding: rpx(64) rpx(48);

    .magnifying-glass-icon {
      margin: 0 rpx(32) rpx(40) 0;
    }

    .no-standards-title {
      font-size: rpx(18);
      margin: 0;
    }
  }

  .breadcrumb-wrapper {
    border-bottom: rpx(2) solid #e0e0e0;
    padding-bottom: rpx(3);
  }

  .error-msg {
    margin-left: rpx(50);
  }
</style>
