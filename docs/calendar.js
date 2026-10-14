// GitHub Pages 線上試用：虛構行事曆，每次載入依目前時間產生（真實環境由 calendar-sync.ps1 產生此檔）
(() => {
  const d0 = new Date(); d0.setHours(0, 0, 0, 0);
  const at = (day, h, m) => d0.getTime() + day * 86400e3 + (h * 60 + m) * 60e3;
  const now = Date.now(), h = new Date().getHours();
  const ev = (id, day, s, e, subject, location, extra = {}) =>
    ({ id, subject, start: at(day, ...s), end: at(day, ...e), allDay: false, location, organizer: '王小明', status: 'Busy', response: 'Accept', ...extra });
  // 讓示範永遠有「進行中」與「下一場」：以目前小時為基準排一場
  const items = [
    ev('c1', 0, [9, 0], [9, 15], '每日站立會議', 'Teams'),
    ev('c2', 0, [h, 0], [h, 50], 'Sprint 規劃會議', '3F 會議室 A'),
    ev('c3', 0, [h + 2, 0], [h + 3, 0], '需求訪談：訂單系統', '5F 會議室 B'),
    ev('c4', 0, [h + 5, 30], [h + 6, 0], '架構評審', 'Teams', { response: 'NoResponseReceived' }),
    ev('c5', 1, [9, 0], [9, 15], '每日站立會議', 'Teams'),
    ev('c6', 1, [11, 0], [12, 0], '供應商簡報', '2F 大會議室'),
    { ...ev('c7', 2, [0, 0], [23, 59], '部門活動日', ''), allDay: true, status: 'Free' },
  ].filter(e => e.end < at(3, 0, 0));
  window.STARTPAGE_CALENDAR && STARTPAGE_CALENDAR({ ts: now - 3 * 60e3, owa: 'https://mail.example.com/owa/#path=/calendar', error: '', items });
})();
