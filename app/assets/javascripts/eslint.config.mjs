import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [{
    ignores: [
      '**/*.min.js',
      '**/angular-*.js',
      '**/fine_uploader/*.js',
      '**/jquery-*.js',
      '**/jquery.*.js',
      '!**/jquery.*.vhl.js',
      '!**/jquery.vhl*.js',
      '**/JavaScriptFlashGateway.js',
      '**/angular.js',
      '**/jquery.js',
      '**/jwerty.js',
      '**/sha256.js',
      '**/swfobject.js',
      '**/textAngular.js',
      '**/toastr.js',
    ],
  }, ...compat.extends("eslint:recommended"), {
    languageOptions: {
        globals: {
            ...globals.browser,
            ...globals.jasmine,
            ...globals.jquery,
            ...globals.worker,
            ARC: true,
            CKEDITOR: true,
            VHL: true,
            _: true,
            angular: true,
            zE: "readonly",
        },
    },

    settings: {
        angular: 1,
    },
}];