<template>
  <div>
    <div class="c-search-terms">
      <div class="c-form-item-group">
        <div class="c-form-item">
          <label
            class="c-form-item-label"
            for="standard-set-select">
            Select Standard Set
          </label>
          <BrowseDropdown
            id="standard-set-select"
            v-model="selectedStandardSet"
            class="c-std-set-dropdown"
            :class="testClass('standard-set-select')"
            :options="availableStdSetOptions"
            :placeholder="'Select Standard Set'"
            aria-label="Select Standard Set" />
        </div>
        <div class="c-form-item  search-term-input-wrapper">
          <label
            class="c-form-item-label"
            for="search-term-input">
            Search by Keywords
          </label>
          <input
            id="search-term-input"
            v-model="searchTerm"
            class="search-standard-input"
            :class="testClass('search-term-input')"
            type="text"
            placeholder="Enter topic or standard code"
            maxLength="256"
            aria-label="Search by Keywords"
            @keyup.enter="!isSearchDisabled && searchStandards()">
        </div>
        <div class="find-btn-wrapper">
          <StandardButton
            variant="border"
            :class="testClass('find-btn')"
            :disabled="isSearchDisabled"
            aria-label="Search Standards"
            @click="searchStandards">
            Search
          </StandardButton>
        </div>
      </div>
    </div>
    <div
      v-if="isSearchLoading"
      class="c-spinner-wrapper"
      role="status"
      aria-live="polite">
      <img
        :src="spinnerImage"
        class="search-spinner"
        :class="testClass('save-spinner')"
        alt="Loading">
    </div>
    <div v-if="searchErrorMsg">
      <div class="u-mar-top-10" role="alert">
        {{ searchErrorMsg }}
      </div>
    </div>
    <MatchedStandardsList :class="testClass('matched-standards')" />
  </div>
</template>

<script setup>
  import { ref, computed } from 'vue';
  import { StandardButton, testClass } from 'music';
  import { putToEndpoint } from 'shared/ajax_utils';
  import { storeToRefs } from 'pinia';
  import BrowseDropdown from './components/BrowseDropdown';
  import MatchedStandardsList from 'features/standards_assigning/MatchedStandardsList';
  import spinnerImage from 'images/loading_32.gif';
  import useStandardsAssigningStore from './models/use_standards_assigning_store.js';

  const store = useStandardsAssigningStore();
  const props = defineProps({
    availableSets: { required: true, type: Array },
    searchStandardsEndpoint: { required: true, type: String },
  });
  const { selectedStandards } = storeToRefs(store);

  const ajaxErrorMsg = `There was a problem processing your search. Please try again.
                        If this problem continues, please contact technical support.`;

  const searchTerm = ref(null);
  const searchErrorMsg = ref(null);

  const selectedStandardSet = computed({
    get: () => store.selectedStandardSet?.value,
    set: (value) => {
      store.setSelectedStandardSet(value);
    },
  });

  /**
   * Get options for standard set dropdown in the format of {key,value}.
   * @return {Array<object>}
   */
  const availableStdSetOptions = computed(() => {
    return props.availableSets?.map((item)=> {
      return {
        key: item.display_name,
        value: `${item.display_name} - ${item.name} (${item.adopt_year})`,
        vendor_guid: item.vendor_guid,
      };
    });
  });

  const isSearchDisabled = computed(
    () => {
      return !store.selectedStandardSet || isSearchInputEmpty.value;
    }
  );

  const isSearchInputEmpty = computed(
    () => {
      return searchTerm.value === null || searchTerm.value === '';
    }
  );

  const isSearchLoading = ref(false);

  /**
   * Performs a search for standards based on the selected standard set and search term.
   * Updates the store with the matched standards or sets an error message if the search fails.
  */
  function searchStandards() {
    initializeSearch();
    store.isFirstSearch = false;

    putToEndpoint(
      props.searchStandardsEndpoint,
      {
        standard_set_vendor_guid: store.selectedStandardSet?.vendor_guid,
        search_term: searchTerm.value,
      },
      (result) => {
        isSearchLoading.value = false;
        if (result.error_message) {
          console.log(`Error in searchStandards. Error: ${result.error_message}`);
          searchErrorMsg.value = ajaxErrorMsg;
        } else if (result.matched_standards) {
          store.updateMatchedStandards(result.matched_standards);
        } else {
          searchErrorMsg.value = ajaxErrorMsg;
        }
      });
  }

  /**
   * Initializes the search by setting the loading state and clearing previous search results.
  */
  function initializeSearch() {
    isSearchLoading.value = true;
    clearSearchResults();
  }

  /**
   * Clear the previous search results and reset the search-related state in the store.
  */
  function clearSearchResults() {
    store.isFirstSearch = true;
    selectedStandards.value = [];
    store.matchedStandards = null;
    searchErrorMsg.value = null;
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-btn {
    border-radius: rpx(3);
    font-size: rpx(14);
    letter-spacing: rpx(1);
    line-height: rpx(24);
    padding: rpx(8) rpx(24);
    text-transform: uppercase;
  }

  .c-btn:disabled {
    cursor: not-allowed;
  }

  .c-btn-group {
    align-items: flex-start;
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
    gap: rpx(8);
    justify-content: flex-end;
    margin-bottom: rpx(16);
  }

  .c-form-item {
    margin-bottom: rpx(8);
    margin-right: rpx(16);
  }

  .c-form-item-group {
    margin: 0 rpx(16) 0 0;
  }

  .c-form-item-label {
    color: $lightest-text;
    display: block;
    font-size: rpx(14);
    font-weight: 400;
    letter-spacing: rpx(1);
    margin-left: rpx(10);
    margin-right: 0;
    text-transform: uppercase;
  }

  .c-search-terms {
    justify-content: space-between;
    padding-bottom: rpx(24);
    padding-left: 0;
    padding-top: rpx(5);

    @include viewport-max('sm') {
      flex-wrap: wrap;
    }
  }

  .c-spinner-wrapper {
    align-items: center;
    display: flex;
    justify-content: center;
    min-height: rpx(336);
  }

  .capitalize-text {
    text-transform: capitalize;
  }

  .find-btn-wrapper {
    margin-bottom: rpx(3);
  }

  .search-spinner {
    display: block;
    left: 50%;
    margin: rpx(20) auto 0;
    top: 50%;
    transform: translate(-50%, -50%);
  }

  .search-term-input-wrapper {
    margin-bottom: 0;
    width: rpx(265);
  }

  .search-standard-input {
    background: $white;
    border: rpx(1) solid #ddd;
    border-radius: rpx(3);
    box-shadow: inset 0 rpx(1) rpx(3) rpx(0) rgba(0, 0, 0, 0.1);
    box-sizing: border-box;
    display: inline-block;
    font-size: rpx(14);
    height: rpx(56);
    line-height: rpx(24);
    margin: rpx(0);
    min-width: rpx(128);
    padding: rpx(8);
    vertical-align: top;
    width: 100%;
    height: rpx(56);
  }

  .standard-set-select {
    width: rpx(235);
  }

  :deep(.modock__box) {
    width: 100%;
  }

  .c-std-set-dropdown {
    height: rpx(48);
    width: rpx(235);
  }
</style>
