#!/bin/bash
set -e

echo "🚀 开始构建Android APK..."
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 步骤1: 检查并设置Java版本
echo -e "${YELLOW}📋 步骤1: 检查并设置Java版本...${NC}"
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")

if [ -z "$JAVA_HOME" ]; then
    echo -e "${RED}❌ 错误: 未找到Java 17，请先安装${NC}"
    exit 1
fi

export PATH="$JAVA_HOME/bin:$PATH"
JAVA_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | head -1 | cut -d'"' -f2)
echo "Java版本: $JAVA_VERSION"
echo "JAVA_HOME: $JAVA_HOME"

if [[ ! $JAVA_VERSION == 17.* ]]; then
    echo -e "${RED}❌ 错误: 需要Java 17，当前版本: $JAVA_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Java 17 配置成功${NC}"
echo ""

# 步骤2: 清理旧构建
echo -e "${YELLOW}📋 步骤2: 清理旧构建产物...${NC}"
rm -rf dist/
echo -e "${GREEN}✅ 清理完成${NC}"
echo ""

# 步骤3: 构建Vue项目
echo -e "${YELLOW}📋 步骤3: 构建Vue项目...${NC}"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Vue构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Vue构建成功${NC}"
echo ""

# 步骤4: 同步到Android
echo -e "${YELLOW}📋 步骤4: 同步到Android项目...${NC}"
npx cap sync android
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 同步失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 同步成功${NC}"
echo ""

# 步骤5: 修复Java版本配置
echo -e "${YELLOW}📋 步骤5: 修复Java版本配置...${NC}"
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle 2>/dev/null || true
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle 2>/dev/null || true
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle 2>/dev/null || true
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle 2>/dev/null || true

# 修复 filesystem 插件
if [ -f "node_modules/@capacitor/filesystem/android/build.gradle" ]; then
  sed -i '' 's/sourceCompatibility JavaVersion.VERSION_21/sourceCompatibility JavaVersion.VERSION_17/' node_modules/@capacitor/filesystem/android/build.gradle
  sed -i '' 's/targetCompatibility JavaVersion.VERSION_21/targetCompatibility JavaVersion.VERSION_17/' node_modules/@capacitor/filesystem/android/build.gradle
  sed -i '' 's/jvmToolchain(21)/jvmToolchain(17)/' node_modules/@capacitor/filesystem/android/build.gradle
fi

# 应用自定义图标
if [ -f "icon-cropped.png" ]; then
  echo "应用自定义图标..."
  sips -z 48 48 icon-cropped.png --out android/app/src/main/res/mipmap-mdpi/ic_launcher.png > /dev/null 2>&1
  sips -z 72 72 icon-cropped.png --out android/app/src/main/res/mipmap-hdpi/ic_launcher.png > /dev/null 2>&1
  sips -z 96 96 icon-cropped.png --out android/app/src/main/res/mipmap-xhdpi/ic_launcher.png > /dev/null 2>&1
  sips -z 144 144 icon-cropped.png --out android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png > /dev/null 2>&1
  sips -z 192 192 icon-cropped.png --out android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png > /dev/null 2>&1
  sips -z 48 48 icon-cropped.png --out android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png > /dev/null 2>&1
  sips -z 72 72 icon-cropped.png --out android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png > /dev/null 2>&1
  sips -z 96 96 icon-cropped.png --out android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png > /dev/null 2>&1
  sips -z 144 144 icon-cropped.png --out android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png > /dev/null 2>&1
  sips -z 192 192 icon-cropped.png --out android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png > /dev/null 2>&1
fi

echo -e "${GREEN}✅ 配置修复完成${NC}"
echo ""

# 步骤6: 构建APK
echo -e "${YELLOW}📋 步骤6: 构建Android APK...${NC}"
cd android
./gradlew clean assembleDebug
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ APK构建失败${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ APK构建成功${NC}"
echo ""

# 步骤7: 复制APK
echo -e "${YELLOW}📋 步骤7: 复制APK到项目根目录...${NC}"
cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk
APK_SIZE=$(ls -lh TODO-App.apk | awk '{print $5}')
echo -e "${GREEN}✅ APK已生成: TODO-App.apk (${APK_SIZE})${NC}"
echo ""

# 完成
echo "================================"
echo -e "${GREEN}🎉 构建完成！${NC}"
echo ""
echo "📱 APK位置: $(pwd)/TODO-App.apk"
echo "📦 APK大小: $APK_SIZE"
echo ""
echo "安装方法:"
echo "1. 将APK传输到Android设备"
echo "2. 开启'允许安装未知来源应用'"
echo "3. 点击APK文件安装"
