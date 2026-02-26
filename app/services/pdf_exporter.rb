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
      #set page(margin: (x: 1.5cm, y: 2cm))
      #set text(font: "New Computer Modern", size: 10pt, lang: "ru")
      #set par(justify: true, leading: 0.7em, first-line-indent: 1.5em)

      #align(center)[
        #text(size: 28pt, weight: "bold")[Ъ]
        #v(0.2em)
        #line(length: 100%, stroke: 1pt)
        #v(0.3em)
        #grid(
          columns: (1fr, auto, 1fr),
          align: (left, center, right),
          text(size: 7pt, tracking: 2pt, upper[#{rubric}]),
          [],
          text(size: 7pt, fill: gray)[#{date}],
        )
        #v(0.1em)
        #line(length: 100%, stroke: 0.3pt)
      ]

      #v(0.8em)

      #text(size: 16pt, weight: "bold")[#{topic}]

      #v(0.3em)
      #line(length: 100%, stroke: 0.3pt)
      #v(0.5em)

      #columns(2, gutter: 1.5em)[
        #line(length: 0pt)
        #{content}
        #h(0.3em)#text(size: 7pt)[■]
      ]
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
