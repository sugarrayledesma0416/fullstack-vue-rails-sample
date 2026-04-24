import { createPinia } from 'pinia';
import { useGradingSuggestionsStore } from './grading_suggestions_store';

/**
 * Creates a new Pinia instance to be shared among all Vue apps that need to access the grading
 * suggestions store.
 */
export const gradingSuggestionsPinia = createPinia();

/**
 * Initializes the Grading Suggestions store on the Grading Suggestions pinia.  Since multiple Vue
 * apps need to access this store, we create it beforehand so that it already exists when the Vue
 * apps mount.  This prevents an error that can occur when multiple Vue apps try to create the same
 * store on the same Pinia at the same time.
 */
export const gradingSuggestionsStore = useGradingSuggestionsStore(gradingSuggestionsPinia);
