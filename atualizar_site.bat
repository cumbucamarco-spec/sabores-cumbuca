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

:: 🔥 AJUSTA AQUI COM SEUS ARQUIVOS REAIS

start "" "..\ligar_marmita.bat"
start "" "..\buscar_pedidos.bat"

echo =========================

if "%1"=="" pause