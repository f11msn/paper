# Ъ Paper

Article generator in Kommersant newspaper style. Rails 8, DeepSeek via OpenRouter, OpenAI-compatible API.

Covers system messages, tool calling loop, streaming (SSE), temperature/max_tokens tuning. Full API exchange visualized in Debug Panel.

## Быстрый старт

```bash
# Ruby 4.0.1 (через mise)
git clone <repo>
cd paper
bundle install
bin/rails db:prepare
export OPENROUTER_API_KEY=sk-or-v1-...
bin/dev
```

Открыть http://localhost:3000

## Концепции OpenAI API

### 1. System Message

**Что:** Первое сообщение в массиве messages с `role: "system"`. Задаёт поведение модели — персону, стиль, ограничения. Не видно пользователю.

**Где в коде:**
- Дефолтный промпт Коммерсанта → [`app/services/article_generator.rb`](app/services/article_generator.rb) (`DEFAULT_SYSTEM_PROMPT`)
- Редактирование в UI → [`app/views/articles/new.html.erb`](app/views/articles/new.html.erb)
- Сохранение в чате → [`app/controllers/conversations_controller.rb`](app/controllers/conversations_controller.rb) (`#create`)

**Пример:**
```json
{
  "role": "system",
  "content": "Ты — опытный журналист газеты «Коммерсантъ»..."
}
```

### 2. Roles (роли сообщений)

**Что:** Каждое сообщение в массиве messages имеет role:
- `system` — инструкция модели
- `user` — сообщение от человека
- `assistant` — ответ модели
- `tool` — результат вызова инструмента

**Где в коде:**
- Модель Message с валидацией ролей → [`app/models/message.rb`](app/models/message.rb)
- Сборка массива для API → [`app/controllers/messages_controller.rb`](app/controllers/messages_controller.rb) (`#create`)
- Визуализация ролей в чате → [`app/views/conversations/show.html.erb`](app/views/conversations/show.html.erb)

### 3. Tool Calling (Function Calling)

**Что:** Модель может «вызвать функцию» вместо текстового ответа. Клиент выполняет функцию и отправляет результат обратно. Цикл:
1. Клиент отправляет messages + tools (описание доступных функций)
2. Модель возвращает `tool_calls` с именем функции и аргументами
3. Клиент выполняет функцию
4. Клиент добавляет результат как message с `role: "tool"`
5. Повторяет запрос → модель даёт финальный ответ

**Где в коде:**
- Описание tools (JSON Schema) → [`app/services/tool_executor.rb`](app/services/tool_executor.rb) (`.tools_schema`)
- Выполнение функций-заглушек → [`app/services/tool_executor.rb`](app/services/tool_executor.rb) (`.execute`)
- Цикл tool calling → [`app/services/article_generator.rb`](app/services/article_generator.rb) (`#generate`)
- Визуализация в Debug Panel → [`app/views/articles/show.html.erb`](app/views/articles/show.html.erb)

**Доступные tools:**
- `search_news(query)` — поиск новостей (заглушка)
- `get_quote(person, topic)` — цитата эксперта (заглушка)
- `get_statistics(topic)` — статистика (заглушка)

### 4. Streaming

**Что:** Параметр `stream: true` заставляет модель отдавать ответ по частям (Server-Sent Events). Каждый chunk содержит `delta` с фрагментом текста.

**Где в коде:**
- Streaming в клиенте → [`app/services/openai_client.rb`](app/services/openai_client.rb) (`#chat_streaming`)
- SSE endpoint → [`app/controllers/articles_controller.rb`](app/controllers/articles_controller.rb) (`#stream`)
- Отображение в браузере → [`app/javascript/controllers/generator_controller.js`](app/javascript/controllers/generator_controller.js)

### 5. Temperature и Max Tokens

**Что:**
- `temperature` (0.0–2.0) — «креативность» модели. 0 = детерминированный, 1+ = креативный
- `max_tokens` — максимальная длина ответа в токенах

**Где в коде:**
- UI с слайдером → [`app/views/articles/new.html.erb`](app/views/articles/new.html.erb)
- Передача в API → [`app/services/openai_client.rb`](app/services/openai_client.rb) (`#chat`)

## Архитектура

```
app/services/
├── openai_client.rb       # HTTP-клиент OpenAI протокола (Faraday)
├── article_generator.rb   # Оркестрация: промпт + tool calling loop
└── tool_executor.rb       # Функции-заглушки для tool calling

app/models/
├── article.rb             # Сгенерированная статья
├── conversation.rb        # Чат-сессия
└── message.rb             # Сообщение (system/user/assistant/tool)

app/controllers/
├── articles_controller.rb       # Генерация + streaming (SSE)
├── conversations_controller.rb  # CRUD чатов
└── messages_controller.rb       # Отправка сообщений
```

## Тесты

```bash
bundle exec rspec
```

Используется WebMock для стабирования API-запросов — тесты не ходят в реальный OpenRouter.

## Стек

- Ruby 4.0.1
- Rails 8.1.2
- SQLite
- Faraday (HTTP)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- RSpec + WebMock + FactoryBot
