import 'package:flutter/material.dart';

/// Utility class for parsing text with markdown-like formatting with enhanced typography
class RichTextParser {
  /// Parses text containing **bold** and # heading markers with enhanced font sizes
  static List<TextSpan> parseMarkdownText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];

    // Enhanced patterns for different text elements
    final RegExp headingPattern = RegExp(r'^#+\s+(.+)$', multiLine: true);
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    // Split text by headings first
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if line is a heading
      final headingMatch = headingPattern.firstMatch(line);
      if (headingMatch != null) {
        final headingText = headingMatch.group(1) ?? '';
        final headingLevel = line.indexOf(' '); // Count # symbols

        // Add heading with larger font
        spans.add(TextSpan(
          text: headingText + '\n',
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 16) * _getHeadingScale(headingLevel),
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        // Process line for bold text
        spans.addAll(_processLineForBold(line + (i < lines.length - 1 ? '\n' : ''), baseStyle));
      } else if (line.isEmpty && i < lines.length - 1) {
        // Add empty line spacing
        spans.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    // If no spans were created, process the entire text for bold
    if (spans.isEmpty) {
      spans.addAll(_processLineForBold(text, baseStyle));
    }

    return spans;
  }

  /// Process a line of text for bold formatting with enhanced font sizes
  static List<TextSpan> _processLineForBold(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    int lastMatchEnd = 0;

    for (final Match match in boldPattern.allMatches(text)) {
      // Add normal text before the bold section
      if (match.start > lastMatchEnd) {
        final normalText = text.substring(lastMatchEnd, match.start);
        if (normalText.isNotEmpty) {
          spans.add(TextSpan(text: normalText, style: baseStyle));
        }
      }

      // Add bold text with enhanced size
      final boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        spans.add(TextSpan(
          text: boldText,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (baseStyle.fontSize ?? 16) * 1.15, // 15% larger for bold text
            letterSpacing: 0.3, // Slightly increased letter spacing for emphasis
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining normal text
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText, style: baseStyle));
      }
    }

    // If no bold patterns were found, return the original text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }

  /// Get scaling factor for heading levels
  static double _getHeadingScale(int headingLevel) {
    switch (headingLevel) {
      case 1:
        return 1.8; // H1 - 80% larger
      case 2:
        return 1.6; // H2 - 60% larger
      case 3:
        return 1.4; // H3 - 40% larger
      case 4:
        return 1.3; // H4 - 30% larger
      case 5:
        return 1.2; // H5 - 20% larger
      default:
        return 1.5; // Default heading size - 50% larger
    }
  }
}

/// Enhanced widget that displays text with modern typography and improved formatting
class FormattedSelectableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const FormattedSelectableText(
    this.text, {
    Key? key,
    this.style,
    this.semanticsLabel,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Enhanced base style with modern typography
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      height: 1.6, // Improved line height for better readability
      letterSpacing: 0.15, // Subtle letter spacing
    );

    final textSpans = RichTextParser.parseMarkdownText(text, baseStyle);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: SelectableText.rich(
        TextSpan(children: textSpans),
        textAlign: textAlign ?? TextAlign.start,
        maxLines: maxLines,
        style: baseStyle,
      ),
    );
  }
}
