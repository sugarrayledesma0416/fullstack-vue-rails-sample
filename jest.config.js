module.exports = {
  collectCoverage: true,
  collectCoverageFrom: ["./app/javascript/src/**/*.{js,vue}"],
  coverageDirectory: 'public/js_coverage',
  coverageReporters: ["html"],
  moduleFileExtensions: [
    "js",
    "json",
    "vue"
  ],
  moduleNameMapper: {
    "\\.(gif|jpg)$": "<rootDir>/config/jest/fileMock.js",
    ".*\\.svg(\\?inline)?$": "<rootDir>/config/jest/svgImportMock.js",
    "^vanillajs-datepicker$": "<rootDir>/node_modules/vanillajs-datepicker/js/main.js",
    "\\.(css|less)$": "<rootDir>/config/jest/cssImportMock.js"
  },
  modulePathIgnorePatterns: ["<rootDir>/vendor/bundle/"],
  modulePaths: ["app/javascript/src", "app/assets", "node_modules/music/app/javascript/src",],
  globalSetup: "<rootDir>/app/javascript/spec/support/global-setup.js",
  setupFilesAfterEnv: ['./app/javascript/spec/support/jest.setup.js'],
  testMatch: ['<rootDir>/app/javascript/spec/**/*{_s,S}pec.js'],
  transform: {
    "^.+\\.js$": "babel-jest",
    "^.+\\.vue$": "vue-jest"
  },
  /**
   * Most of the modules in node_modules are pre-transpiled, so Jest's
   *   default behavior is not to transpile them. If a module is
   *   published without having been transpiled, however, it will need
   *   to be transpiled for Jest to process it.
   *
   *   The pattern below overrides the default behavior and tells Jest
   *   not to transform anything in node_modules, _unless_ it matches
   *   any of the module names following "?!".
   */
  transformIgnorePatterns: [
    "/node_modules/(?!lit-element|lit-html|mae|music|vanillajs-datepicker).+\\.js"
  ],
  globals: {
    CKEDITOR: {
      env: {}
    },
    d3: {},
    VHL: {
      Music: {
      },
    },
    VISTA_ONLINE_LEARNING: true,
  },
};
