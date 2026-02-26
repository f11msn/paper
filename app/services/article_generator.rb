class ArticleGenerator
  MAX_TOOL_ITERATIONS = 3

  DEFAULT_SYSTEM_PROMPT = <<~PROMPT
    Ты — опытный журналист газеты «Коммерсантъ». Пиши статьи в фирменном стиле Ъ:

    СТИЛЬ:
    - Деловой, сдержанный тон без эмоций
    - Заголовок: игра слов, каламбур или аллюзия (фирменный стиль заголовков Ъ)
    - Первый абзац (лид): кто, что, где, когда — максимально сжато
    - Структура «перевёрнутая пирамида» — самое важное вверху
    - Используй фирменные обороты: «Как стало известно Ъ», «По данным Ъ», «Как выяснил Ъ»

    ОБЯЗАТЕЛЬНЫЕ ЭЛЕМЕНТЫ:
    - Конкретные цифры и факты
    - Цитаты экспертов (с указанием должности)
    - Контекст: предыстория, сравнения
    - Подпись автора в конце

    ФОРМАТ:
    - Заголовок на первой строке
    - Подзаголовок (если уместен)
    - Текст статьи
    - Подпись: Имя Фамилия (вымышленные)

    Если у тебя есть доступ к инструментам (tools), используй их для поиска новостей, получения цитат и статистики. Это сделает статью достовернее.
  PROMPT

  def initialize(client: nil)
    @client = client || OpenaiClient.new(api_key: ENV.fetch("OPENROUTER_API_KEY"))
    @api_log = []
    @tool_calls_log = []
  end

  def generate(topic:, rubric:, system_prompt: DEFAULT_SYSTEM_PROMPT, temperature: 0.7, max_tokens: 4096)
    messages = build_messages(topic:, rubric:, system_prompt:)

    MAX_TOOL_ITERATIONS.times do
      response = @client.chat(messages:, temperature:, max_tokens:, tools: ToolExecutor.tools_schema)
      log_api_exchange(messages, response)

      message = response.dig("choices", 0, "message")
      tool_calls = message["tool_calls"]

      if tool_calls.nil? || tool_calls.empty?
        return {
          content: message["content"],
          api_log: @api_log,
          tool_calls_log: @tool_calls_log
        }
      end

      messages << { role: "assistant", content: message["content"], tool_calls: }

      tool_calls.each do |tc|
        fn_name = tc.dig("function", "name")
        fn_args = JSON.parse(tc.dig("function", "arguments"))
        result = ToolExecutor.execute(function_name: fn_name, arguments: fn_args)

        @tool_calls_log << { function_name: fn_name, arguments: fn_args, result: }

        messages << { role: "tool", tool_call_id: tc["id"], content: result }
      end
    end

    last_response = @client.chat(messages:, temperature:, max_tokens:)
    log_api_exchange(messages, last_response)

    {
      content: last_response.dig("choices", 0, "message", "content") || "Модель не вернула ответ после #{MAX_TOOL_ITERATIONS} итераций tool calling.",
      api_log: @api_log,
      tool_calls_log: @tool_calls_log
    }
  end

  def generate_streaming(topic:, rubric:, system_prompt: DEFAULT_SYSTEM_PROMPT, temperature: 0.7, max_tokens: 4096, &block)
    messages = build_messages(topic:, rubric:, system_prompt:)

    @client.chat_streaming(messages:, temperature:, max_tokens:) do |chunk|
      content = chunk.dig("choices", 0, "delta", "content")
      block.call(content) if content
    end
  end

  private

  def build_messages(topic:, rubric:, system_prompt:)
    [
      { role: "system", content: system_prompt },
      { role: "user", content: "Напиши статью в стиле Коммерсанта.\nРубрика: #{rubric}\nТема: #{topic}" }
    ]
  end

  def log_api_exchange(messages, response)
    @api_log << {
      request: { messages:, model: @client.instance_variable_get(:@model) },
      response:
    }
  end
end
