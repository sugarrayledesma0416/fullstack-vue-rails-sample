import globals from 'globals';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default [
  ...compat.extends('eslint:recommended', 'google'),
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.commonjs,
        ...globals.jasmine,
        ...globals.jquery,
        ...globals.worker,
        ARC: true,
        CKEDITOR: true,
        VHL: true,
        _: true,
        angular: true,
      },

      ecmaVersion: 2020,
      sourceType: 'module',
    },

    settings: {
      angular: 1,
    },

    rules: {
      // Disable legacy rules (safety for Google config)
      'valid-jsdoc': 'off',
      'require-jsdoc': 'off',
    },
  },
];
