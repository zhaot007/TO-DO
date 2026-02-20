#!/bin/bash

# Windows Electron 打包脚本
# 用途：构建 Windows 平台的 Electron 安装包

echo "========================================="
echo "开始构建 Windows Electron 安装包"
echo "========================================="

# 1. 清理旧的构建文件
echo "步骤 1/3: 清理旧的构建文件..."
rm -rf release dist

# 2. 构建前端资源
echo "步骤 2/3: 构建前端资源..."
npm run build

# 3. 打包 Electron 应用
echo "步骤 3/3: 打包 Electron 应用..."
npx electron-builder --win

echo "========================================="
echo "构建完成！"
echo "安装包位置: release/TODO App Setup 1.5.7.exe"
echo "========================================="
