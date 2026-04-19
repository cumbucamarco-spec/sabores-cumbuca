cd /d %~dp0

echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy ..\cardapio_hoje.json cardapio_html.json /Y

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add .

git diff --cached --quiet
IF %ERRORLEVEL%==0 (
    echo Nenhuma alteracao.
) ELSE (
    git commit -m "Atualizacao do site"
    git push
    echo SITE ATUALIZADO!
)

echo =========================
pause