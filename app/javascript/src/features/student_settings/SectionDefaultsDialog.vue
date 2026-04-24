<template>
  <sl-dialog
    class="section-default-settings-dialog"
    style="--width:600px;"
    @sl-show="resetForm"
    aria-labelledby="section-defaults-title"
    aria-describedby="section-defaults-description"
  >
    <span slot="label" id="section-defaults-title" class="c-heading-v3 c-heading-v3--2 u-txt-true-gray-600">Manage Default Settings</span>
    <p id="section-defaults-description" class="u-mar-bot-40">
      Choose default settings to apply to your students. You can return to customizing individual student settings any time.
    </p>
    <form class="u-dis-flex u-flex-dir-column" @submit.prevent="handleSubmit" aria-label="Default settings form">
      <div class="u-dis-flex u-flex-grow-1 u-justify-content-space-between u-align-items-center u-pad-bot-12 u-mar-bot-12 u-bord-solid u-bord-bot-1 u-bord-gray-200">
        <div>
          <div class="u-align-icon">
            <span class="u-txt-semibold">Video Subtitles and Closed Captions (CC)</span>
            <sl-tooltip :content="`The recommended video subtitles and CC setting for this program is: ${props.programLanguageName} only`">
              <sl-icon class="u-txt-regular u-txt-body-2" name="info-circle" library="untitled-ui" aria-hidden="true"></sl-icon>
            </sl-tooltip>
          </div>
        </div>
        <sl-select
          class="c-modal-select u-flex-shrink-0"
          :value="videoSubtitleLanguages"
          size="small"
          name="video_subtitle_languages"
          aria-label="Video subtitles and closed captions settings"
          @sl-change="handleVideoSubtitlesChange"
        >
          <sl-option v-for="option in languageOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </sl-option>
        </sl-select>
      </div>
      <div class="u-dis-flex u-flex-grow-1 u-justify-content-space-between u-align-items-center u-pad-bot-12 u-mar-bot-12 u-bord-solid u-bord-bot-1 u-bord-gray-200">
        <div>
          <div class="u-align-icon">
            <span class="u-txt-semibold">Video Transcripts</span>
            <sl-tooltip content="The recommended video transcript setting for this program is: Off">
              <sl-icon class="u-txt-regular u-txt-body-2" name="info-circle" library="untitled-ui" aria-hidden="true"></sl-icon>
            </sl-tooltip>
          </div>
        </div>
        <sl-select
          class="c-modal-select u-flex-shrink-0"
          :value="videoTranscriptLanguages"
          size="small"
          name="video_transcript_languages"
          aria-label="Video transcripts settings"
          @sl-change="handleVideoTranscriptsChange"
        >
          <sl-option v-for="option in languageOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </sl-option>
        </sl-select>
      </div>
      <div class="u-dis-flex u-flex-grow-1 u-justify-content-space-between u-pad-bot-12 u-mar-bot-24">
        <div class="u-txt-semibold">Audio Transcripts</div>
        <sl-checkbox
          :checked="audioTranscript"
          name="audio_transcript"
          aria-label="Audio transcripts settings"
          @sl-change="handleAudioTranscriptChange"
        ></sl-checkbox>
      </div>
      <div v-if="props.hasAiVirtualChatActivities" class="u-dis-flex u-flex-grow-1 u-justify-content-space-between u-align-items-center u-pad-bot-12 u-mar-bot-12 u-bord-solid u-bord-bot-1 u-bord-gray-200">
        <div class="u-txt-semibold">AI Interaction Mode</div>
        <sl-select
          class="c-modal-select u-flex-shrink-0  ai-interaction-mode-select"
          :value="inputMode"
          size="small"
          name="input_mode"
          aria-label="AI chat activities only"
          @sl-change="handleInputModeChange"
        >
          <sl-option v-for="[value, displayName] in Object.entries(props.aiInputModes)" :key="value" :value="value">{{ displayName }}</sl-option>
        </sl-select>
      </div>
      
      <div class="u-mar-bot-24">
        <sl-checkbox
          :checked="applyToAll"
          name="apply_to_all"
          aria-label="Apply settings to all students"
          @sl-change="handleApplyToAllChange"
        >Apply settings to <strong>all</strong> students</sl-checkbox>
      </div>
      <p class="u-txt-true-gray-600">Any students with customized settings will be updated to the new defaults.</p>
    </form>
    <div slot="footer" class="u-dis-flex u-justify-content-center">
      <button
        type="submit"
        class="c-button-v3 c-button-v3--primary"
        @click="handleSubmit"
        aria-label="Save default settings"
      >Save</button>
    </div>
  </sl-dialog>
</template>

<script setup>
import { ref, watch } from 'vue';
import { postToEndpoint } from '../../shared/ajax_utils';
import { notify } from './notification_utils';

const props = defineProps({
  aiInputModes: {
    type: Object,
    required: true,
  },
  languageOptions: {
    type: Array,
    required: true,
  },
  programLanguageName: {
    type: String,
    required: true,
  },
  sectionVideoTranscriptLanguages: {
    type: String,
    required: true,
  },
  sectionVideoSubtitleLanguages: {
    type: String,
    required: true,
  },
  sectionAudioTranscript: {
    type: Boolean,
    required: true,
  },
  sectionInputMode: {
    type: String,
    required: true,
  },
  hasAiVirtualChatActivities: {
    type: Boolean,
    required: true,
  },
  updateSectionDefaultsUrl: {
    type: String,
    required: true,
  }
});

const emit = defineEmits(['update:students', 'update:sectionSettings']);

const videoSubtitleLanguages = ref(props.sectionVideoSubtitleLanguages);
const videoTranscriptLanguages = ref(props.sectionVideoTranscriptLanguages);
const audioTranscript = ref(props.sectionAudioTranscript);
const inputMode = ref(props.sectionInputMode);
const applyToAll = ref(false);

// Watch for changes to the props and update our local state
watch(() => props.sectionVideoTranscriptLanguages, (newValue) => {
  videoTranscriptLanguages.value = newValue;
});
watch(() => props.sectionVideoSubtitleLanguages, (newValue) => {
  videoSubtitleLanguages.value = newValue;
});
watch(() => props.sectionAudioTranscript, (newValue) => {
  audioTranscript.value = newValue;
});
watch(() => props.sectionInputMode, (newValue) => {
  inputMode.value = newValue;
});

function handleVideoSubtitlesChange(event) {
  videoSubtitleLanguages.value = event.target.value;
}

function handleVideoTranscriptsChange(event) {
  videoTranscriptLanguages.value = event.target.value;
}

function handleAudioTranscriptChange(event) {
  audioTranscript.value = event.target.checked;
}

function handleInputModeChange(event) {
  inputMode.value = event.target.value;
}

function handleApplyToAllChange(event) {
  applyToAll.value = event.target.checked;
}

/**
 * Handles submission of the section defaults form
 */
function handleSubmit() {
  const settings = {
    audio_transcript: audioTranscript.value,
    video_subtitle_languages: videoSubtitleLanguages.value,
    video_transcript_languages: videoTranscriptLanguages.value,
    input_mode: inputMode.value,
    apply_to_all: applyToAll.value
  };

  postToEndpoint(
    props.updateSectionDefaultsUrl,
    settings,
    (response) => {
      if (response.success) {
        // Update the students data with the new data from the response
        if (response.students) {
          emit('update:students', response.students);
        }
        // Emit the new section settings to update the parent component
        emit('update:sectionSettings', {
          sectionVideoTranscriptLanguages: videoTranscriptLanguages.value,
          sectionVideoSubtitleLanguages: videoSubtitleLanguages.value,
          sectionAudioTranscript: audioTranscript.value,
          sectionInputMode: inputMode.value
        });
        notify(
          'Default settings updated successfully.',
          'success',
          'check',
          3000,
          'section-defaults-alert'
        );
        closeDialog();
      } else {
        notify(
          'There was an error updating the default settings.',
          'danger',
          'alert-circle',
          3000,
          'section-defaults-alert'
        );
      }
    }
  );
}

function closeDialog() {
  const dialogElement = document.querySelector('.section-default-settings-dialog');
  if (dialogElement) {
    dialogElement.hide();
  }
}

// Whenever we open the form, we want to reset its data to the defaults.
function resetForm(event) {
  // Shoelace events like sl-show bubble.  You need to make sure that the event is at the "TARGET"
  // phase, which means it was created by the current element.  We need this here, in particular,
  // because this dialog contains selects which also publish the same bubbling event.
  // https://www.abeautifulsite.net/posts/custom-event-names-and-the-bubbling-problem/
  if (event.eventPhase === Event.AT_TARGET) {
    videoSubtitleLanguages.value = props.sectionVideoSubtitleLanguages;
    videoTranscriptLanguages.value = props.sectionVideoTranscriptLanguages;
    audioTranscript.value = props.sectionAudioTranscript;
    inputMode.value = props.sectionInputMode;
    applyToAll.value = false;
  }
}
</script>

<style lang="scss">
  .section-default-settings-dialog {
    .c-modal-select {
      // The selects in the modal are too wide by default, given their content and the width of the
      // modal.  This just forces them to take up less space.
      width: 185px;
    }
  }

  .ai-interaction-mode-select {
    min-width: 310px;
  }
</style>
