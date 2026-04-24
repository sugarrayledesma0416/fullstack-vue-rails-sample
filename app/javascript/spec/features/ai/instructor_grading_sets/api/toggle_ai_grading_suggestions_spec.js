import { toggleAIGradingSuggestions } from
  'features/ai/instructor_grading_sets/api/toggle_ai_grading_suggestions';
import ENDPOINTS from 'features/ai/instructor_grading_sets/api/endpoints';
import fetchMock from 'fetch-mock';

const endpoint = ENDPOINTS.INSTRUCTOR_UPDATE_AI_GRADING_SUGGESTIONS_SETTINGS;

describe('toggleAIGradingSuggestions', () => {
  beforeEach(() => {
    fetchMock.restore();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('Returns a resolved Promise with the value of the completed toggle.', async () => {
    fetchMock.mock(endpoint, { status: 200, body: true });
    const response = await toggleAIGradingSuggestions(true);
    const expected = { response: true, toggleValue: true };
    expect(response).toStrictEqual(expected);
  });

  it('Returns a rejected Promise with the error message if the request fails.', async () => {
    fetchMock.mock(endpoint, { status: 400, body: { errors: 'Bad Request' }});
    try {
      await toggleAIGradingSuggestions(true);
    } catch (error) {
      expect(error).toBe('Bad Request');
    }
  });
});
