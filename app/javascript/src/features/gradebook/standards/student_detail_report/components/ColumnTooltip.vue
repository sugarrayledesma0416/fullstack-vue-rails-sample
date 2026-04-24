<template>
  <div>
    <div
      class="tooltip"
      v-for="(point, index) in tooltipPoints">
      <div v-if="index !== 0" class="separator"></div>
      <div v-if="index !== 0" class="spacer"></div>
      <div
        class="u-txt-upper  u-txt-gray-6  assessment-type"
        :class="['u-pad-bot-2']">{{ point.seriesName }}</div>
      <div
        class="percentage"
        :class="[
                  testClass(`${point.seriesName}-score`),
                  {
                    'below-threshold': point.score < lowGradeThreshold,
                    'percentage--number': !isNaN(parseInt(point.score)),
                  }
                ]">
        {{ point.score ? `${Math.round(point.score)}%` : '--' }}
      </div>
    </div>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';

  const props = defineProps({
    points: {
      type: Array,
      default: function() {
        return [];
      },
    },
    lowGradeThreshold: {
      type: Number,
      required: true,
    },
    hasMidBookAssessment: {
      type: Boolean,
      default: false,
    },
    hasEndBookAssessment: {
      type: Boolean,
      default: false,
    },
  });

  const scoreLookup = computed(() => {
    return props.points.reduce(
      (acc, curr) => {
        acc[curr.series.name] = curr.y;
        return acc;
      },
      {}
    );
  });

  const tooltipPoints = computed(() => {
    let seriesArray = ['Mid-Unit', 'End-of-Unit'];
    if (props.hasMidBookAssessment) {
      seriesArray.push('Mid-Book');
    }
    if (props.hasEndBookAssessment) {
      seriesArray.push('End-of-Book');
    }
    return seriesArray.map((seriesName) => {
      const score = scoreLookup.value[seriesName];
      return { seriesName, score };
    });
  });
</script>

<style>
  .tooltip {
    text-align: center;
    position: relative;
    padding: 0 0.5rem;
  }

  .assessment-type {
    font-size: 1.05rem;
    font-weight: 400;
    letter-spacing: 0.09rem;
  }

  .percentage {
    font-size: 1.5rem;
    height: 2.5rem;
  }

  .percentage--number {
    font-weight: 700;
  }

  .below-threshold {
    color: red;
  }
  
  .separator {
    border-top: 0.5px solid #d8d8d8;
    position: absolute;
    width: 60%;
    left: 20%;
  }

  .spacer {
    padding-bottom: 0.5rem;
  }
</style>
