<template>
  <div
    class="assessment"
    :class="testClass(`assessment-workset-${index}`)">
    <div
      class="assessment__picture">
      <vhl-icon size="xxxl" :path="worksetIconPath" />
    </div>

    <div class="c-vertical-divider" />
    <hr>
    <div>
      <div class="assessment__info">
        <div class="assessment__status" :class="testClass('due-date')">
          Due {{ assessment.due_date }}
        </div>
        <span class="assessment__full-title" :class="testClass('full-title')">
          <!-- eslint-disable vue/no-v-html -->
          <span class="assessment__lesson-name" v-html="assessment.lesson" />
          <!-- eslint-enable vue/no-v-html -->
          <!-- maybe overkill, but color of pipe is different in comp -->
          <span class="assessment__pipe">|</span>
          <span class="assessment__title">{{ assessment.title }}</span>
        </span>
      </div>

      <div class="assessment__go-button-wrapper">
        <form
          class="button_to"
          :class="testClass('assessment-link')"
          method="get"
          :action="assessment.link">
          <input
            class="c-button  c-button--jr  c-button--jr-primary  u-no-width"
            type="submit"
            value="Go">
        </form>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';

  export default {
    props: {
      assessment: { required: true, type: Object },
      index: { required: true, type: Number },
      worksetIconPath: { required: true, type: String },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>

<style lang="sass" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

/* ================================================================================= *

    Workset Block structure styles

 * ================================================================================= */
@mixin o-workset-block() {
  // Arrange children horizontally:
  display: flex;
  // Standard block component spacing:
  margin-bottom: mod(1.5);
  // Contain child margins:
  padding: rpx(1);

  &__strand {
    // Keep the strand image & label aligned
    // on larger screen sizes:
    @include viewport-min(sm) {
      flex: 0 0 10rem;
    }
  }

  &__info {
    flex: 1.25; // Take up leftover space.
  }

  &__go-button-wrapper {
    // Force wrapping of button at a wider
    // viewport than it would otherwise:
    min-width: 10ch;
    flex: 1;
  }
}

/* ================================================================== *

    Lozenge -- shared aesthetic style

* =================================================================== */

/*
  Lozenge
*/
@mixin lozenge($radius: mod(1)) {
  border-radius: $radius;
  box-shadow: rpx(1) rpx(1) mod(0.5) vhl-shadow(0.4);
}

/* ================================================================== *

    Pill -- shared skin

* =================================================================== */

/*
  Pill

  Used for components like tags/badges.
*/
@mixin pill() {
  display: inline-block;
  text-transform: uppercase;
  font-size: var(--font-2);
  background-color: var(--ui-fill-color);
  border-radius: mod(1);
  color: var(--ui-text-color);
  padding: 0 rpx(8);
  vertical-align: rpx(2);
  white-space: nowrap;
  width: min-content; /* shrink-wrap */
 }

.assessment {
  .c-vertical-divider {
    display: none;

    @include viewport-min(sm) {
      display: inline-block;
    }
  }

  --vhl-icon-size: 4.2rem;

  @include viewport-min(sm) {
    --vhl-icon-size: unset;
  }

  @include o-workset-block();
  @include lozenge();

  // Locals:
  --c-workset-padding: #{mod(1.5)} #{mod(1)};

  flex-wrap: wrap;
  justify-content: center;
  color: var(--ui-text-color);
  background-color: var(--ui-fill-color);
  padding: var(--c-workset-padding);

  @include viewport-min(sm) {
    flex-wrap: nowrap;
    justify-content: flex-start;
  }

  > * {
    @include viewport-min(sm) {
      text-align: unset;
    }
  }

  &__picture {
    width: 8rem;
    max-width: 8rem;
    align-self: center;
  }

  &__info {
    @include viewport-min(sm) {
      // horizontal version only:
      padding-left: rpx(8); // make room for __status negative margin.
    }
  }

  &__lesson-name {
    margin-bottom: mod(0.5);
  }

  &__status {
    @include pill();

    // NOTE: This matches the comp, but it also is the same as .is-due-today below.
    --ui-fill-color: var(--ui-primary-darker);
    --ui-text-color: var(--white);

    border: 0;
    display: block;
    font-weight: normal;
    margin-bottom: mod(0.75);
    text-align: center;
    white-space: normal;
    width: auto;

    @include viewport-min(sm) {
      // horizontal version only:
      margin-left: mod(-0.5); // align the inner text of the c-tag with the lesson name.
    }

    &.is-due-today {
      --ui-fill-color: var(--ui-primary-darker);
      --ui-text-color: var(--white);
      font-weight: bold;
    }
  }

  &__full-title {
    display: block;
    font-size: var(--font-3);
    letter-spacing: 0.08rem;
    text-align: center;

    @include viewport-min(sm) {
      text-align: left;
    }
  }

  &__lesson-name {
    font-weight: bold;
  }

  &__lesson-name, &__title {
    display: block;

    @include viewport-min(sm) {
      display: inline-block;
    }
  }

  &__pipe {
    color: var(--ui-divider-color);
    display: none;

    @include viewport-min(sm) {
      display: inline-block;
    }
  }

  &__go-button-wrapper {
    margin-top: mod(1.5);
    text-align: center;

    @include viewport-min(sm) {
      align-self: flex-end;
      text-align: right;
    }
  }
}
</style>
