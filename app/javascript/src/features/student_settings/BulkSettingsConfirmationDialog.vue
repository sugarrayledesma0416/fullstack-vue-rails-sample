<template>
  <sl-dialog class="bulk-settings-confirmation-dialog" style="--width:450px;">
    <span slot="label" class="c-heading-v3 c-heading-v3--2 u-txt-true-gray-600">Apply Settings</span>
    <p class="u-mar-bot-16">
      {{ confirmationMessage }}
    </p>
    <p class="u-mar-bot-24">
      Are you sure you want to make these changes?
    </p>
    <div slot="footer" class="u-dis-flex u-justify-content-space-between w-full-width">
      <button
        data-testid="bulk-settings-cancel"
        class="c-button-v3 c-button-v3--tertiary"
        @click="handleCancel"
      >
        Cancel
      </button>
      <button
        data-testid="bulk-settings-confirm"
        class="c-button-v3 c-button-v3--primary"
        @click="handleConfirm"
      >
        Confirm
      </button>
    </div>
  </sl-dialog>
</template>

<script setup>
  import { computed } from 'vue';

  const props = defineProps({
    selectedCount: {
      type: Number,
      required: true
    },
    programLanguageName: {
      type: String,
      required: true
    },
    pendingSettings: {
      type: Object,
      required: true
    }
  });

  const emit = defineEmits(['confirm', 'cancel']);

  const handleConfirm = () => {
    emit('confirm');
  };

  const handleCancel = () => {
    emit('cancel');
  };

  const confirmationMessage = computed(() => {
    // There should only ever be one key in this object, so use it.
    const key = Object.keys(props.pendingSettings)[0];
    const value = props.pendingSettings[key];

    return `This action will ${getValueMessage(props.programLanguageName, key, value)} ${getKeyMessage(key)} for ${getStudentCountMessage(props.selectedCount)}.`;
  });

  const getKeyMessage = (key) => {
    if (key === 'video_subtitle_languages') {
      return 'video subtitles and closed captions';
    } else if (key === 'video_transcript_languages') {
      return 'video transcripts';
    } else if (key === 'audio_transcript') {
      return 'audio transcripts';
    } else if (key === 'input_mode') {
      return 'input mode';
    }
  }

  const getValueMessage = (programLanguageName, key, value) => {
    if (key === 'video_subtitle_languages' || key === 'video_transcript_languages') {
      if (value === 'foreign') {
        return `turn on ${getDisplayValue(value, programLanguageName)}`;
      } else if (value === 'foreign_and_english') {
        return `turn on ${getDisplayValue(value, programLanguageName)}`;
      } else if (value === 'none') {
        return 'turn off'
      }
    } else if (key === 'audio_transcript') {
      return value ? 'turn on' : 'turn off';
    } else if (key === 'input_mode') {
      return value ? 'turn on' : 'turn off';
    }
  }

  const getDisplayValue = (value, programLanguageName) => {
    if (value === 'foreign') {
      return programLanguageName;
    } else if (value === 'foreign_and_english') {
      return `${programLanguageName} and English`;
    } else if (value === 'none') {
      return 'off';
    }
  }

  const getStudentCountMessage = (count) => {
    return count === 1 ? `${count} student` : `${count} students`;
  }
</script>
