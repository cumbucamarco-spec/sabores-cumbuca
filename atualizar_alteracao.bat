@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0"

:: =====================================================
:: CONFIGURACOES DE SEGURANCA
:: =====================================================
:: Impede que o Git fique esperando login/senha para sempre
:: (isso e o que provavelmente travava o envio quando o bat
:: era chamado escondido, sem ninguem ver o prompt pedindo credencial)
set GIT_TERMINAL_PROMPT=0
set GIT_ASKPASS=

set "LOGFILE=%~dp0log_atualizacao.txt"
set "LOCKDIR=%~dp0.atualizacao.lock"

call :log "=========================================="
call :log "INICIANDO atualizar_alteracao.bat"

:: =====================================================
:: 0. TRAVA DE EXECUCAO SIMULTANEA
:: =====================================================
:: mkdir e atomico no Windows: se a pasta ja existe, outra
:: instancia deste script esta rodando (ou travou antes).
mkdir "%LOCKDIR%" 2>nul
if errorlevel 1 (
    set "LOCK_OK=0"
) else (
    set "LOCK_OK=1"
)

if "!LOCK_OK!"=="0" (
    call :log "Lock ja existe. Verificando se esta desatualizado (travado ha muito tempo)..."

    set "LOCK_IDADE_MIN=999"
    for /f %%A in ('powershell -NoProfile -Command "try { $dt=(Get-Item -LiteralPath '%LOCKDIR%').LastWriteTime; [int]([math]::Floor(((Get-Date)-$dt).TotalMinutes)) } catch { 999 }" 2^>nul') do set "LOCK_IDADE_MIN=%%A"

    call :log "Idade do lock (minutos): !LOCK_IDADE_MIN!"

    if !LOCK_IDADE_MIN! GTR 20 (
        call :log "Lock com mais de 20 minutos. Considerado residuo de execucao anterior (travada/interrompida). Removendo."
        rmdir /s /q "%LOCKDIR%" >nul 2>&1
        mkdir "%LOCKDIR%" 2>nul
        if not errorlevel 1 set "LOCK_OK=1"
    )
)

if "!LOCK_OK!"=="0" (
    call :log "ERRO: ja existe uma atualizacao em andamento (lock ativo)."
    echo.
    echo ERRO: ja existe uma atualizacao em andamento.
    echo Se tiver certeza de que nao ha nenhuma rodando, apague a pasta:
    echo   %LOCKDIR%
    echo e tente novamente.
    goto erro_sem_lock
)

echo =========================
echo ATUALIZANDO CARDAPIO...
echo =========================

if not exist "..\cardapio_hoje.json" (
    call :log "ERRO: cardapio_hoje.json nao encontrado."
    echo.
    echo ERRO: arquivo ..\cardapio_hoje.json nao encontrado.
    goto erro
)

py -m json.tool "..\cardapio_hoje.json" >nul 2>&1
if errorlevel 1 python -m json.tool "..\cardapio_hoje.json" >nul 2>&1
if errorlevel 1 (
    call :log "ERRO: JSON invalido."
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
    call :log "ERRO: pasta nao e repositorio Git."
    echo.
    echo ERRO: esta pasta nao parece ser um repositorio Git.
    goto erro
)

:: Remove lock do Git (.git\index.lock) SOMENTE se nao houver
:: nenhum processo git rodando agora (evita corromper operacao real)
tasklist /fi "imagename eq git.exe" 2>nul | findstr /i "git.exe" >nul
if errorlevel 1 (
    if exist ".git\index.lock" (
        call :log "AVISO: index.lock antigo encontrado e removido (nenhum git.exe ativo)."
        del /f /q ".git\index.lock" >nul 2>&1
    )
)

git status --porcelain | findstr /R "^UU ^AA ^DD ^DU ^UD ^UA ^AU" >nul
if not errorlevel 1 (
    call :log "ERRO: conflito de merge pendente."
    echo.
    echo ERRO: existe conflito de Git pendente. Resolva antes de publicar.
    git status --short
    goto erro
)

git rebase --abort >nul 2>&1

echo.
echo =========================
echo VERIFICANDO CONEXAO COM O GITHUB...
echo =========================

set CONECTADO=0
for /l %%i in (1,1,3) do (
    if "!CONECTADO!"=="0" (
        git ls-remote --exit-code origin >nul 2>&1
        if not errorlevel 1 (
            set CONECTADO=1
        ) else (
            call :log "Tentativa %%i: sem conexao com o GitHub. Aguardando..."
            timeout /t 5 /nobreak >nul
        )
    )
)

if "!CONECTADO!"=="0" (
    call :log "ERRO: sem conexao com o GitHub apos 3 tentativas."
    echo.
    echo ERRO: nao foi possivel conectar ao GitHub.
    echo Verifique sua internet e tente novamente.
    goto erro
)

echo.
echo =========================
echo BAIXANDO ULTIMA VERSAO...
echo =========================

set FETCH_OK=0
for /l %%i in (1,1,4) do (
    if "!FETCH_OK!"=="0" (
        git fetch origin main
        if not errorlevel 1 (
            set FETCH_OK=1
        ) else (
            call :log "Tentativa %%i de git fetch falhou. Nova tentativa em breve."
            timeout /t 8 /nobreak >nul
        )
    )
)

if "!FETCH_OK!"=="0" (
    call :log "ERRO: git fetch falhou apos varias tentativas."
    goto erro_git
)

git merge --ff-only origin/main
if errorlevel 1 (
    call :log "ERRO: historico local divergiu do GitHub."
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
    call :log "ERRO ao copiar cardapio_hoje.json."
    echo.
    echo ERRO AO COPIAR O CARDAPIO.
    goto erro
)

git diff --quiet -- cardapio_html.json
if not errorlevel 1 (
    call :log "Nenhuma mudanca detectada no cardapio."
    echo.
    echo Nada mudou no cardapio. Site ja esta com esta versao.
    goto enviar
)

git add cardapio_html.json
git commit -m "Atualizacao do cardapio (alteracao) %date% %time%"
if errorlevel 1 (
    call :log "ERRO: git commit falhou."
    goto erro_git
)

:enviar
echo.
echo =========================
echo ENVIANDO PARA O GITHUB...
echo =========================

set PUSH_OK=0
set TENTATIVAS_RECOVERY=0

:tentar_push
for /l %%i in (1,1,5) do (
    if "!PUSH_OK!"=="0" (
        git push origin main
        if not errorlevel 1 (
            set PUSH_OK=1
        ) else (
            call :log "Tentativa %%i de git push falhou."

            :: Verifica se foi rejeitado por non-fast-forward
            :: (alguem publicou algo enquanto isso rodava)
            git fetch origin main >nul 2>&1
            git merge --ff-only origin/main >nul 2>&1
            if not errorlevel 1 (
                if "!TENTATIVAS_RECOVERY!"=="0" (
                    call :log "Push rejeitado por divergencia. Sincronizado com origin/main, tentando push novamente (1x)."
                    set /a TENTATIVAS_RECOVERY+=1
                )
            )

            timeout /t 10 /nobreak >nul
        )
    )
)

if "!PUSH_OK!"=="0" (
    call :log "ERRO CRITICO: git push falhou apos todas as tentativas."
    echo.
    echo ERRO: nao foi possivel enviar as alteracoes para o GitHub
    echo apos varias tentativas. Nenhuma alteracao local foi perdida.
    echo Rode "git status" e "git log" para investigar.
    goto erro_git
)

call :log "Push concluido com sucesso."

echo.
echo =========================
echo VERIFICANDO SITE PUBLICADO...
echo =========================

powershell -NoProfile -ExecutionPolicy Bypass -Command "$local = (Get-FileHash -Algorithm SHA256 -LiteralPath 'cardapio_html.json').Hash; $ok = $false; for ($i = 1; $i -le 24; $i++) { try { $url = 'https://cumbucamarco-spec.github.io/sabores-cumbuca/cardapio_html.json?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $tmp = Join-Path $env:TEMP ('cardapio_pages_' + [guid]::NewGuid() + '.json'); Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $tmp -TimeoutSec 15 | Out-Null; $remote = (Get-FileHash -Algorithm SHA256 -LiteralPath $tmp).Hash; Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue; if ($remote -eq $local) { $ok = $true; break } } catch { }; Start-Sleep -Seconds 15 }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
    call :log "AVISO: push OK, mas publicacao publica nao confirmada dentro do tempo limite."
    echo.
    echo AVISO: o GitHub recebeu o envio (push OK), mas a pagina publica
    echo ainda nao confirmou o cardapio novo dentro do tempo esperado.
    echo Isso pode ser apenas demora de propagacao do GitHub Pages.
    echo O envio foi feito com sucesso; verifique o site em alguns minutos.
    goto sucesso_parcial
)

:sucesso
call :log "SUCESSO: cardapio publicado e confirmado no site."
echo.
echo =========================
echo CARDAPIO ATUALIZADO COM SUCESSO!
echo =========================
rmdir "%LOCKDIR%" >nul 2>&1
if "%1"=="" pause
exit /b 0

:sucesso_parcial
rmdir "%LOCKDIR%" >nul 2>&1
if "%1"=="" pause
exit /b 0

:erro_git
call :log "ERRO: comando Git falhou."
echo.
echo ERRO: comando Git falhou.

:erro
rmdir "%LOCKDIR%" >nul 2>&1
call :log "PUBLICACAO CANCELADA."
echo.
echo PUBLICACAO CANCELADA COM SEGURANCA.
if "%1"=="" pause
exit /b 1

:erro_sem_lock
if "%1"=="" pause
exit /b 1

:log
echo [%date% %time%] %~1 >> "%LOGFILE%"
exit /b 0