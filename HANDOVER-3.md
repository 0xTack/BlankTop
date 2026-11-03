# 留白 / BlankTop 1.1.0 → 下一版 交接

> 给下一个对话 / 下一个开发者。时间：2026-11-03。
> 先看「当前状态」和「已知坑」，再看「下一版建议」。

## 一句话

macOS 菜单栏折叠工具。1.1.0 已发布（Apple 芯片 / Intel 双安装包），官网、Release、源码都已上线；应用内保留赞赏，网站和 README 已移除赞赏内容。

## 当前状态

| 项 | 值 |
|---|---|
| 仓库 | `/Users/xa/Documents/Default Project/BlankTop` |
| 远程 | `https://github.com/0xTack/BlankTop`（旧 xiaoan223 已 301） |
| 版本 | 1.1.0，CFBundleVersion 7 |
| Bundle ID | `com.xa.blanktop` |
| 默认模式 | **不看还看（peek）** |
| 当前配置 | `~/Library/Application Support/BlankTop/config.json` |
| 安装 | `/Applications/BlankTop.app`（本地签名 `BlankTop Local`） |
| 官网 | https://0xtack.github.io/BlankTop/（Pages 源：`main` 的 `docs/`） |
| 更新说明页 | https://0xtack.github.io/BlankTop/release-1.1.0.html |
| Release | https://github.com/0xTack/BlankTop/releases/tag/v1.1.0 |
| 日志 | `~/Library/Logs/BlankTop.log` |

安装包（`dist/`，Release 同名附件）：

- `BlankTop-1.1.0-arm64.dmg` / `.zip` — M1–M4
- `BlankTop-1.1.0-intel.dmg` / `.zip` — x86_64

桌面也放了一份：`~/Desktop/BlankTop-1.1.0/`。

## 硬约束

1. **改之前先给预览**（截图 / Markdown / 试听），确认后再动代码。
2. `./build.sh` 只编译到项目里的 `BlankTop.app`；`./package.sh` 会安装到 `/Applications`；`./package-arch.sh` 只生成双架构到 `dist/`，不安装。
3. 只改 `BlankTop/`（除非明确要求改别的项目）。
4. 不要删用户文件；应用内的赞赏码 `assets/donation-qr.png` 要保留（网站和 README 的赞赏已删除）。
5. 用户偏好：中文、直接、少废话；界面小、不要多余元素。

## 1.1.0 本轮完成的内容

### 模式

| 模式 | 行为 |
|---|---|
| 开关 manual | 点一下收起 / 展开，不自动 |
| 不看还看 peek | 点开 10 秒后自动收起；**默认模式** |
| 无聊盒子 box | 猫箱图标 + 屏幕外的手（HandPress）按回去，纸箱音效 |
| 抓狂模式 crazy | 棋子躲 3 次，第 4 次抓住：原处消失 → 从正上方落回原位 → 落子声 |
| 混沌模式 custom | 自定义：延时、动作、两张状态图、两个音效、切换效果 |

启动时如果已是展开状态，也会开始自动收起倒计时（之前只有手动点开才计时，这是“自动隐藏失效”的原因）。

### 混沌 / 自定义

- 菜单：模式 → 混沌模式，选中后自动弹出设置窗口；主菜单不再单独放「自定义设置…」。
- 设置项：展开后 N 秒、到时收起/展开/不动、切换效果（直接/淡入淡出/从上落下）、展开图、收起图、单色模板、收起音、展开音。
- 图片：「选择…」上传，或「内置 ▾」从本季素材里选（默认手势、睁/闭眼、猫箱开/关、棋子、18 种图标样式）。
- 音效：不响 / 纸箱合上 / 木盖轻抬 / 纸板摩擦 / 空气轻推 / 低沉啵 / 两声轻叩 / 轻叩+气流 / 落子 / 棋子飞出 / 系统 Tink、Pop、Purr、Bottle、Glass / 上传。
- 存储：`config.json` 的 `custom`；上传文件在 `~/Library/Application Support/BlankTop/custom/`。
- 内置 token：`builtin:hand-open|hand-closed|cat-open|cat-closed|knight|icon:<style>`。

### 图标

- 图标菜单统一 18pt、单色、SF Symbols；名称去掉括号和 emoji。
- macOS 27 默认隐藏菜单项图片：已用 `item.preferredImageVisibility = .visible` 修复。
- 手势（peek）：`assets/hand-open.png` / `hand-closed.png`，转 alpha 遮罩 + 膨胀加粗（`PeekArt.swift`），template。
- 猫箱：`BoxCat.swift` 矢量，打开 = 耳朵+眼睛，关闭 = 合上（无猫）。
- 棋子：`♞` 字符按墨迹裁切 + 底座，放大 1.1 倍（`knightImage()`）。
- 自绘开关：浅色绿 + 黑轮廓/黑点；深色保留绿 + 白轮廓/白点。判断依据是**菜单栏按钮的 appearance**（每秒轮询），系统外观切换本身不触发变化。

### 音效

- 盒子：收起 `box-close.wav`（纸箱闷响），展开 `box-open.wav`（两声轻叩）。
- 抓狂：落子 `chess-place.wav`（清脆），跳出 `chess-leap.wav`。
- 音量：系统音 `max(0.35, soundVolume)`；自带音效 `soundVolume × 0.6`。

### 其它

- 语言子菜单（中文 / English）；长文本双语。
- 检查更新（GitHub Releases，`repoSlug = 0xTack/BlankTop`）。
- 打开日志菜单；`btLog` 全量替换 `NSLog`。
- 官网新首页（`docs/index.html` = `preview-v2` 内容）、`preview.html` 同步、`release-1.1.0.html` 更新说明 + 安装排错。
- 宣传页强调 MIT 开源；双架构下载按钮。
- TokenPeek 作品的 BlankTop 卡片：真实图标、新文案、「打开介绍页 →」。

## 关键文件

| 文件 | 作用 |
|---|---|
| `main.swift` | 主逻辑：模式、配置、菜单、图标、peek/box/crazy、权限、语言、更新、日志、自定义接入 |
| `IconStyle.swift` | 图标样式 + `IconRenderer`（状态栏与菜单共用） |
| `BoxCat.swift` | 猫箱图标（开/关） |
| `PeekArt.swift` | 手势 PNG → 遮罩图标 |
| `CustomMode.swift` | 自定义设置窗口、音效播放、素材库 |
| `CrazyGame.swift` | 抓狂模式：面板、点击 tap、跳跃、被抓动画 |
| `HandPress.swift` | 无聊盒子的外部手 |
| `HandSVG.swift` | SVG path 解析（旧手势兜底） |
| `build.sh` | 单架构编译 + 组装 + 签名 |
| `package.sh` | 单架构 build + 安装 + dist |
| `package-arch.sh` | arm64 / intel 双架构 + dist（不安装） |
| `docs/` | 官网（Pages 从 main 的 docs 发布） |

## 已知坑

1. **深色判断**：`NSApp.effectiveAppearance` 跟系统设置走，不等于菜单栏底色。现在用状态栏按钮的 appearance（每秒轮询）。如果菜单栏因壁纸变黑但按钮仍报 light，图标不会变白。
2. `IconRenderer.drawToggle` 里不要用 `addClip()` 画半截胶囊——在某些上下文里 clip 会残留，只剩半边；现在用自绘路径。
3. `PeekArt` 的膨胀半径 7 是给 600px 源图用的；换图要重新调。
4. 抓狂面板默认会被系统夹回屏幕内，`ClickPanel` 已重写 `constrainFrameRect` 允许位于屏幕上方。
5. `♞` 字形周围留白很大，必须按墨迹裁切，不能直接按字号摆。
6. Intel 构建会有 `libswiftCompatibilityPacks.a` 缺 x86_64 的链接警告，但产物可用（已验证 `lipo -archs`）。
7. 官网：`0xtack.github.io/BlankTop` 来自 `BlankTop` 仓库 `main` 的 `docs/`；`0xtack.github.io/TokenPeek` 来自 TokenPeek 仓库的 **`gh-pages`** 分支（改 main 不会上线）。
8. 旧的 `xiaoan223.github.io/BlankTop/` 已 404；仓库 Homepage 已改为 0xtack 地址。

## 测试 / 发布

```bash
cd "/Users/xa/Documents/Default Project/BlankTop"
./build.sh            # 只编译
./package-arch.sh     # arm64 + intel，输出到 dist/
./package.sh          # 安装到 /Applications（需用户同意）

# 菜单栏截图
screencapture -x -R0,0,1920,40 /tmp/menu.png

# 自测抓狂模式（不点鼠标，自动跳三次再被抓）
launchctl setenv BLANKTOP_CRAZY_AUTOPLAY 1
```

发布：

```bash
git add -A && git commit -m "..." && git push origin main
gh release upload v1.1.0 dist/BlankTop-1.1.0-arm64.dmg --clobber
```

## 下一版建议（按优先级）

1. **手势滑动动画**：现在 peek 的睁/闭眼是直接切换；用户一直想要「三指整体下滑露眼、上滑盖住」的 0.5s 动画（眼睛不缩放）。
2. **深色检测更稳**：可考虑截取菜单栏一条像素判断亮度（需要屏幕录制权限），替代 appearance 轮询。
3. **自定义模式增强**：多套预设（方案 1/2/3）、每种模式单独配图/音、窗口内直接试听内置素材。
4. **公证与分发**：目前本地签名未公证；首次打开有“已损坏/无法验证”提示，靠 `xattr -dr com.apple.quarantine` 解决。有条件做 notarization。
5. **清理死代码**：`animatePeekCover` 已无调用；赞赏窗口代码保留但入口只在菜单里，可按需重构。
6. **安装文档**：`release-1.1.0.html` 已含排错；可把「更新说明」加入官网导航。
7. **版本号**：下一版改 `Info.plist` 到 1.1.1 / 2.2.0，并更新 `package*.sh` 里的 `VERSION` 与页面下载链接。

## 备注

- 应用内赞赏入口：菜单「👏 有你真好」，窗口里有 `assets/donation-qr.png`；网站与 README 已不再提。
- 旧的 `HANDOVER-1.1.md` / `HANDOVER-2.md` 部分内容已过时，以本文件为准。
