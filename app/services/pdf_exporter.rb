class PdfExporter
  HEADING_RE = /^\#{1,6}\s+(.+)$/

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
    headline, content = extract_headline_and_body(@article.content || "")
    body = markdown_to_typst(content)
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

      #text(size: 16pt, weight: "bold")[#{headline}]

      #v(0.3em)
      #line(length: 100%, stroke: 0.3pt)
      #v(0.5em)

      #columns(2, gutter: 1.5em)[
        #line(length: 0pt)
        #{body}
      ]
    TYP
  end

  def extract_headline_and_body(text)
    lines = text.strip.split("\n")
    first = lines.first&.strip || ""

    if first.match?(/\A\*\*(.+)\*\*\z/)
      headline = escape(first.gsub(/\*\*/, ""))
      rest = lines.drop(1).join("\n").strip
      [headline, rest]
    else
      [escape(@article.topic), text.strip]
    end
  end

  def markdown_to_typst(text)
    lines = text.strip.split("\n")

    author = extract_author(lines)
    body = author ? lines[0...-2].join("\n").strip : lines.join("\n").strip

    result = escape(body)
    result = convert_inline(result)
    result = convert_blocks(result)

    result += " #text(size: 7pt)[■]"

    if author
      result += "\n\n#align(right)[#emph[#{escape(author)}]]"
    end

    result
  end

  def extract_author(lines)
    trimmed = lines.map(&:strip).reject(&:empty?)
    return nil if trimmed.size < 3

    last = trimmed.last
    return last if last.match?(/\A[А-ЯЁA-Z][а-яёa-z]+\s+[А-ЯЁA-Z][а-яёa-z]+\z/)

    nil
  end

  def convert_inline(text)
    text
      .gsub(/\*\*\*(.+?)\*\*\*/) { "#text(weight: \"bold\")[#emph[#{$1}]]" }
      .gsub(/\*\*(.+?)\*\*/) { "#text(weight: \"bold\")[#{$1}]" }
      .gsub(/__(.+?)__/) { "#text(weight: \"bold\")[#{$1}]" }
      .gsub(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/) { "#emph[#{$1}]" }
      .gsub(/(?<!_)_(?!_)(.+?)(?<!_)_(?!_)/) { "#emph[#{$1}]" }
      .gsub(/~~(.+?)~~/) { "#strike[#{$1}]" }
      .gsub(/`(.+?)`/) { "#raw(\"#{$1.gsub('"', '\\"')}\")" }
      .gsub(/\[([^\]]+)\]\([^)]+\)/) { "#underline[#{$1}]" }
  end

  def convert_blocks(text)
    text
      .gsub(/^\\>\s*(.+)$/) { "#block(inset: (left: 1.5em), stroke: (left: 2pt + gray))[#emph[#{$1}]]" }
      .gsub(HEADING_RE) { "\n#text(size: 12pt, weight: \"bold\")[#{$1}]\n" }
  end

  def escape(text)
    text
      .gsub("\\", "\\\\")
      .gsub("<", "\\<")
      .gsub(">", "\\>")
      .gsub("$", "\\$")
      .gsub("@", "\\@")
  end
end
