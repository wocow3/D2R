#IfWinActive 

CoordMode, ToolTip, Window

ToolTip(text="")
{
	ToolTip, %text%, 554, 624 
}
;==============================================================
;注意:本脚本包含大量的屏幕颜色判定,不要随意调整游戏亮度
;大部分颜色参数是基于默认亮度来设定的
;调整后一般需要重新修改用于判定的颜色参数
;影响 PixelGetColor, PixelSearch
;==============================================================
CloseD2REventHandle() {
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /C " "d:\Kit\Handle\handle64.exe -a -p D2R.exe Instances" )
	handleListString := exec.StdOut.ReadAll()
	;OutputDebug, %handleListString%
	for i,handleString in StrSplit(handleListString, "`n", "`r")
	{
		if InStr(handleString, "Instances") 
		{
			; every event
			;OutputDebug, %handleString%
			newList := []
			for j,tokenString in StrSplit(handleString, [A_Space, ":"], " `t")
			{
				if (tokenString != "")
					newList.Push(tokenString)
			}
			pid := newList[3]  
			handle := newList[6]
			;OutputDebug, %pid%, %handle%
			closeHandleString := "d:\Kit\Handle\handle64.exe -c " handle " -p " pid " -y"
			;OutputDebug, %closeHandleString%
			shell.Exec(ComSpec " /C " closeHandleString)
		}
	}
}

#K::
	CloseD2REventHandle() ;关闭多开禁止
return


#IfWinActive ahk_exe D2R.exe

~`::
	;地图拾取同步开启
	;Send {Alt}
	Sleep 500
	Send t			;~一般为保护甲,多释放一个技能T,SOR设置为顶球
return

QueryCtaTime(player = "")
{
	if (player = "bar")
		return 260
	Else
		return 160
}

CTA() {
	;双技能
	Send {WheelUp}	;一些奇怪的游戏机制: 可以先切换武器再施放技能,但不能在施放技能中切换武器
	Sleep 200		;依赖CTA的职业需要延迟加载CTA技能,蛮子则不需要
	Send [
	Sleep 200		;相邻战吼类技能必须间隔200ms以上
	Send {WheelDown}
	;Sleep 800		;一个战吼需要500ms平静时间,两个700ms
	Sleep 1500		
	Send {WheelUp}
	Sleep 200

	global g_Player
	global startTime
	global toolTipControl
	global tooltipCTA
	global timeoutAlarm
	startTime := A_TickCount
	timeoutAlarm := True

	if (!tooltipCTA) {
		tooltipCTA := True
		Gui, ToolTip:Color, EEAA99
		Gui, ToolTip:Font, S30, Tahoma
		Gui, ToolTip:Add, Text, cFFB10F BackgroundTrans vtoolTipControl, % QueryCtaTime(g_Player)
		Gui, ToolTip:+LastFound +AlwaysOnTop +ToolWindow
		WinSet, TransColor, EEAA99
		Gui, ToolTip:-Caption
	}
	Gui, ToolTip:Show, X421 Y932 NoActivate AutoSize	;469 972
	SetTimer, UpdateCTA, 500
UpdateCTA:
	leftTime := QueryCtaTime(g_Player) - (A_TickCount - startTime)// 1000
	if (leftTime > 0) {
		GuiControl, ToolTip:, toolTipControl, % leftTime
		if (timeoutAlarm) {
			if (leftTime < 10) {
				Gui, ToolTip:Show, X1111 Y532 NoActivate	;1151 572
				timeoutAlarm := False
				SoundPlay, 1.wav
			}
		}
	}
	else {
		Gui, ToolTip:Hide
		SetTimer, UpdateCTA, Off
	}
	return
}

WheelDown::
	CTA()
return

InLoading()
{	
	;典型的,人物界面是0x454542
	;加载画面周围大部分显示黑色,是0x000000
	PixelGetColor, color, 1973, 1283
	return color < 0x010101
}

InGameRoom()
{
	;刚好是魔法球的光照白点
	PixelGetColor, color, 1973, 1283
	return color > 0xEEEEEE
}

IsBagOpend()
{
	;涉及仓库/方块/传送点
	;注意这是非焦点时的颜色,移动光标使按钮获得焦点颜色会变化
	;颜色格式0xBBGGRR
	PixelGetColor, color, 901, 164
	;ToolTip(color)
	return color = 0x2A57F8
}

ThrowWhenStopNextActions()
{
	global StopNextActions

	if (StopNextActions) 
		throw "StopNextActions"
}

CreateGame() {
	global RunsCounts
	global IsPublicGameControl

	GuiControlGet, IsPublicGameControl

	if (IsPublicGameControl) {
		;公开游戏
		Click, 1700 100
		Sleep 100
		Click, 1728 230 2	;双击游戏名称
		Sleep 100

		Clipboard := ""
		Send ^a
		Send ^c
		ClipWait, 0.2
		str := Clipboard
		Clipboard := ""
		;输入纯数字视为重置计数
		if str is integer
			RunsCounts["PublicGameCount"] := str - 0
		Send {BackSpace}
		Sleep 100
		Send % "yytyyre"RunsCounts["PublicGameCount"]
		Sleep 200
		Click, 2124 500	;地狱游戏
		Sleep 100
		Click, 1950 870

		RunsCounts["PublicGameCount"]++
	}
	else {
		;个人游戏
		Click, 1054 1282
		Sleep 100
		Click, 1288 775
	}
}

FollowFriend()
{
	Click, 241 1022
	Sleep 100
	Click, 476 202
	Sleep 100
	Click, 236 256 Right
	Sleep 200
	Click, 350 413
}

VerifyAccount(account)
{
	global PIDs

	if (PIDs.Length() != 2)
        return

	WinGet, currentPID, PID, A
	if (account = "A") {
		if (currentPID != PIDs[1])
			SwitchGame()		
	}
	else {
		if (currentPID != PIDs[2])
			SwitchGame()	
	}
}

VerifyCloseBag()
{
	if (IsBagOpend())
		Click, 901 164 	
}

CheckQuitGame()
{
	if (InGameRoom()) {
		VerifyCloseBag()

		Send {Escape}
		Sleep 300

		Click, 1270 630 ;储存并离开
		Sleep 300	

		WaitLoading()
	}

	global g_WeaponState
	g_WeaponState := ""
	SetTimer, UpdateCTA, Off
	SetTimer, SwapWeapon, Off
	Gui, ToolTip:Hide
}

;等待加载画面,判断非黑色底色
WaitLoading()
{
	Sleep 300 ;必要的延时以保证进入加载画面

	try {
		ToolTip("等待过场画面") 
		While (InLoading())
		{
			ThrowWhenStopNextActions()
			Sleep 100	
		}
	}
	finally {
		ToolTip()
	}
}

;等待游戏画面,判断出现魔法球白点
WaitInGame()
{
	try {
		ToolTip("等待进入游戏")
		While (!InGameRoom())
		{
			ThrowWhenStopNextActions()
			Sleep 100	
		}
	}
	finally {
		ToolTip()
	}
}

QueryHand(player = 0)
{
	if (player = "bar") {
		PixelGetColor, color, 1174, 1376
		if (color = 0xA5A7A2 || color = 0x2E2EA2)
			return "主手"
		else if (color = 0x040744)
			return "副手"
	}
	return ""
}

AssistSwapWeapon(weapon)
{
	global g_WeaponState
	global g_CheckCount
	global g_Player

	if (g_WeaponState != weapon) {
		g_WeaponState := weapon
		g_CheckCount := 0
		SetTimer, SwapWeapon, 400
		goto SwapWeapon
	}
	return
SwapWeapon:
	hand := QueryHand(g_Player)
	if (hand) {
		if (hand != g_WeaponState)
			Send {WheelUp}
		else {
			g_CheckCount++
			ToolTip("确认" g_WeaponState " " g_CheckCount)
			if (g_CheckCount > 5) {
				SetTimer, SwapWeapon, Off
				ToolTip("")
			}
		}
	}
	return
}

Q::
	global StopConflictHotKey
	global g_Player
	if (!StopConflictHotKey && g_Player) {
		AssistSwapWeapon("主手")
	}
	Send %A_ThisHotkey%
return

E::
	global StopConflictHotKey
	global g_Player
	if (!StopConflictHotKey && g_Player) {
		AssistSwapWeapon("副手")
	}
	Send %A_ThisHotkey%
return

F::
	global StopConflictHotKey
	global g_Player
	if (!StopConflictHotKey && g_Player) {
		AssistSwapWeapon("主手")
	}
	Send %A_ThisHotkey%
return

Z::
	;存钱
	global StopConflictHotKey
	if (!StopConflictHotKey) {
		if (IsBagOpend()) {
			Click, 1937 1057
			Sleep 100
			Click, 1088 774
		}
	}
	else
		Send z
return

/*
C::
V::
	;辨识
	global StopConflictHotKey
	if (!StopConflictHotKey) {
		if (IsBagOpend()) {
			MouseGetPos, X, Y
			MouseClick, Right, 1790, 936
			MouseMove, X+5, Y
		}
	}
	else
		Send %A_ThisHotkey%
return
*/

Space::
	;Space对应方块, i对应背包
	;但方块有个问题是持有物品时方块快捷键不起作用
	;i却是起作用的
	;为了防止持有物品时方块快捷键不起作用;
	;关闭方块统一使用i, 持有还是不持有物品时都有效
	;持有物品时没有办法打开方块,
	;但可以通过把鼠标移动到右上打开背包
	;在方块中再次触发热键时是辨识
	global StopConflictHotKey
	if (!StopConflictHotKey) {
		if (IsBagOpend()) {
			MouseGetPos, X, Y
			if (x > 440 && x < 648 && y > 493 && y < 761) {
				MouseClick, Right, 1790, 936
				MouseMove, X, Y
			}
			else
				send i
		}
		else {
			MouseGetPos, X, Y
			if (x > 1636) {
				send i
				MouseMove, X, Y
			}
			else
				Send {Space}
		}
	}
	else
		Send {Space}
return

;PAL自动切换光环
;(天堂)切换(净化)
;(锤子)切换(专注)
/*
E::
	global StopConflictHotKey
	global AutoAura
	global IsAuraWithButtonE
	if (!StopConflictHotKey && AutoAura) {
		if (!IsAuraWithButtonE) {
			Send d
			IsAuraWithButtonE := True
		}
	}
	Send e
return

W::
	global StopConflictHotKey
	global AutoAura
	global IsAuraWithButtonE
	if (!StopConflictHotKey && AutoAura) {
		;if (IsAuraWithButtonE) {
			Send k
			IsAuraWithButtonE := False
		;}
	}
	Send w
return
*/

/*
A::
	if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 300) {
		;DoubleA: 恢复传送
		MouseGetPos, X, Y
		Click, 1382 1392
		;Sleep, 100
		Click, 1461 822
		MouseMove, X, Y
	}
	else
		Send a
return
*/

F8::
	;重置双号切换器
	ResetPIDs()
	CloseD2REventHandle()
return

XButton1::
	SwitchGame(0)
return

Esc::
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 300) {
        Click, 1270 630 ;储存并离开

		SetTimer, UpdateCTA, Off
		SetTimer, SwapWeapon, Off
		Gui, ToolTip:Hide
	}
	else
		Send {Escape}
return

F4::
	;停止当前动作
	global StopNextActions
	StopNextActions := True
return

F7::
	;打开控制器
	ShowController()
return

F9::
	;升级背包宝石
	global StopNextActions
	StopNextActions := False
	try {
		CombineJewelInBagage()
	}
	catch{
	}
return

GambleHaveCirclets(ByRef OutputX, ByRef OutputY)
{
	;IsFound := 0
	Loop, % 9*7
	{
		;OutputDebug, loop %A_Index%
		x := 233 + Floor((A_Index - 1) / 9) * 65
		y := 368 + Mod((A_Index - 1), 9) * 65

		PixelSearch, OutputX, OutputY, x, y, x+3, y+3, 0x7A55DA, 0, Fast
		if (ErrorLevel = 0) {
			;IsFound := 1
			;break
			;OutputDebug, return True
			return True
		}	
	}
	;MsgBox, % IsFound
	;OutputDebug, return False
	return False
}

LWin::
return
/*
RWin::
	global StopNextActions
	StopNextActions := False

	while (!GambleHaveCirclets(OutputX, OutputY)) {
		if (StopNextActions)
			return
		Click, 780 1024 ;刷新
		Sleep 200
	}

	SoundPlay, Clarinet.wav
	MouseMove, OutputX+40, OutputY
return
*/

DropGolds()
{
	if (!IsBagOpend())
		return

	X := [458,625,780] ; 公共背包的X坐标

	Loop, % X.Length()
	{
		Click, % X[A_Index] " 272" ; 选择背包
		Sleep 100

		Loop, 5
		{
			ThrowWhenStopNextActions()

			Click, 458 1024 ;箱子取金币
			Sleep 100

			Click, 1293 669 ;金币数量输入框 
			Sleep 100
			Send 1111111	;保证最大金币数量
			Sleep 100
			Click, 1094 775 ;确定
			Sleep 100

			Send {Space}			;打开背包
			Sleep 200

			Click, 1936 1056 ;背包取金币
			Sleep 100
			
			Click, 1293 669 ;金币数量输入框
			Sleep 100
			Send 1111111	;保证最大金币数量
			Sleep 100
			Click, 1094 775 ;确定
			Sleep 100

			VerifyCloseBag()
			Sleep 100
		}
	}
	Click, 295 272 ;切换第一页
	Sleep 100
	VerifyCloseBag()
	Send {Alt}	
}

F10::
	;扔金币
	global StopNextActions
	StopNextActions := False
	try {
		DropGolds()
	}
	catch{
	}
return

Foo1()
{
	Click, 780 272 ; 选择其他
	Sleep 100
	;while True
	Loop, 193
	{
		ThrowWhenStopNextActions()
		Send ^{Click 2247 964}
		Sleep 100
		Click, 848 335 Right
		Sleep 100
	}
}

Home::
	global StopNextActions
	StopNextActions := False
	try {
		Foo1()
		SoundPlay, 1.wav
	}
	catch{
	}
return

Foo2(x, y, cnt)
{
	Loop, %cnt%
	{
		ThrowWhenStopNextActions()
		Click, %x% %y% Right
		Sleep 500
	}
}

Delete::
	global g_GoodsX
	global g_GoodsY
	MouseGetPos, g_GoodsX, g_GoodsY
	line := "get coords " g_GoodsX " " g_GoodsY
	ToolTip(line) 
return

End::
	global g_GoodsX
	global g_GoodsY
	global StopNextActions
	StopNextActions := False
	try {
		Foo3(10, 2, 9)
		Foo2(g_GoodsX, g_GoodsY, 5)
		index := 25
		x := 1716 + Floor((index - 1) / 4) * 65
		y := 762 + Mod((index - 1), 4) * 65
		MouseMove, x, y
		SoundPlay, 1.wav
	}
	catch{
	}
return

Foo3(start, step, cnt)
{
	Loop, %cnt%
	{
		ThrowWhenStopNextActions()
		index := A_Index * step + start
		x := 1716 + Floor((index - 1) / 4) * 65
		y := 762 + Mod((index - 1), 4) * 65
		Send ^{Click %x% %y%}
		Sleep 100
	}
}

PgDn::
	;赌戒指
	global StopNextActions
	StopNextActions := False
	try {
		Foo3(10, 1, 22)
		Foo2(835, 325, 22)
		index := 29
		x := 1716 + Floor((index - 1) / 4) * 65
		y := 762 + Mod((index - 1), 4) * 65
		MouseMove, x, y
		SoundPlay, 1.wav
	}
	catch{
	}
return

F12::
	;通过队伍界面OCR识别房间名
	Send a
	Sleep 100
	Clipboard := PaddleOCR([336, 276, 190, 30])
	Sleep 100
	Send a
return

ResetPIDs()
{
    global PIDs := []
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /C " "TaskList /FI ""ImageName eq D2R.exe""" )
	handleListString := exec.StdOut.ReadAll()
    ;OutputDebug, %handleListString%

	for i,handleString in StrSplit(handleListString, "`n", "`r")
	{
		if InStr(handleString, "D2R.exe") 
		{
			;OutputDebug, %handleString%
			newList := []
			for j,tokenString in StrSplit(handleString, [A_Space,A_Tab], " `t")
			{
				if (tokenString != "")
					newList.Push(tokenString)
			}
			;pid1 := newList[1]
			;pid2 := newList[2]
			;pid3 := newList[3]
			;pid4 := newList[4]
			;OutputDebug, %pid1%,%pid2%,%pid3%,%pid4%
			PIDs.Push(newList[2])
		}
	}
    ;OutputDebug, % PIDs.Length()

	;调整PIDs[1]总是账号A
	if (PIDs.Length() = 2) {
		filter := "ProcessID=" + PIDs[1]
		;OutputDebug, %filter%
		exec := shell.Exec(ComSpec " /C " "wmic process where " "" filter "" " get commandline" )
		exepath := exec.StdOut.ReadAll()
		;OutputDebug, %exepath%
		;OutputDebug, % PIDs[1]
		;OutputDebug, % PIDs[2]
		if InStr(exepath, "多开") 
		{
			tmp := PIDs[1]
			PIDs[1] := PIDs[2]
			PIDs[2] := tmp
		}
		;OutputDebug, % PIDs[1]
		;OutputDebug, % PIDs[2]
	}
}

SwitchGame(waitDelay = 300)
{
    global PIDs

    if (PIDs.Length() != 2)
        return
    
    WinGet, currentPID, PID, A
    ;OutputDebug, %currentPID%
    ;OutputDebug, % PIDs[1]
    ;OutputDebug, % PIDs[2]
    if (currentPID = PIDs[1])
        WinActivate, % "ahk_pid" . PIDs[2]
    Else
        WinActivate, % "ahk_pid" . PIDs[1]

	if (waitDelay)
		Sleep, waitDelay
}

GuiClose:
	global IsRunning

	Gui, Destroy
	IsRunning := False
return

StopConflictHotKey:
	global StopConflictHotKey
	GuiControlGet, StopConflictHotKey
	;MsgBox, %AutoAura%
return

AutoAura:
	global AutoAura
	GuiControlGet, AutoAura
	;MsgBox, %AutoAura%
return

AddRecorder(place)
{
	global IsRunning
	global RunsCounts
	global EditControl

	if (!IsRunning)
		return

	RunsCounts[place]++
	GuiControlGet, EditControl
	EditControl := place . RunsCounts[place] "`t" A_Hour ":" A_Min ":" A_Sec "`t`n" EditControl
	GuiControl, ,EditControl, %EditControl%
	;ControlGet, handle, Hwnd , , EditControl
	;PostMessage, 0x115, 7, , Edit1
	Gui, Show, Restore NoActivate

	Sleep, 4000

	if (IsRunning)
		Gui, Show, Minimize
}

HslFromRgb(rgb, BYREF hue, BYREF lum, BYREF sat) {
	DllCall("Shlwapi\ColorRGBToHLS", "UInt", rgb, "UShort*", hue, "UShort*", lum, "UShort*", sat)
	hue := Round(hue * 255 / 239)
	lum := Round(lum * 255 / 240)
	sat := Round(sat * 255 / 240)
}

CombineJewelInBagage()
{
	if (!IsBagOpend())
		return

	MouseMove 1575, 762	;防止光标影响识别
	Sleep 100

	Slots := []
	
	Loop, 40
	{
		item := {}
		item.x := 1716 + Floor((A_Index - 1) / 4) * 65
		item.y := 762 + Mod((A_Index - 1), 4) * 65
		PixelGetColor, color, item.x, item.y
		item.color := color
		Slots.Push(item)
	}

	for index in Slots
	{
		;分析类别
		HslFromRgb(Slots[index].color, hue, lum, sat)
		Slots[index].hue := hue
		Slots[index].lum := lum
		Slots[index].sat := sat
		
		/*
		hue=34, lum=238, sat=211
		hue=171, lum=3, sat=0
		hue=213, lum=31, sat=4
		hue=0, lum=26, sat=245
		hue=37, lum=171, sat=234
		hue=89, lum=23, sat=255
		hue=159, lum=150, sat=204
		hue=200, lum=136, sat=200
		*/
		if (lum > 200) {
			; 白
			Slots[index].token := "骨"
		}
		else if (lum < 7) {
			; 黑
			Slots[index].token := "空白"
		}
		else if (sat < 40) {
			; 灰
			Slots[index].token := "钻"
		}
		else if (hue < 19 || hue >  239) {
			; 红
			Slots[index].token := "红"
		}
		else if (hue > 21 && hue < 50) {
			; 黄
			Slots[index].token := "黄"
		}
		else if (hue > 59 && hue < 116) {
			; 绿
			Slots[index].token := "绿"
		}
		else if (hue > 129 && hue < 169) {
			; 蓝
			Slots[index].token := "蓝"
		}
		else if (hue > 179 && hue < 237 ) {
			; 紫
			Slots[index].token := "紫"
		}
		else {
			Slots[index].token := "unknown"
		}
	}

	;dump
	;for index in Slots
	;	OutputDebug % "(" index ")" Slots[index].token " color:" Slots[index].color " hue:" Slots[index].hue " lum:" Slots[index].lum " sat:" Slots[index].sat " x:" Slots[index].x " y:" Slots[index].y

	;合成
	jewelTokens := ["骨", "钻", "红", "黄", "绿", "蓝", "紫"]
	for token in jewelTokens
	{
		jewelIndexList := []
		for index in Slots
		{
			if (Slots[index].token == jewelTokens[token])
				jewelIndexList.Push(index)
		}	

		walker := 3
		;OutputDebug % "count: " jewelIndexList.Count()
		while (walker <= jewelIndexList.Count())
		{
			item1 := Slots[jewelIndexList[walker-2]]
			item2 := Slots[jewelIndexList[walker-1]]
			item3 := Slots[jewelIndexList[walker]]
			;OutputDebug % item1.token " " item1.x " " item1.y "," item2.token " " item2.x " " item2.y "," item3.token " " item3.x " " item3.y  
			walker += 3

			ThrowWhenStopNextActions()

			MouseMove, item1.x, item1.y
			Sleep 50
			Send ^{Click}
			Sleep 200
			MouseMove, item2.x, item2.y
			Sleep 50
			Send ^{Click}
			Sleep 200
			MouseMove, item3.x, item3.y
			Sleep 50
			Send ^{Click}
			Sleep 200

			Click 543 825	;合成
			Sleep 200

			Send ^{Click 604 600}
			Sleep 200
			Send ^{Click 604 660}
			Sleep 200
			Send ^{Click 604 720}
			Sleep 200	
		}
	}
}

DoActions(actions, option = 0)
{
	if (actions = "ACT1出生到传送点") {
		;寻找传送点
		;选择的像素点为小地图传送点的右边火苗标志
		result := 0
		try {
			PixelSearch, OutputVarX, OutputVarY, 1482, 704, 1482+12, 704+12, 0xAF9A7F , 5, Fast
			if (ErrorLevel = 0)
				throw 1 ;下开口
			PixelSearch, OutputVarX, OutputVarY, 1482, 680, 1482+12, 680+12, 0xAF9A7F , 5, Fast
			if (ErrorLevel = 0)
				throw 2 ;上开口
			PixelSearch, OutputVarX, OutputVarY, 1340, 584, 1340+12, 584+12, 0xAF9A7F , 5, Fast
			if (ErrorLevel = 0)
				throw 3 ;左开口
			PixelSearch, OutputVarX, OutputVarY, 1315, 572, 1315+12, 572+12, 0xAF9A7F , 5, Fast
			if (ErrorLevel = 0)
				throw 4 ;右开口
		}
		catch e {
			result := e
		}
		finally{
			Switch result
			{
				case 1:
					;OutputDebug % "下开口 " OutputVarX "," OutputVarY
					ToolTip("下开口")
					if (option = "sor") {
						ThrowWhenStopNextActions()
						Click, 2421 928
						Sleep 1500
						MouseMove 1899, 592
						Send F
					}
				case 2:
					;OutputDebug % "上开口 " OutputVarX "," OutputVarY
					ToolTip("上开口") 
					if (option = "sor") {
						ThrowWhenStopNextActions()
						Click, 2163 368
						Sleep 1500
						MouseMove 2084, 990
						Send F	
					}
				case 3:
					;OutputDebug % "左开口 " OutputVarX "," OutputVarY
					ToolTip("左开口") 
					if (option = "sor") {
						ThrowWhenStopNextActions()
						Click, 1650 173
						Sleep 1500
						MouseMove 1444, 437
						Send F
					}
				case 4:
					;OutputDebug % "右开口 " OutputVarX "," OutputVarY
					ToolTip("右开口") 
					if (option = "sor") {
						ThrowWhenStopNextActions()
						Click, 1647 255
						Sleep 1500
						MouseMove 1250, 240
						Send F
					}
				default:
					ToolTip("未识别开口") 
			}	
		}
		return result
	}
	else if (actions = "ACT3出生到传送点") {
		ThrowWhenStopNextActions()
		Click 2540 644
		Sleep 1300
		ThrowWhenStopNextActions()
		Click 2241 222
		Sleep 1300
		ThrowWhenStopNextActions()
		Click 2241 222
		Sleep 1300
		ThrowWhenStopNextActions()
		Click 2458 720
		Sleep 1000
		ThrowWhenStopNextActions()
		Click 2226 504
		Sleep 1000

		if (option = "bar") {
			;蛮子在箱子前停止并不到传送点
		}
		else {
			;default
			ThrowWhenStopNextActions()
			Click 2177 424
			Sleep 1200
		}
	}
	else if (actions = "ACT4出生到传送点") {
		if (option = "sor") {
			ThrowWhenStopNextActions()
			MouseMove 2026, 183
			Sleep 200
			Send F
		}
		else {
			;default
			ThrowWhenStopNextActions()
			Click, 2031 169
			Sleep 1600
		}
	}
	else if (actions = "ACT4传送门") {
		if (option = "sor") {
			ThrowWhenStopNextActions()
			MouseMove, 1171, 585
			Sleep 200
			Send f
		}
	}
	else if (actions = "ACT5出生到传送点") {
		ThrowWhenStopNextActions()
		Click, 731 1199
		Sleep 1300

		ThrowWhenStopNextActions()
		Click, 738 1260
		Sleep 1300
	}
	else if (actions = "ACT5出生到安雅") {
		ThrowWhenStopNextActions()
		Click 838 1170
		Sleep 1000

		ThrowWhenStopNextActions()
		Click 2388 1344
		Sleep 1400

		ThrowWhenStopNextActions()
		Click 408 1127
		Sleep 1000

		ThrowWhenStopNextActions()
		Click 60 1299
		Sleep 1500

		ThrowWhenStopNextActions()
		Click 213 1209
		Sleep 1300

		ThrowWhenStopNextActions()
		Click 646 247
		Sleep 1000
	}
	else if (actions = "ACT5传送门") {
		if (option = "sor") {
			ThrowWhenStopNextActions()
			MouseMove, 1293, 585
			Sleep 200
			Send f
		}
		else if (option = "ama") {
			ThrowWhenStopNextActions()
			Click, 1208 546
			Sleep, 200
		}
	}

	return 1
}

F1Actions()
{
	global PIDs
	global IsRunning
	global RunsCounts
	global StopNextActions
	global F1DropDownListControl
	StopNextActions := False

	GuiControlGet, F1DropDownListControl

	try {

		if (F1DropDownListControl = "新建单人游戏")
		{
			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt} ;开图拾取, 没有游戏动作不需要额外的延时
			Send ~
			Sleep 500 ;一般来说,如果对应技能有动作需要时间,则增加必要的延时,否则会影响后序指令的时序
			Send t	;~一般为保护甲,多释放一个技能T,SOR设置为顶球
		}

		else if (F1DropDownListControl = "新建双人游戏")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t			
			;Sleep 500 ;由于下面做游戏切换,所以这里不需要额外的延时

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t	
		}

		else if (F1DropDownListControl = "新建双人游戏ACT3")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t			

			SwitchGame()

			CheckQuitGame()
			FollowFriend()

			SwitchGame()

			DoActions("ACT3出生到传送点")

			MouseMActions()

			SwitchGame()

			Send {Alt}
			;Send ~
			;Sleep 500
			;Send t	
			;Sleep 500	

			DoActions("ACT3出生到传送点")

			MouseMActions()

			WaitLoading()

			CTA()

			MouseMove 1180, 742
			Send ~
			;Sleep 700
		}

		else if (F1DropDownListControl = "新建双人游戏ACT4")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t
			Sleep 500			

			DoActions("ACT4出生到传送点")

			MouseMActions()

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t	
			Sleep 500	

			DoActions("ACT4出生到传送点", "sor")

			MouseMActions()

			WaitLoading()

			CTA()
		}

		else if (F1DropDownListControl = "SOR双人地穴")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~		
			Sleep 500
			;Send t	
			;Sleep 500

			;移动至传送门处
			Click, 1278 1203
			Sleep 1600
			Click, 678 1090
			Sleep 1200

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~		
			Sleep 500
			Send t			
			Sleep 500	

			if (DoActions("ACT1出生到传送点", "sor")) {

				GotoActZone(1, 6)

				WaitLoading()

				CTA()

				;一直传送
				Click, 20 1273 Right Down
				Sleep 2000
				Click, Right Up
			}

			AddRecorder("地穴")
		}

		else if (F1DropDownListControl = "SOR双人超市")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			;移动至传送门处
			;Click, 1278 1203
			;Sleep 1600
			;Click, 678 1090
			;Sleep 1200

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t		
			Sleep 500

			DoActions("ACT4出生到传送点", "sor")

			GotoActZone(4, 3)

			WaitLoading()

			CTA()

			;一直传送
			Click, 2186 95 Right Down
			Sleep 3900
			Click, Right Up

			AddRecorder("超市")
		}

		else if (F1DropDownListControl = "SOR双人牛场")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			;移动至传送门处
			Click, 1278 1203
			Sleep 1600
			Click, 678 1090
			Sleep 1200

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t	
			Sleep 500

			if (DoActions("ACT1出生到传送点", "sor")) {	
			
				GotoActZone(1, 3)

				WaitLoading()

				CTA()
			}

			AddRecorder("牛场")
		}

		else if (F1DropDownListControl = "SOR双人K3C")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}

			SwitchGame()

			CheckQuitGame()
			FollowFriend()

			SwitchGame()

			DoActions("ACT3出生到传送点")

			GotoActZone(3, 8)

			;WaitLoading()

			SwitchGame()

			Send {Alt}	
			Send ~
			Sleep 500
			Send t	
			Sleep 500

			DoActions("ACT3出生到传送点")

			GotoActZone(3, 8)

			WaitLoading()
			
			CTA()

			;MouseMove 1180, 742	;防止女武神召唤失败
			;Send ~
			;Sleep 700

			; 从传送点开始传送至3C,使用传送术
			Click, 2523 755 Right Down
			Sleep 1500
			Click, Right Up
			
			AddRecorder("议会")
		}

		else if (F1DropDownListControl = "PAL双人地穴")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			;移动至传送门处
			Click, 1278 1203
			Sleep 1600
			Click, 678 1090
			Sleep 1200

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t
			Sleep 500

			if (DoActions("ACT1出生到传送点", "sor")) {	
			
				GotoActZone(1, 6)

				WaitLoading()

				;CTA()

				;一直传送
				Click, 20 1273 Right Down
				Sleep 2000
				Click, Right Up
			}

			AddRecorder("地穴")
		}

		else if (F1DropDownListControl = "PAL双人超市")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			DoActions("ACT4出生到传送点")

			GotoActZone(4, 3)

			;WaitLoading()

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()
			
			Send {Alt}
			;Send ~
			;Sleep 500
			Send t

			SwitchGame()

			CTA()

			;一直传送
			MouseMove 2186, 95
			Send {q down}
			Sleep 4800
			Send {q up}

			Send h		;开门
			
			SwitchGame()
			
			DoActions("ACT4传送门", "sor")

			SwitchGame()

			AddRecorder("超市")
		}

		else if (F1DropDownListControl = "PAL双人王座")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			DoActions("ACT5出生到传送点")

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t

			SwitchGame()

			GotoActZone(5, 9)

			WaitLoading()

			;移出传送点
			Click, 1036 931
			Sleep 300
			Send h		;开门

			SwitchGame()

			DoActions("ACT5传送门", "sor")
			
			SwitchGame()

			CTA()

			AddRecorder("王座")	
		}

		else if (F1DropDownListControl = "NEC单人皮叔")
		{
			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			DoActions("ACT5出生到安雅")

			WaitLoading()

			Click, 2027 74 Right
			Sleep 200
			Send r
			MouseMove 1900, 182
			Sleep 1000
			;Sleep 500
			Send k
			Sleep 500

			MouseMove 2155, 88
			Sleep 200
			Send {RButton}
			Sleep 300
			MouseMove 2112, 89
			Sleep 200
			Send {RButton}
			Sleep 300
			MouseMove 1689, 475
			Send q

			AddRecorder("皮叔")
		}

		else if (F1DropDownListControl = "NEC双人王座")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			DoActions("ACT5出生到传送点")

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t	

			SwitchGame()

			GotoActZone(5, 9)

			WaitLoading()

			;移出传送点
			Click, 1036 931
			Sleep 300
			Send h		;开门

			SwitchGame()

			DoActions("ACT5传送门", "sor")

			SwitchGame()

			CTA()

			AddRecorder("王座")	
		}

		else if (F1DropDownListControl = "NEC双人牛场")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			;移动至传送门处
			Click, 1278 1203
			Sleep 1600
			Click, 678 1090
			Sleep 1200

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500
			Send t	
			Sleep 500

			if (DoActions("ACT1出生到传送点", "sor")) {	
			
				GotoActZone(1, 3)

				WaitLoading()

				CTA()
			}

			AddRecorder("牛场")
		}

		else if (F1DropDownListControl = "BAR单人K3C")
		{
			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}

			;DoActions("ACT3出生到传送点", "bar")
			DoActions("ACT3出生到传送点")

			GotoActZone(3, 8)

			WaitLoading()

			CTA()
			Send r
			Sleep 1000

			; 从传送点开始传送至3C,使用传送术
			Click, 2523 755 Right Down
			Sleep 2000
			Click, Right Up
			
			AddRecorder("议会")
		}

		else if (F1DropDownListControl = "BAR单人皮叔")
		{
			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}

			DoActions("ACT5出生到安雅")

			WaitLoading()

			CTA()
			Sleep 100
			Send r						;右键施法需考虑点击快捷施法后右键的归位情况,典型的是350ms归位
			Sleep 400

			Click, 2005 180 Right Down
			Sleep 1500
			Click, Right Up
			
			Send q

			AddRecorder("皮叔")
		}

		else if (F1DropDownListControl = "AMA双人K3C")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}

			SwitchGame()

			CheckQuitGame()
			FollowFriend()

			SwitchGame()

			DoActions("ACT3出生到传送点")

			GotoActZone(3, 8)

			;WaitLoading()

			SwitchGame()

			Send {Alt}	
			;Send ~
			;Sleep 500
			Send t	
			Sleep 500

			DoActions("ACT3出生到传送点")

			GotoActZone(3, 8)

			WaitLoading()
			
			CTA()

			MouseMove 1180, 742	;防止女武神召唤失败
			Send ~
			Sleep 700

			; 从传送点开始传送至3C,使用传送术
			Click, 2523 755 Right Down
			Sleep 2100
			Click, Right Up
			
			AddRecorder("议会")
		}

		else if (F1DropDownListControl = "AMA双人王座")
		{
			VerifyAccount("A")

			CheckQuitGame()
			CreateGame()
			WaitInGame()

			Send {Alt}
			Send ~
			Sleep 500

			DoActions("ACT5出生到传送点")

			SwitchGame()

			CheckQuitGame()
			FollowFriend()
			WaitInGame()

			Send {Alt}
			MouseMove 1215, 493	;防止女武神召唤失败
			Send ~
			;Sleep 700

			SwitchGame()

			GotoActZone(5, 9)

			WaitLoading()

			;移出传送点
			Click, 1036 931
			Sleep 300
			Send h		;开门

			SwitchGame()

			DoActions("ACT5传送门", "ama")

			WaitLoading()

			CTA()

			AddRecorder("王座")	
		}
	}
	catch {

	}
}

F1::
	global IsRunning
	if (IsRunning)
		F1Actions()
	else
		Send {F1}
	return
return

F2Actions()
{
	global PIDs
	global IsRunning
	global StopNextActions
	global F2DropDownListControl
	StopNextActions := False

	GuiControlGet, F2DropDownListControl

	try {
		if (F2DropDownListControl = "加入游戏")
		{
			CheckQuitGame()
			FollowFriend()
		}
	}
	catch {

	}
}

F2::
	global IsRunning
	if (IsRunning)
		F2Actions()
	else
		Send {F2}
	return
return

GotoActZone(act, zone)
{
	/*
		传送坐标
		X(5个): 310, 430, 540, 660, 770
		Y标签: 300
		Y(9个): 360, 440, 520, 600, 680, 760, 840, 930, 1000
	*/
	acts := [310, 430, 540, 660, 770]
	zones := [360, 440, 520, 600, 680, 760, 840, 930, 1000]

	if (act) {
		Sleep 200
		Click, % acts[act] " 300"
	}

	Sleep 250
	Click, % "314 " zones[zone]
}

MouseMActions()
{
	global PIDs
	global IsRunning
	global StopNextActions
	global MouseMDropDownListControl
	StopNextActions := False

	GuiControlGet, MouseMDropDownListControl

	try {

		if (MouseMDropDownListControl = "ACT4主城")
		{
			Send F	; 多释放一个技能F,SOR设置为心灵传送可远距离打开传送点
			GotoActZone(4, 1)
		}
		else if (MouseMDropDownListControl = "ACT5主城")
		{
			Send F
			GotoActZone(5, 1)
		}
		else if (MouseMDropDownListControl = "石块荒野")
		{
			Send F
			GotoActZone(1, 3)

			WaitLoading()

			CTA()
		}
		else if (MouseMDropDownListControl = "外侧回廊*带传送*")
		{
			Send F
			GotoActZone(1, 8)

			WaitLoading()

			CTA()

			;一直传送
			Click, 20 1273 Right Down
			Sleep 2000
			Click, Right Up
		}
		else if (MouseMDropDownListControl = "庇护所")
		{
			Send F
			GotoActZone(2, 8)

			WaitLoading()

			CTA()
		}
		else if (MouseMDropDownListControl = "崔凡克")
		{
			Send F
			GotoActZone(3, 8)

			WaitLoading()

			CTA()
		}
		else if (MouseMDropDownListControl = "崔凡克*带传送*")
		{
			Send F
			GotoActZone(3, 8)

			WaitLoading()

			CTA()
			
			;Sleep 100
			Send r
			Sleep 400

			; 从传送点开始传送至3C,使用传送术
			Click, 2523 755 Right Down
			Sleep 2000
			Click, Right Up
		}
		else if (MouseMDropDownListControl = "火焰之河")
		{
			Send F
			GotoActZone(4, 3)

			WaitLoading()

			CTA()
		}
		else if (MouseMDropDownListControl = "王座")
		{
			Send F
			GotoActZone(5, 9)

			WaitLoading()

			Send {Alt}
			;Sleep 500
			;Send t	

			CTA()

			Sleep 200

			Send ~
		}
		else {
			if MouseMDropDownListControl is integer
				GotoActZone("", MouseMDropDownListControl)
		}
	}
	catch {
	}
}

MButton::
	global IsRunning
	if (IsRunning)
		MouseMActions()
	else
		Send {MButton}
return

ShowController()
{
	global IsRunning
	global RunsCounts
	global EditControl

	global F1DropDownListControl
	global F2DropDownListControl
	global MouseMDropDownListControl
	global IsPublicGameControl
	global StopConflictHotKey
	global AutoAura
	global g_Player

	if (!IsRunning) 
	{
		IsRunning := True

		;WinSet, TransColor, FFFFFF 240
		gui, Font, s12, Tahoma
		Gui, Add, Text, w70 xm, F1:
		Gui, Add, DropDownList, vF1DropDownListControl x+10, 新建单人游戏|新建双人游戏|新建双人游戏ACT3|新建双人游戏ACT4|SOR双人地穴||SOR双人超市|SOR双人牛场|SOR双人K3C|PAL双人地穴|PAL双人超市|PAL双人王座|NEC单人皮叔|NEC双人王座|NEC双人牛场|BAR单人K3C|BAR单人皮叔|AMA双人K3C|AMA双人王座|
		Gui, Add, CheckBox, vIsPublicGameControl Checked, 公开房
		Gui, Add, Text, w70 xm, F2:
		Gui, Add, DropDownList, vF2DropDownListControl x+10, 加入游戏||
		Gui, Add, Text, w70 xm, MouseM:
		Gui, Add, DropDownList, vMouseMDropDownListControl x+10, 1||2|3|4|5|6|7|8|9|ACT4主城|ACT5主城|石块荒野|外侧回廊*带传送*|庇护所|崔凡克|火焰之河|崔凡克*带传送*|王座|
		Gui, Add, Edit, w280 R5 vEditControl xm
		Gui, Add, CheckBox, vStopConflictHotKey gStopConflictHotKey, 停止输入冲突?
		Gui, Add, CheckBox, vAutoAura x+10 gAutoAura, PAL自动光环?
		Gui, Add, Text, w70 xm, Player:
		Gui, Add, DropDownList, vg_Player gPlayer x+10, |bar
		Gui, +AlwaysOnTop
		Gui, Show, X2144 Y1017 NA

		RunsCounts := {}
		RunsCounts["议会"] := 0
		RunsCounts["地穴"] := 0
		RunsCounts["超市"] := 0
		RunsCounts["牛场"] := 0
		RunsCounts["皮叔"] := 0
		RunsCounts["王座"] := 0
		Random, beginCount, ,200 
		RunsCounts["PublicGameCount"] := beginCount

		EditControl := "三开乔贝罗"
		GuiControl, ,EditControl, %EditControl%
	}

	Gui, Show, Restore NoActivate

	Sleep, 15000	;显示停留时间

	if (IsRunning)
		Gui, Show, Minimize
}

Player:
	global g_Player
	GuiControlGet, g_Player
	;ToolTip(g_Player)
	;MsgBox, %AutoAura%
return


#IfWinActive 
#Include PaddleOCR\PaddleOCR.ahk

#IfWinActive NEVER_RUN_BlaBlaBlaBlaBlaBlaBlaBla
;#IfWinActive 
N::
	key := "f"
	Send, %key%
return
