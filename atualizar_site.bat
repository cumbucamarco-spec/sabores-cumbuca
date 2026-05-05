@echo off
cd /d %~dp0

echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy /Y "..\cardapio_hoje.json" "cardapio_html.json"

if not exist "cardapio_html.json" (
echo ERRO: nao foi possivel copiar o arquivo!
pause
exit /b
)

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add .

REM força commit mesmo se o Git nao detectar mudanca
git commit -m "Atualizacao do site %date% %time%" 2>nul

REM garante que esta na branch correta
git branch | find "main" >nul
IF %ERRORLEVEL%==0 (
git push origin main
) ELSE (
git push origin master
)

echo =========================
echo SITE ATUALIZADO!
echo =========================

if "%1"=="" pause
