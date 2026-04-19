cd /d %~dp0

echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy ..\cardapio_hoje.json cardapio_html.json /Y

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add cardapio_html.json

git diff --cached --quiet
IF %ERRORLEVEL%==0 (
    echo Nenhuma alteracao no cardapio.
) ELSE (
    git commit -m "Atualizacao diaria do cardapio"
    git push
    echo SITE ATUALIZADO!
)

echo =========================
pause