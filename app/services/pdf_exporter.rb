class PdfExporter
  def initialize(article)
    @article = article
  end

  def generate
    Dir.mktmpdir do |dir|
      typ_path = File.join(dir, "article.typ")
      pdf_path = File.join(dir, "article.pdf")

      File.write(typ_path, typst_source)

      system("typst", "compile", typ_path, pdf_path, exception: true)

      File.binread(pdf_path)
    end
  end

  private

  def typst_source
    content = strip_markdown(@article.content || "")
    topic = escape(@article.topic)
    rubric = escape(@article.rubric)
    date = @article.created_at.strftime("%d.%m.%Y %H:%M")

    <<~TYP
      #set page(margin: (x: 2cm, y: 2.5cm))
      #set text(font: "New Computer Modern", size: 11pt, lang: "ru")
      #set par(justify: true, leading: 0.8em)

      #align(center)[
        #text(size: 24pt, weight: "bold")[Ъ]
        #v(0.3em)
        #line(length: 100%, stroke: 0.5pt)
        #v(0.3em)
        #text(size: 8pt, tracking: 2pt, upper[#{rubric}])
        #h(1em)
        #text(size: 8pt, fill: gray)[#{date}]
      ]

      #v(1em)

      #text(size: 18pt, weight: "bold")[#{topic}]

      #v(1em)

      #{content}
    TYP
  end

  def strip_markdown(text)
    text
      .gsub(/\*{1,3}(.+?)\*{1,3}/, '\1')
      .gsub(/__(.+?)__/, '\1')
      .gsub(/_(.+?)_/, '\1')
      .gsub(/~~(.+?)~~/, '\1')
      .gsub(/`(.+?)`/, '\1')
      .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      .then { |t| escape(t) }
  end

  def escape(text)
    text
      .gsub("\\", "\\\\")
      .gsub("#", "\\#")
      .gsub("$", "\\$")
      .gsub("@", "\\@")
      .gsub("<", "\\<")
      .gsub(">", "\\>")
  end
end
