const { test, expect } = require('@playwright/test');

test('should create a task and see it in the list', async ({ page }) => {
  await page.goto('http://localhost');

  // 1. Fill out the form
  await page.fill('#title', 'E2E Test Task');
  await page.selectOption('#priority', 'High');
  await page.fill('#date', '2026-12-31');
  
  // 2. Click Create
  await page.click('button:has-text("Create")');

  // 3. Verify the feedback message appears
  const feedback = page.locator('#api-feedback');
  await expect(feedback).toBeVisible();
  await expect(feedback).toContainText('Success');

  // 4. Verify the task appears in the list
  const taskList = page.locator('#task-list');
  await expect(taskList).toContainText('E2E Test Task');
});