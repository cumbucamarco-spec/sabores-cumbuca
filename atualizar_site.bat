@echo off
setlocal

cd /d "%~dp0"

echo =========================
echo ATUALIZANDO CARDAPIO...
echo =========================

if not exist "..\cardapio_hoje.json" (
    echo.
    echo ERRO: arquivo ..\cardapio_hoje.json nao encontrado.
    goto erro
)

py -m json.tool "..\cardapio_hoje.json" >nul 2>&1
if errorlevel 1 python -m json.tool "..\cardapio_hoje.json" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERRO: cardapio_hoje.json esta com JSON invalido.
    goto erro
)

echo.
echo =========================
echo CHECANDO GIT...
echo =========================

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERRO: esta pasta nao parece ser um repositorio Git.
    goto erro
)

git status --porcelain | findstr /R "^UU ^AA ^DD ^DU ^UD ^UA ^AU" >nul
if not errorlevel 1 (
    echo.
    echo ERRO: existe conflito de Git pendente. Resolva antes de publicar.
    git status --short
    goto erro
)

git rebase --abort >nul 2>&1

echo.
echo =========================
echo BAIXANDO ULTIMA VERSAO...
echo =========================

git fetch origin main
if errorlevel 1 goto erro_git

git merge --ff-only origin/main
if errorlevel 1 (
    echo.
    echo ERRO: o historico local divergiu do GitHub.
    echo Para seguranca, o script nao vai fazer rebase automatico nem sobrescrever nada.
    echo Rode: git status
    goto erro
)

echo.
echo =========================
echo COPIANDO CARDAPIO...
echo =========================

copy /Y "..\cardapio_hoje.json" "cardapio_html.json" >nul
if errorlevel 1 (
    echo.
    echo ERRO AO COPIAR O CARDAPIO.
    goto erro
)

git diff --quiet -- cardapio_html.json
if not errorlevel 1 (
    echo.
    echo Nada mudou no cardapio. Site ja esta com esta versao.
    goto enviar
)

git add cardapio_html.json
git commit -m "Atualizacao do cardapio %date% %time%"
if errorlevel 1 goto erro_git

:enviar
echo.
echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

git push origin main
if errorlevel 1 goto erro_git

echo.
echo =========================
echo VERIFICANDO SITE PUBLICADO...
echo =========================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$local = (Get-FileHash -Algorithm SHA256 -LiteralPath 'cardapio_html.json').Hash; $ok = $false; for ($i = 1; $i -le 18; $i++) { try { $url = 'https://cumbucamarco-spec.github.io/sabores-cumbuca/cardapio_html.json?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $tmp = Join-Path $env:TEMP ('cardapio_pages_' + [guid]::NewGuid() + '.json'); Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $tmp -TimeoutSec 15 | Out-Null; $remote = (Get-FileHash -Algorithm SHA256 -LiteralPath $tmp).Hash; Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue; if ($remote -eq $local) { $ok = $true; break } } catch { }; Start-Sleep -Seconds 10 }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
    echo.
    echo ERRO: GitHub recebeu o envio, mas a pagina publica ainda nao publicou o cardapio novo.
    echo Aguarde alguns minutos e tente novamente.
    goto erro
)

:sucesso
echo.
echo =========================
echo SITE ATUALIZADO!
echo =========================
if "%1"=="" pause
exit /b 0

:erro_git
echo.
echo ERRO: comando Git falhou.

:erro
echo.
echo PUBLICACAO CANCELADA COM SEGURANCA.
if "%1"=="" pause
exit /b 1
