<template>
  <div>
    <VueAwesomePaginate
      v-model="currentPage"
      :itemsPerPage="1"
      :maxPagesShown="1"
      :showBreakpointButtons="false"
      :totalItems="store.gradingSuggestionInputs.length"
      @click="selectPage" />
    <div class="c-box  c-box--bubble-wrap">
      <div
        v-if="data.currentPageInput"
        class="l-grid">
        <div class="l-col-6">
          <div class="u-txt-bold">
            Student Answer:
          </div>
          <!-- eslint-disable vue/no-v-html -->
          <div v-html="data.currentPageInput.studentResponse" />
          <!-- eslint-enable vue/no-v-html -->
        </div>
        <div class="l-col-6">
          <div>
            <h2 class="u-txt-bold">
              Overall Feedback:
            </h2>
            <div
              v-if="data.currentPageInput && data.currentPageInput.overallComments.length">
              <div
                v-for="overallComment in data.currentPageInput.overallComments"
                :key="overallComment.id">
                <OverallComment :overallComment="overallComment" />
              </div>
            </div>
            <div v-else>
              No overall comment available.
            </div>
          </div>
          <div>
            <h2 class="u-txt-bold">
              Suggestions:
            </h2>
            <ol
              v-if="data.currentPageInput && data.currentPageInput.gradingSuggestions.length">
              <li
                v-for="gradingSuggestion in data.currentPageInput.gradingSuggestions"
                :key="gradingSuggestion.id">
                <GradingSuggestion :gradingSuggestion="gradingSuggestion" />
              </li>
            </ol>
            <div v-else>
              No suggestion available.
            </div>
          </div>
        </div>
      </div>
      <div v-else>
        No Student answer.
      </div>
    </div>
    <VueAwesomePaginate
      v-model="currentPage"
      :itemsPerPage="1"
      :maxPagesShown="1"
      :showBreakpointButtons="false"
      :totalItems="store.gradingSuggestionInputs.length"
      @click="selectPage" />
  </div>
</template>

<script setup>
  import { reactive, ref } from 'vue';
  import { VueAwesomePaginate } from 'vue-awesome-paginate';
  import "vue-awesome-paginate/dist/style.css";
  import OverallComment from './components/OverallComment';
  import GradingSuggestion from './components/GradingSuggestion';
  import { storeToRefs } from 'pinia';
  import useQuestionRatingStore from './models/question_rating_store';

  const props = defineProps({
    /**
     * The raw data for all grading suggestion inputs.
     */
    gradingSuggestionInputs: {
      required: true,
      type: String
    },
    rateGradingSuggestionUrl: {
      required: true,
      type: String,
    },
    acceptGradingSuggestionRatingCategoryId: {
      required: true,
      type: String
    },
    rejectGradingSuggestionRatingCategoryId: {
      required: true,
      type: String
    },
    rateOverallCommentUrl: {
      required: true,
      type: String,
    },
    acceptOverallCommentRatingCategoryId: {
      required: true,
      type: String
    },
    rejectOverallCommentRatingCategoryId: {
      required: true,
      type: String
    },
  });

  let currentPage = ref(1);
  const data = {
    currentPageInput: null,
  };

  const store = useQuestionRatingStore();

  const selectPage = (page) => {
    data.currentPageInput = store.gradingSuggestionInputs[page - 1];
  };

  store.init({
    gradingSuggestionInputsAttrs: JSON.parse(props.gradingSuggestionInputs),
    acceptGradingSuggestionRatingCategoryId: Number(props.acceptGradingSuggestionRatingCategoryId),
    rejectGradingSuggestionRatingCategoryId: Number(props.rejectGradingSuggestionRatingCategoryId),
    rateGradingSuggestionUrl: props.rateGradingSuggestionUrl,
    acceptOverallCommentRatingCategoryId: Number(props.acceptOverallCommentRatingCategoryId),
    rejectOverallCommentRatingCategoryId: Number(props.rejectOverallCommentRatingCategoryId),
    rateOverallCommentUrl: props.rateOverallCommentUrl,
  });
  selectPage(currentPage.value);
</script>

<style lang="scss" scoped>
  .pagination-container {
    display: flex;
    column-gap: 10px;
  }

  .paginate-buttons {
    height: 40px;
    width: 40px;
    border-radius: 20px;
    cursor: pointer;
    background-color: rgb(242, 242, 242);
    border: 1px solid rgb(217, 217, 217);
    color: black;
  }

  .paginate-buttons:hover {
    background-color: #d8d8d8;
  }

  .active-page {
    background-color: #3498db;
    border: 1px solid #3498db;
    color: white;
  }

  .active-page:hover {
    background-color: #2988c8;
  }
</style>
