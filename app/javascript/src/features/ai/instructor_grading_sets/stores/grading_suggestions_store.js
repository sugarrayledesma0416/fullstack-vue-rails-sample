import { defineStore } from 'pinia';
import { GradingSuggestionsAppModel } from '../models/grading_suggestions_app_model';
import { toggleAIGradingSuggestions } from '../api/toggle_ai_grading_suggestions';

export const useGradingSuggestionsStore = defineStore(
  'grading_suggestions',
  {
    state: () => ({
      /**
       * The page spawns a number of feedback apps, each with its own state.
       */
      apps: [],
      showDisableSuggestionsConfirmation: false,
      suggestionsEnabled: null,
      suggestionsEnabledAtProgramLevel: false,
    }),
    getters: {
      getApp: (state) => {
        return (id) => state.apps.find((app) => app.id === id);
      },
      getSuggestion: (state) => {
        return (appId, suggestionId) => {
          // This repeats the getApp getter.  Pinia should support calling one getter from another,
          // but this isn't covered well in the docs.  Consider refactoring to use getApp getter.
          const app = state.apps.find((app) => app.id === appId);
          const suggestion = app ? app.getSuggestion(suggestionId) : undefined;
          return suggestion;
        };
      },
    },
    actions: {
      cancelToggleAllGradingSuggestions() {
        this.showDisableSuggestionsConfirmation = false;
      },
      async confirmToggleAllGradingSuggestions() {
        const response = await toggleAIGradingSuggestions(!this.suggestionsEnabled);
        this.suggestionsEnabled = response.toggleValue;
        this.showDisableSuggestionsConfirmation = false;
      },
      registerApp(data) {
        const app = new GradingSuggestionsAppModel(data);
        this.apps.push(app);
      },
      async toggleAllGradingSuggestions() {
        if (this.suggestionsEnabled) {
          this.showDisableSuggestionsConfirmation = true;
        } else {
          await this.confirmToggleAllGradingSuggestions();
        }
      },
    },
  }
);
