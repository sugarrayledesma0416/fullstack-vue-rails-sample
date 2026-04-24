<template>
  <div class="path-step  l-stack  l-stack--md">
    <Heading
      level="1"
      variant="page-title"
      :class="testClass('path-step__heading')">
      Course Setup
    </Heading>
    <p class="path-step__info">
      Both options provide access to the same course content and settings.
      Choose the option that best fits your needs:
    </p>

    <div class="path-step__grid">
      <button
        class="path-step__button"
        type="button"
        :class="testClass('path-step__express-setup-button')"
        @click="onExpressSetupClick()">
        <div class="path-step__image-wrapper">
          <ExpressIcon class="path-step__image" alt="A lightning bolt" />
        </div>

        <h3 class="path-step__path-heading" :class="testClass('path-step__path-heading')">
          Express
        </h3>

        <hr class="path-step__separator">

        <div
          class="path-step__course-desc"
          :class="testClass('path-step__course-desc')">
          <p>
            Choose from a variety of pre-built courses that have expertly-curated assignments,
            course settings, and gradebook categories
          </p>
          <p><em>OR</em></p>
          <p>
            Copy assignments, course settings, and gradebook categories from a previous course.
          </p>
        </div>
      </button>

      <button
        class="path-step__button"
        type="button"
        :class="testClass('path-step__advance-setup-button')"
        @click="selectAdvancedSetup()">
        <div class="path-step__image-wrapper">
          <CustomIcon
            class="path-step__image"
            alt="A pencil drawing on a large sheet of paper, with a drafting triangle" />
        </div>

        <h3 class="path-step__path-heading" :class="testClass('path-step__path-heading')">
          Custom
        </h3>

        <hr class="path-step__separator">

        <div
          class="path-step__course-desc"
          :class="testClass('path-step__course-desc')">
          <p>
            Design your own course by choosing assignments, course settings, and
            gradebook categories
          </p>
          <p><em>OR</em></p>
          <p>
            Copy assignments, course settings, and gradebook categories from a
            previous course.
          </p>
        </div>
      </button>
    </div>

    <VhlLink
      href="javascript://"
      class="path-step__cancel"
      :class="testClass('path-step__cancel')"
      @click="courseDataStore.returnToDashboard()">
      Cancel
    </VhlLink>
  </div>
</template>

<script>
  import { inject, onMounted } from 'vue';
  import { scrollToTopOfPage } from 'shared/utils';
  import { testClass } from 'music';
  import { useRouter } from 'vue-router';
  import Heading from 'features/shared/Heading';
  import VhlLink from './VhlLink';
  import ExpressIcon from './ExpressIcon';
  import CustomIcon from './CustomIcon';

  export default {
    name: 'PathSelectorStep',
    components: { VhlLink, ExpressIcon, CustomIcon, Heading },
    setup() {
      const router = useRouter();
      /**
       * Handler for Express Setup button click.
       */
      function onExpressSetupClick() {
        courseDataStore.setPathAndGo('express');
        router.push({ name: 'express-course-step' });
      }

      /**
       * Handler for Advanced Setup button click.
       */
      function selectAdvancedSetup() {
        courseDataStore.setPathAndGo('custom');
        router.push({ name: 'advanced-course-step' });
      }

      const courseDataStore = inject('courseDataStore');

      onMounted(() => {
        scrollToTopOfPage();
      });

      return { courseDataStore, onExpressSetupClick, selectAdvancedSetup, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .path-step {
    font-size: var(--font-3, $font-size-16);
    margin: 0 4rem;
  }

  .path-step__grid {
    display: grid;
    gap: 2rem;
    margin: 1rem auto;

    @include viewport-min(lg) {
      grid-template-columns: 1fr 1fr;
      gap: 1rem 4rem;
      margin: 2rem auto;
      max-width: 60rem;
    }
  }

  .path-step__button {
    display: inline-flex;
    flex-direction: column;
    align-items: center;
    background-color: $white;
    border: rpx(1) solid transparent;
    border-radius: 1rem;
    box-shadow: 0 rpx(1) rpx(3) vhl-shadow(0.6);
    font-size: inherit;
    margin: 0 0 1.5rem;
    padding: 1.5rem 1.75rem;

    &:hover {
      border-color: var(--ui-hover-color, $link-color);
      background-color: var(--ui-hover-border-color, $lightest-blue);
    }
  }

  .path-step__image-wrapper {
    width: 4rem;
    height: 4rem;
    margin: auto;
    margin-bottom: 1rem;
    text-align: center;
  }

  .path-step__image {
    filter: drop-shadow(0 rpx(1) rpx(1) vhl-shadow(0.6));
  }

  .path-step__path-heading {
    color: $gray-3;
    font-size: var(--font-5, $font-size-20);
    font-weight: bold;
    margin-bottom: 1rem;
    padding: 0;
    text-align: center;
    text-transform: uppercase;
  }

  .path-step__separator {
    border-color: $gray-e;
    align-self: stretch;
    margin: 0 0 1.5rem;
  }

  .path-step__info {
    text-align: center;
  }

  .path-step__course-desc {
    flex: 1;
    align-self: start;
  }

  .path-step__course-button {
    float: right;
    margin-top: 1rem;
  }

  .path-step__cancel {
    margin-top: 0.9375rem;
  }
</style>
