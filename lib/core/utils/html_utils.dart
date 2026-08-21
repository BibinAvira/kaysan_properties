/// Minimal HTML→plain-text conversion for the API's `description` fields,
/// which come back as inline-styled HTML (`<p>`, `<span style="...">`,
/// `<strong>`, entities like `&nbsp;`/`&rsquo;`). Pulling in a full HTML
/// rendering package for a handful of paragraph tags would be overkill —
/// this keeps line breaks between block elements and decodes the common
/// entities actually seen in the API responses.
class HtmlUtils {
  HtmlUtils._();

  static final RegExp _blockTags = RegExp(r'</(p|div|li|br)\s*>|<br\s*/?>', caseSensitive: false);
  static final RegExp _anyTag = RegExp(r'<[^>]*>');
  static final RegExp _blankLines = RegExp(r'\n{3,}');

  static String stripTags(String html) {
    if (html.trim().isEmpty) return '';
    String text = html.replaceAll(_blockTags, '\n');
    text = text.replaceAll(_anyTag, '');
    text = _decodeEntities(text);
    text = text.replaceAll(_blankLines, '\n\n');
    return text.trim();
  }

  static String _decodeEntities(String text) {
    const Map<String, String> entities = <String, String>{
      '&nbsp;': ' ',
      '&amp;': '&',
      '&rsquo;': '\u2019',
      '&lsquo;': '\u2018',
      '&rdquo;': '\u201d',
      '&ldquo;': '\u201c',
      '&mdash;': '\u2014',
      '&ndash;': '\u2013',
      '&hellip;': '\u2026',
      '&quot;': '"',
      '&#39;': "'",
      '&lt;': '<',
      '&gt;': '>',
    };
    String result = text;
    entities.forEach((String key, String value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
