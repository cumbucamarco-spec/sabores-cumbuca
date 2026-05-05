@echo off
cd /d %~dp0

echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy /Y "..\cardapio_hoje.json" "cardapio_html.json"

if not exist "cardapio_html.json" (
echo ERRO AO COPIAR O CARDAPIO!
pause
exit /b
)

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add .

git commit -m "Atualizacao do site %date% %time%" 2>nul

git push origin main

echo SITE ATUALIZADO!

echo =========================
echo INICIANDO SISTEMAS...
echo =========================

:: 🔥 LIGA O BOT WHATSAPP
start "" "..\BOT-WHATSAPP\Ligar_Marinete.bat"

:: 🔥 INICIA BUSCADOR DE PEDIDOS (PYTHON)
start "" python baixar_pedidos.py

echo =========================

if "%1"=="" pause
