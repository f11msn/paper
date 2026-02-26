module MarkdownHelper
  ALLOWED_TAGS = %w[
    p br h1 h2 h3 h4 h5 h6 strong em a ul ol li
    code pre blockquote table thead tbody tr th td
    hr del img span div
  ].freeze

  def render_markdown(text)
    return "" if text.blank?

    cleaned = strip_xml_artifacts(text)

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true),
      autolink: true,
      fenced_code_blocks: true,
      strikethrough: true,
      tables: true,
      no_intra_emphasis: true
    )

    sanitize(markdown.render(cleaned), tags: ALLOWED_TAGS, attributes: %w[href src alt class title])
  end

  def strip_markdown(text)
    return "" if text.blank?

    strip_tags(render_markdown(text)).squish
  end

  private

  def strip_xml_artifacts(text)
    text
      .gsub(%r{</?function_calls>}i, "")
      .gsub(%r{</?invoke[^>]*>}i, "")
      .gsub(%r{</?parameter[^>]*>}i, "")
      .gsub(%r{</?antml:[^>]*>}i, "")
  end
end
