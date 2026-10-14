// GitHub Pages 線上試用：虛構通知（真實環境由 notify.ps1 寫入此檔）
(() => {
  const now = Date.now();
  window.STARTPAGE_INBOX && STARTPAGE_INBOX([
    { id: 'demo-n3', ts: now - 2 * 60e3, title: '夜間批次', message: '資料匯入完成：共 12,480 筆', priority: 'default', click: '', source: '排程' },
    { id: 'demo-n2', ts: now - 40 * 60e3, title: '部署', message: 'Website v2.8.0 已部署到測試環境', priority: 'default', click: 'https://ci.example.com/builds/482', source: 'CI' },
    { id: 'demo-n1', ts: now - 95 * 60e3, title: '監控', message: 'API 回應時間超過 2 秒（已恢復）', priority: 'high', click: '', source: '監控' },
  ]);
})();
