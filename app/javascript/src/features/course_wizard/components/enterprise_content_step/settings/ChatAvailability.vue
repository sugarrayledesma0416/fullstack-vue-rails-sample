<template>
  <div>
    <div
      v-if="config.institutionSupportsChat"
      class="u-mar-bot-8  u-txt-body-1">
      Allow students and / or yourself to send text messages and share and
      record live video or audio.
    </div>
    <div
      v-else
      class="u-mar-bot-8  u-txt-body-1">
      Your institution has disabled this behavior.
    </div>

    <div
      v-if="config.institutionSupportsChat"
      class="radio-group">
      <!-- eslint-disable vue/no-v-model-argument -->
      <VhlRadioButton
        id="chat_level_disabled"
        v-model:modelValue="courseDataStore.store.course.chatLevel"
        name="chat_level_disabled"
        testSelectorInput="chat-availability-never-rb"
        text="Never available"
        value="disabled" />
      <VhlRadioButton
        id="chat_level_partner_chat"
        v-model:modelValue="courseDataStore.store.course.chatLevel"
        name="chat_level_partner_chat"
        testSelectorInput="chat-availability-in-partner-chat-rb"
        text="Only in chat activities"
        value="partner_chat" />
      <VhlRadioButton
        id="chat_level_partner_chat_and_live_chat"
        v-model:modelValue="courseDataStore.store.course.chatLevel"
        name="chat_level_partner_chat_and_live_chat"
        testSelectorInput="chat-availability-always-rb"
        text="Always available"
        value="partner_chat_and_live_chat" />
      <!-- eslint-enable vue/no-v-model-argument -->
    </div>
  </div>
</template>

<script setup>
  import { inject } from 'vue';
  import VhlRadioButton from '../../VhlRadioButton';

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .radio-group {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 1rem;
  }
</style>
