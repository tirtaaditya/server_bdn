@echo off
setlocal EnableDelayedExpansion

set input_file=server.json
set temp_file=server_temp.json

:loop
echo.

set name=
set ip=
set started=0

set "jam=[%TIME:~0,8%]"

if exist %temp_file% del %temp_file%
> %temp_file% echo [

for /f "usebackq delims=" %%L in ("%input_file%") do (
    set "line=%%L"

    REM Ambil server_name
    echo !line! | findstr /i "\"server_name\"" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:" %%A in ("!line!") do (
            set "raw_name=%%A"
            set "raw_name=!raw_name:"=!"
            set "raw_name=!raw_name: (OK)=!"
            set "raw_name=!raw_name: (ERROR)=!"
            set "raw_name=!raw_name:,=!"
            call :trimleft "!raw_name!" name
        )
    )

    REM Ambil server_ip dan ping
    echo !line! | findstr /i "\"server_ip\"" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=:" %%B in ("!line!") do (
            set "raw_ip=%%B"
            set "ip=!raw_ip:"=!"
            set "ip=!ip:,=!"
            set "ip=!ip: =!"
        )

        ping -n 1 -w 1000 !ip! | findstr "TTL=" >nul
        if !errorlevel! == 0 (
            set "status=(OK)"
        ) else (
            set "status=(ERROR)"
        )

        echo !jam! !name! !status!

        if !started! == 1 (
            >> %temp_file% echo     },
        ) else (
            set started=1
        )

        >> %temp_file% echo     {
        >> %temp_file% echo         "server_name": "!name! !status!",
        >> %temp_file% echo         "server_ip": "!ip!"
    )
)

>> %temp_file% echo     }
>> %temp_file% echo ]

move /Y %temp_file% %input_file% >nul

REM Git Push
git add server.json >nul 2>&1
git commit -m "Update status server [%DATE% %TIME%]" >nul 2>&1
git push origin main >nul 2>&1

echo !jam! Push Sukses
timeout /t 10 >nul
goto loop

REM === TRIM LEFT FUNCTION ===
:trimleft
setlocal EnableDelayedExpansion
set "string=%~1"
:trimloop
if not "!string:~0,1!"==" " goto :done
set "string=!string:~1!"
goto trimloop
:done
endlocal & set "%~2=%string%"
exit /b
