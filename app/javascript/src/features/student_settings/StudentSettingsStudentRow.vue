<template>
  <tr>
    <td data-testid="student-name" class="c-table-v3__td u-bord-rt-1 u-bord-rt-gray-300">
      <sl-checkbox
        data-testid="student-select"
        :checked="isSelected"
        :aria-label="`Select ${localStudent.firstName} ${localStudent.lastName}`"
        @sl-change="handleSelectionChange"
      >
        <span part="label" class="u-txt-true-gray-900">{{ localStudent.lastName }}, {{ localStudent.firstName }}</span>
      </sl-checkbox>
    </td>
    <td class="c-table-v3__td u-cell-shadow">
      <form>
        <sl-select
          class="c-select--table"
          data-testid="video-subtitles"
          :id="props.appcuesId ? props.appcuesId : null"
          :value="localStudent.video_subtitle_languages"
          name="video_subtitle_languages"
          :aria-label="`Video subtitles and closed captions settings for ${localStudent.firstName} ${localStudent.lastName}`"
          @sl-change="handleVideoSubtitlesChange"
        >
          <sl-option v-for="option in languageOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </sl-option>
        </sl-select>
      </form>
    </td>
    <td class="c-table-v3__td">
      <form>
        <sl-select
          class="c-select--table"
          data-testid="video-transcripts"
          :value="localStudent.video_transcript_languages"
          name="video_transcript_languages"
          :aria-label="`Video transcripts settings for ${localStudent.firstName} ${localStudent.lastName}`"
          @sl-change="handleVideoTranscriptsChange"
        >
          <sl-option v-for="option in languageOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </sl-option>
        </sl-select>
      </form>
    </td>
    <td class="c-table-v3__td">
      <form>
        <sl-checkbox
          data-testid="audio-transcript"
          :checked="localStudent.audio_transcript"
          name="audio_transcript"
          :aria-label="`Audio transcript settings for ${localStudent.firstName} ${localStudent.lastName}`"
          @sl-change="handleAudioTextChange"
        />
      </form>
    </td>
    <td class="c-table-v3__td" v-if="props.hasAiVirtualChatActivities">
      <form>
        <sl-select
          class="c-select--table  ai-interaction-mode-select"
          data-testid="input-mode"
          :value="localStudent.input_mode"
          name="input_mode"
          :aria-label="`Input mode settings for ${localStudent.firstName} ${localStudent.lastName}`"
          @sl-change="handleInputModeChange"
        >
          <sl-option v-for="[value, displayName] in Object.entries(props.aiInputModes)" :key="value" :value="value">{{ displayName }}</sl-option>
        </sl-select>
      </form>
    </td>
  </tr>
</template>

<script setup>
  import { ref, watch } from 'vue';
  import { postToEndpoint } from '../../shared/ajax_utils';
  import { notify } from './notification_utils';

  const emit = defineEmits(['selection-change']);
  const props = defineProps({
    aiInputModes: {
      type: Object,
      required: true,
    },
    student: {
      type: Object,
      required: true,
    },
    appcuesId:{
      type: String,
      required: false,
    },
    hasAiVirtualChatActivities: {
      type: Boolean,
      required: true,
    },
    languageOptions: {
      type: Array,
      required: true,
    },
    programId: {
      type: Number,
      required: true,
    },
    updateStudentsUrl: {
      type: String,
      required: true,
    },
    courseId: {
      type: Number,
      required: true,
    },
    sectionId: {
      type: Number,
      required: true,
    },
    isSelected: {
      type: Boolean,
      default: false
    },
  });

  // Initialize with current prop values
  const localStudent = ref({ ...props.student });
  // This avoids a very strange interaction between Vue and Shoelace where if a sl-option is fully
  // static and the select is set to its value, the select won't render properly.  By dynamically
  // dumping the "off" text into the select, we avoid the issue.
  const dynamicOffOptionText = 'Off';

  // Watch for prop changes and update our local state
  watch(() => props.student, (newStudent) => {
     localStudent.value = { ...newStudent };
  });

  /**
   * Handler for changes to the audio transcript checkbox.
   */
  function handleAudioTextChange(event) {
    localStudent.value.audio_transcript = event.target.checked;
    updateStudentsConfig({
      audio_transcript: localStudent.value.audio_transcript,
    });
  }

  function handleInputModeChange(event) {
    localStudent.value.input_mode = event.target.value;
    updateStudentsConfig({
      input_mode: localStudent.value.input_mode,
    });
  }

  /**
   * Handler for changes to the video subtitles dropdown.
   */
  function handleVideoSubtitlesChange(event) {
    localStudent.value.video_subtitle_languages = event.target.value;
    updateStudentsConfig({
      video_subtitle_languages: localStudent.value.video_subtitle_languages,
    });
  }

  /**
   * Handler for changes to the video transcripts dropdown.
   */
  function handleVideoTranscriptsChange(event) {
    localStudent.value.video_transcript_languages = event.target.value;
    updateStudentsConfig({
      video_transcript_languages: localStudent.value.video_transcript_languages,
    });
  }

  /**
   * Handler for changes to the student selection checkbox.
   */
  function handleSelectionChange(event) {
    emit('selection-change', {
      userId: localStudent.value.id,
      selected: event.target.checked
    });
  }

  /**
   * Sends a request to the server to update a student's section config.
   *
   * @param {*} settings
   */
  function updateStudentsConfig(settings) {
    postToEndpoint(
      props.updateStudentsUrl,
      {
        user_ids: [localStudent.value.id],
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
            `${settingName} successfully applied for ${localStudent.value.firstName} ${localStudent.value.lastName}.`,
            'success',
            'check',
            3000,
            'student-settings-alert'
          );
          // Ensure our student matches what came back from the server.
          localStudent.value = {
            ...localStudent.value,
            ...response.config
          }
        } else {
          notify(
            `There was an error updating the ${settingName.toLowerCase()} for ${localStudent.value.firstName} ${localStudent.value.lastName}.`,
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

<style scoped>
  sl-select.c-select--table::part(expand-icon) {
    color: var(--music-true-gray-900);
  }

  sl-checkbox[data-testid="audio-transcript"]::part(control--checked) {
    background-color: var(--music-util-info);
  }

  .ai-interaction-mode-select {
    min-width: 310px;
  }
</style>
