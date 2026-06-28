import { test, expect } from '@playwright/test';

test.describe('Static Website Smoke Tests', () => {

  test('Home page loads successfully and has correct title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/CI\/CD Static Website/);
    
    // Check key elements are present
    const header = page.locator('header');
    await expect(header).toBeVisible();
    
    const heading = page.locator('h1');
    await expect(heading).toHaveText('Automated Static Web Pipeline');
  });

  test('About page loads successfully and contains system blueprint info', async ({ page }) => {
    await page.goto('/');
    
    // Click on Architecture link
    await page.click('#navAbout');
    
    // Check URL
    await expect(page).toHaveURL(/\/about.html/);
    
    // Check heading
    const heading = page.locator('h1');
    await expect(heading).toHaveText('System Blueprint');
    
    // Check cards
    const cards = page.locator('.card');
    await expect(cards).toHaveCount(3);
  });

  test('Theme toggle updates data-theme attribute on HTML root', async ({ page }) => {
    await page.goto('/');
    
    const html = page.locator('html');
    
    // Initial theme check (dynamically accept either light or dark depending on runner preference)
    const initialTheme = await html.getAttribute('data-theme');
    expect(initialTheme).toMatch(/^(light|dark)$/);
    
    const expectedToggledTheme = initialTheme === 'dark' ? 'light' : 'dark';
    
    // Click toggle
    await page.click('#themeToggle');
    
    // Check updated theme
    const updatedTheme = await html.getAttribute('data-theme');
    expect(updatedTheme).toBe(expectedToggledTheme);
    
    // Click toggle again
    await page.click('#themeToggle');
    const finalTheme = await html.getAttribute('data-theme');
    expect(finalTheme).toBe(initialTheme);
  });
});
