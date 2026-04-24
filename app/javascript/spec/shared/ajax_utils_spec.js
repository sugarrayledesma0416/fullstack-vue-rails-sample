import { getFromEndpoint, postToEndpoint } from 'shared/ajax_utils.js';
import fetchMock from 'fetch-mock';

describe('create instance', () => {
  afterEach(() => {
    fetchMock.restore();
  });

  it('test getFromEndpoint', async () => {
    /* Mock the fetch call. */
    let jsonResponse = { foo: 'bar' };
    fetchMock.mock('https://some_url', { status: 200, body: jsonResponse });

    /* Create a spy. */
    let spyObj = { spy: (data) => {} };
    spyOn(spyObj, 'spy');

    /**
     * Define an asynchronous function that resolves after
     *   getFromEndpoint has called the callback.
     */
    let test = () => {
      return new Promise(resolve => {
        getFromEndpoint('https://some_url', (data) => {
          spyObj.spy(data);
          resolve();
        });
      });
    };

    await test();

    /**
     * Assert that the callback received the expected data
     *   from the endpoint.
     */
    expect(spyObj.spy).toHaveBeenCalledWith(jsonResponse);
  })

  it('test postToEndpoint', async () => {
    let postData = { key: 'value' };
    let jsonResponse = { foo: 'bar' };
    fetchMock.mock('https://some_url', { status: 200, body: jsonResponse });

    /* Create a spy. */
    let spyObj = { spy: (data) => {} };
    spyOn(spyObj, 'spy');

    /**
     * Define an asynchronous function that resolves after
     *   getFromEndpoint has called the callback.
     */
    let test = () => {
      return new Promise(resolve => {
        postToEndpoint('https://some_url', postData, (data) => {
          spyObj.spy(data);
          resolve();
        });
      });
    };

    await test();

    /**
     * Assert that fetch was called with the expected URL
     *   and options.
     */
    expect(
      fetchMock.called('https://some_url',
                       { body: postData,
                         method: 'POST' })
    ).toBe(true);

    /**
     * Assert that the callback received the expected data
     *   from the endpoint.
     */
    expect(spyObj.spy).toHaveBeenCalledWith(jsonResponse);
  });
});
