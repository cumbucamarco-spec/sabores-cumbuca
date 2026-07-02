@echo off
setlocal

cd /d "%~dp0"

echo =========================
echo FECHANDO CARDAPIO...
echo =========================
echo Removendo itens do cardapio publicado.
echo O site deve mostrar apenas a mensagem de remessa encerrada.
echo.

if not exist "cardapio_fechado.json" (
    echo ERRO: arquivo cardapio_fechado.json nao encontrado.
    goto erro
)

py -m json.tool "cardapio_fechado.json" >nul 2>&1
if errorlevel 1 python -m json.tool "cardapio_fechado.json" >nul 2>&1
if errorlevel 1 (
    echo ERRO: cardapio_fechado.json esta com JSON invalido.
    goto erro
)

echo =========================
echo CHECANDO GIT...
echo =========================

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERRO: esta pasta nao parece ser um repositorio Git.
    goto erro
)

git status --porcelain | findstr /R "^UU ^AA ^DD ^DU ^UD ^UA ^AU" >nul
if not errorlevel 1 (
    echo ERRO: existe conflito de Git pendente. Resolva antes de fechar o cardapio.
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
    echo ERRO: o historico local divergiu do GitHub.
    echo Para seguranca, o fechamento foi cancelado.
    echo Rode: git status
    goto erro
)

echo.
echo =========================
echo COPIANDO CARDAPIO FECHADO...
echo =========================

copy /Y "cardapio_fechado.json" "cardapio_html.json" >nul
if errorlevel 1 (
    echo ERRO AO COPIAR O CARDAPIO FECHADO.
    goto erro
)

echo Conteudo publicado localmente:
type "cardapio_html.json"
echo.

git diff --quiet -- cardapio_html.json
if not errorlevel 1 (
    echo O cardapio ja estava fechado nesta versao.
    goto enviar
)

git add cardapio_html.json
git commit -m "Loja fechada %date% %time%"
if errorlevel 1 goto erro_git

:enviar
echo.
echo =========================
echo ENVIANDO FECHAMENTO PARA O GITHUB...
echo =========================

git push origin main
if errorlevel 1 goto erro_git

echo.
echo =========================
echo VERIFICANDO SITE PUBLICADO...
echo =========================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$local = (Get-FileHash -Algorithm SHA256 -LiteralPath 'cardapio_html.json').Hash; $ok = $false; for ($i = 1; $i -le 18; $i++) { try { $url = 'https://cumbucamarco-spec.github.io/sabores-cumbuca/cardapio_html.json?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $tmp = Join-Path $env:TEMP ('cardapio_fechado_pages_' + [guid]::NewGuid() + '.json'); Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $tmp -TimeoutSec 15 | Out-Null; $remote = (Get-FileHash -Algorithm SHA256 -LiteralPath $tmp).Hash; Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue; if ($remote -eq $local) { $ok = $true; break } } catch { }; Start-Sleep -Seconds 10 }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
    echo ERRO: GitHub recebeu o envio, mas a pagina publica ainda nao publicou o fechamento.
    echo Aguarde alguns minutos e tente novamente.
    goto erro
)

echo.
echo =========================
echo CARDAPIO FECHADO COM SUCESSO!
echo =========================
echo Itens removidos. A pagina publica mostra a mensagem de remessa encerrada.

echo.
echo =========================
echo ENCERRANDO BUSCADORES E API...
echo =========================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$processos = Get-CimInstance Win32_Process | Where-Object { $cmd = $_.CommandLine; $_.ProcessId -ne $PID -and $cmd -and ($cmd -like '*C:\exe4_2\BOT-WHATSAPP\baixar_pedidos.py*' -or $cmd -like '*cd /d C:\exe4_2\novo_app*' -or $cmd -like '*servidor.py*') }; if (-not $processos) { Write-Host 'Nenhum buscador/API encontrado em execucao.'; exit 0 }; foreach ($p in $processos) { Write-Host ('Encerrando ' + $p.Name + ' PID ' + $p.ProcessId); Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }"

echo.
echo =========================
echo FECHAMENTO FINALIZADO!
echo =========================
echo Cardapio removido, site conferido, buscador e API encerrados.
powershell -NoProfile -Command "Start-Sleep -Seconds 3" >nul
exit

:erro_git
echo.
echo ERRO: comando Git falhou.

:erro
echo.
echo FECHAMENTO CANCELADO COM SEGURANCA.
if "%1"=="" pause
exit /b 1
