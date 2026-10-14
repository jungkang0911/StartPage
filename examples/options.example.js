// 放在 index.html 同資料夾、改名為 options.js 即生效（install.ps1 首次安裝會自動複製一份）
// 只寫要改的項目即可；頁面「⋯ → ⚙ 設定」存的值會再覆蓋這裡
// 適合統一派送給同事
window.STARTPAGE_OPTIONS = {
  title: '★ StartPage',     // 左上角文字
  favicon: false,         // true：自動向網站抓 /favicon.ico（內網站台也適用）；false：只用字母 / Emoji，不對外連線
  inbox: true,            // 收件匣通知：notify.ps1 → inbox.js
  devops: false,          // Azure DevOps 工作項：devops-tasks.ps1 → devops.js（需 settings.json 的 devops.org）
  calendar: false,        // Outlook 行事曆：calendar-sync.ps1 → calendar.js（需 settings.json 的 calendar.ewsUrl）
  calendarRemind: 10,     // 會議前幾分鐘通知
  calendarStrip: false,   // 常用列下方顯示 1~3 天行事曆
  engines: [              // 搜尋引擎：[名稱, 查詢網址（關鍵字接在最後）]
    ['Google', 'https://www.google.com/search?q='],
    ['DuckDuckGo', 'https://duckduckgo.com/?q='],
    ['GitHub', 'https://github.com/search?q='],
  ],
};

