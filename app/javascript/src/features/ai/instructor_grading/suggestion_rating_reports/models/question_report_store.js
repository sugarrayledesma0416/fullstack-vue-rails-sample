import { defineStore } from 'pinia';
import StudentResponse from './student_response';
import * as ajaxUtils from 'shared/ajax_utils';

const useQuestionReportStore = defineStore(
  'questionReportStore',
  {
    state: () => ({
      currentPage: 1,
      currentPageInput: null,
      loadMoreUrl: null,
      loadingMoreData: false,
    }),
    actions: {
      init({
        ratingCategories,
        studentResponses,
        loadMoreUrl,
        gradingSuggestionPrompts,
        overallCommentPrompts,
        options,
      }) {
        this.studentResponses = studentResponses.map(
          (attrs) => new StudentResponse({
            ...attrs,
            ratingCategories: ratingCategories,
            gradingSuggestionPrompts: gradingSuggestionPrompts,
            overallCommentPrompts: overallCommentPrompts,
          })
        );
        this.ratingCategories = ratingCategories;
        this.gradingSuggestionPrompts = gradingSuggestionPrompts;
        this.overallCommentPrompts = overallCommentPrompts;
        this.loadMoreUrl = loadMoreUrl;
        this.options = options;
      },

      selectPage(page) {
        if (page <= this.studentResponses.length) {
          // The page is already loaded, select it
          this.currentPage = page;
          this.currentPageInput = this.studentResponses[page - 1];
        }
        if ((!this.currentPageInput || this.currentPage >= this.studentResponses.length - 1) && this.loadMoreUrl) {
          // No page loaded, or displaying the last page, fetch more data.
          this.loadMoreStudentResponses();
        }
      },

      async loadMoreStudentResponses() {
        this.loadingMoreData = true;
        try {
          ajaxUtils.getFromEndpoint(
            this.loadMoreUrl,
            (data) => {
              if (data.errors) {
                console.log('Failed to load more results:', data.errors);
                this.loadingMoreData = false;
              } else {
                this.loadMoreUrl = data.nextUrl;
                data.entries.forEach(
                  (entry) => this.studentResponses.push(
                    new StudentResponse({
                      ...entry,
                      ratingCategories: this.ratingCategories,
                      gradingSuggestionPrompts: this.gradingSuggestionPrompts,
                      overallCommentPrompts: this.overallCommentPrompts,
                    })
                  )
                );
                this.loadingMoreData = false;
                this.selectPage(this.currentPage);
              }
            }
          );
        } catch (error) {
          console.log('Failed to load more results:', error);
          this.loadingMoreData = false;
        }
      },
    }
  }
);

export default useQuestionReportStore;
