<<<<<<< HEAD
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

=======
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

>>>>>>> 283c1c9efbe98e45384772404245cf7fc4b776bb
exit