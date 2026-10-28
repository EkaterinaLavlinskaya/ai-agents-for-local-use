markdown
![Docker](https://img.shields.io/badge/docker-ready-2496ED?logo=docker&logoColor=white)
# AI Agents for Local Use 🤖

Локальный AI‑агент на базе [Ollama](https://ollama.com) + [LangChain](https://python.langchain.com) / [LangGraph](https://langchain-ai.github.io/langgraph/), работающий **полностью офлайн**. Модель — `qwen2.5` (1.5B или 7B), кастомная сборка `my-qwen`.

## Возможности

- 🖥️ **Полностью локальный запуск** — без API‑ключей и внешних сервисов.
- 🛠️ **Вызов инструментов (tools)**: текущее время, подсчёт слов.
- 🧠 **Память диалога** через `InMemorySaver` (LangGraph checkpointer).
- ⚡ Работает в **Google Colab (T4 GPU)** и локально (CPU/GPU).
- 📓 Готовый **ноутбук** для быстрого старта.

## Архитектура

```
User ──► LangGraph Agent ──► ChatOllama (my-qwen)
                 │
                 └──► Tools: current_time, word_count
                 │
                 └──► InMemorySaver (история по thread_id)
```

## Быстрый старт

### Вариант A — Google Colab
1. Откройте [`AI_agents.ipynb`](AI_agents.ipynb) в Colab (бейдж в ноутбуке).
2. Выберите среду выполнения с **T4 GPU**.
3. Выполните ячейки по порядку.

### Вариант B — локально

```bash
# 1. Установить Ollama: https://ollama.com/download
ollama serve &

# 2. Скачать базовую модель
ollama pull qwen2.5:7b

# 3. Создать кастомную модель
ollama create my-qwen -f Modelfile

# 4. Установить зависимости
pip install -r requirements.txt

# 5. Запустить агента
python agent.py
```

## Пример работы

```
You: Который час?
[tool call] current_time({})
Answer: Сейчас 2026-10-19 08:41:12.

You: Сколько слов в "привет мир как дела"?
[tool call] word_count({'text': 'привет мир как дела'})
Answer: 4 слова.
```

## Требования

- Python 3.10+
- Ollama ≥ 0.5
- ~5 ГБ диска для `qwen2.5:7b` (или ~1 ГБ для `1.5b`)
- GPU — опционально (но быстрее)

## Конфигурация

В `agent.py`:

| Параметр      | Значение по умолчанию | Описание                     |
|---------------|-----------------------|------------------------------|
| `CHAT_MODEL`  | `my-qwen`             | Имя модели в Ollama          |
| `temperature` | `0.7`                 | Креативность ответов         |
| `repeat_penalty` | `1.1`              | Штраф за повторы             |
| `thread_id`   | `"thread"`            | Идентификатор сессии памяти  |

## Структура проекта

```
.
├── AI_agents.ipynb   # Colab-ноутбук (пошаговая демонстрация)
├── agent.py          # Чистый скрипт агента
├── Modelfile         # Определение кастомной модели my-qwen
├── requirements.txt
└── README.md
```

## Известные ограничения

- `InMemorySaver` хранит историю **только в RAM** — после перезапуска она теряется. Для персистентности используйте `SqliteSaver` / `PostgresSaver`.
- Модель `qwen2.5:1.5b` может нестабильно вызывать инструменты; для надёжности рекомендуется `7b`.
- При запуске в Colab `systemd` не работает — сервер Ollama запускается вручную через `subprocess.Popen`.

## Лицензия

MIT — см. [LICENSE](LICENSE).

## Благодарности

- [Ollama](https://ollama.com)
- [LangChain](https://github.com/langchain-ai/langchain)
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [Qwen](https://github.com/QwenLM/Qwen2.5)
