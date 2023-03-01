@echo off
cls
SET OUTPUTFILENAME=MinipanzerGUI.exe

del *.map
del *.obj
del %OUTPUTFILENAME%
rcc Icon.rc
dfl Icon.res -gui -of%OUTPUTFILENAME% -release Minipanzer_GUIServer.d Minipanzer_Configuration.d PEInfo.d
del *.map
del *.obj
PAUSE