# v1.5.9 快速启动指南

## 🚀 立即测试修改

### 方式1：Web开发模式（推荐快速测试）

```bash
npm run dev
```

在浏览器中打开 `http://localhost:5173` 即可测试所有修改。

### 方式2：构建Android APK

```bash
# 1. 构建Web资源
npm run build

# 2. 同步到Android
npx cap sync android

# 3. 在Android Studio中打开并运行
# 或使用命令行构建APK
cd android
./gradlew assembleDebug
```

APK位置：`android/app/build/outputs/apk/debug/app-debug.apk`

---

## ✅ 验证修改

### 1. Bug修复验证（30秒）

1. 创建任务：
   - 1个待办任务（今天）
   - 1个已完成任务
   - 1个已逾期任务（修改系统时间到昨天创建，再改回来）

2. 点击"待办"筛选
3. 确认：只显示1个待办任务

### 2. UI优化验证（2分钟）

打开以下弹窗，观察空间利用率：
- 个人主页（右上角头像）
- 番茄钟统计（个人主页内）
- 回收站（右上角图标）
- 联系与支持（个人主页内）
- 修改密码（个人主页内）
- 绑定手机号（个人主页内）
- 星期选择（新建任务→每周重复）
- 任务编辑（点击任务标题）
- 隐私政策（页脚链接）

### 3. UX优化验证（10秒）

1. 查看搜索框：`🔍 搜索任务名称或描述...`
2. 点击添加按钮
3. 查看新建框：`➕ 新建任务：输入任务名称...`

---

## 📱 移动端测试

### Android真机测试

```bash
# 安装APK到设备
adb install android/app/build/outputs/apk/debug/app-debug.apk

# 或直接运行
cd android
./gradlew installDebug
```

### Chrome DevTools模拟

1. 打开 `http://localhost:5173`
2. F12 → 切换设备工具栏
3. 选择移动设备（如 iPhone 12 Pro）
4. 测试所有弹窗

---

## 🔍 关键测试点

| 测试项 | 预期结果 | 优先级 |
|--------|----------|--------|
| 待办筛选 | 统计=列表数量 | 🔴 高 |
| 弹窗宽度 | 更宽，更充分 | 🟡 中 |
| 输入框区分 | 一眼识别功能 | 🟢 低 |

---

## 🐛 如果遇到问题

### 问题1：修改未生效
```bash
# 清除缓存重新构建
rm -rf node_modules/.vite
npm run dev
```

### 问题2：Android构建失败
```bash
# 清理Android缓存
cd android
./gradlew clean
cd ..
npx cap sync android
```

### 问题3：样式显示异常
- 检查浏览器缓存（Ctrl+Shift+R 强制刷新）
- 检查是否有CSS语法错误

---

## 📝 版本信息

- **当前版本**: v1.5.9
- **上一版本**: v1.5.7
- **修改文件**: 3个
- **代码行数**: 约31行
- **测试时间**: 约5分钟

---

## 🎯 下一步

1. ✅ 完成本地测试
2. ✅ 构建生产APK
3. ✅ 更新CHANGELOG.md
4. ✅ 提交Git
5. ✅ 打标签 v1.5.9
6. ✅ 推送到远程仓库
