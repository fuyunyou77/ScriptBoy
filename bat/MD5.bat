@echo off
for %%f in (*.bin) do (
    echo Hashing %%f :
    certutil -hashfile "%%f" MD5
    echo ----------------------
)
pause