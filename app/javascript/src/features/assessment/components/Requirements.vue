<template>
  <div>
    <p
      class="requirement-heading"
      :class="testClass('requirement-heading')">
      What is required?
    </p>
    <ul class="requirement-list">
      <li
        v-for="(iconObj, index) in filterValues()"
        :key="index"
        class="requirement-list-item"
        :class="[iconObj.class, testClass('requirement-list-item')]"
        :title="iconObj.title">
        {{ iconObj.title }}
      </li>
    </ul>
    <hr>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  const props = defineProps({
    icons: { default: '', type: String },
  });

  /**
   * Represents an object with class and title properties.
   * @typedef {Object} IconObject
   * @property {string} class - The CSS class.
   * @property {string} title - The title associated with the class.
   */

  /**
   * Filters values based on provided icons.
   * @return {Array<IconObject>} An array of objects containing unique classes
   * and titles.
   */
  function filterValues() {
    const iconsArr = props.icons.split(',');
    const output = [];
    const iconMapping = {
      'solo_video_recording': [
        { class: 'audio', title: 'Listening' },
        { class: 'microphone', title: 'Speaking' },
        { class: 'video', title: 'Video Recording' },
      ],
      'partner_chat': [
        { class: 'audio', title: 'Listening' },
        { class: 'microphone', title: 'Speaking' },
        { class: 'video', title: 'Video Recording' },
      ],
      'audio': [{ class: 'audio', title: 'Listening' }],
      'microphone': [{ class: 'microphone', title: 'Speaking' }],
      'video': [{ class: 'video', title: 'Video Recording' }],
    };

    for (const iconObj of iconsArr) {
      if (iconMapping[iconObj]) {
        output.push(...iconMapping[iconObj]);
      }
    }

    return output.filter((value, index, self) =>
      index === self.findIndex((t) => (
        t.class === value.class
      ))
    );
  }
</script>

<style lang="scss" scoped>
.requirement-heading {
  font-weight: bold;
}

ul.requirement-list {
  padding-left: 1rem;
  margin-left: 0;
}

.requirement-list-item {
  min-height: 1.5625rem;
  margin: 0.125rem;
  padding-left: 0.3125rem;
  padding-top: 0.0625rem;
  text-indent: 2em;

  &.audio {
    background: url(/images/headphone.svg) no-repeat 0 0.188rem;
  }

  &.microphone {
    background: url(/images/microphone.svg) no-repeat 0 0.188rem;
  }

  &.video {
    background: url(/images/camera.svg) no-repeat 0 0.188rem;
  }
}

.t-supersites-jr {
  .requirement-list-item {
    padding-left: 0;

    &.audio {
      background-position-y: 0.5rem;
    }

    &.microphone {
      background-position-y: 0.5rem;
    }

    &.video {
      background-position-y: 0.5rem;
    }
  }
}
</style>

