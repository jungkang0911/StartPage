// GitHub Pages 線上試用的預設內容（由 scripts/build-pages.ps1 從 examples/default.json 產生）
window.STARTPAGE_DEFAULT = {
    "theme":  "light",
    "engine":  0,
    "current":  0,
    "pages":  [
                  {
                      "id":  "home",
                      "name":  "首頁",
                      "widgets":  [
                                      {
                                          "id":  "tools",
                                          "type":  "links",
                                          "title":  "團隊工具",
                                          "color":  "blue",
                                          "links":  [
                                                        {
                                                            "id":  "wiki",
                                                            "name":  "團隊 Wiki",
                                                            "url":  "https://wiki.example.com",
                                                            "icon":  "📘",
                                                            "star":  true
                                                        },
                                                        {
                                                            "id":  "board",
                                                            "name":  "專案看板",
                                                            "url":  "https://board.example.com",
                                                            "icon":  "📋",
                                                            "star":  true
                                                        },
                                                        {
                                                            "id":  "reports",
                                                            "name":  "報表中心",
                                                            "url":  "https://reports.example.com",
                                                            "icon":  "📊"
                                                        },
                                                        {
                                                            "id":  "share",
                                                            "name":  "共用資料夾",
                                                            "url":  "\\\\fileserver.example\\team\\shared"
                                                        }
                                                    ]
                                      },
                                      {
                                          "id":  "reading",
                                          "type":  "links",
                                          "title":  "閱讀清單",
                                          "color":  "green",
                                          "links":  [
                                                        {
                                                            "id":  "weekly",
                                                            "name":  "技術週報",
                                                            "url":  "https://weekly.example.org",
                                                            "icon":  "📰"
                                                        },
                                                        {
                                                            "id":  "learn",
                                                            "name":  "線上課程",
                                                            "url":  "https://learn.example.org",
                                                            "icon":  "🎓",
                                                            "star":  true
                                                        }
                                                    ]
                                      },
                                      {
                                          "id":  "dev",
                                          "type":  "devops",
                                          "title":  "DevOps Task",
                                          "color":  "purple"
                                      },
                                      {
                                          "id":  "notes",
                                          "type":  "notes",
                                          "title":  "今日筆記",
                                          "text":  "## 本週重點\n- [x] 整理專案書籤\n- [ ] 準備週五 Demo\n- [ ] 閱讀 **技術週報** 第 42 期\n\n| 項目 | 狀態 |\n|---|---|\n| 新版首頁 | 進行中 |\n| 文件更新 | 待辦 |"
                                      },
                                      {
                                          "id":  "todo",
                                          "type":  "todo",
                                          "title":  "待辦事項",
                                          "color":  "amber",
                                          "items":  [
                                                        {
                                                            "id":  "t1",
                                                            "text":  "建立自己的起始頁",
                                                            "done":  true
                                                        },
                                                        {
                                                            "id":  "t2",
                                                            "text":  "匯入常用書籤",
                                                            "done":  false
                                                        },
                                                        {
                                                            "id":  "t3",
                                                            "text":  "匯出一份設定備份",
                                                            "done":  false
                                                        }
                                                    ]
                                      }
                                  ]
                  },
                  {
                      "id":  "learn",
                      "name":  "學習",
                      "widgets":  [
                                      {
                                          "id":  "docs",
                                          "type":  "links",
                                          "title":  "參考文件",
                                          "links":  [
                                                        {
                                                            "id":  "style",
                                                            "name":  "程式風格指南",
                                                            "url":  "https://docs.example.com/style-guide",
                                                            "icon":  "📐"
                                                        },
                                                        {
                                                            "id":  "faq",
                                                            "name":  "常見問題",
                                                            "url":  "https://docs.example.com/faq",
                                                            "icon":  "❓"
                                                        }
                                                    ]
                                      }
                                  ]
                  }
              ]
};
