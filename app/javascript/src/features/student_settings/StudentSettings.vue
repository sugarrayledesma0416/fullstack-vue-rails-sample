<template>
  <div class="u-mar-lt-24" role="main" aria-labelledby="student-settings-title">
    <a
      data-testid="back-to-link"
      class="c-button-v3 c-button-v3--quaternary u-mar-bot-16"
      :href="backToLink">
      <sl-icon name="arrow-left" library="untitled-ui"></sl-icon>
      {{ backToLabel }}
    </a>
    <h1 id="student-settings-title" class="u-mar-bot-16 c-heading-v3 c-heading-v3--2 u-txt-true-gray-600">Student Interaction Settings</h1>
    <p class="u-mar-bot-40">
      Customize settings for each student's learning needs.
      <a
        :id="appcuesId('section-defaults-link')"
        data-testid="section-defaults-link"
        class="u-txt-red-500"
        href="javascript:void(0)"
        role="button"
        aria-label="Manage default settings for all students"
        @click="openSectionDefaultSettingsDialog">Manage default settings</a>.
    </p>
    <h4 class="c-heading-v3 c-heading-v3--4 u-txt-true-gray-600 u-mar-bot-24">{{ sectionName }}</h4>
  </div>

  <BulkSettingsDropdowns
    v-if="studentsRef.length > 0"
    :languageOptions="languageOptions"
    :programLanguageName="programLanguageName"
    :selectedStudentIds="selectedStudentIds"
    :updateStudentsUrl="updateStudentsUrl"
    :hasAiVirtualChatActivities="props.hasAiVirtualChatActivities"
    :aiInputModes="aiInputModesRef"
    :aiInputModeValues="aiInputModeValuesRef"
    @update:students="handleBulkSettingsUpdate"
  />

  <table v-if="studentsRef.length > 0" class="u-mar-bot-24 c-table-v3" aria-label="Student settings table">
    <thead>
      <tr class="c-table-v3__tr--sticky">
        <th class="c-table-v3__th u-txt-lt u-bord-rt-1 u-txt-middle u-bord-rt-gray-300 u-txt-semibold" scope="col">
          <sl-checkbox
            data-testid="select-all-students"
            :checked="allStudentsSelected"
            :indeterminate="isIndeterminate"
            aria-label="Select all students"
            @sl-change="handleSelectAllChange"
          >
            <span class="u-txt-semibold u-txt-true-gray-900" part="label">All Students</span>
          </sl-checkbox>
        </th>
        <th class="c-table-v3__th u-txt-lt u-txt-middle u-cell-shadow" scope="col">
          <div class="u-mar-bot-4 u-txt-semibold">
            <div class="u-align-icon">
              <span>Video Subtitles and Closed Captions (CC)</span>
              <sl-tooltip :content="`The recommended video subtitles and CC setting for this program is: ${programLanguageName} only`">
                <sl-icon class="u-txt-regular u-txt-body-2" name="info-circle" library="untitled-ui" aria-hidden="true"></sl-icon>
              </sl-tooltip>
            </div>
          </div>
          <div class="u-txt-legal u-txt-regular">
            <a
              :id="appcuesId('video-subtitles-example-link')"
              data-testid="video-subtitles-example-link"
              class="u-txt-red-500"
              href="javascript:void(0)"
              role="button"
              aria-label="View example of video subtitles and closed captions"
              @click="openVideoSubtitlesExampleDialog">Example</a>
          </div>
        </th>
        <th class="c-table-v3__th u-txt-lt u-txt-middle" scope="col">
          <div class="u-mar-bot-4 u-txt-semibold">
            <div class="u-align-icon">
              <span>Video Transcripts</span>
              <sl-tooltip content="The recommended video transcript setting for this program is: Off">
                <sl-icon class="u-txt-regular u-txt-body-2" name="info-circle" library="untitled-ui" aria-hidden="true"></sl-icon>
              </sl-tooltip>
            </div>
          </div>
          <div class="u-txt-legal u-txt-regular">
            <a
              :id="appcuesId('video-transcript-example-link')"
              data-testid="video-transcript-example-link"
              class="u-txt-red-500"
              href="javascript:void(0)"
              role="button"
              aria-label="View example of video transcripts"
              @click="openVideoTranscriptExampleDialog">Example</a>
          </div>
        </th>
        <th class="c-table-v3__th u-txt-lt u-txt-middle" scope="col">
          <div class="u-mar-bot-4 u-txt-semibold">Audio Transcripts</div>
        </th>
        <th v-if="props.hasAiVirtualChatActivities" class="c-table-v3__th u-txt-lt u-txt-middle" scope="col">
          <div class="u-mar-bot-4 u-txt-semibold">
            <div class="u-align-icon">
              <span>AI Interaction Mode</span>
              <sl-tooltip content="AI chat activities only">
                <sl-icon class="u-txt-regular u-txt-body-2" name="info-circle" library="untitled-ui" aria-hidden="true"></sl-icon>
              </sl-tooltip>
            </div>
          </div>
        </th>
      </tr>
    </thead>
    <tbody>
      <StudentSettingsStudentRow
        v-for="(student, index) in studentsRef"
        :key="student.id"
        :appcuesId="index === 0 ? 'appcues-student-settings-student-row' : null"
        :courseId="courseId"
        :programId="programId"
        :sectionId="sectionId"
        :languageOptions="languageOptions"
        :hasAiVirtualChatActivities="props.hasAiVirtualChatActivities"
        :programLanguageName="props.programLanguageName"
        :aiInputModes="aiInputModesRef"
        :aiInputModeValues="aiInputModeValuesRef"
        :student="student"
        :isSelected="selectedStudentIds.includes(student.id)"
        :updateStudentsUrl="updateStudentsUrl"
        @selection-change="handleStudentSelectionChange" />
    </tbody>
  </table>

  <EmptyStudentState
    v-if="studentsRef.length === 0"
    :rostering="rostering"
    :rosterUrl="rosterUrl"
  />

  <ExampleDialog
    title="Video Subtitles & CC Example"
    imageSrc="/images/subtitles-screenshot.jpg"
    dialogClass="video-subtitles-example-dialog"
  />

  <ExampleDialog
    title="Video Transcript Example"
    imageSrc="/images/transcript-screenshot.jpg"
    dialogClass="video-transcript-example-dialog"
  />

  <SectionDefaultsDialog
    :aiInputModes="aiInputModesRef"
    :aiInputModeValues="aiInputModeValuesRef"
    :sectionVideoTranscriptLanguages="sectionVideoTranscriptLanguagesRef"
    :sectionVideoSubtitleLanguages="sectionVideoSubtitleLanguagesRef"
    :sectionAudioTranscript="sectionAudioTranscriptRef"
    :sectionInputMode="sectionInputModeRef"
    :hasAiVirtualChatActivities="props.hasAiVirtualChatActivities"
    :languageOptions="languageOptions"
    :programLanguageName="programLanguageName"
    :updateSectionDefaultsUrl="updateSectionDefaultsUrl"
    @update:students="studentsRef = $event"
    @update:section-settings="updateSectionSettings"
  />
</template>

<script setup>
  import { ref, watch, computed } from 'vue';
  import StudentSettingsStudentRow from './StudentSettingsStudentRow.vue';
  import SectionDefaultsDialog from './SectionDefaultsDialog.vue';
  import ExampleDialog from './ExampleDialog.vue';
  import EmptyStudentState from './EmptyStudentState.vue';
  import BulkSettingsDropdowns from './BulkSettingsDropdowns.vue';
  import { appcuesId } from '../../shared/utils';

  const props = defineProps({
    aiInputModes: {
      type: Object,
      required: true,
    },
    aiInputModeValues: {
      type: Array,
      required: true,
    },
    backToLink: {
      type: String,
      required: true,
    },
    sectionInputMode: {
      type: String,
      required: true,
    },
    courseId: {
      type: Number,
      required: true,
    },
    hasAiVirtualChatActivities: {
      type: Boolean,
      required: true,
    },
    programId: {
      type: Number,
      required: true,
    },
    programLanguageName: {
      type: String,
      required: true,
    },
    programLanguageCode: {
      type: String,
      required: true,
    },
    rostering: {
      type: Boolean,
      required: true,
    },
    rosterUrl: {
      type: String,
      required: true
    },
    sectionName: {
      type: String,
      required: true,
    },
    sectionId: {
      type: Number,
      required: true,
    },
    students: {
      type: Array,
      required: true,
    },
    updateStudentsUrl: {
      type: String,
      required: true,
    },
    updateSectionDefaultsUrl: {
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
  });

  const studentsRef = ref(props.students);
  watch(() => props.students, (newStudents) => {
    studentsRef.value = newStudents;
    // Clear any selected IDs that are no longer in the students list
    selectedStudentIds.value = selectedStudentIds.value.filter(id =>
      newStudents.some(student => student.id === id)
    );
  });

  const aiInputModesRef = ref(props.aiInputModes);
  const aiInputModeValuesRef = ref(props.aiInputModeValues);
  const languageOptions = computed(() => {
    const options = [
      { value: 'none', label: 'Off' },
      { value: 'foreign', label: props.programLanguageName },
    ];

    if (props.programLanguageCode !== 'en') {
      options.push({
        value: 'foreign_and_english',
        label: `${props.programLanguageName} and English`
      });
    }

    return options;
  });

  const sectionVideoTranscriptLanguagesRef = ref(props.sectionVideoTranscriptLanguages);
  const sectionVideoSubtitleLanguagesRef = ref(props.sectionVideoSubtitleLanguages);
  const sectionAudioTranscriptRef = ref(props.sectionAudioTranscript);
  const sectionInputModeRef = ref(props.sectionInputMode);
  const selectedStudentIds = ref([]);

  const allStudentsSelected = computed(() => {
    return selectedStudentIds.value.length === studentsRef.value.length;
  });

  const isIndeterminate = computed(() => {
    return selectedStudentIds.value.length > 0 && selectedStudentIds.value.length < studentsRef.value.length;
  });

  const backToLabel = computed(() => {
    if (props.backToLink.includes('roster')) {
      return 'Back to Roster';
    } else if (props.backToLink.includes('grading') || props.backToLink.includes('dashboard')) {
      return 'Back to Dashboard';
    } else {
      return 'Back';
    }
  });

  const handleStudentSelectionChange = ({ userId, selected }) => {
    if (selected) {
      selectedStudentIds.value.push(userId);
    } else {
      selectedStudentIds.value = selectedStudentIds.value.filter(id => id !== userId);
    }
  };

  const handleSelectAllChange = (event) => {
    if (event.target.checked) {
      selectedStudentIds.value = studentsRef.value.map(student => student.id);
    } else {
      selectedStudentIds.value = [];
    }
  };

  const handleBulkSettingsUpdate = (settings) => {
    // Update settings for all selected students
    studentsRef.value = studentsRef.value.map(student => {
      if (selectedStudentIds.value.includes(student.id)) {
        return {
          ...student,
          ...settings,
        };
      }
      return student;
    });
  };

  const openDialog = (selector) => {
    const dialogElement = document.querySelector(selector);
    if (dialogElement) {
      dialogElement.show();
    }
  };

  const openVideoSubtitlesExampleDialog = () => openDialog('.video-subtitles-example-dialog');
  const openVideoTranscriptExampleDialog = () => openDialog('.video-transcript-example-dialog');
  const openSectionDefaultSettingsDialog = () => openDialog('.section-default-settings-dialog');

  function updateSectionSettings(newSettings) {
    sectionVideoTranscriptLanguagesRef.value = newSettings.sectionVideoTranscriptLanguages;
    sectionVideoSubtitleLanguagesRef.value = newSettings.sectionVideoSubtitleLanguages;
    sectionAudioTranscriptRef.value = newSettings.sectionAudioTranscript;
    sectionInputModeRef.value = newSettings.sectionInputMode;
  }
</script>

<style lang="scss">
  // These l-* styles are overrides of the default behavior.  They're here to allow us to
  // have a sticky header and first column.
  .l-application-v3 {
    height: 100vh;
  }

  .l-content {
    display: flex;
    flex-direction: column;
    padding-top: 16px !important;
  }

  .student-settings {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    align-items: flex-start;

    .u-cell-shadow {
      box-shadow: 16px 0px 16px -16px rgba(0, 0, 0, 0.15) inset;
    }

    .u-align-icon {
      display: inline;
    }

    .u-align-icon sl-icon {
      display: inline-block;
      vertical-align: middle;
      margin-left: 4px;
    }

    .u-align-icon sl-icon::part(base) {
      display: inline-block;
      vertical-align: middle;
    }

    // TODO: These two styles enable a sticky column, but don't work for some reason.  It has to do with
    // the overflow x/y settings of the page.  If overflow-x is set, then the sticky header doesn't
    // work properly.  If it's unset, then the sticky column doesn't work instead. Commenting them
    // out for now since we know we want this later.
    /* thead th:first-child {
      position: sticky;
      top: 0;
      left: 0;
      z-index: 3;
    }

    tr td:first-child {
      position: sticky;
      left: 0;
      z-index: 1;
      background-color: var(--music-util-white);
    } */
  }
</style>
