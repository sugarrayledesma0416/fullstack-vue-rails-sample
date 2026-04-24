<template>
  <div>
    <p class="rules-heading">
      What counts?
    </p>
    <ul class="strictness-list">
      <li
        v-for="(item, index) in formattedRules"
        :key="index"
        class="strictness-list-item"
        :class="[item.classes, testClass('strictness-list-item')]"
        :title="item.title">
        {{ item.text }}
      </li>
    </ul>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  const props = defineProps({
    rules: { default: '', type: String },
  });
  const rulesObject = JSON.parse(props.rules);

  /**
   * @typedef {Object} Rule
   * @property {string} text - The text representing the rule.
   * @property {boolean} status - The status of the rule (true for inactive,
   * false for active).
   */

  /**
   * @typedef {Object} FormattedRule
   * @property {string} text - The formatted rule text.
   * @property {string} classes - The CSS classes generated based on the rule status
   * and text.
   * @property {string} title - The title attribute for the HTML element, with the
   * first letter capitalized.
   */

  /**
   * Formats a rule object into a human-readable format and generates corresponding
   * CSS classes.
   *
   * @param {Rule} rule - The rule object containing information about the rule.
   * @return {FormattedRule} An object containing the formatted rule text,
   * CSS classes, and title.
   */
  function formatRule(rule) {
    const msg = {
      'accents': 'Extra or missing accent marks',
      'capitalization': 'Incorrect capitalization',
      'punctuation': 'Punctuation errors',
    };
    const msgSuffix = 'affect your score.';

    const ruleText = `${msg[rule.text]} ${rule.status ? 'WILL NOT' : 'WILL'} ${msgSuffix}`;
    const ruleClasses = `${rule.status ? 'inactive' : 'active'} ${rule.text}`;

    return {
      text: ruleText,
      classes: ruleClasses,
      title: rule.text.charAt(0).toUpperCase() + rule.text.slice(1),
    };
  }
  const formattedRules = rulesObject.map((rule) => formatRule(rule));

</script>

<style lang="scss" scoped>
.rules-heading {
  font-weight: bold;
}

ul.strictness-list {
  margin-left: 0;
  padding-left: 0.8rem;
}

.strictness-list-item {
  display: flex;
  min-height: 1.5625rem;
  margin: 0.125rem;
  padding-left: 0.3125rem;
  padding-top: 0.0625rem;
}

.t-supersites-jr .active.accents {
  background: url(/images/activity_punct_accentsy.png) 0 0 no-repeat;
}

.t-supersites-jr .active.capitalization {
  background: url(/images/activity_punct_capsy.png) 0 0 no-repeat;
}

.t-supersites-jr .active.punctuation {
  background: url(/images/activity_punct_puncty.png) 0 0 no-repeat;
}

.t-supersites-jr .accents {
  background: url(/images/activity_punct_accentsn.png) 0 0 no-repeat;
}

.t-supersites-jr .capitalization {
  background: url(/images/activity_punct_capsn.png) 0 0 no-repeat;
}

.t-supersites-jr .punctuation {
  background: url(/images/activity_punct_punctn.png) 0 0 no-repeat;
}

.t-supersites-jr .strictness-list-item {
  padding-left: 0;
}

.t-supersites-jr .active.accents,
.t-supersites-jr .active.capitalization,
.t-supersites-jr .active.punctuation,
.t-supersites-jr .accents,
.t-supersites-jr .capitalization,
.t-supersites-jr .punctuation {
  background-position-y: 0.3rem;
}
</style>

