import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import QuestionReportApp from 'features/ai/instructor_grading/suggestion_rating_reports/QuestionReportApp'
import { VueAwesomePaginate } from 'vue-awesome-paginate'
import OverallComment from 'features/ai/instructor_grading/suggestion_rating_reports/components/OverallComment'
import GradingSuggestion from 'features/ai/instructor_grading/suggestion_rating_reports/components/GradingSuggestion'
import MusicIcon from 'shared/vue/MusicIcon'
import { Tippy } from 'vue-tippy'

describe('QuestionReportApp', () => {
  let wrapper
  const mockProps = {
    ratingCategories: JSON.stringify([]),
    studentResponses: JSON.stringify([
      {
        attemptId: '123',
        studentResponse: '<p>Test response</p>',
        overallComments: [],
        gradingSuggestions: []
      }
    ]),
    loadMoreUrl: '/api/load-more',
    gradingSuggestionPrompts: JSON.stringify([]),
    overallCommentPrompts: JSON.stringify([]),
    options: JSON.stringify({
      showPagination: true
    })
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    wrapper = mount(QuestionReportApp, {
      props: mockProps,
      global: {
        components: {
          VueAwesomePaginate,
          OverallComment,
          GradingSuggestion,
          MusicIcon,
          Tippy
        }
      }
    })
  })

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('displays student response when available', () => {
    expect(wrapper.text()).toContain('Test response')
  })

  it('shows pagination when enabled', () => {
    expect(wrapper.findComponent(VueAwesomePaginate).exists()).toBe(true)
  })

  it('hides pagination when disabled', async () => {
    const store = wrapper.vm.store
    store.options.showPagination = false
    await wrapper.vm.$nextTick()
    expect(wrapper.findComponent(VueAwesomePaginate).exists()).toBe(false)
  })

  it('displays loading state when loading more data', async () => {
    const store = wrapper.vm.store
    store.loadingMoreData = true
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('Loading...')
  })

  it('displays "No Student answer" when no data is available', async () => {
    const store = wrapper.vm.store
    store.studentResponses = []
    store.currentPageInput = null
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('No Student answer')
  })

  it('renders overall comments when available', async () => {
    const store = wrapper.vm.store
    store.currentPageInput = {
      attemptId: '123',
      studentResponse: '<p>Test response</p>',
      overallComments: [{
        id: 1,
        content: 'Test comment',
        overallComment: 'Test comment',
        explanation: 'Test explanation',
        prompt: { id: 1, label: 'Test prompt', url: '#' },
        ratingCategory: { id: 1, label: 'Test rating' }
      }],
      gradingSuggestions: []
    }
    await wrapper.vm.$nextTick()
    expect(wrapper.findComponent(OverallComment).exists()).toBe(true)
  })

  it('renders grading suggestions when available', async () => {
    const store = wrapper.vm.store
    store.currentPageInput = {
      attemptId: '123',
      studentResponse: '<p>Test response</p>',
      overallComments: [],
      gradingSuggestions: [{
        id: 1,
        incorrectText: 'Test text',
        errorExplanation: 'Test explanation',
        prompt: { id: 1, label: 'Test prompt', url: '#' },
        ratingCategory: { id: 1, label: 'Test rating' }
      }]
    }
    await wrapper.vm.$nextTick()
    expect(wrapper.findComponent(GradingSuggestion).exists()).toBe(true)
  })
})
