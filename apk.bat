@echo off
setlocal EnableExtensions
pushd "%~dp0"
if errorlevel 1 (
  echo ERRO: nao foi possivel abrir a pasta do projeto.
  exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERRO: Flutter nao esta no PATH. Abra o terminal do Flutter ou adicione flutter\bin ao PATH.
  exit /b 1
)

echo [1/4] Atualizando dependencias...
flutter pub get
if errorlevel 1 exit /b 1

echo [2/4] Executando flutter analyze...
flutter analyze
if errorlevel 1 exit /b 1

echo [3/4] Executando testes Flutter...
flutter test
if errorlevel 1 exit /b 1

echo [4/4] Gerando APK debug...
flutter build apk --debug
if errorlevel 1 exit /b 1

if not exist "dist" mkdir "dist"
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "dist\truco-br-android.apk" >nul
if errorlevel 1 (
  echo ERRO: APK gerado, mas nao foi possivel copia-lo para dist.
  exit /b 1
)

echo APK pronto em:
echo %~dp0dist\truco-br-android.apk
exit /b 0
