# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS base

# ---- Системные зависимости ----
# zstd нужен установщику Ollama, curl — для скачивания, tini — для корректного PID 1
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        zstd \
        tini \
        && rm -rf /var/lib/apt/lists/*

# ---- Ollama ----
# Официальный скрипт ставит бинарь в /usr/local/bin/ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# ---- Python-зависимости ----
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Код приложения ----
COPY agent.py Modelfile ./
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---- Пользователь без root (Ollama умеет работать от непривилегированного) ----
RUN useradd -m -u 1000 agent && \
    mkdir -p /home/agent/.ollama && \
    chown -R agent:agent /home/agent /app
USER agent

# Ollama слушает 11434
EXPOSE 11434

# Модели храним в volume, чтобы не качать при каждом рестарте
ENV OLLAMA_MODELS=/home/agent/.ollama/models
ENV OLLAMA_HOST=127.0.0.1:11434

# tini как init — корректно пробрасывает SIGTERM дочерним процессам
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["python", "agent.py"]
