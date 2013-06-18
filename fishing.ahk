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

	FishcageCapacity := 50
	gInfoCastCount :=  0

	GoSub, ShowGui
	SellAllFish()
	
StartFishing:

	GoSub, UpdateGui
	CastALine()
	gInfoCastCount++

	WaitForStrike()
	
	Pattern := PullingTheFish()

	WriteLineToDatafile( "Pattern", Pattern )
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

	CheckForLvlUp()
	WaitForFishingScreen()

	CheckingEnergyStatusAndFeeding()
	
	If ( gInfoFishesInFishcage >= FishcageCapacity )
	{
		; MsgBox, 50 fishes catched.
		SellAllFish()
		gInfoFishesInFishcage := 0
	}

	If ( gInfoCastCount > 550 )
		MsgBox, 550 fishes catched!!!
	
	GoTo, StartFishing

^x::
EndScript:

ExitApp

; ======================== Body end ====================================================

TestEntryFunc()
{
}

; ======================== GUI ====================================================

ShowGui:

	guiX := X(800)
	guiY := Y(0)
	
	Gui,+AlwaysOnTop
	
	Gui, Add, Tab, x5 y5 w260 h180, General|Options 
	
	Gui, Tab, 1
	Gui, Add, GroupBox, x15 y30 w120 h65, Catched
	Gui, Add, Text, x25  y45 w80 h15,Fishes
	Gui, Add, Text, x110 y45 w20 h15 vguiFishCatchedQtyText, %gInfoFishCatched%
	Gui, Add, Text, x25  y60 w80 h15,Collection items
	Gui, Add, Text, x110 y60 w20 h15 vguiCollectionCatchedQtyText, %gInfoCollectionCatched%
	Gui, Add, Text, x25  y75 w80 h15,Treasures
	Gui, Add, Text, x110 y75 w20 h15 vguiTreasuresCatchedQtyText, %gInfoTreasuresCatched%
	
	Gui, Add, Text, x145 y45 w80 h15,Lost
	Gui, Add, Text, x230 y45 w20 h15 vguiLostText, %gInfoLost%
	Gui, Add, Text, x145 y60 w80 h15 cGray,Quests complted
	Gui, Add, Text, x230 y60 w20 h15 cGray vguiQuests, %gInfoQuests%
	Gui, Add, Text, x145 y75 w80 h15,Level Up's
	Gui, Add, Text, x230 y75 w20 h15 vguiLvlUp, %gInfoLvlUp%
	
	Gui, Add, Text, x15  y100 w100 h15, Fishcage
	Gui, Add, Text, x120 y100 w50 h15 vguiFishcageInfo, 0 / %FishcageCapacity%
	Gui, Add, Progress, x15 y115 w240 h5 cAqua BackgroundTeal vguiFishcageProgress
	Gui,Show,x%guiX% y%guiY% w270 h200 NoActivate, Facebook Go-Fishing trainer
	
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

	; If ( Energy < 20 ) 
	; {
		; Sleep, 1000
		; Energy := GetEnergyPercents()
	; }

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
	; Also can be used points 255, 455 and 495, 455
	If (    TestPixelColor( 199, 455, 0x0 ) 
		and TestPixelColor( 551, 455, 0x0 ) )
	{
		Return 1
	}
	else
	{
		Return 0
	}
}

TestPixelColor(PixelX, PixelY, TestColor)
{
	PixelGetColor, PixelColor, X(PixelX), Y(PixelY)
	If (PixelColor = TestColor)
		Return 1
	Else
		Return 0
}

CastALine()
{
	While ( !CastBtnX )
	{
		FindImgPosInRect( "CastBtnTag", CastBtnX, CastBtnY, 480, 480, 600, 530 )
	}
	WriteLineToLogfile( "{CastALine}", "Cast button on " . CastBtnX . ", " . CastBtnY )

	MouseClick Left, CastBtnX, CastBtnY
	MouseMove, CastBtnX, CastBtnY - 150
}

WaitForStrike()
{
	While ( not isImgTagInRect( "StrikeBtnTag", 480, 480, 600, 530 ) ) 
	{
		if ( CheckForLvlUp() )
			WaitForFishingScreen()
		else
			Sleep, 50
	}
	
	WriteLineToLogfile( "{WaitForStrike}", "Fish strike detected!" )
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
	Imagesearch, ImgTagX, ImgTagY, X(ectCorner1X), Y(RectCorner1Y), X(RectCorner2X), Y(RectCorner2Y), *30 *Trans0xFF0000 %A_ScriptDir%\Images\%ImgTagStr%.png

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
	
	Imagesearch, ImgX, ImgY, 1, 1, WindowWidth, WindowHeight,*30 *Trans0xFF0000 %A_ScriptDir%\Images\LeftUpperCornedDefImg.png
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