# 留白 / BlankTop 1.1.0 — 交接文档

> 给下一个对话 / 下一个 AI。时间：2026-11-02。
> 先读「硬约束」和「当前状态」，再看「手势图标待决定」。

## 一句话

macOS 27 菜单栏折叠工具。当前 1.1.0（build 7），应用名已改成英文 **BlankTop**，正在「不看还看」模式。代码已编译安装，但工作区有大量未提交改动。

## 当前状态

| 项 | 值 |
|---|---|
| 仓库 | `/Users/xa/Documents/Default Project/BlankTop` |
| 远程 | `https://github.com/0xTack/BlankTop`（旧 xiaoan223 已 301 迁移） |
| 版本 | 1.1.0，CFBundleVersion 7 |
| Bundle ID | `com.xa.blanktop` |
| 安装 | `/Applications/BlankTop.app`，正在运行（pid 68680 左右） |
| Git | HEAD `458339b`，**大量未提交改动** |
| 配置 | `~/Library/Application Support/BlankTop/config.json` |
| 当前配置 | `mode = peek`、`icon = toggle`、`language = zh`、`sound = tink` |
| 应用名 | `CFBundleDisplayName = BlankTop`，菜单里是「退出 BlankTop」 |
| 当前图标 | SVG 手势，open = 放大眼睛 + 下移三指的 warped 版（见下） |
| 当前进程 | 从 `/Applications/BlankTop.app` 启动 |

当前 config：

```json
{
  "autoCollapseSeconds": 10,
  "expandMode": "allowlist",
  "hotkey": "opt+cmd+h",
  "icon": "toggle",
  "language": "zh",
  "mode": "peek",
  "sound": "tink",
  "soundVolume": 0.12
}
```

## 硬约束（用户明确要求）

1. **改之前先给预览**：截图 / Markdown / 试听音频，等用户确认再动代码。
2. **不要擅自打包安装**：`./build.sh` 可以跑（只编译到项目里的 `BlankTop.app`）；`./package.sh` 会安装到 `/Applications` 并生成 dist，**必须等用户明确说「安装 / 打包」**。
3. 只改 `BlankTop/`，不要动其它项目。
4. 不要删用户文件，尤其是 `assets/donation-qr.png`（未跟踪，但 build.sh 会拷贝它）。
5. 用户偏好：中文、直接、少废话；界面小、不要多余元素。

## 已实现的功能

### 模式

| 模式 | 行为 |
|---|---|
| `manual` 开关 | 点一下收起 / 展开，不自动 |
| `peek` 不看还看 | 点开 10 秒后自动合上；当前是**直接切换**到无眼并收起，没有动画 |
| `box` 无聊盒子 | 绿色透明开关 + 从屏幕上方伸下来的手（`HandPress.swift`）按回去，10 秒 |
| `crazy` 抓狂模式 | 状态项撑宽成空地，♞ 在空地内跳；第 4 次抓住后摔下菜单栏；10 秒 watchdog |

右键菜单 → **模式** 切换。模式说明（悬停 0.1 秒出现，浅色小气泡，位置在模式子菜单右侧）：

- 开关：`决定权在自己`
- 不看还看：`就是想看`
- 无聊盒子：`屏幕外的手永远多管闲事`
- 抓狂模式：`别点，会发生未知情况`

### 其它

- 应用名、权限弹窗、路径提示里的「留白」都已改成 `BlankTop`
- README / 官网 / 发布页版本号已到 1.1.0；官网图标和图标图库已更新
- 绿色透明开关已恢复（红色按钮、拨杆方案都已回退）
- 权限：启动时调用 `resetStalePermissionIfNeeded()`；不再每次启动/点击弹授权框
- 签名：`BlankTop Local` 证书，钥匙串密码 `blanktop-signing`

## 手势图标：当前实现与待决定（最重要）

用户对图标非常在意，已经来回很多版。**不要假设当前版本是最终版。**

### 当前已安装的图标

- 直接读取 SVG 路径渲染：`HandSVG.swift` 解析 potrace 生成的 `<path d="...">`，转成 `NSBezierPath`，再画到 20pt。
- 当前 `assets/hand-open.svg` 是 **eye-big4** 版：在用户原图 1:1 基础上
  - 眼睛放大约 1.3 倍
  - 上下手指拉开
  - 下面三根手指再向下移动约 38px（相对 255px 原图）
- 当前 `assets/hand-closed.svg` 是用户原图的无眼版（未改）。
- `peekImage` 里对 SVG 路径做了 `fill` + `0.55pt stroke`，让线条和菜单图标粗细接近。
- 状态切换是 `cover >= 0.5 ? closed : open`，**没有过渡动画**；10 秒到点直接合眼 + 收起。
- 用户对当前 eye-big4 的反馈：**「手指没有向下移动的感觉，眼睛像是挤出来的」**。

### 用户原始素材

桌面：

- `~/Desktop/BlankTop-hand-open-final.svg` — 用户确认过的干净睁眼手（1:1 原图描摹）
- `~/Desktop/BlankTop-hand-closed-final.svg` — 干净无眼手
- `~/Desktop/BlankTop-hand-open-1to1.svg` / `-closed-1to1.svg` — 完整 1:1 描摹
- `~/Desktop/BlankTop-hand-open-clean.svg` / `-closed-clean.svg` — 去掉小细节的 1:1
- `~/Desktop/BlankTop-hand-open-thumb.svg` / `-thumb2.svg` / `-thumb4.svg` — 大拇指简化实验
- `~/Desktop/BlankTop-hand-open-thumb4.svg` / `-thumb4.svg` — 保留指甲、去关节线的版本

项目里：

- `assets/hand-open.svg`（eye-big4）
- `assets/hand-closed.svg`（干净无眼）
- `assets/hand-open.pdf` / `hand-closed.pdf`（旧 PDF，仅作 SVG 解析失败时的兜底）

### 已经试过但被否定的方向

- 1:1 细线描摹：20pt 太淡
- 加粗 R12：糊成一团
- 去掉大拇指指甲：线条断，后来保留指甲/重画
- 把整只手做交叉淡入淡出：像两个图标切换
- 用黑条盖眼睛：线条太重、过渡太多
- 把三根手指直接向下移动（warp / 拉伸）：眼睛变形、像挤出来
- 简化矢量（两根/三根手指、v6）：用户认为偏离原图

### 最新的、还没安装的预览

`/tmp/two-pose-preview.png`（生成脚本 `/tmp/twopose.swift`）：

- 把手指拆成图层重画
- 眼睛固定在原位、自然大小，不再拉挤
- 睁眼：上手指在上，下面三根手指整体在眼睛下方，分开明显
- 闭合：三指收回盖眼，无眼
- 这个版本可以做「三根手指整体向下滑动」的动画

用户还没确认这个静态姿势。**下一步应该先让用户看这个 `/tmp/two-pose-preview.png`，确认姿势和眼睛大小，再做滑动动画。**

### SVG 解析注意

`HandSVG.swift` 只支持 potrace 风格的 `M/m L/l C/c H/h V/v Z/z`（当前文件只有 `M/c/l/m/z`）。如果用户在 Illustrator/Figma 里另存 SVG，可能带 `S/Q/A` 等命令，解析会失败，需要扩展解析器或改回 PDF。`HandSVG` 里做了 y 翻转（SVG y 向下，NSImage y 向上）。

## 半成品 / 未完成（重要）

### 英文菜单（已完成 2026-11-02）

- 右键菜单 → **语言 → 中文 / English**，当前语言打勾
- 选择后写入 `Config.language` 并立即生效（菜单每次重建，下次打开就是新语言）
- 切换时会销毁赞赏窗口缓存，下次打开用新语言重建
- 长文本用 `tt(中文, English)`：路径提示、辅助功能权限弹窗、空菜单提示都已双语
- `enStrings` / `t(_:)` / `Config.language` 继续使用

### 检查更新（已完成 2026-11-02）

- 菜单底部 **检查更新…** → GitHub Releases API
- `repoSlug = "0xTack/BlankTop"`（**仓库已从 xiaoan223 迁移到 0xTack**，旧地址 301）
- 按数字段比较 `tag_name` 和 `CFBundleShortVersionString`
- 有新版：「发现新版本 x.y.z / 下载 / 稍后」，下载打开 release 页面
- 已是最新：「已是最新版本」；失败会显示 HTTP 状态或网络错误
- 实测：API 最新 release 是 `v1.0.5`，app 是 1.1.0，所以现在提示已是最新；发 1.1.0 后才有更新
- README / `docs/index.html` / `docs/launch.html` 里的仓库链接已一并改成 `0xTack/BlankTop`

### 日志（已完成 2026-11-02）

- `main.swift` 23 处 + `CrazyGame.swift` 6 处 `NSLog` 已全部换成 `btLog`
- 写入 `~/Library/Logs/BlankTop.log`，ISO8601 时间戳
- 菜单底部 **打开日志**，文件不存在时先写一条再打开
- 换语言、检查更新、抓狂流程都会写日志

### 抓狂模式音效

- 现在摔倒时播放的是系统 `Glass`（玻璃声），用户认为不对
- 已生成一个木头棋子声 `/tmp/chess-fall.wav`（脚本思路：短噪声 + 180/260/340Hz 衰减 + 低频桌面共鸣），**还没接进 app**
- 用户要「下棋那种木头质感、有倒下的感觉」

### 无聊盒子矢量

- `/tmp/box-preview.png` 是开盖/合盖的线稿预览，**还没确认、没实现**
- 当前 box 模式仍是绿色开关 + `HandPress` 外部手

### 其它

- `animatePeekCover` 函数还在，但已经没有人调用（dead code）
- `peekImage` 的 open/closed 切换没有过渡；用户可能还要动画
- `assets/hand-open.pdf` 是旧版本（干净 1:1），不是 eye-big4；只作兜底
- `assets/donation-qr.png` 未跟踪，是用户给的赞赏码；`build.sh` 已经会拷贝

## 关键文件

| 文件 | 作用 |
|---|---|
| `main.swift` | 主逻辑：模式、配置、菜单、悬停说明、图标绘制、peek/box/crazy、权限、语言脚手架、btLog |
| `CrazyGame.swift` | 抓狂模式：NSPanel、棋子跳跃/摔倒、事件 tap、宽状态项空地 |
| `HandPress.swift` | 无聊盒子的外部手：从屏幕上方降下、按开关、收回 |
| `HandSVG.swift` | SVG path 解析 → NSBezierPath，y 翻转，适配 20pt |
| `build.sh` | 编译 ObjC + 4 个 Swift 文件，组装 bundle，拷贝 icon / hand PDF+SVG / 赞赏码，签名 |
| `package.sh` | build + 安装到 `/Applications` + 生成 `dist/BlankTop-1.1.0.dmg` / `.zip`（**需要用户同意**） |
| `Info.plist` | 1.1.0 / 7，DisplayName = BlankTop |
| `README.md` / `docs/` | 官网文档，版本号已 1.1.0 |
| `HANDOVER-1.1.md` | 上一份交接，部分内容已过时 |
| `HANDOVER-2.md` | 本文件 |

## 测试 / 调试命令

```bash
cd "/Users/xa/Documents/Default Project/BlankTop"
./build.sh                     # 只编译，不安装
./package.sh                   # 会安装！用户同意后再跑

# 看状态项位置（dev 里的小工具要先编译）
swiftc -O dev/scan.swift -framework AppKit -framework ApplicationServices -o /tmp/btscan2
/tmp/btscan2 | grep blanktop

# 截图菜单栏
screencapture -R0,0,1920,40 /tmp/menu.png
```

当前安装的进程是 `BlankTop.app`，单实例保护：重复启动会退出。

## 下一步建议（按优先级）

1. **手势图标**：先给用户看 `/tmp/two-pose-preview.png`（图层重画、眼睛固定、三指在下）。确认后：
   - 用 `twopose.swift` 的绘制逻辑做成 app 内图标
   - 把「三指整体向下滑动」做成 0.5s 动画（眼睛固定，不要缩放）
   - 不要再用整手拉伸/warp
2. ~~英文菜单~~（已完成，见上）
3. ~~检查更新~~（已完成，见上）
4. ~~日志~~（已完成，见上）
5. **抓狂音效**：把 `/tmp/chess-fall.wav` 放进 `assets/`，`NSSound` 播放，替换 `Glass`；先给用户试听。
6. **无聊盒子矢量**：确认 `/tmp/box-preview.png` 后替换绿色开关。
7. **提交**：当前所有改动未 commit；确认后再 commit。**不要擅自 package。**
8. 调试提示：项目里的 `BlankTop.app` 不在 `/Applications`，折叠时连自己的图标也会被藏起来——这是路径提示里说的正常现象，不是 bug。预览菜单建议用 `launchctl setenv BLANKTOP_SKIP_PATH_ALERT 1` 再 `open ./BlankTop.app`，看完 `unsetenv` 并重启 `/Applications` 版本。
