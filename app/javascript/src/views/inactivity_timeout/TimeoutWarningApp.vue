<template>
  <TimeoutWarningModal
    v-show="inactivityTimeout.dialogData.show"
    :remainingTime="inactivityTimeout.dialogData.remainingTime"
    @signout="signOutUser"
    @confirm="confirmUserActivity" />
</template>

<script setup>
  import { inject } from 'vue';
  import TimeoutWarningModal from './TimeoutWarningModal';

  const inactivityTimeout = inject('inactivityTimeout');

  /**
   * Inform inactivityTimeout poller about user's
   * confirmation on Timeout Warning dialog.
   */
  function confirmUserActivity() {
    inactivityTimeout.confirmUserActivity();
  }

  /**
   * Inform inactivityTimeout poller about user's
   * choice to log out.
   */
  function signOutUser() {
    inactivityTimeout.signOutUser();
  }
</script>
