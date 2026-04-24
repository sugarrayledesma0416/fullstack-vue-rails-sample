<template>
  <div
    :id="localSuggestion.id"
    class="suggestion">
    <div class="suggestion-checkbox">
      <input
        :id="`rating_suggestion_${localSuggestion.id}`"
        placeholder="placeholer"
        :checked="localSuggestion.ratingCategoryId !== null"
        type="checkbox"
        @change="onSelection($event.target.checked)">
    </div>
    <div>
      <label
        :for="`rating_suggestion_${localSuggestion.id}`"
        class="suggestion-text"
        :class="{ 'suggestion-text--indexed' : index !== null }">
        <div
          v-if="index !== null"
          class="number">
          {{ index + 1 }}
        </div>
        <div
          :class="testClass('text')">
          <slot />
        </div>
      </label>
      <select
        v-if="suggestion.ratingCategoryId !== null"
        class="c-select  rating-category"
        :value="suggestion.ratingCategoryId"
        @change="onRatingCategorySelection(Number($event.target.value))">
        <option :value="0">
          Select reason
        </option>
        <option
          v-for="category in categories"
          :key="category.id"
          :value="category.id"
          class="rating-category">
          {{ category.label }}
        </option>
      </select>
      <div
        v-if="showRatingComment"
        class="c-form-item  u-mar-top-8">
        <input
          type="text"
          placeholder="Comment (optional)"
          autocomplete="off"
          class="c-form-item__input  suggestion-rating-comment"
          :value="suggestion.ratingComment"
          @change="onRatingCommentChange($event.target.value)">
      </div>
    </div>
  </div>
</template>

<script setup>
  import { defineProps, ref } from 'vue';
  import { testClass } from 'music';

  const props = defineProps({
    suggestion: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: false,
      default: null,
    },
    categories: {
      type: Array,
      required: true,
    },
    showRatingComment: {
      type: Boolean,
      required: true,
    },
    onSelection: {
      type: Function,
      required: true,
    },
    onRatingCategorySelection: {
      type: Function,
      required: true,
    },
    onRatingCommentChange: {
      type: Function,
      required: true,
    },
  });

  const localSuggestion = ref({ ...props.suggestion });
</script>

<style lang="sass" scoped>
  .suggestion {
    background-color: #fff;
    border-radius: 0.625rem;
    display: grid;
    font-size: 1rem;
    grid-template-columns: min-content 1fr;
    font-family: 'Open Sans', sans-serif;
    padding: 0.2rem 0.9rem;
  }

  .number {
    &::after {
      content: '.';
    }
  }

  .suggestion-text {
    padding: 0 0 .5em 0.5em;
    background-color: transparent;
    display: flex;
    font-weight: normal;

    &--indexed {
      //grid-template-columns: min-content 1fr;
      display: grid;
      grid-template-columns: 2rem 1fr;
      flex-direction: row;
      justify-content: flex-end;
    }
  }

  .suggestion input.suggestion-rating-comment {
    padding: 0 1em;
    font-weight: normal;
    outline: none;
  }

  .suggestion .rating-category {
    text-transform: capitalize;
  }
</style>
