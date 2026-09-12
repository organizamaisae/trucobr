@echo off
setlocal EnableExtensions
pushd "%~dp0"
if errorlevel 1 (
  echo ERRO: nao foi possivel abrir a pasta do projeto.
  exit /b 1
)

echo [1/4] Verificando repositorio...
git.exe rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo ERRO: esta pasta nao e um repositorio Git.
  exit /b 1
)

set "COMMIT_MESSAGE=%~1"
if "%COMMIT_MESSAGE%"=="" set "COMMIT_MESSAGE=Atualiza Truco BR"

echo [2/4] Adicionando arquivos (segredos locais ignorados pelo .gitignore)...
git.exe add -A
if errorlevel 1 (
  echo ERRO: nao foi possivel preparar os arquivos.
  exit /b 1
)

git.exe diff --cached --quiet
if not errorlevel 1 (
  echo Nenhuma alteracao nova para enviar.
  exit /b 0
)

echo [3/4] Criando commit: %COMMIT_MESSAGE%
git.exe commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 (
  echo ERRO: o commit falhou.
  exit /b 1
)

echo [4/4] Enviando para origin/main...
git.exe push origin main
if errorlevel 1 (
  echo ERRO: o envio falhou. Confira login, permissao e remote origin.
  exit /b 1
)

echo Commit e push concluidos.
exit /b 0
