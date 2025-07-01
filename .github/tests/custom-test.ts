import { test as baseTest, expect as baseExpect } from '@playwright/test';

// Extend base test by providing a custom 'page' fixture.
export const test = baseTest.extend({
  page: async ({ page }, use) => {
    // Set custom headers for all page navigations/requests initiated by the page.
    await page.setExtraHTTPHeaders({
      'Deterrence-Bypass': 'true',
    });
    // Continue with the test, providing the modified page fixture.
    await use(page);
  },
});

// Re-export expect so you can import it from this file as well.
export { baseExpect as expect };
