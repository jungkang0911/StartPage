// 用虛構資料截「行事曆 / DevOps / 通知中心」的 README 圖
//   node scripts/demo-integrations.cjs <已安裝的 index.html>
// 會在安裝資料夾寫入假的 calendar.js、devops.js、inbox.js、options.js（請用暫存安裝資料夾，不要用自己的）
const { chromium } = (() => { try { return require('playwright'); } catch { return require('playwright-core'); } })();
const launchOpts = { headless: true, ...(process.env.PW_CHANNEL ? { channel: process.env.PW_CHANNEL } : {}) };
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const html = path.resolve(process.argv[2]), dir = path.dirname(html);
const images = path.resolve(__dirname, '../docs/images');
const now = new Date('2026-12-30T10:20:00+08:00').getTime();
const at = (day, hm) => new Date(`2026-12-30T${hm}:00+08:00`).getTime() + day * 86400e3;
const write = (name, fn, data) => fs.writeFileSync(path.join(dir, name), `window.${fn} && ${fn}(${JSON.stringify(data)});\n`);

const ev = (id, day, s, e, subject, location, extra = {}) =>
  ({ id, subject, start: at(day, s), end: at(day, e), allDay: false, location, organizer: '王小明', status: 'Busy', response: 'Accept', ...extra });
write('calendar.js', 'STARTPAGE_CALENDAR', {
  ts: now - 3 * 60e3, owa: 'https://mail.example.com/owa/#path=/calendar', error: '',
  items: [
    ev('c1', 0, '09:00', '09:15', '每日站立會議', 'Teams'),
    ev('c2', 0, '10:00', '10:45', 'Sprint 規劃會議', '3F 會議室 A'),
    ev('c3', 0, '14:00', '15:00', '需求訪談：訂單系統', '5F 會議室 B'),
    ev('c4', 0, '16:30', '17:00', '架構評審', 'Teams', { response: 'NoResponseReceived' }),
    ev('c5', 1, '09:00', '09:15', '每日站立會議', 'Teams'),
    ev('c6', 1, '11:00', '12:00', '供應商簡報', '2F 大會議室'),
    { ...ev('c7', 2, '00:00', '23:59', '元旦連假', ''), allDay: true, status: 'Free' },
  ],
});

const task = (id, project, title, state, due, remaining, parentTitle) =>
  ({ id, title, state, type: 'Task', project, parentId: id - 100, parentTitle, changed: '2026-12-29', due, remaining,
     url: `https://dev.azure.com/example-org/${project}/_workitems/edit/${id}` });
write('devops.js', 'STARTPAGE_DEVOPS', {
  ts: now - 5 * 60e3, org: 'https://dev.azure.com/example-org', project: '', error: '',
  items: [
    task(1204, 'Website', '首頁改版：導覽列 RWD', 'Active', '2026-12-28', 4, '官網改版 2027'),
    task(1211, 'Website', '撰寫登入流程 E2E 測試', 'Active', '2026-12-31', 6, '官網改版 2027'),
    task(1215, 'Website', '更新部署文件', 'New', '', 2, '維運文件整理'),
    task(2302, 'Mobile App', '推播通知設定頁', 'Active', '2027-01-05', 8, '會員功能強化'),
    task(2310, 'Mobile App', '修正深色模式文字對比', 'New', '', 1, '會員功能強化'),
  ],
});

write('inbox.js', 'STARTPAGE_INBOX', [
  { id: 'n3', ts: now - 2 * 60e3, title: '夜間批次', message: '資料匯入完成：共 12,480 筆', priority: 'default', click: '', source: '排程' },
  { id: 'n2', ts: now - 40 * 60e3, title: '部署', message: 'Website v2.8.0 已部署到測試環境', priority: 'default', click: 'https://ci.example.com/builds/482', source: 'CI' },
  { id: 'n1', ts: now - 95 * 60e3, title: '監控', message: 'API 回應時間超過 2 秒（已恢復）', priority: 'high', click: '', source: '監控' },
]);
fs.writeFileSync(path.join(dir, 'options.js'), 'window.STARTPAGE_OPTIONS = { devops: true, calendar: true, calendarStrip: true };\n');

(async () => {
  const browser = await chromium.launch(launchOpts);
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, timezoneId: 'Asia/Taipei', locale: 'zh-TW' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.clock.install({ time: now });
  await page.clock.pauseAt(now);
  // 首次開啟前先放好內容：DevOps 區塊放在第一個，並標記收件匣已讀過游標（讓通知進入紀錄而不是逐一跳出）
  const cfg = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../examples/default.json'), 'utf8'));
  cfg.pages[0].widgets.splice(2, 0, { id: 'dev', type: 'devops', title: 'DevOps Task', color: 'purple' });
  cfg.inboxCursor = now - 120 * 60e3;
  await page.addInitScript(s => { if (!localStorage.getItem('startpage.v1')) localStorage.setItem('startpage.v1', s); }, JSON.stringify(cfg));
  await page.goto(pathToFileURL(html).href);
  await page.locator('.dtask').first().waitFor();
  await page.locator('.cal-col').first().waitFor();
  await page.evaluate(() => document.querySelector('.toast')?.classList.remove('show'));
  await page.screenshot({ path: path.join(images, 'integrations-demo.png'), fullPage: true });
  await page.locator('#btnBell').click();
  await page.locator('.nitem').first().waitFor();
  await page.screenshot({ path: path.join(images, 'notifications.png'), clip: { x: 900, y: 0, width: 540, height: 560 } });
  await browser.close();
  if (errors.length) throw Error(errors.join('\n'));
  console.log('Integration screenshots generated.');
})().catch(e => { console.error(e); process.exit(1); });
