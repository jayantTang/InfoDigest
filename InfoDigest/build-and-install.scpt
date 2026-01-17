tell application "Xcode"
	activate
	delay 5

	-- 查找并打开项目
	set projectPath to "/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest.xcodeproj"
	open projectPath as alias
	delay 10

	-- 构建并运行到设备
	try
		build project "InfoDigest" scheme "InfoDigest" build configuration "Debug" destination "id=00008120-00012D1A3C80201E"
	on error errMsg
		display dialog "构建失败: " & errMsg
	end try
end tell
