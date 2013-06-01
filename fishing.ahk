	SetWorkingDir, %A_ScriptDir%
	SetBatchLines, -1

	DebugFile = %A_ScriptDir%\Report_Run_%A_Now%.log
	DataFile = %A_ScriptDir%\Pulling_data.log
	WndTitleKeyword := "Go Fishing"
	BrowserTitleKeyword := "- Google Chrome"
	
	WriteLineToLogfile( A_LineNumber, "=========================" )
	WriteLineToLogfile( A_LineNumber, "====== Starting up ======" )

	;== SetupEnvironment()
	FindAndActivateGameWindow(BrowserTitleKeyword, WndTitleKeyword)
	GetGameWindowDimensions()
	SetupUpperLeftCorner()
	
	SellAllFish()
	FishesInFishcage := 0
	FishcageCapacity := 50
	CastCount :=  0

StartFishing:

	CastALine()
	CastCount :=  CastCount + 1

	WaitForStrike()
	
	Pattern := PullingTheFish()

	PullingResult := -1
	While (PullingResult = -1)
		If (IsFishCatched()) {
			PullingResult := "`nCatched"
			FishesInFishcage := FishesInFishcage + 1
		}
		Else
			If (IsCollectionCatched())
				PullingResult := "`nCollection"
			Else
				If (IsMessageOn())
					PullingResult := "`nLost"

	WriteLineToDatafile( PullingResult, Pattern )
	
	If ( FishesInFishcage >= FishcageCapacity )
	{
		SellAllFish()
		FishesInFishcage := 0
	}

	; If ( CastCount >= 10 )
		; GoTo, EndScript
		
	Sleep, 1000

	GoTo, StartFishing

^x::
EndScript:

ExitApp

; ======================== Body end ====================================================

WaitForPullingBar()
{
	i := 0
	while ( ( not IsPullingBarOn() ) and ( i < 1000 ) )
	{
		i := i + 1
	}
}
	
PullingTheFish()
{
	RightPullingLimit := 16
	LeftPullingLimit  := 4
	PrevOverloadState := 0
	PullingPattern := ""
	
	ProgressLogStr := "`t" . LeftPullingLimit . " <-> " . RightPullingLimit

	SwitchDirection( PullingDirection )
	WaitForPullingBar()
	
	PullingProgress := GetPullingBarProgress( PullingDirection, 0, "init")
	PullingPattern := PullingPattern 
					. "`n" . A_NowUTC . " . " 
					. (0 ? "#" : " ") 
					. (PrevOverloadState ? "+ " : "  ") 
					. (PullingDirection ? "---> " : "<--- ") 
					.  PullingProgress
					.  ProgressLogStr

	While ( IsPullingBarOn() )
	{
		RodOverloadedState := isRodOverloaded()
		PullingProgress := GetPullingBarProgress( PullingDirection, RodOverloadedState )

		If ( RodOverloadedState )
		{
			If (!PrevOverloadState)
			{
				LeftPullingLimit := LeftPullingLimit + 1
				RightPullingLimit := RightPullingLimit - 1
			}
		}

		If ( (PullingDirection = 0) and ( PullingProgress < LeftPullingLimit ) )
			SwitchDirection( PullingDirection )
		Else
			If ( (PullingDirection = 1) and ( PullingProgress > RightPullingLimit ) )
				SwitchDirection( PullingDirection )

		ProgressLogStr := "`t" . LeftPullingLimit . " <-> " . RightPullingLimit
		PullingPattern := PullingPattern 
						. "`n" . A_NowUTC . " : " 
						. (RodOverloadedState ? "#" : " ") 
						. (PrevOverloadState ? "+ " : "  ") 
						. (PullingDirection ? "---> " : "<--- ") 
						.  PullingProgress
						.  ProgressLogStr

		PrevOverloadState := RodOverloadedState
	}
	; WriteLineToLogfile( "{PullingTheFish}", "Pulling finished" )
	Return PullingPattern
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

MakeLogStrOfGetPulBarProgr(Stage, i, PLFlag, LFlag, PRFlag, RFlag, Progr)
{
	Return "`n -" . Stage . "-" . i . "- " . PLFlag . "->" . LFlag . " " . PRFlag . "<-" . RFlag . " = " . Progr 
}

GetPullingBarProgress( PullingDirection, OverloadingFlag, isNewRun = 0 )
{
	static LeftBarLimit  := 265
	static RightBarLimit := 485
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
			StartingPosition := RightBarLimit
			StartingProgress := 20
			ComparitionAnswer := 0
		}
		Else
		{
			OperationSign := 1
			StartingPosition := LeftBarLimit
			StartingProgress := 0
			ComparitionAnswer := 1
		}

		Loop, 20
		{
			ProgressDelta := OperationSign * A_Index
			ColorFlagOnPos := TestPixelColor( StartingPosition + ProgressDelta * 12, 460, 0x00CC00)
			If ( ColorFlagOnPos != ComparitionAnswer )
				Break
		}

		ProgressValue := StartingProgress + ProgressDelta
	}
	PrevProgressValue := ProgressValue
	
	Return ProgressValue
}

IsPullingBarOn()
{
	; Also can be used points 255, 455 and 495, 455
	If (    TestPixelColor( 199, 455, 0x0 ) 
		and TestPixelColor( 551, 455, 0x0 ) )
	{
		; WriteLineToLogfile( "{IsPullingBarOn}", "Pulling bar is ON" )
		Return 1
	}
	else
	{
		; WriteLineToLogfile( "{IsPullingBarOn}", "Pulling bar is OFF" )
		Return 0
	}
}

TestPixelColor(PixelX, PixelY, TestColor)
{
	PixelGetColor, PixelColor, X(PixelX), Y(PixelY)
	; WriteLineToLogfile( "{TestPixelColor}", "Pixel on " . PixelX . " is " . PixelColor )
	If (PixelColor = TestColor)
		Return 1
	Else
		Return 0
}

CastALine()
{
	Imagesearch, CastBtnX, CastBtnY, X(480), Y(480), X(600), Y(530), *30 *Trans0xFF0000 %A_ScriptDir%\Images\CastBtnTag.png
	WriteLineToLogfile( "{CastALine}", "Cast button on " . CastBtnX . ", " . CastBtnY )

	Sleep, 500
	MouseClick Left, CastBtnX, CastBtnY
	MouseMove, CastBtnX, CastBtnY - 150
}

WaitForStrike()
{
	While ( not isImgTagInRect( "StrikeBtnTag", 480, 480, 600, 530 ) ) 
		Sleep, 50

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
	Imagesearch, ImgTagX, , X(ectCorner1X), Y(RectCorner1Y), X(RectCorner2X), Y(RectCorner2Y), *30 *Trans0xFF0000 %A_ScriptDir%\Images\%ImgTagStr%.png

	If ( ImgTagX > 1 )
		TagInRectState := 1
	Else
		TagInRectState := 0
		
	; WriteLineToLogfile( "{isImgTagInRect}", ImgTagStr . " searching result => " . TagInRectState  )

	Return TagInRectState
}

IsFishCatched() 
{
	CatchedResult := 0

	If (   isImgTagInRect( "NormalCatchTag", 300, 100, 450, 200 ) 
		or isImgTagInRect( "CatchTagRecord", 300, 100, 450, 200 ) 
		or isImgTagInRect( "TrophyCatchTag", 300, 100, 450, 200 ))
	{
		UncheckFishInfoSharingBox()
		MouseClick, Left, X(380), Y(450)
		CatchedResult := 1
		WriteLineToLogfile( "{IsFishCatched}", "Normal fish catched." )
	}
	
	Return CatchedResult
}

UncheckFishInfoSharingBox()
{
	If ( isImgTagInRect( "ShareFishCheckBox", 180, 430, 230, 470 ) )
	{
		WriteLineToLogfile( "{IsFishCatched}", "Sharing CheckBox unchecked." )
		MouseClick, Left, X(200), Y(450)
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
	}
	Else
	{
		If ( isImgTagInRect( "CatchTagCollectionFull", 150, 130, 350, 230 ) )
		{
			WriteLineToLogfile( "{IsCollectionCatched}", "Collection item catched. One more Collection complited." )
			CatchedResult := 2
			MouseClick, Left, X(250), Y(450)
		}
	}
	Return CatchedResult
}

IsMessageOn() 
{
	MsgResult := 0
	Imagesearch, OkBtnX, OkBtnY, X(250), Y(250), X(450), Y(450), *30 *Trans0xFF0000 %A_ScriptDir%\Images\InfoOkBtn.png
	If (OkBtnX>0)
	{
		WriteLineToLogfile( "{IsMessageOn}", "Message detected. Ok button on " . OkBtnX . ", " . OkBtnY )
		MsgResult := 1
		MouseClick, Left, OkBtnX+20, OkBtnY+20
	}
	Return MsgResult
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