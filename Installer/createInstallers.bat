@echo off

REM How to create LesionTracker and OHIF Viewer installers:
REM 1. Install Node.js
REM 2. Install Meteor
REM 3. OPTIONAL: Install Windows 10 SDK for signing (https://go.microsoft.com/fwlink/?LinkID=698771)
REM 4. Run 'npm install -g windows-build-tools' in Node.js command prompt
REM 5. Put all prerequisites under 'Prerequisites' folder
REM 6. Run this script

set APPLICATIONWXS=ViewersWXS
set SIGNTOOL="C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"
set SIGNPFXFILE=""
set SIGNPASS=""
set ISSIGN=false

REM Clear old installers
rmdir /s /q output & mkdir output

REM Create LesionTracker and OHIF Viewer Installers
call :CreateLesionTrackerInstaller
call :CreateOHIFViewerInstaller

exit /B 0

:CreateLesionTrackerInstaller

	echo Creating LesionTracker installer...
	
	set APPLICATIONNAME="LesionTracker"
	set VERSIONNUMBER=1.0.0
	set SRCDIR="C:\Workspace\Viewers\LesionTracker"
	set INSTALLERNAME=LTInstaller
	set INSTALLERSINGLE=LTSingle
	set INSTALLERCOMPLETE=LTComplete
	set UPGRADECODE="83f70f33-3bd9-4aef-9405-fc0361ec2d4f"
	set SERVICESPATH="Services\LesionTracker"

	call :CreateInstaller
	
	exit /B 0

:CreateOHIFViewerInstaller
	echo Creating OHIF Viewer installer...
	
	set APPLICATIONNAME="OHIF Viewer"
	set VERSIONNUMBER=1.0.0
	set SRCDIR="C:\Workspace\Viewers\OHIFViewer"
	set INSTALLERNAME=OHIFViewerInstaller
	set INSTALLERSINGLE=OHIFViewerSingle
	set INSTALLERCOMPLETE=OHIFViewerComplete
	set UPGRADECODE="47f4c60b-d205-4445-8cd7-8ed72efae78c"
	set SERVICESPATH="Services\OHIF Viewer"
	
	call :CreateInstaller
	
	exit /B 0


:CreateInstaller

	REM Build Meteor Server
	cd %SRCDIR%
	rmdir /s /q ..\Installer\build & mkdir ..\Installer\build
	call meteor npm install --production
	set METEOR_PACKAGE_DIRS=..\Packages
	call meteor build --directory ..\Installer\build
	cd ..\Installer\build\bundle\programs\server
	call npm install --production
	cd ..\..\..\..\

	REM Copy Node Windows Service to run installer as a windows service
	cd NodeWindowsService
	call npm install --production
	cd ..
	mkdir build\NodeWindowsService
	xcopy /y /s /e NodeWindowsService build\NodeWindowsService

	REM Copy Services folder that controls to start and stop services
	xcopy /y /s /e %SERVICESPATH% build

	REM Copy Lesion tracker startup and settings file
	xcopy /y orthancDICOMWeb.json build
	xcopy /y mongod.cfg build

	REM Copy LICENSE and Logo files
	xcopy /y LICENSE.rtf build
	xcopy /y logo.ico build
	xcopy /y wix-dialog.bmp build
	xcopy /y wix-top-banner.bmp build

	REM Create Installer Folders
	rmdir /s /q output\%INSTALLERSINGLE% & mkdir output\%INSTALLERSINGLE%
	rmdir /s /q output\%INSTALLERCOMPLETE% & mkdir output\%INSTALLERCOMPLETE%

	REM Create Installer (Single)
	del /q "%APPLICATIONWXS%\BuildDir.wxs"
	call "%WIX%bin\heat.exe" dir build -dr INSTALLDIR -cg MainComponentGroup -var var.SourceDir -out "%APPLICATIONWXS%\BuildDir.wxs" -srd -ke -sfrag -gg -sreg -scom
	call "%WIX%bin\candle.exe" -dSourceDir="build" -dVersionNumber="%VERSIONNUMBER%" -dApplicationName=%APPLICATIONNAME% -dUpgradeCode=%UPGRADECODE% "%APPLICATIONWXS%\*.wxs" -o output\%INSTALLERSINGLE%\ -arch x64 -ext WiXUtilExtension
	call "%WIX%bin\light.exe" -o "output\%INSTALLERSINGLE%\%INSTALLERNAME%-Single-%VERSIONNUMBER%.msi" output\%INSTALLERSINGLE%\*.wixobj -cultures:en-US -ext WixUIExtension.dll -ext WiXUtilExtension

	if "%ISSIGN%"=="true" (
		REM Sign Installer (Single)
		call %SIGNTOOL% sign /f %SIGNPFXFILE% /p %SIGNPASS% /d "%APPLICATIONNAME%" /t http://timestamp.verisign.com/scripts/timstamp.dll /v output\%INSTALLERSINGLE%\%INSTALLERNAME%-Single-%VERSIONNUMBER%.msi
	)

	REM Create Leasion Tracker Bundle Installer with prerequisites (Complete)
	call "%WIX%bin\candle.exe" -dSourceDir="build" -dPreqDir="Prerequisites" -dInstallerPath="output\%INSTALLERSINGLE%\%INSTALLERNAME%-Single-%VERSIONNUMBER%.msi" -dApplicationName=%APPLICATIONNAME% -dUpgradeCode=%UPGRADECODE% BundleWXS\*.wxs -o output\%INSTALLERCOMPLETE%\ -ext WiXUtilExtension -ext WixBalExtension
	call "%WIX%bin\light.exe" -o "output\%INSTALLERCOMPLETE%\%INSTALLERNAME%-Complete-%VERSIONNUMBER%.exe" output\%INSTALLERCOMPLETE%\*.wixobj -cultures:en-US -ext WixUIExtension.dll -ext WiXUtilExtension -ext WixBalExtension

	if "%ISSIGN%"=="true" (
		REM Sign Leasion Tracker Bundle Installer with prerequisites (Complete)
		call "%WIX%bin\insignia.exe" -ib output\%INSTALLERCOMPLETE%\%INSTALLERNAME%-Complete-%VERSIONNUMBER%.exe -o output\%INSTALLERCOMPLETE%\engine.exe
		call %SIGNTOOL% sign /f %SIGNPFXFILE% /p %SIGNPASS% /d "%APPLICATIONNAME%" /t http://timestamp.verisign.com/scripts/timstamp.dll /v output\%INSTALLERCOMPLETE%\engine.exe
		call "%WIX%bin\insignia.exe" -ab output\%INSTALLERCOMPLETE%\engine.exe output\%INSTALLERCOMPLETE%\%INSTALLERNAME%-Complete-%VERSIONNUMBER%.exe -o output\%INSTALLERCOMPLETE%\%INSTALLERNAME%-Complete-%VERSIONNUMBER%.exe
		call %SIGNTOOL% sign /f %SIGNPFXFILE% /p %SIGNPASS% /d "%APPLICATIONNAME%" /t http://timestamp.verisign.com/scripts/timstamp.dll /v output\%INSTALLERCOMPLETE%\%INSTALLERNAME%-Complete-%VERSIONNUMBER%.exe
	)
	
	exit /B 0
