<template>
  <transition
    name="expand"
    @enter="enter"
    @after-enter="afterEnter"
    @leave="leave">
    <div
      v-show="expand"
      class="expandable-body"
      :class="[
        { expanded: expand },
        testClass('expanded-body')
      ]">
      <slot />
    </div>
  </transition>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'Expandable',
    props: {
      expand: { default: false, type: Boolean },
    },
    setup(props) {
      /**
       * This is event handler for enter transition event.
       * This calculates element's height when its height is auto and
       * triggers animation to change height from 0 to calculated height.
       *
       * To calculate computedHeight, function positions the element absolute
       * to prevent it having an effect on other elements when its height is set to auto.
       * Also sets the width explicitly so the element still has the same dimensions.
       * And reverts changes on element style after calculation.
       * @param {HTMLElement} element
       */
      function enter(element) {
        const width = getComputedStyle(element).width;

        element.style.width = width;
        element.style.position = 'absolute';
        element.style.visibility = 'hidden';
        element.style.height = 'auto';

        const computedHeight = getComputedStyle(element).height;

        element.style.width = null;
        element.style.position = null;
        element.style.visibility = null;
        element.style.height = 0;

        // Force repaint to make sure the animation is triggered correctly.
        getComputedStyle(element);

        requestAnimationFrame(() => {
          element.style.height = computedHeight;
        });
      }

      /**
       * This is event handler for after-enter transition event.
       * This sets element's height to auto.
       * @param {HTMLElement} element
       */
      function afterEnter(element) {
        element.style.height = 'auto';
      }

      /**
       * This is event handler for leave transition event.
       * This calculates element's height and triggers animation
       * to change height from computedHeight to 0.
       * @param {HTMLElement} element
       */
      function leave(element) {
        element.style.height = getComputedStyle(element).height;

        // Force repaint to make sure the animation is triggered correctly.
        getComputedStyle(element);

        requestAnimationFrame(() => {
          element.style.height = 0;
        });
      }

      return { afterEnter, enter, leave, testClass };
    },
  };
</script>

<style scoped>
  .expand-enter-active,
  .expand-leave-active {
    overflow: hidden;
    transition: height 250ms ease-in-out;
  }

  .expand-enter,
  .expand-leave-to {
    height: 0;
  }
</style>
