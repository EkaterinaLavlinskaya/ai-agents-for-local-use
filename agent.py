"""Локальный AI-агент на Ollama + LangGraph.

Запуск:
    python agent.py
Требуется запущенный `ollama serve` и модель `my-qwen` (см. README).
"""
from datetime import datetime

from langchain.agents import create_agent
from langchain_core.tools import tool
from langchain_ollama import ChatOllama
from langgraph.checkpoint.memory import InMemorySaver

CHAT_MODEL = "my-qwen"

SYSTEM_PROMPT = (
    "You are a helpful assistant with access to tools for getting the current time "
    "and counting words in text. Use tools when the user's request needs one. "
    "If the question doesn't need a tool, answer directly. "
    "If a tool returns an error, explain the error plainly."
)


@tool
def current_time() -> str:
    """Возвращает текущую локальную дату и время.
    Используйте, когда пользователь спрашивает, который час или день.
    """
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


@tool
def word_count(text: str) -> int:
    """Подсчитывает количество слов в тексте.
    Используйте, когда пользователь спрашивает, сколько слов в тексте.
    Возвращает количество слов в виде целого числа.
    """
    return len(text.split())


TOOLS = [current_time, word_count]


def build_agent():
    model = ChatOllama(model=CHAT_MODEL, temperature=0.7, repeat_penalty=1.1)
    checkpointer = InMemorySaver()
    return create_agent(
        model=model,
        tools=TOOLS,
        system_prompt=SYSTEM_PROMPT,
        checkpointer=checkpointer,
    )


def main() -> None:
    agent = build_agent()
    config = {"configurable": {"thread_id": "thread"}}

    print("Ready! Ask the agent something. It remembers the conversation.\n")
    prev_message_count = 0

    while True:
        try:
            question = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not question or question.lower() == "exit":
            break

        result = agent.invoke(
            {"messages": [{"role": "user", "content": question}]},
            config=config,
        )

        new_messages = result["messages"][prev_message_count:]
        for msg in new_messages:
            for call in (getattr(msg, "tool_calls", None) or []):
                print(f"[tool call] {call['name']}({call['args']})")

        print(f"\nAnswer: {result['messages'][-1].content}\n")
        prev_message_count = len(result["messages"])


if __name__ == "__main__":
    main()
