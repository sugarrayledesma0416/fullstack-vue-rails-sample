<template>
  <sl-tree-item
    class="browse-tree"
    :guid="node.vendor_guid"
    :style="{ '--depth': depth }"
    :class="`depth-${depth}`">
    <div part="label">
      <div
        class="row-content"
        :class="[getLayerClass(depth),
                 { 'leaf-node': isLeafNode }
        ]">
        <span
          v-if="!isLeafNode"
          class="standard-label">
          <span v-if="node.number">{{ node.number }}</span>
          <span
            v-if="hasSelectedCount && (node.number && !isStrandWithDescription)"
            class="selected-standard-count">
            {{ node.selectedCount }} selected
          </span>
          <span
            v-if="node.description"
            :class="isStrandWithDescription
              ? 'strand-description'
              : (node.number && node.description
                ? 'standard-description'
                : '')">
            <span>
              {{ node.description }}
            </span>
          </span>
          <span
            v-if="hasSelectedCount && (!node.number || isStrandWithDescription)"
            class="selected-standard-count">
            {{ node.selectedCount }} selected
          </span>
        </span>
        <div
          v-if="isLeafWithData"
          class="standard-details">
          <div class="standard-info-text">
            <span
              v-if="node.number"
              class="standard-number">
              {{ node.number }}
            </span>
            <span
              v-if="node.description"
              class="standard-description">
              {{ node.description }}
            </span>
          </div>
        </div>
      </div>
    </div>
    <template v-if="node.children?.length">
      <TreeItem
        v-for="(child, index) in node.children"
        :key="`${index}-${depth}`"
        :node="child"
        :depth="depth + 1" />
    </template>
  </sl-tree-item>
</template>

<script setup>
  import { computed, defineProps } from 'vue';

  const props = defineProps({
    depth: {
      type: Number,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
  });

  const isLeafNode = computed(() => !props.node.children || props.node.children.length === 0);
  const isLeafWithData = computed(() => {
    return isLeafNode.value && (props.node.number || props.node.description);
  });
  const isStrandWithDescription = computed(() => {
    return props.depth === 0 && props.node.description;
  });
  const hasSelectedCount = computed(() => {
    return props.node.selectedCount > 0;
  });


  /**
   * Returns CSS class based on depth for alternating row colors
   * @param {number} depth - The depth level of the tree item
   * @return {string} The CSS class name for the depth layer
   */
  function getLayerClass(depth) {
    const levelClasses = ['level-1', 'level-2', 'level-3', 'level-4', 'level-5'];
    return levelClasses[depth % 5] || '';
  }
</script>

<style lang="scss" scoped>
  @use 'music/app/styles/library/base';
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  sl-tree-item:focus,
  sl-tree-item:focus-visible {
    outline: 0 !important;
  }

  sl-tree-item::part(base):focus-visible {
    overflow: visible;
  }

  sl-tree-item::part(indentation) {
    width: 0;
  }

  sl-tree-item::part(expand-button) {
    color: #006BAE;
    left: 92%;
    padding: var(--sl-spacing-x-small);
    position: relative;
    transform: rotate(90deg) scale(1.5);
    transform-origin: center;
    width: rpx(20);
  }

  sl-tree-item[expanded]::part(expand-button) {
    transform: rotate(180deg) scale(1.5);
  }

  sl-tree-item::part(item) {
    border-inline-start-color: transparent;
    border-bottom: rpx(1) solid #e0e0e0;
    margin-left: calc(rpx(30)*var(--depth));
    padding-bottom: rpx(5);
    padding-top: rpx(10);
  }

  sl-tree-item::part(item--selected) {
    /*background-color: transparent;*/
  }

  sl-tree-item[selected]::part(item) {
    background-color: #fef3d5;
  }

  .browse-tree {
    cursor: default;
  }

  .standard-description {
    color: #000000;
    display: flex;
    font-size: rpx(14);
    line-height: 1.2;
    margin-top: rpx(2);
    padding-top: rpx(2);;
  }

  .strand-description {
    padding-left: rpx(10);
  }

  .selected-standard-count {
    font-size: rpx(14);
    margin-left: rpx(70);
  }

  .row-content {
    align-items: center;
    box-sizing: border-box;
    display: flex;
    padding: rpx(15);
    padding-left: rpx(8);
  }

  .top-level.row-content {
    border-bottom: none;
  }

  .standard-details {
    align-items: center;
    display: flex;
    font-family: 'Open Sans', sans-serif;
    justify-content: space-between;
    width: 100%;
  }

  .standard-info-text {
    align-items: flex-start;
    display: flex;
    flex-direction: column;
    width: 100%;
  }

  .standard-label {
    color: #000;
    font-family: 'Open Sans', sans-serif;
    font-size: rpx(16);
    font-weight: 400;;
    line-height: normal;
    padding-right: rpx(72);
    width: 100%;
  }

  .standard-number {
    font-weight: bold;
    line-height: 1.2;
  }

  .depth-1::part(item) {
    background-color: #F0F8FC;
  }
  .depth-2::part(item) {
    background-color: #DBECF8;
  }
  .depth-3::part(item) {
    background-color: #AFDAF6;
  }
  .depth-4::part(item) {
    background-color: #83CAF6;
  }
</style>
