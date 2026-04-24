<template>
  <div
    class="container"
    :class="testClass('browse-tree-container')">
    <sl-tree
      selection="multiple"
      class="tree"
      @sl-selection-change="handleSelectionChange">
      <TreeItem
        v-for="(node, index) in dataStore.treeData"
        :key="`${index}-${depth}`"
        class="first-level"
        :class="testClass('first-level')"
        :node="node"
        :depth="depth" />
    </sl-tree>
  </div>
</template>

<script setup>
  import { reactive } from 'vue';
  import { testClass } from 'music';
  import TreeItem from './TreeItem.vue';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';

  const props = defineProps({
    browseTreeData: { required: true, type: Object },
  });

  const dataStore = reactive({
    treeData: props.browseTreeData,
  });
  const store = useStandardsAssigningStore();
  const depth = 0;

  /**
   * Handle selection event on tree.
   * Update selected standards and count of standards in the store.
   * @param {Event} event
   */
  function handleSelectionChange(event) {
    const selectedGuids = event.detail?.selection?.map(
      (item) => item.getAttribute('guid')
    );
    store.selectedStandards.length = 0;
    [...selectedGuids].forEach((elm) => {
      store.selectedStandards.push(elm);
    });
    updateSelectionCounts();
  }

  /**
   * Count all selected nodes (leaf and non-leaf)
   * @param {Object} node - The node to count selected nodes for
   * @returns {number} - The count of selected nodes
   */
  function countSelectedNodes(node) {
    const { selectedStandards } = store;
    let isSelected = selectedStandards.includes(node.vendor_guid) ? 1 : 0;

    if (!node.children || node.children.length === 0) {
      return isSelected;
    }

    return isSelected + node.children.reduce((count, child) => {
      return count + countSelectedNodes(child);
    }, 0);
  }

  /**
   * Update selection counts for all nodes in the tree
   */
  function updateSelectionCounts() {
    dataStore.treeData.forEach(updateNodeCounts);
  }

  /**
   * Update the selected count for a given node and its children
   * @param {Object} node - The node to update counts for
   */
  function updateNodeCounts(node) {
    node.selectedCount = countSelectedNodes(node);
    node.children?.forEach(updateNodeCounts);
  }
</script>

<style lang="scss" scoped>
  @use 'music/app/styles/library/base';
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .container {
    margin: auto;
  }

  .first-level {
    background: none;
    font-size: rpx(18);
  }
</style>
