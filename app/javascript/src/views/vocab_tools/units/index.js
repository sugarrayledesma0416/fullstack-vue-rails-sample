import { createApp } from 'vue';
import UnitList from 'features/vocab_tools/units/UnitList';

document.addEventListener('DOMContentLoaded', async () => {
  const unitsElm = document.querySelector('.js-units');
  const unitsData = JSON.parse(unitsElm.getAttribute('data-units'));
  const currentProgram = JSON.parse(unitsElm.getAttribute('data-current-program'));

  showUnitList(unitsData, currentProgram);
});

/**
* Method that displays the units in a vocab tools for the program.
* @param {Object} unitsData
* @param {Object} currentProgram
*/
const showUnitList = (unitsData, currentProgram) => {
  const unitsContainer = document.querySelector('.js-units-gallery');
  const viewAllLessons = false;
  const app = createApp(UnitList, {
    unitsData: unitsData,
    enrolled: unitsData.enrolled,
    viewAllLessons: viewAllLessons,
  });
  app.provide('currentProgram', currentProgram);
  app.mount(unitsContainer);
};
