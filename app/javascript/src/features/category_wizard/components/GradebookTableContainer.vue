<template>
  <div class="gradebook-table-container">
    <div class="u-mar-bot-20">
      <StandardButton
        ref="addCategoryBtn"
        class="add-category-btn"
        :class="testClass('add-category-btn')"
        variant="primary"
        type="button"
        @click="$emit('openAddCategory')">
        Add Category
      </StandardButton>
      <div hidden>
        <span
          ref="addCategoryBtnHover"
          class="add-category-btn-hover"
          :class="testClass('add-category-btn-hover')">
          Click here to begin adding categories to your gradebook.
        </span>
      </div>
    </div>
    <div class="recording-spinner">
      <img :src="spinnerImage">
    </div>
    <div class="gradebook-category-summary">
      <GradebookTable
        class="gradebook-table-comp"
        @openEditCategory="$emit('openEditCategory', $event)" />
      <CategoryWeightGraph class="category-weight-graph-comp" />
    </div>
  </div>
</template>

<script setup>
  import { inject, onMounted, ref } from 'vue';
  import { StandardButton, testClass } from 'music';
  import spinnerImage from 'images/loading_32.gif';
  import GradebookTable from './GradebookTable';
  import CategoryWeightGraph from './CategoryWeightGraph';
  import tippy from 'tippy.js';

  const emit = defineEmits(['openAddCategory', 'openEditCategory']);
  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
  const addCategoryBtn = ref(null);
  const addCategoryBtnHover = ref(null);

  onMounted(() => {
    tippy(
      '.gradebook-table-container .add-category-btn',
      {
        allowHTML: true,
        content: addCategoryBtnHover.value.outerHTML,
        showOnCreate: true,
      }
    );
  });
</script>

<style lang="css">
  @import 'tippy.js/dist/tippy';
</style>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .gradebook-table-container {
    padding: rpx(20);
    position: relative;
  }

  .recording-spinner {
    display: none;
    left: rpx(140);
    position: absolute;
    top: rpx(18);
  }
  .gradebook-table-comp {
    display: flex;
  }
  .category-weight-graph-comp {
    float: right;
  }

  .gradebook-category-summary {
    display: flex;
    justify-content: space-between;
  }
</style>
