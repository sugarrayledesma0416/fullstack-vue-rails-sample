<template>
  <div class="ns-music-v1">
    <div
      ref="refMediaButton"
      :class="[
        'c-media-button-wrapper',
        { 'c-media-button-wrapper--sm': mediaButtonModel.size == 'sm' },
        mediaButtonModel.classes
      ]">
      <!-- There are few differences in html for medium size vs small size media button.
        Eg. 'md' size media button has loading indicator and volume spinner
        but 'sm' size media button does not have. Also 'md' size media button loads icon svg via
        css definition (background-image) while 'sm' size media button has svg tag embedded in html.
      -->
      <template v-if="mediaButtonModel.size == 'md' ">
        <button
          type="button"
          :data-default-text="mediaButtonModel.text"
          :class="[
            'js-v1-button',
            'c-media-button',
            `c-media-button--${mediaButtonModel.variant}`,
            mediaButtonModel.stateClass,
            mediaButtonModel.toggleClass
          ]"
          :disabled="mediaButtonModel.state == 'disabled'"
          :aria-label="mediaButtonModel.text">
          <div class="c-media-button__loading">
            <MusicLoadingIndicator />
          </div>

          <div
            v-if="mediaButtonModel.hasVolume"
            class="c-volume-spinner  u-hidden  js-volume-spinner" />
        </button>

        <!-- Add conditional to show / hide js-media-button _label so that the toggle event does not affect the other kind of media buttons -->
        <p
          v-if="mediaButtonModel.text"
          :class="[
            'c-media-button__label',
            { 'js-media-button__label': mediaButtonModel.toggle != 'default' },
          ]"
          aria-hidden="true">
          {{ mediaButtonModel.text }}
        </p>
        <p
          v-if="mediaButtonModel.toggle != 'default'"
          class="c-media-button__label  c-txt-capitalize  u-hidden  js-media-button__label"
          aria-hidden="true">
          {{ mediaButtonModel.toggle }}
        </p>
        <div
          class="u-screen-reader-only"
          aria-live="polite"
          aria-atomic="true">
          <!-- data-announce-state value seems was not in quote -->
          {{ mediaButtonModel.text }}
          <span
            class="js-announce-state"
            :data-announce-state="mediaButtonModel.announceStateChange" />
        </div>
      </template>

      <template v-else-if="mediaButtonModel.size == 'sm' ">
        <button
          type="button"
          :data-default-text="mediaButtonModel.text"
          :class="['js-v1-button', 'c-no-button', mediaButtonModel.stateClass]"
          :disabled="mediaButtonModel.state == 'disabled'">
          <MusicIcon
            :variant="mediaButtonModel.iconVariant"
            :classes="['js-v1-icon']"
            size="md"
            :text="mediaButtonModel.text" />
          <MusicIcon
            v-if="mediaButtonModel.toggle != 'default'"
            :variant="mediaButtonModel.toggleIconSm"
            :classes="['u-hidden', 'js-v1-icon']"
            size="md"
            :text="mediaButtonModel.text" />
        </button>
      </template>
    </div>
  </div>
</template>

<script>
  import MusicIcon from './MusicIcon';
  import MusicLoadingIndicator from './MusicLoadingIndicator';
  import useMusicMediaButtonModel from './use_music_media_button_model';
  import { onMounted, ref, toRefs, watch } from 'vue';

  /**
  Approach Note: We ported this component as is from music media button component in ruby.
    This VueJs component generates initial HTML based on props.
    And after initialization, the further functionality and DOM manipulation is delegated
    to javascript class VHL.Music.V1.MediaButton.

    Please note that, change in props may not update this component's html, except for the props
    which we handled in watcher. We can add support for more props in watcher if needed.
  */

  const ALLOWED_VARIANTS = [
    'speak',
    'listen',
    'review',
    'correct',
    'watch',
    'compare',
    'pause',
    'play',
    'record',
    'startover',
    'next',
  ];
  const ALLOWED_STATES = ['default', 'hidden', 'disabled', 'loading', 'active'];
  const ALLOWED_SIZES = ['sm', 'md'];
  const ALLOWED_TOGGLE_OPTIONS = ['default', 'stop', 'pause'];

  const stateArgMap = {
    default: 'DEFAULT',
    disabled: 'DISABLED',
    active: 'ACTIVE',
    loading: 'LOADING',
    hidden: 'HIDDEN',
  };

  const useConnectionWithMediaButtonJs = (mediaButtonInstance, props) => {
    const { state, onActivate, onDeactivate } = toRefs(props);

    const initMediaButton = (refMediaButton, propsObj) => {
      // After initialization, the further functionality and DOM manipulation is delegated
      //  to javascript class VHL.Music.V1.MediaButton.
      const buttonElm = refMediaButton.value;
      if (typeof $ !== 'undefined') {
        return new VHL.Music.V1.MediaButton({
          $button: $(buttonElm),
          activate: propsObj.onActivate,
          deactivate: propsObj.onDeactivate,
          volume: propsObj.onVolume,
        });
      }
    };

    /**
      * This method is to provide VHL.Music.V1.MediaButton's reset method to outside components.
      * This clears all button states and returns button to default state.
      * @param {object} callbacks - An optional argument for replacing the callback actions.
      *  Format is {activate, deactivate}
      */
    const resetMediaButton = (callbacks) => {
      mediaButtonInstance.value?.reset(callbacks);
    };

    watch(
      state,
      (newValue) => {
        if (mediaButtonInstance.value) {
          mediaButtonInstance.value.state = stateArgMap[newValue];
        }
      }
    );

    watch(
      onActivate,
      (newValue) => {
        if (mediaButtonInstance.value) {
          const callbacks = {
            activate: newValue,
          };
          mediaButtonInstance.value.reset(callbacks);
        }
      }
    );

    watch(
      onDeactivate,
      (newValue) => {
        if (mediaButtonInstance.value) {
          const callbacks = {
            deactivate: newValue,
          };
          mediaButtonInstance.value.reset(callbacks);
        }
      }
    );

    return { initMediaButton, resetMediaButton };
  };

  export default {
    name: 'MusicMediaButton',
    components: {
      MusicIcon,
      MusicLoadingIndicator,
    },
    props: {
      classes: {
        type: Array,
        default: [],
      },
      onActivate: Function,
      onDeactivate: Function,
      onVolume: Function,
      size: {
        type: String,
        default: 'md',
        validator: (value) => {
          return ALLOWED_SIZES.includes(value);
        },
      },
      state: {
        type: String,
        default: 'default',
        validator: (value) => {
          return ALLOWED_STATES.includes(value);
        },
      },
      text: String,
      toggle: {
        type: String,
        default: 'default',
        validator: (value) => {
          return ALLOWED_TOGGLE_OPTIONS.includes(value);
        },
      },
      variant: {
        type: String,
        required: true,
        validator: (value) => {
          return ALLOWED_VARIANTS.includes(value);
        },
      },
      volume: {
        type: Boolean,
        default: false,
      },
    },
    setup(props) {
      const refMediaButton = ref(null);
      const mediaButtonInstance = ref(null);
      const {
        initMediaButton,
        resetMediaButton,
      } = useConnectionWithMediaButtonJs(mediaButtonInstance, props);
      const { getModel } = useMusicMediaButtonModel(props);

      onMounted(() => {
        mediaButtonInstance.value = initMediaButton(refMediaButton, props);
      });

      // destructuring for clarity of what fields are expected / used here.
      const {
        announceStateChange,
        classes,
        hasVolume,
        iconVariant,
        size,
        state,
        stateClass,
        text,
        toggle,
        toggleClass,
        toggleIconSm,
        variant,
      } = getModel();

      return {
        mediaButtonModel: {
          announceStateChange,
          classes,
          hasVolume,
          iconVariant,
          size,
          state,
          stateClass,
          text,
          toggle,
          toggleClass,
          toggleIconSm,
          variant,
        },
        refMediaButton,
        resetMediaButton,
      };
    },
  };
</script>

<style scoped>
  .c-txt-capitalize {
    text-transform: capitalize;
  }
</style>
