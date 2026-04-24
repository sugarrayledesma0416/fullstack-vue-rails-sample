import '@testing-library/jest-dom';
import { types } from 'util';
import $ from 'jquery';
import { config } from '@vue/test-utils';
import Icon from 'shared/custom_elements/vhl_icon';

config.global.components = { 'vhl-icon': Icon };
config.global.stubs = { Icon: true };

global.$ = $;

expect.extend({
  toBeGuid(received) {
    if (/^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i.test(received)) {
      return { pass: true, message: () => '' };
    }

    return { pass: false, message: () => `${received} is not in GUID format.` };
  },
  toBeReactiveVersionOf(received, expected) {
    let message;
    const receivedIsProxy = types.isProxy(received);
    const receivedMatchesExpected = this.equals(received, expected);
    const pass = receivedIsProxy && receivedMatchesExpected;
    if (pass) {
      message = () => '';
    } else if (!receivedIsProxy) {
      message = () => `Object is not a proxy.`;
    } else {
      message = () => `
      Object does not equal expected value.

      Expected:
      ${JSON.stringify(expected)}

      Actual:
      ${JSON.stringify(received)}
      `;
    }

    return { pass, message };
  },
});
