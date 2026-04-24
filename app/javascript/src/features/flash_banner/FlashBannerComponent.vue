<template>
  <div class="ns-music-v1" :class="testClass('flash-banner')">
    <div class="u-pos-rel">
      <div
        v-if="currentMessage.shown"
        class="c-flash-banner-group  can-fade"
        :class="[{ 'is-faded-out': currentMessage.fadedOut }, testClass('flash-banner-group')]">
        <div
          :class="`c-flash-banner--${currentMessage.className}  ${testClass(`flash-banner--${currentMessage.className}`)}`"
          class="c-flash-banner"
          role="alert">
          <div class="l-media">
            <div class="l-media__img">
              <span
                class="c-flash-banner__icon"
                :class="`c-flash-banner__icon--${currentMessage.className}`" />
              <span class="u-screen-reader-only">{{ currentMessage.className }}</span>
            </div>
            <div class="l-media__body" :class="testClass('flash-message')">
              {{ currentMessage.text }}
            </div>
          </div>
          <div
            v-if="currentMessage.announce"
            class="u-screen-reader-only"
            :class="testClass('screen-reader')"
            aria-live="assertive">
            {{ currentMessage.text }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import { reactive, watch } from 'vue';

  const useFlashMessage = (currentMessage) => {
    const updateCurrentMessage = (data) => {
      currentMessage.announce = data.announce || false;
      currentMessage.className = data.className;
      currentMessage.fadedOut = data.fadedOut || false;
      currentMessage.shown = data.shown;
      currentMessage.text = data.text;
    };

    return { updateCurrentMessage };
  };

  export default {
    name: 'FlashBannerComponent',
    props: {
      message: {
        type: Object,
        default: () => ({
          announce: false,
          className: '',
          shown: false,
          text: '',
        }),
      },
      timeout: {
        type: Number,
        default: 10000,
      },
    },
    emits: ['reset'],
    setup(props, { emit }) {
      const { timeout } = props;
      const message = reactive(props.message);
      const currentMessage = reactive({ ...message });

      watch(() => message.shown, (value) => {
        updateCurrentMessage(message);
        if (value) {
          setTimeout(() => {
            emit('reset');
          }, timeout);
        }
      });

      const { updateCurrentMessage } = useFlashMessage(currentMessage);

      return { currentMessage, testClass, updateCurrentMessage };
    },
  };
</script>
