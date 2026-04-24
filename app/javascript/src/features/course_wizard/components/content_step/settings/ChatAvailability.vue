<template>
  <ContentSetting :class="testClass('chat-availability')">
    <p v-if="config.institutionSupportsChat">
      By enabling chat features, you and your students can send,
      share, and record messages (text, video, audio).
    </p>
    <p v-else>
      Your institution has disabled this behavior.
    </p>
  </ContentSetting>
  <div class="options" v-if="config.institutionSupportsChat">
    <p class="u-txt-bold">
      Do you want to enable text and video chats?
    </p>
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlRadioButton
      id="chat_level_partner_chat_and_live_chat"
      v-model:modelValue="courseDataStore.store.course.chatLevel"
      class="u-dis-block  u-mar-bot-8"
      name="chat_level_partner_chat_and_live_chat"
      testSelectorInput="chat-availability-always-rb"
      text="Yes"
      value="partner_chat_and_live_chat" />
    <VhlRadioButton
      id="chat_level_partner_chat"
      v-model:modelValue="courseDataStore.store.course.chatLevel"
      class="u-dis-block  u-mar-bot-8"
      name="chat_level_partner_chat"
      testSelectorInput="chat-availability-in-partner-chat-rb"
      text="Enable for chat activities only"
      value="partner_chat" />
    <VhlRadioButton
      id="chat_level_disabled"
      v-model:modelValue="courseDataStore.store.course.chatLevel"
      class="u-dis-block"
      name="chat_level_disabled"
      testSelectorInput="chat-availability-never-rb"
      text="No"
      value="disabled" />
    <!-- eslint-enable vue/no-v-model-argument -->
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import { inject } from 'vue';
  import VhlRadioButton from '../../VhlRadioButton';

  const courseDataStore = inject('courseDataStore');
  const config = inject('config');
</script>
