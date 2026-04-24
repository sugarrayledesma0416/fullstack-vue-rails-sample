<template>
  <div
    :id="id"
    class="suggestion"
    :class="[{ 'suggestion--indexed' : index !== null }, { 'suggestion-edited' : isEdited } ]">
    <div
      v-if="index !== null"
      class="number">
      {{ index }}
    </div>
    <div class="suggestion-text">
      <slot />
      <a
        v-if="isEdited"
        class="u-txt-ital u-txt-bold"
        @click="onEditSuggestion">
        (my edited comment)
      </a>
    </div>
    <div class="controls">
      <tippy
        :content="isAdded ? 'Remove Feedback' : 'Add Feedback'"
        placement="top">
        <DiscreetButton
          v-if="isAdded === true"
          class="suggestion-button"
          type="button"
          @click="onRejectSuggestion">
          <XIcon />
        </DiscreetButton>
        <DiscreetButton
          v-if="isAdded === false"
          class="suggestion-button"
          type="button"
          @click="onAddSuggestion">
          <PlusIcon />
        </DiscreetButton>
      </tippy>
    </div>
  </div>
</template>

<script setup>
  import { defineProps } from 'vue';
  import XIcon from './XIcon';
  import DiscreetButton from './DiscreetButton';
  import PlusIcon from './PlusIcon';
  import { Tippy } from 'vue-tippy';

  defineProps({
    id: {
      type: Number,
      required: true,
    },
    index: {
      type: Number,
      required: false,
      default: null,
    },
    isAdded: {
      type: Boolean,
      required: true,
    },
    isEdited: {
      type: Boolean,
      required: true,
    },
    onAddSuggestion: {
      type: Function,
      required: true,
    },
    onRejectSuggestion: {
      type: Function,
      required: true,
    },
    onEditSuggestion: {
      type: Function,
      required: false,
      default: () => {},
    },
  });
</script>

<style lang="scss" scoped>
  .suggestion {
    background-color: #fff;
    border-radius: 0.625rem;
    display: grid;
    font-size: 1rem;
    grid-template-columns: 1fr 3rem;
    font-family: 'Open Sans', sans-serif;
    padding: 0.62rem 0.9rem;

    &--indexed {
      grid-template-columns: 2rem 1fr 3rem;
    }
  }

  .number {
    &::after {
      content: '.';
    }
  }

  .suggestion-button {
    align-items: center;
    display: flex;
    height: min-content;
    justify-content: center;
    padding: 0;
    text-align: left;
  }

  .controls {
    align-items: center;
    background-color: transparent;
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
  }
</style>
