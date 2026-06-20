# ScrollShot — 滚动长截图

在 iPhone 上录制屏幕，自动拼接成一张无缝长图。

## 功能

- 🔴 系统录屏 → 切换到任意 App 滚动 → 停止
- 🤖 自动提取帧 + 智能拼接 + 保存相册
- ⚙️ 支持预览确认模式和自动模式
- 📜 历史记录管理

## 安装到 iPhone（无需 Mac、无需越狱、无需付费开发者账号）

### 你需要准备
- **Windows 电脑**（你正在用的）
- **iPhone**（iOS 15.0+）
- **一个 GitHub 账号**（免费注册：github.com）
- **一个 Apple ID**（就是你的 iCloud 账号）

---

### 步骤 1：把代码推送到 GitHub

```bash
# 在项目目录下初始化 git
cd ScrollingScreenshot
git init
git add .
git commit -m "Initial commit: ScrollShot app"

# 在 GitHub 网页上创建一个新仓库（如 scrolling-screenshot）
# 然后关联并推送
git remote add origin https://github.com/你的用户名/scrolling-screenshot.git
git branch -M main
git push -u origin main
```

推送后，GitHub Actions 会自动开始编译（约 10-15 分钟）。

### 步骤 2：下载编译好的 IPA

1. 打开你的 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 找到最新的 workflow run（黄色旋转图标表示进行中，绿色 ✓ 表示完成）
4. 点进去 → 拉到页面底部 **Artifacts** 部分
5. 点击 **ScrollingScreenshot.ipa** 下载

> 💡 以后每次修改代码并推送，GitHub Actions 都会自动重新编译。

### 步骤 3：安装到 iPhone

1. 在 Windows 上下载并安装 [AltServer](https://altstore.io/)  
2. 用 USB 数据线连接 iPhone 到 Windows 电脑  
3. 打开 AltServer（任务栏图标）→ 选择"Install AltStore" → 选择你的 iPhone
4. 输入你的 Apple ID 和密码（仅用于签名，不会泄露）
5. iPhone 上出现 AltStore App
6. 在 iPhone 上打开 AltStore → **My Apps** → 点右上角 **+**
7. 选择下载的 `ScrollingScreenshot.ipa`
8. 输入 Apple ID → 安装完成！

### 步骤 4：信任证书

1. iPhone 上：**设置 → 通用 → VPN 与设备管理**
2. 找到你的 Apple ID → 点击 → **信任**
3. App 现在可以打开了！

---

## 使用流程

1. 打开 ScrollShot
2. 点击红色录制按钮 → 系统弹窗确认
3. 切换到目标 App（微信/Safari/微博等），正常滚动浏览
4. 回到 ScrollShot → 点击停止
5. 等待自动处理 → 长图保存到相册

## 配置

- 🔧 点击右上角齿轮图标
- **预览确认**：保存前先预览长图
- **帧间隔**：调整采样频率（0.2s 更精确，0.6s 更快）

## 注意事项

- 录屏时状态栏会显示红色指示器（iOS 系统限制，无法隐藏）
- Netflix 等 DRM 保护内容录屏为黑屏
- 免费 Apple ID 签名的 App 有效期 7 天，到期前需重新安装
- AltStore 会通过 WiFi 自动续签（电脑和手机在同一网络时）

## 技术栈

Swift 5.9, UIKit, iOS 15.0+, ReplayKit, Vision, AVFoundation, Photos
