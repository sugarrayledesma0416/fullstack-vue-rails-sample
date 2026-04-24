<template>
  <ModalComponent
    :title="title"
    @close="onCloseClick($event)">
    <template #body>
      <div
        :class="[
          {
            'screenshot--subtitle': mode === 'subtitle',
            'screenshot--transcript': mode === 'transcript',
          },
          testClass('screenshot-body')
        ]" />
    </template>
  </ModalComponent>
</template>

<script>
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';

  const SUPPORTED_MODES = ['subtitle', 'transcript'];

  export default {
    name: 'Screenshot',
    components: { ModalComponent },
    props: {
      mode: {
        default: '',
        type: String,
        validator: (value) => SUPPORTED_MODES.includes(value),
      },
      title: { default: '', type: String },
    },
    emits: ['close'],
    setup(props, { emit }) {
      /**
       * This is handler for close event from ModalComponent
       * @param {Event} event
       */
      function onCloseClick(event) {
        emit('close', event);
      }

      return { onCloseClick, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  .screenshot--subtitle {
    background: url('/images/subtitles-screenshot.jpg') no-repeat;
    height: 480px;
    width: 860px;
  }

  .screenshot--transcript {
    background: url('/images/transcript-screenshot.jpg') no-repeat;
    height: 287px;
    width: 860px;
  }
</style>
