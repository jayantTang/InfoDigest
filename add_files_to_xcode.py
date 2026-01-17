#!/usr/bin/env python3
"""
自动添加Swift文件到Xcode项目
"""

import os
import uuid
import re

def generate_uuid():
    """生成Xcode风格的UUID（24位十六进制）"""
    return uuid.uuid4().hex[:24].upper()

def main():
    project_path = "/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest.xcodeproj/project.pbxproj"

    print("🔧 开始配置Xcode项目...")

    # Swift文件列表
    swift_files = [
        ("Models/Message.swift", "Models", "Message.swift"),
        ("Views/MessageDetailView.swift", "Views", "MessageDetailView.swift"),
        ("Views/MessageListView.swift", "Views", "MessageListView.swift"),
        ("Views/SettingsView.swift", "Views", "SettingsView.swift"),
        ("ViewModels/MessageListViewModel.swift", "ViewModels", "MessageListViewModel.swift"),
        ("Services/APIService.swift", "Services", "APIService.swift"),
        ("Services/PushNotificationManager.swift", "Services", "PushNotificationManager.swift"),
        ("AppDelegate.swift", "", "AppDelegate.swift"),
        ("InfoDigestApp.swift", "", "InfoDigestApp.swift"),
        ("ContentView.swift", "", "ContentView.swift"),
    ]

    print(f"📝 需要添加 {len(swift_files)} 个Swift文件")

    # 读取项目文件
    print("📖 读取project.pbxproj...")
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 检查文件是否已经被添加
    existing_files = set()
    for line in content.split('\n'):
        if '.swift' in line and 'PBXFileReference' in line:
            match = re.search(r'(\w+\.swift)', line)
            if match:
                existing_files.add(match.group(1))

    print(f"✅ 已存在的文件: {len(existing_files)}")

    # 如果大部分文件都已添加，跳过
    if len(existing_files) >= len(swift_files) - 2:
        print("✅ 文件已添加到项目中")
        print("⏭️  跳过文件添加步骤")
        return

    print("\n⚠️  需要在Xcode中手动添加文件")
    print("\n📝 请按以下步骤操作：")
    print("=" * 50)
    print("1. 在Xcode中，右键点击项目导航器顶部的 'InfoDigest' 文件夹")
    print("2. 选择 'Add Files to InfoDigest...'")
    print("3. 导航到以下路径:")
    print("   /Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest/")
    print("4. 选择所有文件夹和.swift文件")
    print("5. 确保勾选:")
    print("   ✅ Copy items if needed")
    print("   ✅ Create groups")
    print("   ✅ InfoDigest target")
    print("6. 点击 Add")
    print("=" * 50)

if __name__ == "__main__":
    main()
