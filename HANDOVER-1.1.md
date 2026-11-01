# 留白 BlankTop 1.1.0 — 交接

> 给下一个接手的人/AI。时间：2026-11-01。

## 一句话

macOS 27 菜单栏折叠工具。1.1.0 新增「无聊盒子」和「抓狂棋子」两种模式，应用图标换成白底手遮眼。

## 当前状态

| 项 | 值 |
|---|---|
| 版本 | 1.1.0（CFBundleVersion 7） |
| 安装 | `/Applications/BlankTop.app`，正在运行 |
| Bundle ID | `com.xa.blanktop` |
| 仓库 | `/Users/xa/Documents/Default Project/BlankTop` |
| Git | 1.1.0 已提交（3 个 commit），工作区干净 |
| 配置 | `~/Library/Application Support/BlankTop/config.json`，当前 `mode = manual`、`autoCollapseSeconds = 10` |
| 分发包 | `dist/BlankTop-1.1.0.dmg` / `.zip` |
| 应用图标 | 白底手遮眼，无边框、无阴影、圆角透明 |
| 签名 | 新建的 `BlankTop Local` 证书，钥匙串密码 `blanktop-signing` |
| 旧钥匙串 | `~/Library/Keychains/BlankTop-Signing.keychain-db.bak-20261101165258` |
| 当前进程 | 从终端直接启动，日志在 `/tmp/bt-crazy.log`；日常用 `open -a /Applications/BlankTop.app` |

## 1.1.0 提交内容

已修改：

- `Info.plist`（1.1.0 / 7）
- `package.sh`（VERSION=1.1.0）
- `build.sh`（编译 `CrazyGame.swift`）
- `main.swift`（模式、盒子动画、抓狂棋子、权限）
- `assets/Icon.icns`、`assets/icon_1024.png`（新图标）

新增：

- `CrazyGame.swift`（抓狂棋子面板/动画）
- `dev/` 下多个图标探索脚本：`modeicons`、`realbox`、`linebox`、`boxstyles`、`leverbox`、`sleepcat`、`noline`、`simple`、`handeye`、`smoothicon`、`iconfromref`、`iconsolidframe`、`iconwhite`、`previewicon`、`makeappicon`、`clickstatus`

其中**当前应用图标**由 `dev/iconwhite.swift` 生成（源图 `~/Desktop/留白.jpg`，裁掉原边框、白底圆角、无边框）。`assets/icon_1024.png` 是最终 1024 PNG，可直接再生成 `.icns`。注意源图已不在桌面，重新生成前需先找回 `留白.jpg`。

## 三种模式

| 模式 | 图标 | 行为 |
|---|---|---|
| 手动 `manual` | 原有 18 种任选 | 左键折叠/展开，无自动合上 |
| 无聊盒子 `box` | 正面盒子 + 拨杆 | 点一下展开、拨杆向右变绿；10 秒后小手伸出来把拨杆拨回、菜单栏合上。倒计时中再点只抖一下拨杆；热键可提前关 |
| 抓狂棋子 `crazy` | ♞ | 点一下开始，前 3 次点跳走，第 4 次抓住；棋子旋转摔倒 + Glass 音效，然后切换一次菜单栏，回到抓狂模式；10 秒没抓住自动收回 |

右键菜单 → **模式** 切换。抓狂棋子局中右键会取消这一局并打开菜单。

## 关键实现

### `main.swift`

- `PlayMode`：`manual / box / crazy`；旧配置 `auto` 自动迁移成 `box`
- `boxImage(leverAngle:hand:)`：20×20 自绘盒子 + 拨杆；`-42°` 关、`+42°` 开，带过冲
- `boxPrimaryClick / boxToggle / animateLever / wiggleLever / autoClose`：盒子逻辑和 10 秒计时
- `knightImage()`：♞ 21pt semibold，随菜单栏明暗取 `labelColor`
- `startCrazyGame / finishCrazyGame / stopCrazyGame`：把真实状态项隐藏，交给 `CrazyGame` 面板
- 权限：`resetStalePermissionIfNeeded()` **现在真的在启动时调用**；不再启动/每次点击弹系统授权框，每次启动最多解释一次

### `CrazyGame.swift`

- 非激活 `NSPanel`，`level = .popUpMenu`，32×30，层级高于菜单栏
- `PieceView` 自绘棋子：跳跃、旋转、摔倒、回弹
- 前 3 跳随机在状态项左右 ±180pt 内，避开刘海
- 10 秒 watchdog；右键取消
- 实测面板能收到点击（日志：1296 → 1538 → 1357 → catch → collapse）

## 权限 / 签名

- 旧钥匙串密码丢失，已备份并重建同名证书；`build.sh` 用 `blanktop-signing` 解锁，打包不再弹密码
- 实测 `accessibility trusted = true`，权限没有再反复要
- 如果仍看到旧的“留白”勾选不生效：在辅助功能里删掉旧条目，再添加 `/Applications/BlankTop.app`
- TCC 清理只在「未授权 + 二进制 hash 变化」时执行，不会每次启动都清

## 已验证

- 盒子模式：热键展开 → 10 秒 → `auto close, box hand` → 折叠（日志）
- 抓狂棋子：用户点击跑通 3 次跳跃 → 抓住 → 摔倒 → 切换 → 折叠
- 应用图标：白底手遮眼已安装，Finder 可能需要刷新缓存

## 下一步

已完成（2026-11-01）：提交 1.1.0 代码；README / 官网 / 发布页版本号升到 1.1.0；官网图标换成白底手遮眼；首页加入「三种脾气」玩法区。

待办：

1. 录 1.1.0 的演示：盒子 10 秒、棋子 4 次点击；做 Release notes
2. 盒子图标在 18pt 实际菜单栏里可能需要微调（拨杆粗细、小手大小）
3. 抓狂棋子的调试 `NSLog` 可在发版前删掉
4. 打 tag、上传 `dist/BlankTop-1.1.0.dmg` / `.zip`、发 GitHub Release、部署官网
5. 桌面/临时目录里的图标预览文件可以清理

## 约束

- 只在 `BlankTop/` 里改，不要动其它项目
- 改完必须 `./package.sh` 才安装生效；签名证书已固定
- 不要把用户真实菜单栏整条发到公开页面；时间和 App 菜单要裁掉
- 用户偏好：中文、直接、少废话；界面小、不要多余元素
