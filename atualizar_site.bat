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
echo INICIANDO BUSCADOR...
echo =========================

:: 🔥 EVITA ABRIR VARIOS BUSCADORES (verifica pelo nome do script)
tasklist /v | find "baixar_pedidos.py" >nul

if %errorlevel%==0 (
echo Buscador ja esta rodando
) else (
start "" /b python "%~dp0baixar_pedidos.py"
)


echo =========================

:: 🔥 IMPORTANTE: NÃO CHAMA A MARINETE (evita loop)

if "%1"=="" pause
