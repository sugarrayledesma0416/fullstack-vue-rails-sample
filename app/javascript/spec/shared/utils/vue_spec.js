import { mountVueAppOnElm } from 'shared/utils/vue';
import ExampleApp from './ExampleApp';

describe('Vue utils', () => {
  describe('mountVueAppOnElm', () => {
    it('mounts a given app on a given element', async () => {
      document.body.innerHTML = `
      <div id="elmForApp"></div>
      `;

      await mountVueAppOnElm(ExampleApp, '#elmForApp');

      let expectedElm = document.querySelector('.expected-elm');
      expect(expectedElm.innerHTML).toEqual('Here I am!');
    });
  });
});
