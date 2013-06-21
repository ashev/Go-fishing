	#NoEnv
	#SingleInstance force

	SetWorkingDir, %A_ScriptDir%
	SetBatchLines, -1

	DebugFile = %A_ScriptDir%\Report_Run_%A_Now%.log
	DataFile = %A_ScriptDir%\Pulling_data.log
	WndTitleKeyword := "Go Fishing"
	BrowserTitleKeyword := "- Google Chrome"
	
	WriteLineToLogfile( A_LineNumber, "=========================" )
	WriteLineToLogfile( A_LineNumber, "====== Starting up ======" )

	;== SetupEnvironment()
	InitGlobalInfoVars()
	FindAndActivateGameWindow(BrowserTitleKeyword, WndTitleKeyword)
	GetGameWindowDimensions()
	SetupUpperLeftCorner()

	TestEntryFunc()

	gSettingUsingSpinning := 0
	FishcageCapacity := 50
	gInfoCastCount :=  0

	GoSub, ShowGui
	
	Return

StartFishing:
	FindAndActivateGameWindow(BrowserTitleKeyword, WndTitleKeyword)
	GetGameWindowDimensions()
	SetupUpperLeftCorner()

	SellAllFish()
	
	While( 1 )
	{
		GoSub, UpdateGui

		HookTheFish( gSettingUsingSpinning )
		
		Pattern := PullingTheFish()

		WriteLineToDatafile( "Pattern", Pattern )

		DeterminationOfResultOfFishing()

		CheckForLvlUp()
		WaitForFishingScreen()

		CheckingEnergyStatusAndFeeding()
		
		If ( gInfoFishesInFishcage >= FishcageCapacity )
		{
			; MsgBox, 50 fishes catched.
			SellAllFish()
			gInfoFishesInFishcage := 0
		}

		If ( (gInfoFishCatched + gInfoCollectionCatched) > 550 )
			MsgBox, 550 items catched!!!
	}

^x::
EndScript:

ExitApp

; ======================== Body end ====================================================

TestEntryFunc()
{

}

; ======================== GUI ====================================================

ShowGui:

	guiX := X(760)
	guiY := Y(0)
	
	Gui,  +AlwaysOnTop
	Gui, Add, Tab, x5 y5 w265 h400, General|Settings|Options

	Gui, Tab, 1, 1
	Gui, Add, Button, x20 y40 w115 h30 gStartFishing, Start fishing!
	Gui, Add, Text, x145 y40 w110 h15 Center, Time elapsed
	Gui, Add, Text, x145 y55 w110 h15 Center, %gInfoTimeElapsed%
	Gui, Add, GroupBox, x15 y80 w120 h80, Catched
	Gui, Add, Text, x25 y95 w80 h15, Fishes
	Gui, Add, Text, x110 y95 w20 h15 vguiFishCatchedQtyText, %gInfoFishCatched%
	Gui, Add, Text, x25 y110 w80 h15, Collection items
	Gui, Add, Text, x110 y110 w20 h15 vguiCollectionCatchedQtyText, %gInfoCollectionCatched%
	Gui, Add, Text, x25 y125 w80 h15, Treasures
	Gui, Add, Text, x110 y125 w20 h15 vguiTreasuresCatchedQtyText, %gInfoTreasuresCatched%
	Gui, Add, Text, x25 y140 w80 h15, Total items
	Gui, Add, Text, x110 y140 w20 h15 vguiTotalCatchedText, %gInfoTotalCatched%

	Gui, Add, Text, x150 y95 w80 h15, Cast made
	Gui, Add, Text, x235 y95 w20 h15, %gInfoLost%
	Gui, Add, Text, x150 y110 w80 h15, Lost
	Gui, Add, Text, x235 y110 w20 h15 vguiLostText, %gInfoLost%
	Gui, Add, Text, x150 y125 w80 h15 cGray, Quests complted
	Gui, Add, Text, x235 y125 w20 h15 cGray vguiQuests, %gInfoQuests%
	Gui, Add, Text, x150 y140 w80 h15, Level Up's
	Gui, Add, Text, x235 y140 w20 h15 vguiLvlUp, %gInfoLvlUp%

	Gui, Add, Text, x15 y165 w100 h15, Fishcage
	Gui, Add, Text, x120 y165 w50 h15 vguiFishcageInfo, 0 / %FishcageCapacity%
	Gui, Add, Progress, x15 y180 w240 h5 cAqua BackgroundTeal vguiFishcageProgress, 

	Gui, Tab, 2, 1
	
	Gui, Add, GroupBox, x15 y35 w245 h60, Tackle
	Gui, Add, Radio, x25 y50 w55 h15, Floating
	Gui, Add, Radio, x25 y70 w85 h15, Spinning
	Gui, Add, Checkbox, x110 y50 w125 h15, Monitoring the integrity
	Gui, Add, GroupBox, x15 y100 w245 h105, Fishcage
	Gui, Add, Text, x25 y120 w50 h15, Capacity
	Gui, Add, DropDownList, x25 y135 w50 h20 R4 vguiFishCageCapacity gGuiSetFishcageCapacity Choose1, 50|75|100|150
	Gui, Add, GroupBox, x115 y115 w135 h80, On full
	Gui, Add, Radio, x125 y130 w100 h15, Sell fish
	Gui, Add, Radio, x125 y150 w100 h15, Cut stakes
	Gui, Add, Radio, x125 y170 w100 h15, Pause fishing

	Gui, Add, GroupBox, x15 y210 w240 h170, Pulling
	Gui, Add, Text, x30 y230 w45 h15, Left limit
	Gui, Add, Slider, x20 y245 w230 h25 +Tickinterval1 vguiLeftLimit range1-20, 25
	Gui, Add, Text, x30 y280 w45 h15, Right limit
	Gui, Add, Slider, x20 y295 w230 h25 +Tickinterval1 vguiRightLimit range1-20, 25
	Gui, Add, Text, x30 y330 w70 h15, Agressivness
	Gui, Add, Slider, x20 y345 w230 h25 +Tickinterval1 vguiPullingAggresivity range1-10, 25

	Gui, Show, x%guiX% y%guiY% w275 h420, Facebook Go-Fishing trainer
	
Return	

GuiSetFishcageCapacity:

	GuiControlGet,guiFishCageCapacity,,guiFishCageCapacity
	
	FishcageCapacity := guiFishCageCapacity
		
	GuiControl,,guiFishcageInfo, %gInfoFishesInFishcage% / %FishcageCapacity%
	
Return

UpdateGui:

	FishCageProgressPosition := 100 * gInfoFishesInFishcage / FishcageCapacity
	
	GuiControl,,guiFishCatchedQtyText, %gInfoFishCatched%
	GuiControl,,guiCollectionCatchedQtyText, %gInfoCollectionCatched%
	GuiControl,,guiTreasuresCatchedQtyText, %gInfoTreasuresCatched%
	
	GuiControl,,gInfoLost, %gInfoLost%
	; GuiControl,,gInfoQuests, %gInfoQuests%
	GuiControl,,gInfoLvlUp, %gInfoLvlUp%
	
	GuiControl,,guiFishcageInfo, %gInfoFishesInFishcage% / %FishcageCapacity%
	GuiControl,,guiFishcageProgress, %FishCageProgressPosition%
	Gui, Submit, NoHide

Return

; ======================== Info variables management ====================================================

InitGlobalInfoVars()
{
	global gInfoFishCatched := 0
	global gInfoCollectionCatched := 0
	global gInfoTreasuresCatched := 0
	global gInfoFishesInFishcage := 0
	global gInfoLost := 0
	global gInfoQuests := 0
	global gInfoLvlUp := 0
}

; ======================== Energy management ====================================================

WaitForFishingScreen()
{
	while ( not IsImgTagInRect( "LeftUpperCornedDefImg", 4, 7, 34, 37 ) )
		sleep, 50
}

CheckingEnergyStatusAndFeeding()
{
	Energy := GetEnergyPercents()

	If ( Energy < 20 ) {
		OpenFeedingMenu()
		FeedMe(1)
		NewEnergy := GetEnergyPercents()
		EnergyStep := NewEnergy - Energy
		TimesToFeed := floor( ( 100 - NewEnergy ) / EnergyStep )
		FeedMe( TimesToFeed )
		CloseFeedingMenu()
	}
}

OpenFeedingMenu()
{
	MouseMove, X(50), Y(420)
	Sleep, 500
	MouseClick, Left, X(50), Y(420)

	Sleep, 500

	MouseMove, X(250), Y(150)
	Sleep, 500
	MouseClick, Left, X(250), Y(150)

	Sleep, 500

}

CloseFeedingMenu()
{
	MouseClick, Left, X(700), Y(80)
	Sleep, 500
}

FeedMe( nTimes )
{
	MouseMove, X(100), Y(370)
	Sleep, 500
	While ( nTimes > 0 )
	{
		LocateImgAndClick( "SteakTag", 40, 310, 500, 355, 60, 55 )
		; MouseClick, Left, X(100 + 130), Y(370) ; --- !!!! ------
		Sleep, 2000
		nTimes--
	}
}

GetEnergyPercents()
{
	; Energy bar position is 439x32 - 606x32
	; length is 166
	BarLeftX := 439
	RangeLeftX := BarLeftX
	RangeRightX := 606
	BarY     := 32

	Loop
	{
		dX := RangeRightX - RangeLeftX
		If ( dX <= 2 )
			Break
			
		MidX := RangeLeftX + dX // 2
		If ( TestPixelColor( MidX, 32, 0xFD4406) ) 
			RangeLeftX := MidX
		Else
			RangeRightX := MidX
	}

	Return (MidX - BarLeftX)*100/165
}

; ======================== Pulling sequence ====================================================

HookTheFish( isSpinningUsed )
{
	global gInfoCastCount

	CastAgain := 1

	While ( CastAgain ) 
	{
		CastAgain := 0
		CastTheLine()
		gInfoCastCount++

		If ( isSpinningUsed )
		{
			While ( not IsSpinningBarOn() )
				Sleep, 100

			Click down

			while ( (not IsPullingBarOn()) and (not CastAgain) )
			{
				CastAgain := FindImgPosInRect( "CastBtnTag", CastBtnX, CastBtnY, 480, 480, 600, 530 )
				If ( CastAgain ) 
					Click up
			}
		}
	}

	If ( not isSpinningUsed )
		WaitForStrike()
}

WaitForPullingBar()
{
	i := 0
	while ( ( not IsPullingBarOn() ) and ( i < 1000 ) )
	{
		i++
	}
}
	
PullingTheFish()
{
	RightPullingLimit := 16
	LeftPullingLimit  := 4
	PrevOverloadState := 0
	CalmCycles := 0
	PullingPattern := ""
	
	SwitchDirection( PullingDirection )
	WaitForPullingBar()
	
	PullingProgress := GetPullingBarProgress( PullingDirection, 0, "init")
	PullingPattern := PullingPattern . PullingPatternStr(RodOverloadState, PrevRodOverloadState, PullingDirection, PullingProgress, ProgressLogStr, LeftPullingLimit, RightPullingLimit)

	While ( IsPullingBarOn() )
	{
		RodOverloadState := isRodOverloaded()
		PullingProgress := GetPullingBarProgress( PullingDirection, RodOverloadState)

		If ( RodOverloadState )
		{
			CalmCycles := 0
			If (!PrevOverloadState)
			{
				LeftPullingLimit++
				RightPullingLimit--
			}
		}

		If ( (PullingDirection = 0) and ( PullingProgress < LeftPullingLimit ) )
			SwitchDirection( PullingDirection )
		Else
			If ( (PullingDirection = 1) and ( PullingProgress > RightPullingLimit ) )
			{
				SwitchDirection( PullingDirection )
				CalmCycles++
				If ( CalmCycles > 3 ) {
					CalmCycles := 0
					LeftPullingLimit--
					RightPullingLimit++
				}
			}

		PullingPattern := PullingPattern . PullingPatternStr(RodOverloadState, PrevRodOverloadState, PullingDirection, PullingProgress, ProgressLogStr, LeftPullingLimit, RightPullingLimit) 
		PrevOverloadState := RodOverloadState
	}
	; WriteLineToLogfile( "{PullingTheFish}", "Pulling finished" )
	Return PullingPattern
}

PullingPatternStr(RodOverloadState, PrevRodOverloadState, PullingDirection, PullingProgress, ProgressLogStr, LeftPullingLimit, RightPullingLimit)
{
		Return ( "`n" . A_NowUTC . " : " 
				. (RodOverloadState ? "#" : " ") 
				. (PrevOverloadState ? "+ " : "  ") 
				. (PullingDirection ? "---> " : "<--- ") 
				.  PullingProgress
				.  "`t" . LeftPullingLimit . " <-> " . RightPullingLimit )
}

SwitchDirection( ByRef PullingDirection )
{
	If ( PullingDirection )
	{
		PullingDirection := 0
		Click up
	}
	Else
	{
		PullingDirection := 1
		Click down
	}
}

isRodOverloaded()
{
	LeftColorFlag := TestPixelColor( 267, 460, 0x00CC00)
	RightColorFlag := TestPixelColor( 483, 460, 0x00CC00)
	OverloadingFlag :=  not ( LeftColorFlag ^ RightColorFlag )
	
	Return OverloadingFlag
}

GetPullingBarProgress( PullingDirection, OverloadingFlag, isNewRun = 0 )
{
	static LeftBarX  := 265
	static RightBarX := 485
	static BarY      := 460
	static PrevProgressValue
	static PrevDirection
	
	If (isNewRun) 
	{
		PrevProgressValue := 0
		PrevDirection := 1
	}

	If ( OverloadingFlag ) {
		CorrectionValue := ( PullingDirection = PrevDirection ? 2 : 0 )
		ProgressValue := PrevProgressValue + ( PullingDirection ? 1 : -1 ) * CorrectionValue
	}
	else
	{	
		If ( PullingDirection = 1 ) 
		{
			OperationSign := -1
			StartingPosition := RightBarX
			StartingProgress := 20
			ComparitionAnswer := 0
		}
		Else
		{
			OperationSign := 1
			StartingPosition := LeftBarX
			StartingProgress := 0
			ComparitionAnswer := 1
		}

		Loop, 20
		{
			ProgressIndex := OperationSign * A_Index
			ColorFlagOnPos := TestPixelColor( StartingPosition + ProgressIndex * 12, BarY, 0x00CC00)
			If ( ColorFlagOnPos != ComparitionAnswer )
				Break
		}

		ProgressValue := StartingProgress + ProgressIndex
	}
	PrevDirection := PullingDirection
	PrevProgressValue := ProgressValue
	
	Return ProgressValue
}

IsPullingBarOn()
{
	Return IsBarOn( 255, 551 )
}

IsSpinningBarOn()
{
	Return IsBarOn( 254, 551 )
}

IsBarOn( BlackLine1X, BlackLine2X )
{
	; Also can be used points 199, 455 and 551, 455
	; Also can be used points 255, 455 and 495, 455
	Return (TestPixelColor( BlackLine1X, 455, 0x0 ) 
		and TestPixelColor( BlackLine2X, 455, 0x0 ) )
		; Return 1
	; else
		; Return 0
}

TestPixelColor(PixelX, PixelY, TestColor)
{
	PixelGetColor, PixelColor, X(PixelX), Y(PixelY)
	If (PixelColor = TestColor)
		Return 1
	Else
		Return 0
}

CastTheLine()
{
	While ( !CastBtnX )
	{
		if ( CheckForLvlUp() )
		{
			Sleep, 500
			WaitForFishingScreen()
		}
		FindImgPosInRect( "CastBtnTag", CastBtnX, CastBtnY, 480, 480, 600, 530 )
	}
	WriteLineToLogfile( "{CastTheLine}", "Cast button on " . CastBtnX . ", " . CastBtnY )

	MouseClick Left, CastBtnX, CastBtnY
	MouseMove, CastBtnX, CastBtnY - 150
}

WaitForStrike()
{
	While ( not isImgTagInRect( "StrikeBtnTag", 480, 480, 600, 530 ) ) 
	{
		Sleep, 50
	}
	
	WriteLineToLogfile( "{WaitForStrike}", "Fish strike detected!" )
}

; ======================== Fishing management sequence ====================================================

DeterminationOfResultOfFishing()
{
	global gInfoFishesInFishcage
	global gInfoFishCatched
	global gInfoCollectionCatched
	global gInfoLost
	global gInfoTreasuresCatched

	PullingResult := -1
	While (PullingResult = -1)
	{
		If (IsFishCatched()) {
			PullingResult := "= Catched"
			gInfoFishesInFishcage++
			gInfoFishCatched++
		}
		Else If (IsCollectionCatched())
		{
			gInfoCollectionCatched++
			PullingResult := "Collection"
		}
		Else If (IsMessageOn())
		{
			PullingResult := "Lost"
			gInfoLost++
		}
		Else If (IsTreasureCatched()) 
		{
			PullingResult := "Treasure"
			gInfoTreasuresCatched++
		}
	}
	WriteLineToDatafile( PullingResult, "`n`n" )
}

SellAllFish()
{
	MouseMove, X(50), Y(350)
	Sleep, 500
	
	While ( not isFishcageOpened() )
	{
		MouseClick, Left, X(50), Y(350)
		Sleep, 500
	}

	Sleep, 500

	If ( isFishInCage() ) 
	{
		MouseClick, Left, X(630), Y(260)
		While ( isFishInCage() )
		{
			Sleep, 500
		}
	}

	MouseClick, Left, X(700), Y(80)
	Sleep, 500
}

isFishcageOpened()
{
	Return isImgTagInRect( "FishcageRedCrossTag", 680, 60, 700, 80 )
}

isFishInCage()
{
	Return ( not isImgTagInRect( "EmptyFishcageTag", 580, 200, 680, 240 ) )
}

isImgTagInRect( ImgTagStr, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y )
{
	Return FindImgPosInRect( ImgTagStr, ImgTagX, ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y )
}

LocateImgAndClick( ImgTagStr, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y, dx=5, dy=5 )
{
	TagInRectState := FindImgPosInRect( ImgTagStr, ImgTagX, ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y )
	If ( TagInRectState )
		MouseClick, Left, ImgTagX+dX, ImgTagY+dY
		
	Return TagInRectState
}

FindImgPosInRect( ImgTagStr, ByRef ImgTagX, ByRef ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y )
{
	Imagesearch, ImgTagX, ImgTagY, X(ectCorner1X), Y(RectCorner1Y), X(RectCorner2X), Y(RectCorner2Y), *10 *Trans0xFF0000 %A_ScriptDir%\Images\%ImgTagStr%.png

	If ( ImgTagX > 0 )
		TagFound := 1
	Else
		TagFound := 0
		
	Return TagFound
}

IsFishCatched() 
{
	CatchedResult := 0

	If (   isImgTagInRect( "NormalCatchTag", 300, 100, 450, 200 ) 
		or isImgTagInRect( "CatchTagRecord", 300, 100, 450, 200 ) 
		or isImgTagInRect( "TrophyCatchTag", 300, 100, 450, 200 ))
	{
		UnmarkFishInfoSharingBox()
		MouseClick, Left, X(380), Y(450)
		CatchedResult := 1
		WriteLineToLogfile( "{IsFishCatched}", "Normal fish catched." )
	}
	
	Return CatchedResult
}

UnmarkFishInfoSharingBox()
{
	If ( LocateImgAndClick( "ShareFishCheckBox", 180, 430, 230, 470 ) )
	{
		WriteLineToLogfile( "{IsFishCatched}", "Sharing CheckBox Unmarked." )
	}
}

UnmarkLvlUpSharingBox()
{
	If ( LocateImgAndClick( "ShareLvlUpCheckBox", 70, 460, 110, 500 ) )
	{
		WriteLineToLogfile( "{CheckForLvlUp}", "Sharing CheckBox Unmarked." )
	}
}

UnmarkTreasureSharingBox()
{
	If ( LocateImgAndClick( "ShareTreasureCheckBox", 170, 460, 230, 500 ) )
	{
		WriteLineToLogfile( "{Treasure}", "Sharing CheckBox Unmarked." )
	}
}

IsCollectionCatched() 
{
	CatchedResult := 0

	If ( isImgTagInRect( "CatchTagCollection", 150, 130, 350, 230 ) )
	{
		WriteLineToLogfile( "{IsCollectionCatched}", "Collection item catched." )
		CatchedResult := 1
		MouseClick, Left, X(400), Y(430)
		Sleep, 500
	}
	Else
	{
		If ( isImgTagInRect( "CatchTagCollectionFull", 150, 130, 350, 230 ) )
		{
			WriteLineToLogfile( "{IsCollectionCatched}", "Collection item catched. One more Collection completed." )
			CatchedResult := 2
			MouseClick, Left, X(250), Y(450)
			Sleep, 500
		}
	}
	Return CatchedResult
}

IsMessageOn() 
{
	MsgResult := FindImgPosInRect( "InfoOkBtn", OkBtnX, OkBtnY, 250, 250, 450, 450 )
	If ( MsgResult )
	{
		WriteLineToLogfile( "{IsMessageOn}", "Message detected. Ok button on " . OkBtnX . ", " . OkBtnY )
		MouseClick, Left, OkBtnX+20, OkBtnY+20
		Sleep, 500
	}
	Return MsgResult
}

CheckForLvlUp()
{
	global gInfoLvlUp

	LvlUpResult := isImgTagInRect( "lvlUpTag", 140, 100, 200, 130 )
	If ( LvlUpResult )
	{
		gInfoLvlUp++
		UnmarkLvlUpSharingBox()
		MouseClick, Left, X(430), Y(480)
		WriteLineToLogfile( "{CheckForLvlUp}", "== Level up! ==" )
		; Sleep, 500
	}
	Return LvlUpResult
}

IsTreasureCatched()
{
	TreasureResult := isImgTagInRect( "CatchTagTreasure", 280, 80, 380, 130 )
	If ( TreasureResult )
	{
		UnmarkTreasureSharingBox()
		MouseClick, Left, X(370), Y(490)
		WriteLineToLogfile( "{TreasureResult}", "== Treasure catched! ==" )
	}
	Return TreasureResult
}

;================== Screen coordinates operations =============================

SetupUpperLeftCorner()
{
	global WindowWidth, WindowHeight, UpperLeftCornerX, UpperLeftCornerY
	
	Imagesearch, ImgX, ImgY, 1, 1, WindowWidth, WindowHeight, *10 *Trans0xFF0000 %A_ScriptDir%\Images\LeftUpperCornedDefImg.png
	UpperLeftCornerX := ImgX - 4
	UpperLeftCornerY := ImgY - 7
	WriteLineToLogfile( "{SetupUpperLeftCorner}", "Upper left corner on " . UpperLeftCornerX ", " . UpperLeftCornerY )
}

X(xCoord)
{
	global UpperLeftCornerX
	return xCoord + UpperLeftCornerX
}

Y(yCoord)
{
	global UpperLeftCornerY
	return yCoord + UpperLeftCornerY
}

FindAndActivateGameWindow(KeywordInBrowserTitle, KeywordInGameTabTitle)
{
	SetTitleMatchMode, 2
	WinActivate, %KeywordInBrowserTitle%

	Loop, 15
	{
		WinGetTitle, ActiveWindowTitle, A  

		If ( InStr(ActiveWindowTitle, KeywordInGameTabTitle) > 0 )
			break 

		Send ^{Tab}
		Sleep, 100
	}
}

GetGameWindowDimensions()
{
	Global WindowWidth, WindowHeight
	
	WinGetPos, , , WindowWidth, WindowHeight, - Google Chrome

	If (WindowWidth) {
		WriteLineToLogfile( "{GetGameWindowDimensions}", "Window size is " . WindowWidth . ", " . WindowHeight)
		Result := 1
	}
	else {
		WriteLineToLogfile( "{GetGameWindowDimensions}", "Window size unknown" )
		Result := 0
	}
	Return Result
}

;================== File operations =============================

WriteLineToLogfile(CalledFromAddress = "", StringToWrite = "")
{
	global DebugFile
	FileAppend, %A_NowUTC% :: %CalledFromAddress% - %StringToWrite%`n, %DebugFile%
}

WriteLineToDatafile(PullingResult, PullingPattern)
{
	global DataFile
	FileAppend, %PullingResult%`t %PullingPattern%`n, %DataFile%
}

;================== Imported functions =============================