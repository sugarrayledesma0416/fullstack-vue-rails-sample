<template>
  <!-- eslint-disable max-len vue/max-attributes-per-line -->
  <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 20 20" class="c-svg">
    <defs>
      <rect id="icon-calendar-aaa-a" width="4" height="3" x="3" y="9" rx="1" />
      <rect id="icon-calendar-aaa-b" width="4" height="3" x="3" y="13" rx="1" />
      <rect id="icon-calendar-aaa-c" width="4" height="3" x="8" y="9" rx="1" />
      <rect id="icon-calendar-aaa-d" width="4" height="3" x="8" y="13" rx="1" />
      <rect id="icon-calendar-aaa-e" width="4" height="3" x="13" y="9" rx="1" />
      <path id="icon-calendar-aaa-f" d="M4.6,7 L2.99508929,7 C1.8932319,7 1,6.1061002 1,4.9951185 L1,2 L19,2 L19,4.9951185 C19,6.10238398 18.1073772,7 17.0049107,7 L15.4,7 L15.4,4.90766191 C15.4,4.39815903 14.9970563,4 14.5,4 C13.9994783,4 13.6,4.40637408 13.6,4.90766191 L13.6,7 L6.4,7 L6.4,4.90766191 C6.4,4.39815903 5.99705627,4 5.5,4 C4.99947834,4 4.6,4.40637408 4.6,4.90766191 L4.6,7 Z" />
    </defs>
    <g fill="none" fill-rule="evenodd">
      <path :stroke="backgroudColor" stroke-width="1.5" d="M1.75,6.00684547 L1.75,16.9941413 C1.75,17.6892273 2.30795285,18.25 2.99508929,18.25 L17.0049107,18.25 C17.6920111,18.25 18.25,17.6888808 18.25,16.9941413 L18.25,6.00684547 C18.25,5.86230318 18.1391336,5.75 18.0066023,5.75 L1.99339768,5.75 C1.86134731,5.75 1.75,5.86283997 1.75,6.00684547 Z" />
      <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-a" />
      <rect width="3" height="2" x="3.5" y="9.5" :stroke="backgroudColor" rx="1" />
      <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-b" />
      <rect width="3" height="2" x="3.5" y="13.5" :stroke="backgroudColor" rx="1" />
      <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-c" />
      <rect width="3" height="2" x="8.5" y="9.5" :stroke="backgroudColor" rx="1" />
      <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-d" />
      <rect width="3" height="2" x="8.5" y="13.5" :stroke="backgroudColor" rx="1" />
      <g>
        <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-e" />
        <rect width="3" height="2" x="13.5" y="9.5" :stroke="backgroudColor" rx="1" />
      </g>
      <g transform="matrix(1 0 0 -1 0 9)">
        <use :fill="backgroudColor" xlink:href="#icon-calendar-aaa-f" />
        <path :stroke="backgroudColor" stroke-width="2" d="M3.6,6 L3.6,4.90766191 C3.6,3.85535747 4.44588132,3 5.5,3 C6.55266641,3 7.4,3.84920471 7.4,4.90766191 L7.4,6 L12.6,6 L12.6,4.90766191 C12.6,3.85535747 13.4458813,3 14.5,3 C15.5526664,3 16.4,3.84920471 16.4,4.90766191 L16.4,6 L17.0049107,6 C17.5537356,6 18,5.55145069 18,4.9951185 L18,3 L2,3 L2,4.9951185 C2,5.55333959 2.44504866,6 2.99508929,6 L3.6,6 Z" />
      </g>
      <rect width="2" height="4" x="4.5" y=".5" :stroke="backgroudColor" rx="1" />
      <rect width="2" height="4" x="13.5" y=".5" :stroke="backgroudColor" rx="1" />
    </g>
  </svg>
  <!-- eslint-enable max-len -->
</template>

<script setup>
  const props = defineProps({
    disabled: { required: true, type: Boolean },
  });

  const backgroudColor = props.disabled ? '#ddd' : '#006bae';
</script>
