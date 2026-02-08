const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.',
  use: {
    baseURL: 'http://192.168.99.101',
    browserName: 'chromium',
    headless: true,
  },
});