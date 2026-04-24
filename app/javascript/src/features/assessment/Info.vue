<template>
  <div class="assessment-info">
    <PasswordScreen
      v-if="showPasswordScreen"
      :requestPath="requestPath"
      :returnUrl="returnUrl"
      @unlock-assessment="unlockAssessment" />
    <AssessmentDetails
      v-if="showAssessmentDetailScreen"
      :isSupersiteJr="isSupersiteJr === 'true'"
      :isTimedAssessment="isTimedAssessment === 'true'"
      :assessmentTimeLimit="assessmentTimeLimit"
      :returnUrl="returnUrl"
      :rules="rules"
      :icons="icons"
      :pretestType="getPretestType()"
      :questionSummary="questionSummary"
      :beginAssessmentUrl="beginAssessmentUrl"
      @start-pre-test="startPretest" />
    <PretestApp
      v-if="localStore.showPretest"
      :beginAssessmentUrl="beginAssessmentUrl"
      :pretestFlow="PretestFlowEnum.ON_ASSESSMENT_INFO"
      :pretestType="getPretestType()"
      @pretest-ended="stopPretest"
      @hide-bg="onHideBackground" />
  </div>
</template>

<script setup>
  import { computed, reactive } from 'vue';
  import AssessmentDetails from './components/AssessmentDetails';
  import PasswordScreen from './components/PasswordScreen';
  import { PretestApp } from 'mae';

  const StepsEnum = {
    PASSWORD: 'PASSWORD',
    ASSESSMENT_DETAIL: 'ASSESSMENT_DETAIL',
  };

  const PretestTypeEnum = {
    AUDIO: 'AUDIO',
    AUDIO_VIDEO: 'AUDIO_VIDEO',
  };

  const PretestFlowEnum = {
    ON_ACTIVITY: 'ON_ACTIVITY',
    ON_ASSESSMENT_INFO: 'ON_ASSESSMENT_INFO',
  };

  const props = defineProps({
    assessmentTimeLimit: { default: '', type: String },
    beginAssessmentUrl: { default: '', type: String },
    icons: { default: '', type: String },
    isSupersiteJr: { default: '', type: String },
    isTimedAssessment: { default: '', type: String },
    pretestType: { default: '', type: String },
    questionSummary: { default: '', type: String },
    requestPath: { default: '', type: String },
    requireUnlocking: { default: '', type: String },
    returnUrl: { default: '', type: String },
    rules: { default: '', type: String },
  });

  const localStore = reactive({
    currentAppStep: getFirstStep(),
    hideBackgroundScreen: false,
    showPretest: false,
  });

  const showPasswordScreen = computed(() => {
    return localStore.currentAppStep === StepsEnum.PASSWORD;
  });

  const showAssessmentDetailScreen = computed(() => {
    return [
      StepsEnum.ASSESSMENT_DETAIL,
    ].includes(localStore.currentAppStep) && (
      !localStore.hideBackgroundScreen
    );
  });

  /**
   * Return initial screen for the vue app.
   * @return {string}
   */
  function getFirstStep() {
    return props.requireUnlocking === 'true' ? StepsEnum.PASSWORD: StepsEnum.ASSESSMENT_DETAIL;
  }

  /**
   * Change the screen to Assessment Detail if password step is passed.
   * @param {boolean} requireUnlock - boolean indicating whether unlocking of
   * assessment is required.
   */
  function unlockAssessment(requireUnlock) {
    if (!requireUnlock) {
      localStore.currentAppStep = StepsEnum.ASSESSMENT_DETAIL;
    }
  }

  /**
   * Launch pretest flow.
   */
  function startPretest() {
    localStore.showPretest = true;
  }

  /**
   * Stop pretest.
   */
  function stopPretest() {
    localStore.showPretest = false;
  }

  /**
   * Set whether background screen should be hidden.
   * @param {bool} bHide
   */
  function onHideBackground(bHide) {
    localStore.hideBackgroundScreen = bHide;
  }

  /**
   * Return correct pretest type based on requirements in the Assessment.
   * @return {string}
   */
  function getPretestType() {
    const pretestTypeMap = {
      'audio': PretestTypeEnum.AUDIO,
      'video': PretestTypeEnum.AUDIO_VIDEO,
    };

    return pretestTypeMap[props.pretestType] || '';
  }
</script>

<style scoped>
  .assessment-info {
    align-items: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
</style>
