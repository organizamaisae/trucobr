@echo off
setlocal EnableExtensions
set "PROJECT_DRIVE="
for %%D in (Z Y X W V) do if not exist %%D:\ set "PROJECT_DRIVE=%%D:" & goto :map_project
:map_project
if defined PROJECT_DRIVE (
  subst %PROJECT_DRIVE% "%~dp0"
  if errorlevel 1 (
    echo ERRO: nao foi possivel criar uma unidade temporaria para o projeto.
    exit /b 1
  )
  cd /d %PROJECT_DRIVE%\
) else (
  pushd "%~dp0"
  if errorlevel 1 (
    echo ERRO: nao foi possivel abrir a pasta do projeto.
    exit /b 1
  )
)

where flutter.bat >nul 2>&1
if errorlevel 1 (
  echo ERRO: Flutter nao esta no PATH. Abra o terminal do Flutter ou adicione flutter\bin ao PATH.
  goto :fail
)

echo [1/4] Atualizando dependencias...
call flutter.bat pub get
if errorlevel 1 goto :fail

echo [2/4] Executando flutter analyze...
call flutter.bat analyze
if errorlevel 1 goto :fail

echo [3/4] Executando testes Flutter...
call flutter.bat test
if errorlevel 1 goto :fail

echo [4/4] Gerando APK debug...
call flutter.bat build apk --debug
if errorlevel 1 goto :fail

if not exist "dist" mkdir "dist"
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "dist\truco-br-android.apk" >nul
if errorlevel 1 (
  echo ERRO: APK gerado, mas nao foi possivel copia-lo para dist.
  goto :fail
)

echo APK pronto em:
echo %~dp0dist\truco-br-android.apk
if defined PROJECT_DRIVE subst %PROJECT_DRIVE% /d
exit /b 0

:fail
if defined PROJECT_DRIVE subst %PROJECT_DRIVE% /d
echo Falha ao gerar o APK.
exit /b 1
