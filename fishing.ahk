	#NoEnv
	#SingleInstance force

	SetWorkingDir, %A_ScriptDir%
	SetBatchLines, -1
	gDebugFile = %A_ScriptDir%\Report_Run_%A_Now%.log
	
	WriteLineToLogfile( A_LineNumber, "=========================" )
	WriteLineToLogfile( A_LineNumber, "====== Starting up ======" )

	InitGlobalInfoVars()
	InitGlobalSettingsVars()
	FindAndActivateGameWindow()
	GetGameWindowDimensions()
	SetupUpperLeftCorner()

	GoSub, ShowGui
	
Return

StartFishing:

	SetFishingBtnState( 0 )

	FindAndActivateGameWindow()
	GetGameWindowDimensions()
	SetupUpperLeftCorner()
	ManageFishcage()
	
	While( not gPauseFlag )
	{
		If ( HookTheFish( gSettingUsingSpinning ) )
		{
			WriteLineToLogfile( A_LineNumber, "Fish hooked, start pulling." )

			Pattern := PullingTheFish( gSettingLeftPullingLimit, gSettingRightPullingLimit, gSettingAgressivity )
			WriteLineToDatafile( "Pattern", Pattern )

			ResultOfFishingDetermination()
			CheckForLvlUp()
			GoSub, UpdateInfoGui
			WriteLineToLogfile( A_LineNumber, "-> WaitForFishingScreen"  )
			WaitForFishingScreen()
			CheckingEnergyStatusAndFeeding()

			If ( gInfoFishesInFishcage >= gSettingFishcageCapacity )
				ManageFishcage()
		}

		If ( (gInfoFishCatched + gInfoCollectionCatched) > 550 )
			MsgBox, 550 items catched!!!
	}
	
	SetFishingBtnState(1)
	gPauseFlag := 0
	Gui, Show
	
Return

!^p::
	gPauseFlag := 1
	SetFishingBtnState(2)
Return

^q::
EndScript:
GuiEscape:
GuiClose:

ExitApp

; ======================== Body end ====================================================


; ======================== GUI ====================================================

ShowGui:

	guiX := X(760)
	guiY := Y(0)
	TackleName := GetTackleName( gSettingUsingSpinning )
	
	Gui,  +AlwaysOnTop
	Gui, Add, Tab, x5 y5 w260 h255, General|Fishcage/Pulling|Other settings

	Gui, Tab, 1, 1
	Gui, Add, Button, x15 y40 w120 h40 vStartFishingBtn gStartFishing, Start with %TackleName%!
	Gui, Add, GroupBox, x145 y35 w110 h55, Tackle
	Gui, Add, Radio, x155 y50 w75 h15 vTackleType gUpdateTackle Checked1, Floating
	Gui, Add, Radio, x155 y65 w75 h15             gUpdateTackle         , Spinning

	; Gui, Add, Text, x145 y40 w110 h15 Center, Time elapsed
	; Gui, Add, Text, x145 y55 w110 h15 Center vgInfoTimeElapsed, %gInfoTimeElapsed%

	Gui, Add, GroupBox, x15 y85 w120 h80, Catched
	Gui, Add, Text, x25 y100 w80 h15, Fishes
	Gui, Add, Text, x100 y100 w30 h15 Right vgInfoFishCatched, %gInfoFishCatched%
	Gui, Add, Text, x25 y115 w80 h15, Collection items
	Gui, Add, Text, x100 y115 w30 h15 Right vgInfoCollectionCatched, %gInfoCollectionCatched%
	Gui, Add, Text, x25 y130 w80 h15, Treasures
	Gui, Add, Text, x100 y130 w30 h15 Right vgInfoTreasuresCatched, %gInfoTreasuresCatched%
	Gui, Add, Text, x25 y145 w80 h15, Total items
	Gui, Add, Text, x100 y145 w30 h15 Right vgInfoTotalCatched, %gInfoTotalCatched%

	Gui, Add, Text, x150 y100 w80 h15, Cast made
	Gui, Add, Text, x225 y100 w30 h15 Right vgInfoCastCount, %gInfoCastCount%
	Gui, Add, Text, x150 y115 w80 h15, Lost
	Gui, Add, Text, x225 y115 w30 h15 Right vgInfoLost, %gInfoLost%
	Gui, Add, Text, x150 y130 w80 h15 Disabled, Quest ended
	Gui, Add, Text, x225 y130 w30 h15 Disabled Right vgInfoQuests, %gInfoQuests%
	Gui, Add, Text, x150 y145 w80 h15, Level Up
	Gui, Add, Text, x225 y145 w30 h15 Right vgInfoLvlUp, %gInfoLvlUp%

	Gui, Add, Text, x15 y170 w100 h15, Fishcage
	Gui, Add, Text, x120 y170 w50 h15 vguiFishcageInfo, 0 / %gSettingFishcageCapacity%
	Gui, Add, Progress, x15 y185 w240 h5 cAqua BackgroundTeal vguiFishcageProgress, 

	Gui, Tab, 2, 1
	
	Gui, Add, Text, x15 y40 w100 h15, Fishcage capacity
	Gui, Add, DropDownList, x115 y35 w50 h21 R4 Choose1 vguiFishCageCapacity gUpdateFishcageCapacity, 50|75|100|150

	Gui, Add, GroupBox, x15 y65 w240 h185, Pulling
	Gui, Add, Text, x30 y85 w45 h15, Left limit
	Gui, Add, Text, x130 y85 w70 h15 vSettingLeftPullingLimitText, %gSettingLeftPullingLimit%
	Gui, Add, Slider, x20 y100 w230 h25 +Tickinterval1 range1-20 vgSettingLeftPullingLimit gUpdatePullingSettings, %gSettingLeftPullingLimit%
	Gui, Add, Text, x30 y135 w45 h15, Right limit
	Gui, Add, Text, x130 y135 w70 h15 vSettingRightPullingLimitText, %gSettingRightPullingLimit%
	Gui, Add, Slider, x20 y150 w230 h25 +Tickinterval1 range1-20 vgSettingRightPullingLimit gUpdatePullingSettings, %gSettingRightPullingLimit%
	Gui, Add, Text, x30 y185 w80 h15, Aggressiveness
	Gui, Add, Text, x130 y185 w70 h15 vSettingAgressivityText, %gSettingAgressivity%
	Gui, Add, Slider, x20 y200 w230 h25 +Tickinterval1 range1-10 vgSettingAgressivity gUpdatePullingSettings, %gSettingAgressivity%
	Gui, Add, Text, x30 y225 w70 h15, High
	Gui, Add, Text, x170 y225 w70 h15 Right, Low

	Gui, Tab, 3, 1
	
	Gui, Add, Checkbox, x15 y40 w205 h15 Disabled, Tackle integrity monitoring
	Gui, Add, GroupBox, x15 y60 w135 h70, When fishcage is full
	Gui, Add, Radio, x25 y75 w100 h15 Checked1, Sell fish
	Gui, Add, Radio, x25 y90 w100 h15 Disabled, Cut stakes
	Gui, Add, Radio, x25 y105 w100 h15 Disabled, Pause fishing

	Gui, Show, x%guiX% y%guiY% w270 h265, Go-Fishing trainer
	
Return	

SetFishingBtnState( BtnState )
{
	global gSettingUsingSpinning
	
	If ( BtnState = 1 )
	{
		TackleName := GetTackleName( gSettingUsingSpinning )
		SetButtonStateAndText( "StartFishingBtn", "Enable", "Start with " . TackleName . "!"  )
	}
	Else If ( BtnState = 2 )
		SetButtonStateAndText( "StartFishingBtn", "Disable", "Pause initiated `n Please wait" )
	Else
		SetButtonStateAndText( "StartFishingBtn", "Disable", "WORKING `n Ctrl+Alt+P for pause" )
}

SetButtonStateAndText( BtnId, State, Text )
{
	GuiControl,%State%,%BtnId%
	GuiControl,,%BtnId%, %Text%
}

GetTackleName( TackleType )
{
	Return ( TackleType=0 ? " floating tackle" : " spinning tackle" )
}

UpdateFishcageCapacity:

	GuiControlGet,guiFishCageCapacity,,guiFishCageCapacity
	
	gSettingFishcageCapacity := guiFishCageCapacity
	
	GoSub, UpdateFishcageProgress
		
Return

UpdateFishcageProgress:

	GuiControl,,guiFishcageInfo, %gInfoFishesInFishcage% / %gSettingFishcageCapacity%
	FishCageProgressPosition := 100 * gInfoFishesInFishcage / gSettingFishcageCapacity
	GuiControl,,guiFishcageProgress, %FishCageProgressPosition%
	
Return

UpdateTackle:

	Gui, Submit, NoHide
	gSettingUsingSpinning := TackleType - 1
	TackleName := GetTackleName( gSettingUsingSpinning )
	GuiControl,,StartFishingBtn, Start with %TackleName%!

Return

UpdatePullingSettings:

	GuiControl,,SettingLeftPullingLimitText, %gSettingLeftPullingLimit%
	GuiControl,,SettingRightPullingLimitText, %gSettingRightPullingLimit%
	GuiControl,,SettingAgressivityText, %gSettingAgressivity%

Return

UpdateInfoGui:

	GuiControl,,gInfoFishCatched, %gInfoFishCatched%
	GuiControl,,gInfoCollectionCatched, %gInfoCollectionCatched%
	GuiControl,,gInfoTreasuresCatched, %gInfoTreasuresCatched%
	gInfoTotalCatched := gInfoFishCatched + gInfoCollectionCatched + gInfoTreasuresCatched
	GuiControl,,gInfoTotalCatched, %gInfoTotalCatched%
	
	GuiControl,,gInfoCastCount, %gInfoCastCount%
	GuiControl,,gInfoLost, %gInfoLost%
	; GuiControl,,gInfoQuests, %gInfoQuests%
	GuiControl,,gInfoLvlUp, %gInfoLvlUp%
	
	GoSub, UpdateFishcageProgress
	Gui, Submit, NoHide

Return

; ======================== Info variables management ====================================================

InitGlobalInfoVars()
{
	global gPauseFlag := 0
	
	global gInfoFishCatched       := 0
	global gInfoCollectionCatched := 0
	global gInfoTreasuresCatched  := 0
	global gInfoFishesInFishcage  := 0
	global gInfoTotalCatched      := 0
	global gInfoCastCount := 0
	global gInfoLost      := 0
	global gInfoQuests    := 0
	global gInfoLvlUp     := 0
}
	
InitGlobalSettingsVars()
{
	global gSettingUsingSpinning     := 0
	global gSettingFishcageCapacity  := 50
	global gSettingLeftPullingLimit  := 4
	global gSettingRightPullingLimit := 16
	global gSettingAgressivity       := 3

}

; ======================== Energy management ====================================================

WaitForFishingScreen()
{
	i := 0
	ColorTolerance := 10
	LeftCornerPearlFound := IsImgTagInRect( "LeftUpperCornedDefImg", 4, 7, 34, 37, ColorTolerance )
	
	while ( not LeftCornerPearlFound )
	{
		sleep, 50
		i++
		If ( i > 20 )
		{
			i := 0
			ColorTolerance := ColorTolerance + 10
		}
		LeftCornerPearlFound := IsImgTagInRect( "LeftUpperCornedDefImg", 4, 7, 34, 37, ColorTolerance )
	}
	
	WriteLineToLogfile( "{WaitForFishingScreen}", "Screen is clear for fishing. Сolorolerance = " . ColorTolerance  )
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
	global gPauseFlag

	CastAgain := 1
	FishOnHook := 0

	WriteLineToLogfile( "{HookTheFish}", "Enter" )
	
	While ( CastAgain and (not FishOnHook) and (not gPauseFlag) ) 
	{
		CastAgain := 0
		CastTheLine()

		WriteLineToLogfile( "{HookTheFish}", "Line casted" )

		gInfoCastCount++
		GoSub, UpdateInfoGui

		If ( isSpinningUsed )
		{
			While ( not IsSpinningBarOn() )
				Sleep, 100

			Click down

			FishOnHook := 0

			WriteLineToLogfile( "{HookTheFish}", "Wait for strike on spinning" )

			while ( (not FishOnHook) and (not CastAgain) )
			{
				FishOnHook := IsPullingBarOn()
				CastAgain := FindImgPosInRect( "CastBtnTag", CastBtnX, CastBtnY, 480, 480, 600, 530 )
				If ( CastAgain ) 
					Click up
			}
			WriteLineToLogfile( "{HookTheFish}", "FishOnHook = " . FishOnHook . "   CastAgain = " . CastAgain . "   gPauseFlag = " . gPauseFlag )
		}
	}

	If ( not isSpinningUsed )
		FishOnHook := WaitForStrike()
		
	WriteLineToLogfile( "{HookTheFish}", "Exit. FishOnHook = " . FishOnHook )
	Return FishOnHook
}

WaitForPullingBar()
{
	i := 0
	PullingBarState := IsPullingBarOn()
	while ( ( not PullingBarState ) and ( i < 1000 ) )
	{
		Sleep, 100
		PullingBarState := IsPullingBarOn()
		i++
	}
}
	
PullingTheFish( LeftPullingLimit, RightPullingLimit, Agressivity )
{
	
	WriteLineToLogfile( "{PullingTheFish}", "Pulling started" )
	CalmCycles := 0
	PrevOverloadState := 0
	PullingPattern := ""
	
	SwitchDirection( PullingDirection )
	; WaitForPullingBar()
	
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
				If ( CalmCycles > Agressivity ) {
					CalmCycles := 0
					LeftPullingLimit--
					RightPullingLimit++
				}
			}

		PullingPattern := PullingPattern . PullingPatternStr(RodOverloadState, PrevRodOverloadState, PullingDirection, PullingProgress, ProgressLogStr, LeftPullingLimit, RightPullingLimit) 
		PrevOverloadState := RodOverloadState
	}
	WriteLineToLogfile( "{PullingTheFish}", "Pulling finished" )
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
			WriteLineToLogfile( "{CastTheLine}", "-> WaitForFishingScreen"  )
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
	global gPauseFlag

	FishOnHook := 0
	While ( (not FishOnHook) and (not gPauseFlag) )
	{
		FishOnHook := isImgTagInRect( "StrikeBtnTag", 480, 480, 600, 530 ) 
		Sleep, 50
	}
	
	If ( FishOnHook )
	{
		WriteLineToLogfile( "{WaitForStrike}", "Fish strike detected!" )
	}
	MouseClick Left
		
	Return FishOnHook
}

; ======================== Fishing management sequence ====================================================

ResultOfFishingDetermination()
{
	global gInfoFishesInFishcage
	global gInfoFishCatched
	global gInfoCollectionCatched
	global gInfoLost
	global gInfoTreasuresCatched

	WriteLineToLogfile( "{ResultOfFishingDetermination}", "Enter" )
	
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
	WriteLineToLogfile( "{ResultOfFishingDetermination}", "Exit" )
}

ManageFishcage()
{
	global gInfoFishesInFishcage := 0
	
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

isImgTagInRect( ImgTagStr, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y, ColorTolerance = 10 )
{
	Return FindImgPosInRect( ImgTagStr, ImgTagX, ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y, ColorTolerance )
}

LocateImgAndClick( ImgTagStr, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y, dx=5, dy=5 )
{
	TagInRectState := FindImgPosInRect( ImgTagStr, ImgTagX, ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y )
	If ( TagInRectState )
		MouseClick, Left, ImgTagX+dX, ImgTagY+dY
		
	Return TagInRectState
}

FindImgPosInRect( ImgTagStr, ByRef ImgTagX, ByRef ImgTagY, RectCorner1X, RectCorner1Y, RectCorner2X, RectCorner2Y, Tolerance = 10 )
{
	Imagesearch, ImgTagX, ImgTagY, X(ectCorner1X), Y(RectCorner1Y), X(RectCorner2X), Y(RectCorner2Y), *%Tolerance% *Trans0xFF0000 %A_ScriptDir%\Images\%ImgTagStr%.png

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
	WriteLineToLogfile( "{IsMessageOn}", "Searching for Ok button" )

	MsgResult := FindImgPosInRect( "InfoOkBtn", OkBtnX, OkBtnY, 250, 250, 450, 450, 50 )
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
	
	Imagesearch, ImgX, ImgY, 1, 1, WindowWidth, WindowHeight, *30 *Trans0xFF0000 %A_ScriptDir%\Images\LeftUpperCornedDefImg.png
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

FindAndActivateGameWindow()
{
	KeywordInBrowserTitle := "- Google Chrome"
	KeywordInGameTabTitle := "Go Fishing"

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
	global gDebugFile
	
	FileAppend, %A_NowUTC% :: %CalledFromAddress% - %StringToWrite%`n, %gDebugFile%
}

WriteLineToDatafile(PullingResult, PullingPattern)
{
	FileAppend, %PullingResult%`t %PullingPattern%`n, %A_ScriptDir%\Pulling_data.log
}

;================== Imported functions =============================