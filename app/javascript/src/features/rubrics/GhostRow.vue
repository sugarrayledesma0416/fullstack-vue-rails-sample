<template>
  <table
    ref="tableGhostRef"
    class="c-table  c-rubric-table  c-rubric-table--edit  c-rubric-table--ghost">
    <tbody>
      <tr
        class="c-row  c-row--with-gutter">
        <!-- editable row header -->
        <th
          scope="row"
          class="gutter--ghost">
          <div
            aria-live="polite"
            aria-atomic="true"
            class="gutter-actions-wrapper">
            <span class="u-screen-reader-only">Choose an action</span>
            <div
              class="l-line  l-line--justify  gutter-actions">
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
              </span>
              <!-- eslint-enable vue/no-v-html -->
            </div>
          </div>
        </th>
        <!-- editable row header -->
        <th
          scope="row"
          class="title-header  u-txt-bold  u-txt-top">
          <div class="header-container">
            <span class="header-text">
              {{ criteria.Criteria.title }}
            </span>
            <!-- eslint-disable vue/no-v-html -->
            <a
              href="javascript://"
              v-html="icons.edit" />
            <!-- eslint-enable vue/no-v-html -->
          </div>
        </th>
        <td
          v-for="performance in criteria.Criteria.performances"
          :key="performance.header_id"
          class="column-criteria">
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
  const rubric = inject('rubric');
  const tableGhostRef = ref(null);
  const selectedRowData = props.selectedCellData;

  const criteria = selectedRowData.criteria;

  const trContainer = rubric.targetContainer(selectedRowData.event.target, 'criteriaRow');
  const srcStyle = document.defaultView.getComputedStyle(trContainer);

  const width = srcStyle.getPropertyValue('width');
  const height = srcStyle.getPropertyValue('height');

  onMounted(() => {
    selectedRowData.event.dataTransfer
      .setDragImage(tableGhostRef.value, 0, 0);
  });

</script>

<style lang="scss" scoped>

  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  .ns-rubrics-preview.ns-music-v1 .c-rubric-table--ghost {
    --table-width: v-bind(`${width}`);
    --table-height: v-bind(`${height}`);

    position: absolute;
    top: -1000px;
    width: var(--table-width);
    height: var(--table-height);
  }

  .c-row--with-gutter .gutter--ghost {
    background-color: var(--white, $white);
    padding: 0;
    max-height: rpx(20);
    width: var(--col-gutter-width);
    max-width: var(--col-gutter-width);
    height: 0;

    .gutter-actions-wrapper {
      width: 100%;
      height: 100%;
    }

    .gutter-actions {
      flex-direction: column;
      padding: 0 0.25rem;
      height: 100%;
    }

  }

  .column-criteria {
    width: var(--col-width);
  }

  .title-header {
    width: var(--criterion-width);
  }

</style>
