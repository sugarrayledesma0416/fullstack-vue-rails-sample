import { setActivePinia, createPinia } from 'pinia';
import { useGradingSuggestionsStore } from 'features/ai/instructor_grading_sets/stores/grading_suggestions_store';
import { GradingSuggestionsAppModel } from 'features/ai/instructor_grading_sets/models/grading_suggestions_app_model';
import { toggleAIGradingSuggestions } from 'features/ai/instructor_grading_sets/api/toggle_ai_grading_suggestions';

jest.mock('features/ai/instructor_grading_sets/models/grading_suggestions_app_model');
jest.mock('features/ai/instructor_grading_sets/api/toggle_ai_grading_suggestions');

describe('GradingSuggestionsStore', () => {
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useGradingSuggestionsStore();
    jest.clearAllMocks();
  });

  describe('getters', () => {
    beforeEach(() => {
      store.apps = [
        { id: 'app1', getSuggestion: jest.fn() },
        { id: 'app2', getSuggestion: jest.fn() }
      ];
    });

    describe('getApp', () => {
      it('returns the correct app by id', () => {
        const app = store.getApp('app1');
        expect(app).toEqual(store.apps[0]);
      });

      it('returns undefined for non-existent app id', () => {
        const app = store.getApp('non-existent');
        expect(app).toBeUndefined();
      });
    });

    describe('getSuggestion', () => {
      it('returns the correct suggestion from the app', () => {
        const mockSuggestion = { id: 'suggestion1' };
        store.apps[0].getSuggestion.mockReturnValue(mockSuggestion);

        const suggestion = store.getSuggestion('app1', 'suggestion1');
        expect(suggestion).toBe(mockSuggestion);
        expect(store.apps[0].getSuggestion).toHaveBeenCalledWith('suggestion1');
      });

      it('returns undefined for non-existent app', () => {
        const suggestion = store.getSuggestion('non-existent', 'suggestion1');
        expect(suggestion).toBeUndefined();
      });
    });
  });

  describe('actions', () => {
    describe('registerApp', () => {
      it('creates and registers a new app', () => {
        const appData = { id: 'new-app' };
        store.registerApp(appData);

        expect(GradingSuggestionsAppModel).toHaveBeenCalledWith(appData);
        expect(store.apps).toHaveLength(1);
      });
    });

    describe('toggleAllGradingSuggestions', () => {
      it('shows confirmation when disabling suggestions', async () => {
        store.suggestionsEnabled = true;
        await store.toggleAllGradingSuggestions();
        expect(store.showDisableSuggestionsConfirmation).toBe(true);
      });

      it('immediately toggles when enabling suggestions', async () => {
        store.suggestionsEnabled = false;
        toggleAIGradingSuggestions.mockResolvedValue({ toggleValue: true });
        await store.toggleAllGradingSuggestions();
        expect(toggleAIGradingSuggestions).toHaveBeenCalledWith(true);
      });
    });

    describe('confirmToggleAllGradingSuggestions', () => {
      it('toggles suggestions and updates state', async () => {
        const mockResponse = { toggleValue: true };
        toggleAIGradingSuggestions.mockResolvedValue(mockResponse);

        await store.confirmToggleAllGradingSuggestions();

        expect(store.suggestionsEnabled).toBe(true);
        expect(store.showDisableSuggestionsConfirmation).toBe(false);
      });
    });

    describe('cancelToggleAllGradingSuggestions', () => {
      it('hides the confirmation dialog', () => {
        store.showDisableSuggestionsConfirmation = true;
        store.cancelToggleAllGradingSuggestions();
        expect(store.showDisableSuggestionsConfirmation).toBe(false);
      });
    });
  });
});
