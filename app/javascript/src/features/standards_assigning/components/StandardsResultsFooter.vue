<template>
  <div class="c-btn-group  standards-footer">
    <button
      class="c-btn  find-content-btn"
      :class="testClass('find-content')"
      :disabled="isApplyFilterDisabled"
      aria-label="Find Content"
      @click="applyFilter">
      <span>Find Content</span>
    </button>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import useStandardsAssigningStore from
  'features/standards_assigning/models/use_standards_assigning_store';

  defineEmits(['applyfilter']);
  const store = useStandardsAssigningStore();

  const isApplyFilterDisabled = computed(
    () => {
      return !store.anyRequiredFiltersSelected;
    }
  );
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-btn {
    border-radius: rpx(3);
    font-size: rpx(14);
    letter-spacing: rpx(1);
    line-height: rpx(24);
    margin-right: rpx(56);
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

  .find-btn {
    border: rpx(1) solid #ddd;
    padding: rpx(8) rpx(24);
    width: 100%;
  }

  .find-content-btn {
    background: #006bae;
    border: 0;
    box-shadow: rpx(1) rpx(4) rpx(6) rpx(0) rgba(0, 0, 0, 0.18);
    color: $white;
    min-width: rpx(128);
  }

  .find-content-btn:hover {
    background: #005a9c;
  }

  .find-content-btn:disabled {
    background: #ccc;
    box-shadow: none;
    color: $white;
  }

  .standards-footer {
    border-top: rpx(1) solid #EEEEEE;
    display: flex;
    margin-top: rpx(32);
    padding-top: rpx(10);
    position: relative;
    text-align: right;
  }
</style>
