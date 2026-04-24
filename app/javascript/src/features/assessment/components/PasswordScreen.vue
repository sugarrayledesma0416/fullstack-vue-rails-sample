<template>
  <div
    lang="en"
    role="document"
    class="password-screen"
    data-helpable-type="password_required">
    <div class="password-header">
      <h3
        class="password-header-title"
        :class="testClass('password-header-title')">
        Password Required
      </h3>
    </div>
    <div class="password-body">
      <p
        class="enter-password-info"
        :class="testClass('enter-password-info')">
        Enter the password required to begin this assessment.
      </p>
      <div class="field">
        <div class="password-input-wrapper">
          <input
            id="assessment_password"
            v-model="passwordInput"
            class="password-input"
            :class="testClass('password-input')"
            type="password"
            name="assessment_password"
            placeholder="Password"
            @keyup.enter.stop="unlockAssessment($event)">
        </div>
        <div
          v-if="errorMessage.value != ''"
          class="password-error-message"
          :class="testClass('password-error-message')">
          {{ errorMessage }}
        </div>
        <input
          id="section_id"
          :class="testClass('section-id')"
          type="hidden"
          name="section_id"
          :value="requestArr[2]"
          autocomplete="off">
        <input
          id="activity_id"
          :class="testClass('activity-id')"
          type="hidden"
          name="activity_id"
          :value="requestArr[4]"
          autocomplete="off">
        <input
          id="url"
          type="hidden"
          name="url"
          :value="`/sections/${requestArr[2]}/activities/${requestArr[4]}`"
          autocomplete="off">
      </div>

      <div class="assessment-password-unlock">
        <StandardButton
          variant="link"
          class="password-screen-btn  password-cancel-btn"
          :class="testClass('password-cancel')"
          @click="redirectToUrl(returnUrl)">
          Cancel
        </StandardButton>
        <StandardButton
          variant="primary"
          class="password-screen-btn  password-continue-btn"
          :class="testClass('password-continue')"
          @click="unlockAssessment($event)">
          continue
        </StandardButton>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { StandardButton, testClass } from 'music';
  import { redirectToUrl } from 'shared/utils.js';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { ref } from 'vue';

  const props = defineProps({
    requestPath: { default: '', type: String },
    returnUrl: { default: '', type: String },
  });
  const emit = defineEmits(['unlockAssessment']);

  const requestArr = props.requestPath.split('/');
  const passwordInput = ref('');
  const errorMessage = ref('');

  /**
   * Unlocks an assessment by sending a request to the server.
   * @param {Event} evt - The event triggering the function.
   */
  function unlockAssessment(evt) {
    ajaxUtils.postToEndpoint(
      '/assessment_access/unlock',
      {
        assessment_password: passwordInput.value,
        section_id: requestArr[2],
        activity_id: requestArr[4],
      },
      (response) => {
        if (response.success) {
          emit('unlockAssessment', false);
        } else {
          errorMessage.value = response.error;
          passwordInput.value = '';
        }
      }
    );
  }
</script>

<style lang="scss" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

.password-screen {
  background-color: #fff;
  border: 0.0625rem solid #E2E2E2;
  border-radius: 0.1875rem;
  box-shadow: 0 0.125rem 0.25rem 0 rgba(0, 0, 0, 0.25);
  font-size: 1rem;
  max-width: 39.25rem;
  width: 40vw;

  @include viewport-max('sm') {
    width: 100%;
  }
}

.password-header {
  background-color: #f5f5f5;
  padding: 1rem 2rem;
}

.password-header-title {
  color: #000;
  font-size: 1.25rem;
  font-weight: normal;
  margin-bottom: 0;
}

.password-body {
  padding: 1rem 2rem;
}

.enter-password-info {
  font-weight: bold;
  margin: 1rem 0 1rem;
}

.password-input {
  border: 0.0625rem solid #ddd;
  line-height: 2rem;
  padding-left: 0.5rem;
}

.assessment-password-unlock {
  display: flex;
  justify-content: space-between;
  padding-top: 3rem;
}

.password-error-message {
  color: red;
  display: flex;
  justify-content: right;
  padding-top: 1rem;
}

.password-cancel-btn {
  text-transform: uppercase;
}

.password-input-wrapper {
  @include viewport-max('sm') {
    flex-direction: column;
    display: flex;
  }
}

.t-supersites-jr {
  .password-screen {
    font-size: 1.375rem;
  }

  .password-header {
    background-color: var(--yellow-lightest);
  }

  .password-header-title {
    color: var(--yellow-darkest);
    font-size: 1.375rem;
  }

  .password-screen-btn {
    font-size: 2.5rem;
    font-weight: bold;
    left: 0;
    margin-bottom: 0.25rem;
    padding: 0.5rem 1.5rem;
    position: relative;
    top: 0;
    transition: none;
  }

  .password-continue-btn {
    color: #fff;
    background-color: var(--green-medium);
    border: 0.125rem solid transparent;
    border-radius: 0.5rem;
    box-shadow: 0.25rem 0.4rem 0 var(--green-darker);
    margin-left: 1rem;
    text-shadow: 0.125rem 0.125rem 0.125rem var(--green-darker);
    text-transform: capitalize;

    &:hover {
      background: var(--green-medium);
      box-shadow: 0.125rem 0.125rem 0 var(--green-darker);
      top: calc(0.25rem * 0.5);
      left: calc(0.25rem * 0.5);
    }

    &:focus {
      outline: 0;
    }

    @include viewport-max('sm') {
      margin-top: 1rem;
      padding: 1.2rem;
    }
  }

  .password-cancel-btn {
    background-color: #fff;
    border: 0.125rem solid #ccc;
    border-radius: 0.5rem;
    box-shadow: 0.25rem 0.4rem 0 #ccc;
    color: var(--green-medium);
    text-transform: capitalize;

    &:hover:not([disabled]) {
      box-shadow: 0 0 0 #ccc;
      color: var(--green-medium);
      left: calc(0.25rem * 0.5);
      text-decoration: none;
      top: calc(0.25rem * 0.5);
    }

    &:focus {
      outline: 0;
    }
  }

  .password-input {
    background-color: var(--green-lightest);
    border: 0.063rem solid var(--green-medium);
    border-radius: 0.375rem;
    line-height: 2.5rem;

    &:focus {
      outline-color: transparent;
    }

    @include viewport-max('sm') {
      display: flex;
      flex-direction: column;
    }
  }

  .assessment-password-unlock {
    justify-content: space-evenly;
    padding: 3rem 0rem 1rem;

    @include viewport-max('sm') {
      align-items: center;
      flex-direction: column;
    }
  }
}
</style>

