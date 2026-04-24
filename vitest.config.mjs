import { defineConfig, mergeConfig } from 'vitest/config';
import { default as viteConfig } from './vite.config.mjs';
import { resolve } from 'path';

export default mergeConfig(
  viteConfig({ mode: 'development' }),
  defineConfig({
    test: {
      /**
       * @since April 28, 2025
       * At the time of this writing, Vitest uses a version of minimatch that
       * is no longer compatible with Node v18.  (It expects Node v20+.)  This
       * causes the process to hang when coverage collection is run.  Since
       * Node v18 will shortly retire from LTS status, the suggested approach is
       * to upgrade to Node v20+ when it makes sense.
       *
       * The Vitest commands in package.json have been configured omit coverage
       * collection for the time being.
       */
      coverage: {
        include: [
          'app/javascript/src/**/*.{js,ts,vue}'
        ],
        provider: 'istanbul',
        reporter: 'lcov',
        reportsDirectory: resolve('coverage', 'vitest'),
      },
      globals: true,
      environment: 'jsdom',
    },
  })
);
