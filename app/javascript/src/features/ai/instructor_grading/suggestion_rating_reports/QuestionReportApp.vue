<template>
  <div>
    <VueAwesomePaginate
      v-model="store.currentPage"
      v-if="store.options.showPagination"
      :itemsPerPage="1"
      :maxPagesShown="3"
      :showBreakpointButtons="false"
      :showEndingButtons="true"
      :hidePrevNextWhenEnds="true"
      :totalItems="store.studentResponses.length"
      @click="store.selectPage">
    </VueAwesomePaginate>
    <span
      v-if="store.loadingMoreData">
      Loading...
    </span>
    <div class="c-box  c-box--bubble-wrap">
      <div
        v-if="store.currentPageInput"
        class="l-grid">
        <div class="l-col-6">
          <div
            v-if="store.options.showPagination"
            class="u-txt-bold">
            <a
              id="page-url-link"
              :href="`?attempt_id=${store.currentPageInput.attemptId}`">
              Student Answer:
            </a>
            <tippy id="page-url-link-tooltip" content="copied!" trigger="manual">
              <MusicIcon
                @click="copyPageUrl"
                variant="copy" />
            </tippy>
          </div>
          <div v-else class="u-txt-bold">
            Student Answer:
          </div>
          <!-- eslint-disable vue/no-v-html -->
          <div v-html="store.currentPageInput.studentResponse" />
          <!-- eslint-enable vue/no-v-html -->
        </div>
        <div class="l-col-6">
          <div
            v-if="store.currentPageInput && store.currentPageInput.overallComments.length"
            class="c-box  c-box--bubble-wrap">
            <h2 class="u-txt-bold">
              Overall Feedback:
            </h2>
            <div
              v-for="overallComment in store.currentPageInput.overallComments"
              :key="overallComment.id">
              <OverallComment :overallComment="overallComment" />
            </div>
          </div>
          <div
            v-if="store.currentPageInput && store.currentPageInput.gradingSuggestions.length"
            class="c-box  c-box--bubble-wrap">
            <h2 class="u-txt-bold">
              Suggestions:
            </h2>
            <ol>
              <li
                v-for="gradingSuggestion in store.currentPageInput.gradingSuggestions"
                :key="gradingSuggestion.id">
                <GradingSuggestion :gradingSuggestion="gradingSuggestion" />
              </li>
            </ol>
          </div>
        </div>
      </div>
      <div v-else-if="store.loadingMoreData">
        Loading...
      </div>
      <div v-else>
        No Student answer.
      </div>
    </div>
  </div>
</template>

<script setup>
  import { VueAwesomePaginate } from 'vue-awesome-paginate';
  import 'vue-awesome-paginate/dist/style.css';
  import OverallComment from './components/OverallComment';
  import GradingSuggestion from './components/GradingSuggestion';
  import { storeToRefs } from 'pinia';
  import useQuestionReportStore from './models/question_report_store';
  import MusicIcon from 'shared/vue/MusicIcon';
  import { Tippy } from 'vue-tippy';
  import 'tippy.js/dist/tippy.css';

  const props = defineProps({
    ratingCategories: {
      required: true,
      type: String
    },
    studentResponses: {
      required: true,
      type: String
    },
    loadMoreUrl: {
      required: true,
      type: String,
    },
    gradingSuggestionPrompts: {
      required: true,
      type: String
    },
    overallCommentPrompts: {
      required: true,
      type: String
    },
    options: {
      required: true,
      type: String
    },
  });

  const store = useQuestionReportStore();

  store.init({
    ratingCategories: JSON.parse(props.ratingCategories),
    studentResponses: JSON.parse(props.studentResponses),
    loadMoreUrl: props.loadMoreUrl,
    gradingSuggestionPrompts: JSON.parse(props.gradingSuggestionPrompts),
    overallCommentPrompts: JSON.parse(props.overallCommentPrompts),
    options: JSON.parse(props.options),
  });
  store.selectPage(store.currentPage);
            
  let hideCopyPageUrlTooltipTimeout = null;
  function copyPageUrl() {
    const link = document.getElementById('page-url-link');
    navigator.clipboard.writeText(link.href);

    // Show the "copied!" tooltip.
    const tooltipElm = document.getElementById('page-url-link-tooltip');
    const tippy = tooltipElm._tippy;
    tippy.show();
    if (hideCopyPageUrlTooltipTimeout) {
      clearTimeout(hideCopyPageUrlTooltipTimeout);
    }
    hideCopyPageUrlTooltipTimeout = setTimeout(() => {
      tippy.hide();
    }, 2000);
  }
</script>

<style lang="scss">
  .pagination-container {
    display: flex;
    column-gap: rpx(10);
    list-style-type: none;
    padding: 0 !important;
  }
  
  ul#componentContainer .paginate-buttons {
    height: 40px;
    width: 40px;
    border-radius: 20px;
    cursor: pointer;
    background-color: rgb(242, 242, 242);
    border: 1px solid rgb(217, 217, 217);
    color: black;
  }
  
  ul#componentContainer .paginate-buttons.active-page {
    background-color: #3498db;
    border: 1px solid #3498db;
    color: white;
  }

  ul#componentContainer .paginate-buttons:hover {
    background-color: #d8d8d8;
  }

  ul#componentContainer .active-page:hover {
    background-color: #2988c8;
  }
</style>
