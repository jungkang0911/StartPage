// Run with Playwright installed: node scripts/preview-check.cjs <installed-index.html>
// playwright（自帶瀏覽器）或 playwright-core + 本機瀏覽器（PW_CHANNEL=msedge / chrome）
const { chromium } = (() => { try { return require('playwright'); } catch { return require('playwright-core'); } })();
const launchOpts = { headless: true, ...(process.env.PW_CHANNEL ? { channel: process.env.PW_CHANNEL } : {}) };
const { pathToFileURL } = require('node:url');
const path = require('node:path');
const fs = require('node:fs');
const { freezeClock, setClockText } = require('./demo-clock.cjs');
(async () => {
  const browser = await chromium.launch(launchOpts);
  const page = await browser.newPage({ viewport: { width: 1440, height: 960 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await freezeClock(page);
  await page.goto(pathToFileURL(path.resolve(process.argv[2])).href);
  await page.locator('.widget').first().waitFor();
  if (await page.locator('.widget').count() !== 4) throw Error('Example widgets missing');
  // Freeze only the documentation screenshots; the shipped clock remains live.
  await setClockText(page);
  const images = path.resolve(__dirname, '../docs/images');
  fs.mkdirSync(images, { recursive: true });
  await page.screenshot({ path: path.join(images, 'light-demo.png'), fullPage: true });
  await page.locator('#btnMenu').click();
  await page.locator('[data-mbtn="set"]').click();
  await page.screenshot({ path: path.join(images, 'settings.png') });
  await page.keyboard.press('Escape');
  await page.locator('#btnTheme').click();
  await page.screenshot({ path: path.join(images, 'dark-demo.png'), fullPage: true });
  await page.locator('#btnEdit').click();
  if (!await page.locator('body').evaluate(el => el.classList.contains('editing'))) throw Error('Edit mode failed');
  await page.keyboard.press('Escape');
  await page.reload();
  if (!await page.locator('body').evaluate(el => el.classList.contains('dark'))) throw Error('Theme persistence failed');
  if (errors.length) throw Error(errors.join('\n'));
  await browser.close();
  console.log('Page render, edit mode and persistence checks passed; screenshots generated.');
})().catch(e => { console.error(e); process.exit(1); });
