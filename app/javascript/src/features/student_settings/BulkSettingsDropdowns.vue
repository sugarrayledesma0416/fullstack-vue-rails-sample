<template>
  <div class="u-dis-flex u-mar-lt-24 u-mar-bot-24" role="toolbar" aria-label="Bulk settings controls">
    <SettingsDropdown
      data-testid="video-subtitles-dropdown"
      aria-label="Video subtitles and closed captions settings"
      :buttonLabel="'Video Subtitles & CC'"
      :disabled="selectedStudentIds.length === 0"
      @select="handleVideoSubtitlesBulkSelect"
    >
      <sl-menu-item v-for="option in languageOptions" :key="option.value" :value="option.value">
        {{ option.label }}
      </sl-menu-item>
    </SettingsDropdown>

    <SettingsDropdown
      data-testid="video-transcripts-dropdown"
      aria-label="Video transcripts settings"
      :buttonLabel="'Video Transcripts'"
      :disabled="selectedStudentIds.length === 0"
      @select="handleVideoTranscriptsBulkSelect"
    >
      <sl-menu-item v-for="option in languageOptions" :key="option.value" :value="option.value">
        {{ option.label }}
      </sl-menu-item>
    </SettingsDropdown>

    <SettingsDropdown
      data-testid="audio-transcripts-dropdown"
      aria-label="Audio transcripts settings"
      :buttonLabel="'Audio Transcripts'"
      :disabled="selectedStudentIds.length === 0"
      @select="handleAudioTranscriptsBulkSelect"
    >
      <sl-menu-item value="on">On</sl-menu-item>
      <sl-menu-item value="off">Off</sl-menu-item>
    </SettingsDropdown>

    <SettingsDropdown
      v-if="props.hasAiVirtualChatActivities"
      aria-label="Input mode settings"
      data-testid="input-mode-dropdown"
      :buttonLabel="'Input Mode'"
      :disabled="selectedStudentIds.length === 0"
      @select="handleInputModeBulkSelect"
    >
        <sl-menu-item v-for="[value, displayName] in Object.entries(props.aiInputModes)" :key="value" :value="value">{{ displayName }}</sl-menu-item>
    </SettingsDropdown>
  </div>

  <BulkSettingsConfirmationDialog
    :selectedCount="selectedStudentIds.length"
    :programLanguageName="programLanguageName"
    :pendingSettings="pendingSettings"
    @confirm="handleConfirmationConfirm"
    @cancel="handleConfirmationCancel"
  />
</template>

<script setup>
import { ref } from 'vue';
import { postToEndpoint } from '../../shared/ajax_utils';
import { notify } from './notification_utils';
import BulkSettingsConfirmationDialog from './BulkSettingsConfirmationDialog.vue';
import SettingsDropdown from './SettingsDropdown.vue';

const props = defineProps({
  languageOptions: {
    type: Array,
    required: true,
  },
  programLanguageName: {
    type: String,
    required: true,
  },
  aiInputModes: {
    type: Object,
    required: true,
  },
  selectedStudentIds: {
    type: Array,
    required: true,
  },
  updateStudentsUrl: {
    type: String,
    required: true,
  },
  hasAiVirtualChatActivities: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['update:students']);

const pendingSettings = ref({});

const settingName = ref('');

const handleVideoSubtitlesBulkSelect = (event) => {
  if (props.selectedStudentIds.length === 0) {
    return;
  }
  pendingSettings.value = {
    video_subtitle_languages: event.detail.item.value,
  };
  showConfirmationDialog();
};

const handleVideoTranscriptsBulkSelect = (event) => {
  if (props.selectedStudentIds.length === 0) {
    return;
  }
  pendingSettings.value = {
    video_transcript_languages: event.detail.item.value,
  };
  showConfirmationDialog();
};

const handleAudioTranscriptsBulkSelect = (event) => {
  if (props.selectedStudentIds.length === 0) {
    return;
  }
  pendingSettings.value = {
    audio_transcript: event.detail.item.value === 'on',
  };
  showConfirmationDialog();
};

const handleInputModeBulkSelect = (event) => {
  if (props.selectedStudentIds.length === 0) {
    return;
  }
  pendingSettings.value = {
    input_mode: event.detail.item.value,
  };
  settingName.value = 'Input Mode';
  showConfirmationDialog();
};

const showConfirmationDialog = () => {
  const dialog = document.querySelector('.bulk-settings-confirmation-dialog');
  if (dialog) {
    dialog.show();
  }
};

const hideConfirmationDialog = () => {
  const dialog = document.querySelector('.bulk-settings-confirmation-dialog');
  if (dialog) {
    dialog.hide();
  }
};

const handleConfirmationConfirm = () => {
  if (pendingSettings.value) {
    updateStudentsConfig(pendingSettings.value);
    pendingSettings.value = {};
  }
  hideConfirmationDialog();
};

const handleConfirmationCancel = () => {
  pendingSettings.value = {};
  hideConfirmationDialog();
};

function updateStudentsConfig(settings) {
  postToEndpoint(
    props.updateStudentsUrl,
    {
      user_ids: props.selectedStudentIds,
      ...settings
    },
    (response) => {
      let settingName = 'Setting';
      if (settings.audio_transcript !== undefined) {
        settingName = 'Audio transcript setting';
      } else if (settings.video_subtitle_languages !== undefined) {
        settingName = 'Video subtitles setting';
      } else if (settings.video_transcript_languages !== undefined) {
        settingName = 'Video transcripts setting';
      }
      if (response.success) {
        notify(
          `${settingName} successfully applied for ${props.selectedStudentIds.length} students.`,
          'success',
          'check',
          3000,
          'student-settings-alert'
        );
        // Emit the settings update to parent component
        emit('update:students', settings);
      } else {
        notify(
          `There was an error updating the ${settingName.toLowerCase()} for ${props.selectedStudentIds.length} students.`,
          'danger',
          'alert-circle',
          3000,
          'student-settings-alert'
        );
      }
    }
  );
}
</script>
