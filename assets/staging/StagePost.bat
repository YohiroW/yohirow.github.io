echo off

rem Copy *.md file in current folder to /post folder
rem Source folder should be ..\assets\staging
rem Destination folder should be ..\..\_posts

set SOURCE_FOLDER=%~dp0
set DESTINATION_FOLDER=%~dp0\..\..\_posts

for /r "%SOURCE_FOLDER%" %%f in (*.md) do (
    copy "%%f" "%DESTINATION_FOLDER%"
)


