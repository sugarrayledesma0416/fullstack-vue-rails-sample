<template>
  <div
    ref="modalElm"
    class="modal-block"
    :class="[
      localstore.sizeVariantClass,
      localstore.featureVariantClass,
    ]">
    <div
      :role="roleType"
      :aria-label="title"
      :aria-labelledby="labelledBy"
      :aria-live="ariaLive"
      aria-modal="true"
      class="modal-block__box"
      :class="[testClass('modal-box'), { 'modal-block__box--scrollable': scrollable === 'auto' }]">
      <button
        v-if="!isConfirmationDialog"
        class="modal-block__close-button  no-button  js-modal-a11y__first-focus-element"
        :class="testClass('modal-close-button')"
        @click.prevent.stop="$emit('close', $event)">
        <Icon :svg="closeSvg" size="md" />
        <span class="screen-reader-only">Close dialog</span>
      </button>

      <div role="document">
        <VhlPanel
          class="mar-bottom-16"
          :hideFooter="hideFooter"
          :hideHeader="hideHeader"
          variant="padded">
          <template
            v-if="!isConfirmationDialog"
            #header>
            <h3 class="modal-block__heading" :class="testClass('modal-heading')">
              {{ title }}
            </h3>
          </template>
          <template #body>
            <slot name="body" />
          </template>
          <template #footer>
            <slot name="footer" />
          </template>
        </VhlPanel>
      </div>
      <button class="screen-reader-only" tabindex="-1">
        Dialog end
      </button>
    </div>
  </div>
</template>

<script>
  import { nextTick, onMounted, ref } from 'vue';
  import { isEmpty } from 'shared/utils';
  import { testClass } from 'music';
  import closeSvg from '!!raw-loader!MusicAssets/images/music/icons/close.svg';
  import Icon from 'features/shared/Icon';
  import VhlPanel from 'features/learning_tracks/components/VhlPanel';

  const SUPPORTED_SIZE = ['sm', 'md', 'lg'];
  const SUPPORTED_VARIANTS = ['category-mappings', 'full-content-area'];

  const useModalComponent = (nextTick) => {
    /**
     * Add cyclic navigation support for TAB/ SHIFT+TAB keys
     * @param {HTMLElement} modal - Modal HTML Element.
     */
    function addCircularNavigation(modal) {
      const firstFocusElement = modal.querySelector('.js-modal-a11y__first-focus-element');

      modal.addEventListener('keydown', (event) => {
        const isTabPressed = event.key === 'Tab' || event.keyCode === 9;
        if (!isTabPressed) {
          return;
        }

        const lastFocusElements = modal.querySelectorAll(
          '.js-modal-a11y__last-focus-element:not([disabled]'
        );
        const lastFocusElement = lastFocusElements[lastFocusElements.length -1];

        if (event.shiftKey) {
          if (document.activeElement === firstFocusElement) {
            lastFocusElement.focus();
            event.preventDefault();
          }
        } else {
          if (document.activeElement === lastFocusElement) {
            firstFocusElement.focus();
            event.preventDefault();
          }
        }
      });
    }

    /**
     * Set default focus on element.
     * @param {HTMLElement} modal - Modal HTML Element.
     */
    function focusDefaultElement(modal) {
      const defaultFocusElement = modal.querySelector('.js-modal-a11y__default-focus');
      if (defaultFocusElement) {
        nextTick(() => {
          defaultFocusElement.focus();
        });
      }
    }

    return { addCircularNavigation, focusDefaultElement };
  };

  export default {
    name: 'ModalComponent',
    components: { Icon, VhlPanel },
    props: {
      featureVariant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_VARIANTS.includes(value),
      },
      isConfirmationDialog: { type: Boolean, default: false },
      hideHeader: { type: Boolean, default: false },
      hideFooter: { type: Boolean, default: false },
      title: { type: String, default: '' },
      labelledBy: { type: String, default: '' },
      roleType: { type: String, default: 'dialog' },
      ariaLive: { type: String, default: '' },
      scrollable: { type: String, default: 'auto' },
      size: {
        default: 'md',
        type: String,
        validator: (value) => SUPPORTED_SIZE.includes(value),
      },
    },
    emits: ['close'],
    setup(props) {
      /**
       * creates a class based on the variant passed.
       * @param {string} variant - variant name passed. It can be variant or
       * feature variant.
       * @return {string} variant class.
       */
      function variantClass(variant) {
        return isEmpty(variant) ? '' : `modal-block--${variant}`;
      }

      const localstore = {
        sizeVariantClass: variantClass(props.size),
        featureVariantClass: variantClass(props.featureVariant),
      };
      const modalElm = ref(null);

      const { addCircularNavigation, focusDefaultElement } = useModalComponent(nextTick);

      onMounted(() => {
        focusDefaultElement(modalElm.value);
        addCircularNavigation(modalElm.value);
      });

      return { closeSvg, localstore, modalElm, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/tools/media_queries';

  $black: #000;
  $blue: #006bae;
  $font-size-16: 1rem;
  $font-size-20: 1.25rem;
  $gray-3:#333;
  $mod: 1rem;
  $modal-border-radius: 0.1875rem;
  $white: #fff;
  $z-modal: 40;

  $breakpoints: (
    xs: 375px,
    sm: 500px,
    md: 700px,
    lg: 900px,
    xl: 1100px,
  );

  @function mod($size) {
    @return $mod * $size;
  }

  @function vhl-shadow($opacity) {
    @return transparentize($black, 1 - $opacity);
  }


  .modal-block {
    align-items: center;
    background-color: vhl-shadow(0.5);
    display: flex;
    height: 100%;
    justify-content: center;
    left: 0;
    position: fixed;
    top: 0;
    width: 100%;
    z-index: $z-modal;
  }

  .modal-block__box {
    background-color: $white;
    border-radius: $modal-border-radius;
    box-shadow: 0.0625rem 0.25rem 0.375rem 0 vhl-shadow(0.18);
    font-size: $font-size-16;
    line-height: 1.5714285714;
    margin: mod(1) 0 mod(2);
    max-width: 80%;
    max-height: 95%;
    overflow: auto;
    position: relative;
    text-align: left;
  }

  .modal-block__box--scrollable {
    overflow: auto;
  }

  .modal-block__body {
    padding: mod(1) mod(3) mod(1) mod(2);
  }

  .no-button {
    background: transparent;
    border: 0;
    border-radius: 0;
    color: $blue;
    cursor: pointer;
    outline: 0.125rem solid transparent;
    outline-offset: 0.125rem;
    padding: 0;
    -webkit-transition: color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
    -o-transition: color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
    transition: color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
  }

  .modal-block__close-button {
    padding: mod(0.5);
    position: absolute;
    right: mod(0.5);
    top: mod(0.5);
  }

  .modal-block__heading {
    color: $gray-3;
    font-size: 1.25rem;
    margin: 0;
  }

  .screen-reader-only {
    border: 0;
    clip: rect(0 0 0 0);
    height: 0.0625rem;
    margin: -0.0625rem;
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: 0.0625rem;
  }

  .mar-bottom-16 {
    margin-bottom: 1rem;
  }

  .modal-block--category-mappings {
    .modal-block__close-button {
      top: 0;
    }
  }

  .modal-block--full-content-area {
    .modal-block__box {
      @include viewport-max(xl) {
        max-width: 95%;
        width: 95%;
      }

      @include viewport-max(md) {
        max-width: 100%;
        max-height: 100%;
        width: 100%;
        height: 100%
      }
    }
  }

  .modal-block--sm {
    .modal-block__box {
      @include viewport-min(md) {
        max-width: 50%;
      }
    }
  }
</style>
