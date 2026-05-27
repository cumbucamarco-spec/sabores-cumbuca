@echo off

:: ==================================================
:: 📂 DEFINE PASTA
:: ==================================================

cd /d "%~dp0"

echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy /Y "..\cardapio_hoje.json" "cardapio_html.json"

if not exist "cardapio_html.json" (

    echo.
    echo ERRO AO COPIAR O CARDAPIO!
    pause
    exit /b
)

echo.
echo =========================
echo SINCRONIZANDO E ENVIANDO...
echo =========================

git add .
git commit -m "Atualizacao do site %date% %time%" 2>nul

:: Adicione estas duas linhas antes do push para evitar erros:
git pull origin main --rebase
git push origin main

echo.
echo =========================
echo SITE ATUALIZADO!
echo =========================

:: ==================================================
:: 🔥 NÃO INICIA MAIS NADA
:: Tudo agora é controlado pela Marinete
:: ==================================================

if "%1"=="" pause