<template>
  <div class="ns-music-v1">
    <p v-if="featureType" class="u-mar-top-32">
      Select a section to see its {{ featureType }}.
    </p>
    <div class="u-txt-20  u-mar-top-32">
      {{ courseName }}
    </div>
    <ul class="c-plain-list  u-mar-top-8">
      <li v-for="section in selectorData.sections" :key="section.id">
        <form :id="section.sectionFormId" :action="updateFocusUrl" method="post">
          <input name="_method" type="hidden" value="put">
          <input :value="authenticityToken" name="authenticity_token" type="hidden">
          <input
            :value="(section.focusInputValue)"
            name="focus"
            type="hidden">
          <input :value="redirectUrl" name="return_to" type="hidden">
          <button type="submit" class="c-no-button">
            {{ section.name }}
          </button>
        </form>
      </li>
    </ul>
  </div>
</template>

<script setup>
  import FocusSelector from './models/focus_selector';

  const props = defineProps({
    courseName: { default: '', type: String },
    featureType: { default: '', type: String },
    sections: { default: '', type: String },
    redirectUrl: { default: 'https://vhlcentral.com', type: String },
    updateFocusUrl: { default: 'https://vhlcentral.com', type: String },
    authenticityToken: { default: '', type: String },
  });

  const selectorData = new FocusSelector(props.sections);
</script>
