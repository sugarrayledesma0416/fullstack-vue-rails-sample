<template>
  <div class="c-embedded-icon">
    <component :is="iconComponents[name]" />
  </div>
</template>

<script setup>
  import AppleIcon from './icons/activity/AppleIcon';
  import AudioIcon from './icons/activity/AudioIcon';
  import CompositionIcon from './icons/activity/CompositionIcon';
  import GroupChatIcon from './icons/activity/GroupChatIcon';
  import InfoGapPartnerChatIcon from './icons/activity/InfoGapPartnerChatIcon';
  import InstructorGradedIcon from './icons/activity/InstructorGradedIcon';
  import MicrophoneIcon from './icons/activity/MicrophoneIcon';
  import PartnerChatIcon from './icons/activity/PartnerChatIcon';
  import PersonIcon from './icons/activity/PersonIcon';
  import SoloVideoRecordIcon from './icons/activity/SoloVideoRecordIcon';
  import TextbookIcon from './icons/activity/TextbookIcon';
  import VideoIcon from './icons/activity/VideoIcon';
  import VideoVirtualChatIcon from './icons/activity/VideoVirtualChatIcon';
  import VirtualChatIcon from './icons/activity/VirtualChatIcon';
  import VOLTextbookIcon from './icons/activity/VOLTextbookIcon';

  defineProps({
    name: { required: true, type: String },
  });

  const iconComponents =
    {
      'apple': AppleIcon,
      'audio': AudioIcon,
      'composition': CompositionIcon,
      'group_chat': GroupChatIcon,
      'icon-apple': AppleIcon,
      'icon-instrcutor-graded': InstructorGradedIcon,
      'info_gap_partner_chat': InfoGapPartnerChatIcon,
      'microphone': MicrophoneIcon,
      'partner_chat': PartnerChatIcon,
      'person_icon': PersonIcon,
      'solo_video_recording': SoloVideoRecordIcon,
      'textbook': TextbookIcon,
      'video_virtual_chat': VideoVirtualChatIcon,
      'video': VideoIcon,
      'virtual_chat': VirtualChatIcon,
      'vol_textbook': VOLTextbookIcon,
    };
</script>
