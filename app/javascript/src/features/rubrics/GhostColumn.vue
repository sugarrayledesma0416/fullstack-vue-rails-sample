<template>
  <table
    ref="tableGhostRef"
    class="c-table  c-rubric-table  c-rubric-table--edit  c-rubric-table--ghost">
    <thead>
      <!-- gutter column header -->
      <tr class="c-header-row  c-header-row--gutter">
        <th
          class="gutter--ghost"
          scope="col">
          <div
            aria-live="polite"
            aria-atomic="true">
            <span class="u-screen-reader-only">Choose an action</span>
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="l-line  l-line--justify  gutter-actions">
              <!-- eslint-enable vue/no-v-html -->
              <!-- eslint-disable vue/no-v-html -->
              <span>
                <a
                  href="javascript://"
                  class="gutter-actions__icon"
                  v-html="icons.add" />
              </span>
              <span>
                <a
                  href="javascript://"
                  class="gutter-actions__icon"
                  v-html="icons.delete" />
              </span>
              <span>
                <a
                  href="javascript://"
                  class="gutter-actions__icon"
                  v-html="icons.add" />
              <!-- eslint-enable vue/no-v-html -->
              </span>
            </div>
          </div>
        </th>
      </tr>
      <!-- editable column header -->
    </thead>
    <tbody>
      <tr class="c-header-row  c-header-row--ghost">
        <th
          class="column-criteria"
          scope="col">
          <div class="header-container">
            <span class="header-text">
              {{ headerColumn.label }}
            </span>
            <!-- eslint-disable vue/no-v-html -->
            <a
              href="javascript://"
              v-html="icons.edit" />
            <!-- eslint-enable vue/no-v-html -->
          </div>
        </th>
      </tr>
      <tr
        v-for="(performance, idx) in selectedColumnData.performances"
        :key="idx"
        class="c-row  c-row--with-gutter">
        <td>
          <!-- eslint-disable vue/no-v-html -->
          <span v-html="performance.description" />
          <!-- eslint-enable vue/no-v-html -->
          <div>
            <span class="u-txt-bold">
              Points: {{ performance.score }}
            </span>
            <!-- eslint-disable vue/no-v-html -->
            <a
              href="javascript://"
              v-html="icons.edit" />
            <!-- eslint-enable vue/no-v-html -->
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script setup>
  import { ref, inject, onMounted } from 'vue';

  const props = defineProps(
    {
      selectedCellData: { required: true, type: Object },
    }
  );
  const icons = inject('icons');
  const tableGhostRef = ref(null);
  const selectedColumnData = props.selectedCellData;

  const headerColumn = selectedColumnData.header;
  const srcStyle = document.defaultView.getComputedStyle(event.target.parentNode);
  const width = srcStyle.getPropertyValue('width');

  onMounted(() => {
    selectedColumnData.event.dataTransfer
      .setDragImage(tableGhostRef.value, 0, 0);
  });

</script>

<style lang="scss" scoped>

  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .ns-rubrics-preview.ns-music-v1 .c-rubric-table--ghost {
    --table-width: v-bind(`${width}`);
    position: absolute;
    top: -1000px;
    width: var(--table-width);
  }

  .c-header-row--gutter .gutter--ghost {
    background-color: var(--white, $white);
    padding: 0;
    height: rpx(20);
    max-height: rpx(20);
    position: static;
  }

  .ns-rubrics-preview .c-header-row--ghost th {
    position: static;
  }

</style>
