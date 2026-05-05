cd /d %~dp0

echo =========================
echo FECHANDO LOJA...
echo =========================

copy cardapio_fechado.json cardapio_html.json /Y

echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git add .

git diff --cached --quiet
IF %ERRORLEVEL%==0 (
    echo Nenhuma alteracao.
) ELSE (
    git commit -m "Loja fechada automaticamente"
    git push
)

exit