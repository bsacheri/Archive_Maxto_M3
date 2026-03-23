@ECHO OFF
REM This will copy files from the Maxto camera to a subfolder under
REM the drive letter an path the batch file is launched from.
REM It uses the date pattern in the filename to determine what folder 
REM to copy the files to.  If it is looking for a folder named 
REM 20220429 and finds 20220429_North_Park it is smart enough
REM to use the existing folder.
REM
REM This will show you the dates of the media currently stored on the camera.
REM The user can use this to determine how many days back they want to copy.
REM
REM This method does not copy files as fast and bulk copying with File Explorer,
REM but it is automated and you don't have to focus on it while you get other 
REM things done. 
REM 
REM Ben Sacherich - 4/29/2022 - https://www.facebook.com/groups/maxtom3
REM Shared online:  https://github.com/bsacheri/Archive_Maxto_M3
REM 				https://pastebin.com/LT5XESs0
REM 				https://www.facebook.com/groups/maxtom3/posts/7992261460846946/
REM   				https://www.facebook.com/groups/maxtom3/posts/34348792078100525
REM
REM BS 11/11/2022:  Implemented filelist.txt that avoids the long delay
REM 				of the previous method when starting the loop.
REM 	Also tested using Robocopy and discovered that the copy speed was 
REM 	basically the same as xcopy.  It does give a nice percentage indicator
REM		for each file but I felt to stick with xcopy because everyone has it.
REM 	If you want more speed the best thing is to use a faster USB port.
REM 
REM BS 11/19/2023:  It will now show a summary of the past 15 recording dates
REM 	with the number of days back, and the number of files for that date.
REM 	This is shown before the user selects how many days back to begin copying.
REM		You must include FolderDayQty.ps1 in the same folder as this batch file,
REM		(https://pastebin.com/KwZQk3uh), 
REM		or you can comment out the call to powershell and let the old method run.
REM
REM Note: If the clock in your Maxto M3 is incorrect (like after daylight savings) you 
REM 	should use the app to link to the camera and that should re-sync the clock.  If 
REM 	you have already recorded video and you want to correct the time shown in the 
REM 	file properties and the filenames (but not the overlay shown on screen) then you 
REM 	can run a Python script I made called TimeStamp_Adjust.py.   
REM 	A good way to know how much your M3 clock is off is to find an image where your 
REM 	phone screen is in view, like when you are unlocking the phone.

REM Show the name of this batch file in the command window title bar
TITLE %0

REM Instead of maintaining separate files for MOVIE and PHOTO files,
REM I decided to set variables so I could easily deploy updates for
REM either file type.
REM set media=PHOTO
REM set ext=jpg
set ext=mp4
set media=MOVIE


set folderpath=%~dp0
set logpath="%folderpath%MaintLog.txt"

REM  Set your source and destination folders.  
REM  ### You must update the following line with the drive letter of your USB reader. ###
set SourceFolder=E:\CARDV\%media%
set TargetFolder=%folderpath%%media%

REM ## See the "Continue:" section further down to adjust the folder name that is the root of the daily folders.

if not exist %SourceFolder% (
	REM Check the F: drive if not found on E:
	set SourceFolder=F:\CARDV\%media%
)
if not exist %SourceFolder% (
	ECHO.
	ECHO   WARNING:  You must have the camera connected with a folder named %SourceFolder% for this to work.
	ECHO 
	pause
	goto :eof
)

if not exist %TargetFolder% (
	ECHO.
	ECHO   WARNING:  You must have the backup drive connected with folder %TargetFolder% available for this to work.
	ECHO 
	pause
	goto :eof
)

TITLE %0 reading from %SourceFolder%

REM _________________________________________________________________________________________________________
REM First show the the user the dates of the media currently stored on the camera.

ECHO Today is %Date%.
ECHO.
ECHO [101;93m Source file count per date: [0m
REM  Count the number of files per date.
REM BS 11/19/2023:  Added PowerShell script to get the number of days back each recording sessions is and limit it to 15 rows.
powershell -ExecutionPolicy RemoteSigned -File FolderDayQty.ps1 %SourceFolder%
goto :GetDays

REM --- Use this method to list the file count per folder without the day count for the last 10 dates.
REM --- The advantage of this method is no dependency on the PowerShell script file: FolderDayQty.ps1
REM  https://stackoverflow.com/a/21380484
REM How to change text colors in a command prompt window:  https://stackoverflow.com/a/38617204/1898524
setlocal enableextensions enabledelayedexpansion
set "count=0"
set "previous="
set "dates=0"
for /f %%f in ('dir "%SourceFolder%" /a-d /tc /o-d ^| findstr /r /c:"^[^ ]"') do (
	if "!previous!"=="%%f" ( 
		set /a "count+=1" 
	) else (
		if defined previous echo !previous! : !count!
		set "previous=%%f"
		set "count=1"
		set /a "dates+=1" 
	)
	if "!dates!"=="11" goto :GetDays
)
if defined previous echo !previous! : !count!
endlocal
ECHO.


REM  Prompt the user to enter the number of days to go back from today to be included 
REM  in the copy.  A postive number will be converted to a negative number.
:GetDays
set qty=3
set /p "qty=How many many days do you want to copy back from?  [%qty%] : "
REM Change the entered quantity into a negative number.
if %qty% GTR 0 set qty=-%qty%


SET "startTime=%time: =0%"
ECHO [32m
REM COLOR 0A
Echo ----------------------------------------------------------- >> %logpath%
Echo ===] %~nx0 started %date% at %time% >> %logpath%
Echo ===] %~nx0 started at %time% 

REM  This section calculates a formatted date that is %qty% days ago.
set date1=today
set separator=/
if /i "%date1%" EQU "TODAY" (set date1=now) else (set date1="%date1%")
echo >"%temp%\%~n0.vbs" s=DateAdd("d",%qty%,%date1%)
echo>>"%temp%\%~n0.vbs" d=weekday(s)
echo>>"%temp%\%~n0.vbs" WScript.Echo year(s)^&_
echo>>"%temp%\%~n0.vbs"         right(100+month(s),2)^&_
echo>>"%temp%\%~n0.vbs"         right(100+day(s),2)^&_
echo>>"%temp%\%~n0.vbs"         d
for /f %%a in ('cscript //nologo "%temp%\%~n0.vbs"') do set result=%%a
del "%temp%\%~n0.vbs"
endlocal& (
set "YY=%result:~0,4%"
set "MM=%result:~4,2%"
set "DD=%result:~6,2%"
set "daynum=%result:~-1%"
)
set "day=%MM%%separator%%DD%%separator%%YY%"
REM ^^^ If your country has a different order of date fields at the command prompt
REM 	then you may have to alter this formula.  In the USA it is MM/DD/YY

echo.
echo Searching for new files since [0m%day%[32m in %SourceFolder%
REM Show a count of the number of files that will be processed.
xcopy /S /L %SourceFolder%\*.%ext% /d:%day% | find "File(s)" >> %logpath%
xcopy /S /L %SourceFolder%\*.%ext% /d:%day% | find "File(s)"  
REM echo (It may hang here for a minute before you see any action)

setlocal enableDelayedExpansion
REM for /f "delims=" %%a in ('forfiles /p %SourceFolder% /d %day% /m *.%ext% /c "cmd /c echo @path"') do (
	REM REM echo %%~na
	REM set "fname=%%~na"
	REM REM Call a routine that copies each file.
	REM call :continue	
REM )
xcopy /S /L %SourceFolder% /d:%day% | find "File(s)" /v  > %folderpath%\filelist.txt
ECHO 

sort %folderpath%\filelist.txt > %folderpath%\sortedfilelist.txt

for /f "delims=" %%a in (%folderpath%\sortedfilelist.txt) do (
REM for /f "delims=" %%a in ('xcopy /S /L f:\cardv\movie /d:11/4/2022 | find "File(s)" /v') do (
	REM echo %%a	"%%~na" 
	set "fname=%%~na"
	REM pause
	REM Call a routine that copies each file.
	call :continue	
)

REM =========================================================================================================
ECHO 

REM Pause if there was an error.
IF %ERRORLEVEL% NEQ 0 (
	COLOR 47
	ECHO ### Error running %0 >> %logpath%	
	ECHO ### Error running %0 
	Pause
)


REM https://stackoverflow.com/a/9935540/1898524
REM Get end time:
SET "endTime=%time: =0%"
REM Get elapsed time:
SET "end=!endTime:%time:~8,1%=%%100)*100+1!"  &  set "start=!startTime:%time:~8,1%=%%100)*100+1!"
SET /A "elap=((((10!end:%time:~2,1%=%%100)*60+1!%%100)-((((10!start:%time:~2,1%=%%100)*60+1!%%100), elap-=(elap>>31)*24*60*60*100"
REM Convert elapsed time to HH:MM:SS:CC format:
SET /A "cc=elap%%100+100,elap/=100,ss=elap%%60+100,elap/=60,mm=elap%%60+100,hh=elap/60+100"
SET "elapsedTime=%hh:~1%%time:~2,1%%mm:~1%%time:~2,1%%ss:~1%%time:~8,1%%cc:~1%"

REM Delete the file list.
IF EXIST %folderpath%\filelist.txt DEL %folderpath%\filelist.txt
IF EXIST %folderpath%\sortedfilelist.txt DEL %folderpath%\sortedfilelist.txt
																			

ECHO.  [104;97m
ECHO ----------------------------------------------------------------------------
ECHO Maxto M3 archive completed at %date% %time% in %elapsedTime%  >> %logpath%
ECHO   Maxto M3 archive completed at %date% %time% in %elapsedTime%     
ECHO ---------------------------------------------------------------------------- [0m
ECHO.>> %logpath%
ECHO.
pause
exit /b


REM ============
:continue
REM ============
REM This section is called for every file that needs to be copied.
REM echo "%fname%" "%fname:~0,8%"
set datefolder=%fname:~0,8%
REM dir .\%media%\%datefolder%*
REM echo if not exist .\%media%\%datefolder%* (
if not exist .\%media%\%datefolder%* (
	echo -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	echo -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-  >> %logpath%
	echo Creating folder: .\%media%\%datefolder%_ >> %logpath%
	echo [37mCreating folder: .\%media%\%datefolder%_ [32m
	md .\%media%\%datefolder%_
)

REM Copy the file to the folder.	
for /D %%i in ("%TargetFolder%\%datefolder%*") do (
	if not exist %%i\%fname%.%ext% (
		echo XCOPY /D %SourceFolder%\%fname%.%ext% %%i >> %logpath%
  		echo XCOPY %SourceFolder%\%fname%.%ext% to %%i
		XCOPY /D "%SourceFolder%\%fname%.%ext%" "%%i" > nul
		IF %ERRORLEVEL% NEQ 0 (
			COLOR 47
			ECHO ### Error copying %SourceFolder%\%fname%.%ext% >> %logpath%	
			ECHO ### Error copying %SourceFolder%\%fname%.%ext%
			Pause
		)		
	) else (
		ECHO %fname%.%ext% already exists in %%i 				>> %logpath%
		ECHO  [33m%fname%.%ext% already exists in %%i [32m
	)
	REM pause
)
goto :eof


:eof
echo EOF
pause
exit /b

