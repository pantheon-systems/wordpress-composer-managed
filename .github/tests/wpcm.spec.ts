import { test, expect } from "@playwright/test";

const exampleArticle = "Hello world!";
const siteTitle = "WPCM Playwright Tests";
const siteUrl = process.env.SITE_URL || "https://dev-wpcm-playwright-tests.pantheonsite.io";

test("homepage loads and contains example content", async ({ page }) => {
  await page.goto(siteUrl);
  await expect(page).toHaveTitle(siteTitle);
  await expect(page.getByText(exampleArticle)).toHaveText(exampleArticle);
});

test("WP REST API is accessible", async ({ request }) => {
  const apiRoot = await request.get(`${siteUrl}/wp-json`);
  expect(apiRoot.ok()).toBeTruthy();
});

test("Hello World post is accessible", async ({ page }) => {
  await page.goto(`${siteUrl}/hello-world`);
  await expect(page).toHaveTitle(`${exampleArticle} – ${siteTitle}`);
});

test("graphql is able to access hello world post", async ({ request }) => {
  const query = `
    query {
      posts(where: { search: "${exampleArticle}" }) {
        edges {
          node {
            title
          }
        }
      }
    }
  `;

  const response = await request.post(`${siteUrl}/wp/graphql`, {
    data: {
      query: query
    },
    headers: {
      'Content-Type': 'application/json'
    }
  });

  const responseBody = await response.json();

  expect(responseBody.data.posts.edges.length).toBeGreaterThan(0);
  expect(responseBody.data.posts.edges[0].node.title).toBe(exampleArticle);
});
