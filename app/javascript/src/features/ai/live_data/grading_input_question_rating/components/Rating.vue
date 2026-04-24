<template>
  <div>
    <HappyFaceIcon
      :disabled="!props.rating.accepted"
      @click="acceptItem" />
    <SadFaceIcon
      :disabled="!props.rating.rejected"
      @click="rejectItem" />
    <div
      class="c-form-item-group"
      :class="props.rating.rejected ? '' : 'u-hidden'">
      <div class="c-form-item">
        <input
          v-model="state.comment"
          type="text"
          placeholder="Optional comment"
          autocomplete="off"
          class="c-form-item__input"/>
      </div>
      <div class="c-form-item">
        <ButtonSecondary
          theme="vol"
          :disabled="isCommentUpToDate() || isCommentEmpty()"
          @click="rejectItem">
            Send
            <MusicIcon
              v-if="isCommentUpToDate() && !isCommentEmpty()"
              variant="checkmark"
              size="lg" />
        </ButtonSecondary>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { reactive, watch } from 'vue';
  import HappyFaceIcon from '../icons/HappyFaceIcon';
  import SadFaceIcon from '../icons/SadFaceIcon';
  import ButtonSecondary from
  'music/app/javascript/src/components/button_secondary/v1.2/ButtonSecondary';
  import MusicIcon from 'shared/vue/MusicIcon';

  const props = defineProps({
    /**
     * The current rating
     */
    rating: {
      required: false,
      type: Object,
      default: function() {
        return {};
      },
    },
    /**
     * Reference to a function that, when called, will accept the rated element.
     */
    accept: {
      type: Function,
      required: true,
    },
    /**
     * Reference to a function that, when called, will reject the rated element.
     */
    reject: {
      type: Function,
      required: true,
    },
  });

  const state = reactive({
    // Save the comment into state. The model will only be updated when sending
    // the comment
    comment: props.rating.comment,
  });

  watch(() => props.rating.comment, (newValue, oldValue) => {
    state.comment = newValue;
  });

  function acceptItem() {
    // Only accept the item if it has not been accepted.
    if (!props.rating.accepted) { 
      props.accept(props.rating);
    }
  } 
  
  function rejectItem() {
    // Only accept the item if it has not been rejected or if ithe comment changed.
    if (!props.rating.rejected || !isCommentUpToDate()) {
      props.reject(props.rating, state.comment);
    }
  }
  
  function isCommentUpToDate() {
    return state.comment === props.rating.comment;
  }

  function isCommentEmpty() {
    return !state.comment || state.comment.length === 0;
  }
</script>
