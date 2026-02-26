class ToolExecutor
  class UnknownToolError < StandardError; end

  TOOLS = {
    "search_news" => {
      description: "Поиск актуальных новостей по теме",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Поисковый запрос" }
        },
        required: ["query"]
      }
    },
    "get_quote" => {
      description: "Получение цитаты эксперта по теме",
      parameters: {
        type: "object",
        properties: {
          person: { type: "string", description: "Имя эксперта или должность" },
          topic: { type: "string", description: "Тема цитаты" }
        },
        required: ["person", "topic"]
      }
    },
    "get_statistics" => {
      description: "Получение статистических данных по теме",
      parameters: {
        type: "object",
        properties: {
          topic: { type: "string", description: "Тема для статистики" }
        },
        required: ["topic"]
      }
    }
  }.freeze

  def self.tools_schema
    TOOLS.map do |name, config|
      {
        type: "function",
        function: {
          name:,
          description: config[:description],
          parameters: config[:parameters]
        }
      }
    end
  end

  def self.execute(function_name:, arguments:)
    case function_name
    when "search_news"    then search_news(arguments)
    when "get_quote"      then get_quote(arguments)
    when "get_statistics" then get_statistics(arguments)
    else raise UnknownToolError, "Unknown tool: #{function_name}"
    end
  end

  def self.search_news(arguments)
    query = arguments["query"] || "новости"
    {
      results: [
        { title: "#{query.capitalize}: последние изменения на рынке", source: "РБК", date: "2025-02-25" },
        { title: "Эксперты оценили перспективы: #{query}", source: "Ведомости", date: "2025-02-24" },
        { title: "Как #{query} повлияет на экономику в 2025 году", source: "Коммерсантъ", date: "2025-02-23" }
      ]
    }.to_json
  end

  def self.get_quote(arguments)
    person = arguments["person"] || "эксперт"
    topic = arguments["topic"] || "ситуация"
    {
      person:,
      position: "директор аналитического департамента",
      organization: "Институт экономической политики",
      quote: "Текущая ситуация с #{topic} требует взвешенного подхода. Мы ожидаем стабилизацию в ближайшие месяцы.",
      date: "2025-02-25"
    }.to_json
  end

  def self.get_statistics(arguments)
    topic = arguments["topic"] || "экономика"
    {
      statistics: [
        { metric: "Рост показателя за год", value: "+12.3%", source: "Росстат" },
        { metric: "Объём рынка #{topic}", value: "2.4 трлн руб.", source: "Минэкономразвития" },
        { metric: "Прогноз на 2025", value: "+5.7%", source: "ЦБ РФ" }
      ],
      period: "2024-2025"
    }.to_json
  end
end
