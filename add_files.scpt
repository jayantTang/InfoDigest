-- AppleScript to add files to Xcode project
-- 使用说明：在Xcode打开项目的情况下运行此脚本

tell application "Xcode"
    activate
end tell

tell application "System Events"
    tell process "Xcode"
        -- 等待Xcode完全加载
        delay 1

        -- 你需要在Xcode中手动操作：
        display dialog "请按照以下步骤操作：" & return & return & "1. 确保Xcode已打开项目" & return & "2. 在左侧项目导航器中，右键点击最上方的 'InfoDigest' 文件夹（蓝色图标）" & return & "3. 选择 'Add Files to InfoDigest...'" & return & "4. 选择以下路径下的所有文件：" & return & "   /Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest/" & return & return & "或者，我可以帮你打开这个文件夹，然后你直接拖拽到Xcode中。" buttons ["打开文件夹", "我知道了"] default button 1

        if result = "打开文件夹" then
            do shell script "open /Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest/"
        end if
    end tell
end tell
