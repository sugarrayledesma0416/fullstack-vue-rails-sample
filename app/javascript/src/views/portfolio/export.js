import Export from 'features/portfolio/Export';
import { mountVueAppOnElm } from 'shared/utils/vue';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(Export, '.js-export-portfolio');
});
