import { test, expect } from "@playwright/test";

const exampleArticle = "Hello world!";
const siteTitle = process.env.SITE_NAME || "WPCM Playwright Tests";
const siteUrl = process.env.SITE_URL || "https://dev-wpcm-playwright-tests.pantheonsite.io";

test("homepage loads and contains example content", async ({ page }) => {
  await page.goto(siteUrl);
  await expect(page).toHaveTitle(siteTitle);
  await expect(page.getByText(exampleArticle)).toHaveText(exampleArticle);
});

test("WP REST API is accessible", async ({ request }) => {
  let apiRoot = await request.get(`${siteUrl}/wp-json`);
  // If the api endpoint isn't /wp-json, it should be /wp/wp-json. This will probably be the case for main sites on subdirectory multisites.
  if (!apiRoot.ok()) {
    apiRoot = await request.get(`${siteUrl}/wp/wp-json`);
  }
  expect(apiRoot.ok()).toBeTruthy();
});

test("Hello World post is accessible", async ({ page }) => {
  await page.goto(`${siteUrl}/hello-world/'`);
  await expect(page).toHaveTitle(`${exampleArticle} – ${siteTitle}`);
  // Locate the element containing the desired text
  const welcomeText = page.locator('text=Welcome to WordPress');
  await expect(welcomeText).toContainText('Welcome to WordPress');
});

test("validate core resource URLs", async ({ request }) => {
  const coreResources = [
    'wp-includes/js/dist/interactivity.min.js',
    'wp-includes/css/dist/editor.min.css',
  ];

  for ( const resource of coreResources ) {
    const resourceUrl = `${siteUrl}/wp/${resource}`;
    const response = await request.get(resourceUrl);
    await expect(response).toBeTruthy();
  }
});

test("graphql is able to access hello world post", async ({ request }) => {
  let graphqlEndpoint = `${siteUrl}/wp/graphql`;
  let apiRoot = await request.get(`${siteUrl}/wp/graphql`);
  // If the above request doesn't resolve, it's because we're on a subsite where the path is ${siteUrl}/graphql -- similar to the rest api.
  if (!apiRoot.ok()) {
    graphqlEndpoint = `${siteUrl}/graphql`;
    apiRoot = await request.get(`${siteUrl}/graphql`);
  }

  expect(apiRoot.ok().toBeTruthy());
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

  const response = await request.post(graphqlEndpoint, {
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
