#!/usr/bin/env bash
set -euo pipefail

OLLAMA_BIN="$(command -v ollama)"
BASE_MODEL="${BASE_MODEL:-qwen2.5:7b}"
CUSTOM_MODEL="${CUSTOM_MODEL:-my-qwen}"

# ---- 1. Запускаем сервер Ollama в фоне ----
echo "[entrypoint] starting ollama serve..."
"$OLLAMA_BIN" serve &
OLLAMA_PID=$!

# Пробрасываем SIGTERM/SIGINT на ollama при остановке контейнера
trap 'echo "[entrypoint] stopping ollama..."; kill -TERM "$OLLAMA_PID" 2>/dev/null || true; wait "$OLLAMA_PID" 2>/dev/null || true' TERM INT

# ---- 2. Ждём, пока API поднимется ----
for i in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo "[entrypoint] ollama is up"
        break
    fi
    sleep 1
    if [ "$i" -eq 30 ]; then
        echo "[entrypoint] ERROR: ollama did not start in 30s" >&2
        exit 1
    fi
done

# ---- 3. Тянем базовую модель (если её ещё нет) ----
if ! "$OLLAMA_BIN" list | grep -q "^${BASE_MODEL}"; then
    echo "[entrypoint] pulling ${BASE_MODEL}..."
    "$OLLAMA_BIN" pull "$BASE_MODEL"
else
    echo "[entrypoint] ${BASE_MODEL} already present"
fi

# ---- 4. Собираем кастомную модель из Modelfile ----
if ! "$OLLAMA_BIN" list | grep -q "^${CUSTOM_MODEL}"; then
    echo "[entrypoint] creating ${CUSTOM_MODEL} from Modelfile..."
    "$OLLAMA_BIN" create "$CUSTOM_MODEL" -f /app/Modelfile
else
    echo "[entrypoint] ${CUSTOM_MODEL} already present"
fi

# ---- 5. Запускаем основной процесс (agent.py по умолчанию) ----
echo "[entrypoint] launching: $*"
exec "$@"
