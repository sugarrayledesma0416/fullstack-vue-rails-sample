<template>
  <div
    lang="en"
    role="document"
    class="assessment-unstarted"
    data-helpable-type="assessment_detail">
    <div class="assessment-detail-header">
      <h3 class="assessment-header-title">
        Assessment Details
      </h3>
    </div>
    <div class="assessment-detail-body">
      <div v-if="isTimedAssessment">
        <p
          class="assessment-info-timed"
          :class="testClass('assessment-info-timed')">
          <span
            class="assessment-info-bold"
            :class="testClass('assessment-info-bold')">
            You have {{ assessmentTimeLimit }} to complete this assessment.
          </span><br>
          Once you start, you will not be able to stop or pause the timer.
        </p>
        <hr>
      </div>
      <QuestionDetails :questionSummary="questionSummary" />
      <Requirements v-if="hasValidRequirement" :icons="icons" />
      <Rules :rules="rules" />
      <div
        class="move-to-assessment">
        <StandardButton
          variant="link"
          class="assessment-info-btn  assessment-cancel-btn"
          :class="testClass('assessment-cancel-btn')"
          @click="redirectToUrl(returnUrl)">
          Cancel
        </StandardButton>
        <StandardButton
          v-if="!isSupersiteJr && pretestType !== ''"
          variant="primary"
          class="assessment-info-btn  pre-test-connection-btn"
          :class="testClass('pre-test-connection')"
          @click="$emit('start-pre-test')">
          <span class="wifi-icon">
            <span class="pre-test-connection-txt">Test Connection</span>
          </span>
        </StandardButton>
        <StandardButton
          v-else
          variant="primary"
          class="assessment-info-btn  assessment-start-btn"
          :class="testClass('assessment-start-btn')"
          @click="redirectToUrl(beginAssessmentUrl)">
          {{ isSupersiteJr ? "Start" : "Begin Assessment" }}
        </StandardButton>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { StandardButton, testClass } from 'music';
  import { redirectToUrl } from 'shared/utils.js';
  import { computed } from 'vue';
  import QuestionDetails from './QuestionDetails';
  import Rules from './Rules';
  import Requirements from './Requirements';

  const props = defineProps({
    assessmentTimeLimit: { default: '', type: String },
    beginAssessmentUrl: { default: '', type: String },
    icons: { default: '', type: String },
    isTimedAssessment: { required: true, type: Boolean },
    isSupersiteJr: { required: true, type: Boolean },
    pretestType: { default: '', type: String },
    questionSummary: { default: '', type: String },
    returnUrl: { default: '', type: String },
    rules: { default: '', type: String },
  });

  defineEmits(['start-pre-test']);

  const hasValidRequirement = computed(() => {
    const validWords = ['solo_video_recording', 'partner_chat', 'audio', 'microphone', 'video'];
    return validWords.some((word) => props.icons.includes(word));
  });
</script>

<style lang="scss" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

.assessment-unstarted {
  background-color: #fff;
  border: 0.0625rem solid #E2E2E2;
  border-radius: 0.375rem;
  box-shadow: 0 0.125rem 0.25rem 0 rgba(0, 0, 0, 0.25);
  font-size: 1rem;
  margin: 0 auto 1.25rem auto;
  width: 40vw;

  @include viewport-max('sm') {
    width: 100%;
  }
}

.assessment-detail-header {
  border-radius: 0.375rem 0.375rem 0 0;
  background: #F3F3F3;
  height: 4.188rem;
  padding: 1rem 2rem;
}

.assessment-detail-body {
  padding: 1rem 2rem;
}

.assessment-header-title {
  color: var(--yellow-darkest);
  font-size: 1.25rem;
  font-weight: normal;
  margin-bottom: 0;
}

.assessment-info-timed {
  min-height: 2.25rem;
  margin: 1rem 0 1rem;
}

.assessment-info-bold {
  font-weight: bold;
}

.move-to-assessment {
  display: flex;
  justify-content: space-between;
  padding-top: 3rem;
}

.assessment-cancel-btn {
  text-transform: uppercase;
}

.move-to-assessment .pre-test-connection-btn {
  padding: 0.5rem 0.813rem;
}

.pre-test-connection-txt {
  font-size: 1rem;
  margin-left: 2rem;
}

.wifi-icon {
  background: url(/images/wifi_outline.svg) no-repeat 0 0;
}

.t-supersites-jr {
  .assessment-unstarted {
    font-size: 1.375rem;
    max-width: 44.25rem;
  }

  .assessment-detail-header {
    background-color: var(--yellow-lightest);
  }

  .assessment-header-title {
    font-size: 1.375rem;
  }

  .move-to-assessment {
    display: flex;
    justify-content: center;
  }

  .assessment-info-btn {
    font-size: 2.5rem;
    font-weight: bold;
    left: 0;
    padding: 0.5rem 1.5rem;
    position: relative;
    text-transform: capitalize;
    top: 0;
    transition: none;

    &:focus-visible {
      box-shadow:
        0.125rem 0.125rem 0 0.125rem var(--ui-primary-darker),
        0.125rem 0.125rem 0 0.25rem var(--ui-secondary-darker),
        0.125rem 0.125rem 0 0.6rem var(--ui-secondary-lighter);
    }
  }

  .assessment-start-btn {
    background-color: var(--green-medium);
    border: 0.125rem solid transparent;
    border-radius: 0.5rem;
    box-shadow: 0.25rem 0.4rem 0 var(--green-darker);
    color: #fff;
    text-shadow: 0.125rem 0.125rem 0.125rem var(--green-darker);

    &:hover {
      background: var(--green-medium);
      box-shadow: 0.125rem 0.125rem 0 var(--green-darker);
      left: calc( 0.25rem * 0.5);
      top: calc( 0.25rem * 0.5);
    }

    &:focus {
      outline: 0;
    }

    @include viewport-max('sm') {
      margin-top: 1.5rem;
      padding: 1rem 2.2rem;
    }
  }

  .assessment-cancel-btn {
    background-color: #fff;
    border: 0.125rem solid #ccc;
    border-radius: 0.5rem;
    box-shadow: 0.25rem 0.4rem 0 #ccc;
    color: var(--green-medium);
    margin-right: 1.5rem;

    &:hover:not([disabled]) {
      box-shadow: 0 0 0 #ccc;
      color: var(--green-medium);
      left: calc( 0.25rem * 0.5);
      text-decoration: none;
      top: calc( 0.25rem * 0.5);
    }

    &:focus {
      outline: 0;
    }

    @include viewport-max('sm') {
      margin-right: 0;
    }
  }
}

@include viewport-max('sm') {
  .move-to-assessment {
    align-items: center;
    flex-direction: column;
  }

  .assessment-info-btn {
    margin-top: 1rem;
  }
}
</style>

