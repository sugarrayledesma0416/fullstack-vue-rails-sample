<template>
  <div
    v-if="store.focusedCriteriaIndex !== null"
    class="c-rubric-toolbar  u-bg-white">
    <div class="c-rubric-toolbar__wrapper">
      <button
        class="c-modal__close-button  c-no-button"
        @click="clearToolbarFocus">
        <span class="c-icon  c-icon--md  c-icon--close" />
        <span class="u-screen-reader-only">Close Rubric Criteria Details</span>
      </button>
      <table
        :class="testClass('rubric-toolbar-table')"
        class="c-table  c-rubric-toolbar__table">
        <thead>
          <tr
            :class="testClass('rubric-toolbar-col-headers')"
            class="c-header-row  u-bg-white">
            <th class="u-bord-0" />
            <th
              v-for="(header, index) in store.rubricColumnHeaders"
              :key="index"
              :ref="el => { headers[index] = el }"
              :class="testClass(`rubric-header-${header.label}`)"
              class="c-rubric-toolbar__header  u-txt-bold  u-bord-0"
              scope="col"
              :data-col-index="index"
              :data-criteria-title="store.rubricCriterias[store.focusedCriteriaIndex].title"
              :data-points-to-award="store.rubricCriterias[store.focusedCriteriaIndex].performances[index].score"
              @click="updateCriteriaPoints($event)"
              @mouseover="showHoverAffordance($event)"
              @mouseleave="hideHoverAffordance($event)">
              {{ header.label }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            class="c-row  u-bg-white">
            <th
              :class="testClass('rubric-toolbar-criteria-title')"
              class="title-header  u-bord-0  u-txt-bold">
              {{ store.rubricCriterias[store.focusedCriteriaIndex].title }}
            </th>
            <!-- eslint-disable vue/no-v-html -->
            <td
              v-for="(performance, index) in store.rubricCriterias[store.focusedCriteriaIndex].performances"
              :key="index"
              :ref="el => { performances[index] = el }"
              :class="testClass(`rubric-toolbar-description-${index}`)"
              :data-col-index="index"
              :data-criteria-title="store.rubricCriterias[store.focusedCriteriaIndex].title"
              :data-points-to-award="performance.score"
              class="c-rubric-toolbar__description  u-bord-0"
              @click="updateCriteriaPoints($event)"
              @mouseover="showHoverAffordance($event)"
              @mouseleave="hideHoverAffordance($event)"
              v-html="performance.description" />
            <!-- eslint-enable vue/no-v-html -->
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
  import { inject, ref } from 'vue';
  import { testClass } from 'music';

  const useStore = inject('useStore');
  const store = useStore();

/* These are cells within the rubric toolbar table,
   and are used to create a column hover effect. */
  const performances = ref([]);
  const headers = ref([]);

  /**
   * Clears the flag that determines which rubric criteria
   * to display in toolbar.
   */
  function clearToolbarFocus() {
    store.focusedCriteriaIndex = null;
    document.body.style.marginBottom = '0';
  }

 /**
  * @param {Object} event - the click event
  * Updates the points for the associated rubric criteria score.
  */
  function updateCriteriaPoints(event) {
    store.updateFocusedCriteriaPoints(event);
    store.updateTotalPoints();
  }
  
 /**
  * @param {Object} event - the mouseover event
  * Adds a class to style the column that is hovered over.
  */
  function showHoverAffordance(event) {
    const colIndex = event.target.getAttribute('data-col-index');
    headers.value[colIndex].classList.add('rubric-hoverable');
    performances.value[colIndex].classList.add('rubric-hoverable');
  }

 /**
  * @param {Object} event - the mouseleave event
  * Removes the class that styles the column hovered over.
  */
  function hideHoverAffordance(event) {
    const colIndex = event.target.getAttribute('data-col-index');
    headers.value[colIndex].classList.remove('rubric-hoverable');
    performances.value[colIndex].classList.remove('rubric-hoverable');
  }
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-rubric-toolbar {
    bottom: 0;
    box-shadow: 0 rpx(1) rpx(3) vhl-shadow(0.6);
    left: 0;
    position: fixed;
    width: 100%;
    z-index: 10;
  }

  .c-rubric-toolbar__wrapper {
    margin: 0 auto;
    max-height: rpx(170);
    overflow: auto;
    position: relative;
    width: rpx(960);
  }

  .c-rubric-toolbar__table {
    margin-bottom: 0px;
    min-height: rpx(170);
  }

  .c-rubric-toolbar__header {
    color: $link-color;
  }

  .c-rubric-toolbar__header, .c-rubric-toolbar__description {
    cursor: pointer;
    vertical-align: top;
  }

  .title-header {
    vertical-align: top;
  }

  .rubric-hoverable {
    background-color:$lightest-blue;
  }

  .c-modal__close-button {
    margin-top: rpx(-12);
  }
</style>
