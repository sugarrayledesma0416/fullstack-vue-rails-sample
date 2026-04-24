<template>
  <div :id="chartDivId" class="growth-chart" />
</template>

<script setup>
  import { getCurrentInstance, onMounted } from 'vue';
  import tippy from 'tippy.js';
  import useGrowthAssessmentChart from '../composables/use_growth_assessment_chart';

  const instance = getCurrentInstance();
  const chartDivId = `chart-${instance.uid}`;

  const props = defineProps({
    config: { required: true, type: String },
  });

  const emit = defineEmits(['unitClicked']);

  const { createChart } = useGrowthAssessmentChart(chartDivId, props.config, emit);

  onMounted(() => {
    createChart();

    tippy(
      '.unit-label-none-score',
      {
        allowHTML: true,
        arrow: false,
        content: 'No scores <br>available</br> for this unit.',
        showOnCreate: false,
        theme: 'custom-tooltip',
        appendTo: () => document.querySelector(`#${chartDivId}`),
      }
    );
  });
</script>

<style scoped lang="sass">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .growth-chart {
    box-shadow: 0 0.125rem 0.625rem 0 rgba($black, 0.1);
    height: 26.8rem;
    margin: 0 6%;
  }

  .growth-chart :deep(svg.highcharts-root rect.highcharts-plot-border) {
    rx: 3;
  }

  .growth-chart :deep(.highcharts-title) {
    font-size: 1.3rem;
    letter-spacing: 0.1rem;
  }

  .growth-chart :deep(.low-grade-threshold-band) {
    opacity: 0.5;
  }

  .growth-chart :deep(.growth-chart-legend) {
    font-size: 1.1rem;
  }

  .growth-chart :deep(.highcharts-tooltip > span) {
    background-color: $white;
  }

  .growth-chart :deep(.unit-labels-container > span) {
    padding: 0.2rem 0.3rem;
    font-weight: normal;
  }

  .growth-chart :deep(.unit-labels-container > span:hover) {
    background-color: $gray-f5;
    border-radius: 0.2rem;
  }

  .growth-chart :deep(.unit-labels-container > span.is-active) {
    border-bottom: rpx(2) solid $black;
    font-weight: bold;
  }

  .growth-chart :deep(.unit-labels-container > span.is-active:hover) {
    border-bottom: rpx(2) solid $gray-f5;
    font-weight: normal;
    background-color: $gray-f5;
  }

  .growth-chart :deep(.tippy-box[data-theme~='custom-tooltip']) {
    background: none;
    color: #8e8e8e;
    text-align: center;
  }
</style>
