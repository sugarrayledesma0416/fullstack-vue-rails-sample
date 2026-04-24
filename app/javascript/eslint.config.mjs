import globals from 'globals';
import vue from 'eslint-plugin-vue';
import jsdoc from 'eslint-plugin-jsdoc';
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

export default [...compat.extends('eslint:recommended', 'google'), {
  languageOptions: {
    globals: {
      ...globals.browser,
      ...globals.commonjs,
      CKEDITOR: true,
      d3: true,
      moment: true,
      OT: true,
      radialProgress: true,
      VHL: true,
      VISTA_ONLINE_LEARNING: true,
    },

    ecmaVersion: 2020,
    sourceType: 'module',
  },

  plugins: { jsdoc },

  rules: {
    'max-len': ['error', 100],

    'object-curly-spacing': ['error', 'always', {
      objectsInObjects: false,
    }],

    'comma-dangle': ['error', {
      arrays: 'always-multiline',
      objects: 'always-multiline',
      imports: 'always-multiline',
      exports: 'always-multiline',
      functions: 'never',
    }],

    'indent': ['error', 2, {
      CallExpression: {
        arguments: 1,
      },
    }],

    'quotes': ['error', 'single', {
      avoidEscape: true,
    }],

    'jsdoc/require-jsdoc': [
      'warn',
      {
        require: {
          FunctionDeclaration: true,
          MethodDefinition: true,
          ClassDeclaration: true,
        },
      },
    ],
    'jsdoc/require-description': 'warn',
    'jsdoc/require-param': 'warn',
    'jsdoc/require-returns': 'warn',
    'jsdoc/check-param-names': 'warn',
    'jsdoc/check-types': 'warn',
    'jsdoc/valid-types': 'warn',
    'jsdoc/check-tag-names': 'warn',

    // Disable legacy rules (safety for Google config)
    'require-jsdoc': 'off',
    'valid-jsdoc': 'off',
  },
}, ...compat.extends('plugin:vue/recommended').map((config) => ({
  ...config,
  files: ['**/*.vue'],
})), {
  files: ['**/*.vue'],

  plugins: {
    vue,
  },

  languageOptions: {
    globals: {
      defineProps: true,
      defineEmits: true,
    },
  },

  rules: {
    'vue/script-indent': ['error', 2, {
      baseIndent: 1,
    }],

    'vue/attribute-hyphenation': ['error', 'never'],

    'vue/html-closing-bracket-newline': ['error', {
      singleline: 'never',
      multiline: 'never',
    }],

    'vue/max-attributes-per-line': ['warn', {
      singleline: 3,
      multiline: 1,
    }],

    'vue/multi-word-component-names': ['error', {
      ignores: [
        'Components',
        'Composition',
        'Entry',
        'Expandable',
        'Expander',
        'Export',
        'Fieldset',
        'Filters',
        'Heading',
        'Icon',
        'Info',
        'Lessons',
        'Levels',
        'Portfolio',
        'Rating',
        'Requirements',
        'Rules',
        'Schedule',
        'Screenshot',
        'Standards',
        'Suggestion',
        'Table',
        'Thing',
        'Tooltip',
        'Topic',
        'Translations',
        'Tutorial',
        'Unit',
        'Workset',
      ],
    }],        
    'indent': 'off',
  },
}, {
  files: ['**/*Spec.js', '**/*spec.js'],

  languageOptions: {
    globals: {
      ...globals.jasmine,
      ...globals.jest,
    },
  },

  rules: {
    'jsdoc/require-jsdoc': 'off',
    'require-jsdoc': 'off',
  },
}];
