<template>
  <div class="options  u-pad-top-16">
    <p class="u-txt-bold">
      Do you want to enable AI chats?
    </p>
    <VhlRadioButton
      id="ai_virtual_chat_level_enabled"
      v-model:modelValue="courseDataStore.store.course.aiVirtualChatLevel"
      class="u-dis-block  u-mar-bot-8"
      name="ai_virtual_chat_level_enabled"
      testSelectorInput="ai-virtual-chat-availability-always-rb"
      text="Yes"
      :value="true" />
    <VhlRadioButton
      id="ai_virtual_chat_level_disabled"
      v-model:modelValue="courseDataStore.store.course.aiVirtualChatLevel"
      class="u-dis-block"
      name="ai_virtual_chat_level_disabled"
      testSelectorInput="ai-virtual-chat-availability-never-rb"
      text="No"
      :value="false" />
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
