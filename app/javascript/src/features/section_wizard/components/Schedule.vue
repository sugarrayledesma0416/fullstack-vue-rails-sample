<template>
  <div class="u-clearfix">
    <h2 class="c-heading--sm  u-txt-bold">
      Schedule
    </h2>
    <div class="l-grid">
      <div class="l-col-4">
        <label for="section_due_time" class="c-form-item__label">Due time</label>
        <select
          id="due_time_hour"
          v-model="datastore.section.dueTimeHour"
          class="c-select"
          :class="testClass('due-time-hour')">
          <option
            v-for="hour in datastore.section.hourOptions"
            :key="hour"
            :value="hour">
            {{ hour }}
          </option>
        </select>

        <select
          id="due_time_min"
          v-model="datastore.section.dueTimeMinute"
          class="c-select"
          :class="testClass('due-time-min')">
          <option
            v-for="minute in datastore.section.minutesOptions"
            :key="minute"
            :value="minute">
            {{ minute }}
          </option>
        </select>

        <select
          id="due_time_ampm"
          v-model="datastore.section.dueTimeAmpm"
          class="c-select"
          :class="testClass('due-time-ampm')">
          <option
            v-for="ampm in datastore.section.ampmOptions"
            :key="ampm"
            :value="ampm">
            {{ ampm }}
          </option>
        </select>
      </div>
      <div class="l-col-6">
        <label for="section_time_zone" class="c-form-item__label">Time zone</label>
        <div data-container="time_zone">
          <select
            id="section_time_zone"
            v-model="datastore.section.timeZone"
            class="c-select"
            :class="testClass('section-time-zone')"
            name="section_time_zone">
            <option
              v-for="tz in timeZones"
              :key="tz"
              :value="tz[1]">
              {{ tz[0] }}
            </option>
            <option value="" disabled="disabled">
              -------------
            </option>
            <option
              v-for="tz in remainingTimeZones"
              :key="tz"
              :value="tz[1]">
              {{ tz[0] }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'Schedule',
    props: {
      remainingTimeZones: { required: true, type: Array },
      timeZones: { required: true, type: Array },
    },
    setup() {
      const datastore = inject('datastore');
      return { datastore, testClass };
    },
  };
</script>
