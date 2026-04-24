<template>
  <div class="browse-standard-filters">
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
        :options="availableBrowseStdSetOptions"
        :placeholder="'Select Standard Set'"
        aria-label="Select Standard Set" />
    </div>
    <div class="c-next-btn-wrapper">
      <StandardButton
        variant="border"
        :class="testClass('find-browse-std')"
        :disabled="isNextDisabled"
        aria-label="Next Button for Browse Standard"
        @click="emit('next')">
        Next
      </StandardButton>
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { StandardButton, testClass } from 'music';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';
  import BrowseDropdown from './BrowseDropdown';

  const props = defineProps({
    availableBrowseStdSets: { required: true, type: Array },
  });

  /**
   * Get options for standard set dropdown in the format of {key,value}.
   * @return {Array<object>}
   */
  const availableBrowseStdSetOptions = computed(() => {
    return props.availableBrowseStdSets?.map((item)=> {
      return {
        key: item.display_name,
        value: `${item.display_name} - ${item.name} (${item.adopt_year})`,
        vendor_guid: item.vendor_guid,
      };
    });
  });

  const emit = defineEmits(['next']);
  const store = useStandardsAssigningStore();

  const selectedStandardSet = computed({
    get: () => store.selectedStandardSet?.value,
    set: (value) => {
      store.setSelectedStandardSet(value);
    },
  });

  const isNextDisabled = computed(() => {
    return !store.selectedStandardSet;
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .browse-standard-filters {
    display: flex;
    margin-bottom: rpx(45);
    margin-left: rpx(50);
    margin-top: rpx(30);
  }

  .c-form-item {
    margin-bottom: 0;
    margin-right: rpx(16);
  }

  .c-form-item-label {
    color: #666;
    display: block;
    font-size: rpx(14);
    font-weight: 400;
    letter-spacing: rpx(1);
    margin-right: 0;
    margin-left: rpx(15);
    text-transform: uppercase;
  }

  .c-next-btn-wrapper {
    margin-right: rpx(16);
    margin-top: rpx(46);
  }

  .c-grade-level-dropdown,
  .c-std-set-dropdown {
    height: rpx(48);
    width: rpx(235);
  }
</style>
