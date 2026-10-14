// GitHub Pages 線上試用：虛構 Azure DevOps 工作項（真實環境由 devops-tasks.ps1 產生此檔）
(() => {
  const day = n => new Date(Date.now() + n * 86400e3).toISOString().slice(0, 10);
  const task = (id, project, title, state, due, remaining, parentTitle) =>
    ({ id, title, state, type: 'Task', project, parentId: id - 100, parentTitle, changed: day(-1), due, remaining,
       url: `https://dev.azure.com/example-org/${project}/_workitems/edit/${id}` });
  window.STARTPAGE_DEVOPS && STARTPAGE_DEVOPS({
    ts: Date.now() - 5 * 60e3, org: 'https://dev.azure.com/example-org', project: '', error: '',
    items: [
      task(1204, 'Website', '首頁改版：導覽列 RWD', 'Active', day(-2), 4, '官網改版 2027'),
      task(1211, 'Website', '撰寫登入流程 E2E 測試', 'Active', day(1), 6, '官網改版 2027'),
      task(1215, 'Website', '更新部署文件', 'New', '', 2, '維運文件整理'),
      task(2302, 'Mobile App', '推播通知設定頁', 'Active', day(6), 8, '會員功能強化'),
      task(2310, 'Mobile App', '修正深色模式文字對比', 'New', '', 1, '會員功能強化'),
    ],
  });
})();
