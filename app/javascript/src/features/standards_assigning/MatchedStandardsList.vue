<template>
  <div class="c-form-item  matching-standards-list">
    <div v-if="!!store.matchedStandards?.length && !store.isFirstSearch">
      <label class="matching-standards-count  c-form-item__label  u-pad-bot-10  u-txt-bold">
        Matching Standards ({{ store.matchedStandards.length }})
      </label>
      <div
        class="standard-results"
        role="list">
        <div
          v-for="(standard, index) in store.matchedStandards"
          id="standard-select"
          :key="`matched-standard-${index}`"
          class="standard-results-item  u-bord-bot-1"
          :class="{ 'c-selected-box': selectedStandards.flat().includes(standard.vendor_guid) }"
          role="listitem">
          <input
            :id="`matched-standard-${index}`"
            v-model="selectedStandards"
            class="standard-input  c-form-item__checkbox"
            :class="testClass(`matched-standard-${index}`)"
            :value="standard.vendor_guid"
            type="checkbox">
          <label
            class="c-form-item__label  u-txt-16  u-txt-gray-3"
            :class="testClass(`matched-standard-label-${index}`)"
            :for="`matched-standard-${index}`">
            <span class="u-txt-bold">{{ standard.display_number }}</span>
            <br>
            {{ standard.description }}
          </label>
        </div>
      </div>
    </div>
    <div v-if="!isSearchLoading">
      <div
        v-if="isFirstSearch"
        class="no-standards-shown">
        <vhl-icon-get-started
          class="magnifying-glass-icon"
          size="xxl" />
        <h3 class="no-standards-title">
          Begin Search
        </h3>
      </div>

      <div
        v-if="store.matchedStandards?.length == 0"
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
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import useStandardsAssigningStore from './models/use_standards_assigning_store.js';
  import { storeToRefs } from 'pinia';

  const store = useStandardsAssigningStore();

  const { isSearchLoading, isFirstSearch, selectedStandards } = storeToRefs(store);
</script>

<style lang="scss" scoped>
  @use '~MusicAssets/stylesheets/music/library/v1/base/main' as *;

  .c-selected-box {
    --selected-standard-background-color: #FEF3D5;
    background-color: var(--selected-standard-background-color);
  }

  .matching-standards-list {
    overflow: hidden;
  }

  .matching-standards-count {
    font-weight: bold;
    padding-bottom: 10px;
    text-transform: capitalize;
  }

  .standard-results {
    border: thin solid $gray-c;
    position: relative;
  }

  .standard-results-item {
    border-color: $gray-e;
    padding: rpx(8);
  }

  .no-standards-shown {
    align-items: center;
    border-radius: rpx(16);
    display: flex;
    flex-direction: column;
    height: rpx(450);
    justify-content: center;
    margin-top: rpx(50);
    min-height: rpx(320);
    padding: rpx(64) rpx(48);

    .magnifying-glass-icon {
      margin: 0 rpx(32) rpx(40) 0;
    }

    .no-standards-title {
      margin: 0;
      font-size: rpx(18);
    }
  }
</style>
