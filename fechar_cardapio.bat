@echo off

cd /d %~dp0

echo =========================
echo FECHANDO LOJA...
echo =========================

copy /Y "cardapio_fechado.json" "cardapio_html.json" >nul

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add . >nul 2>&1
git commit -m "Loja fechada %date% %time%" >nul 2>&1
git push origin main >nul 2>&1

exit
