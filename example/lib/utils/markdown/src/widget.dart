import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markdown/markdown.dart' as md;

import '../flutter_markdown_plus.dart';
import '_functions_io.dart' if (dart.library.js_interop) '_functions_web.dart';

typedef MarkdownOnSelectionChangedCallback = void Function(String? text, TextSelection selection, SelectionChangedCause? cause);

typedef MarkdownTapLinkCallback = void Function(String text, String? href, String title);

typedef MarkdownImageBuilder = Widget Function(Uri uri, String? title, String? alt);

typedef MarkdownCheckboxBuilder = Widget Function(bool value);

typedef MarkdownBulletBuilder = Widget Function(
  MarkdownBulletParameters parameters,
);

class MarkdownBulletParameters {

  const MarkdownBulletParameters({
    required this.index,
    required this.style,
    required this.nestLevel,
  });

  final int index;

  final BulletStyle style;

  final int nestLevel;
}

enum BulletStyle {

  orderedList,

  unorderedList,
}

abstract class SyntaxHighlighter {

  TextSpan format(String source);
}

abstract class MarkdownElementBuilder {

  bool isBlockElement() => false;

  void visitElementBefore(md.Element element) {}

  Widget? visitText(md.Text text, TextStyle? preferredStyle) => null;

  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return visitElementAfter(element, preferredStyle);
  }

  @Deprecated('Use visitElementAfterWithContext() instead.')
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) => null;
}

enum MarkdownStyleSheetBaseTheme {

  material,

  cupertino,

  platform,
}

enum MarkdownListItemCrossAxisAlignment {

  baseline,

  start,
}

abstract class MarkdownWidget extends StatefulWidget {

  const MarkdownWidget({
    super.key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.styleSheetTheme = MarkdownStyleSheetBaseTheme.material,
    this.syntaxHighlighter,
    this.onSelectionChanged,
    this.onTapLink,
    this.onTapText,
    this.imageDirectory,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
    this.imageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.builders = const <String, MarkdownElementBuilder>{},
    this.paddingBuilders = const <String, MarkdownPaddingBuilder>{},
    this.fitContent = false,
    this.listItemCrossAxisAlignment = MarkdownListItemCrossAxisAlignment.baseline,
    this.softLineBreak = false,
  });

  final String data;

  final bool selectable;

  final MarkdownStyleSheet? styleSheet;

  final MarkdownStyleSheetBaseTheme? styleSheetTheme;

  final SyntaxHighlighter? syntaxHighlighter;

  final MarkdownTapLinkCallback? onTapLink;

  final MarkdownOnSelectionChangedCallback? onSelectionChanged;

  final VoidCallback? onTapText;

  final String? imageDirectory;

  final List<md.BlockSyntax>? blockSyntaxes;

  final List<md.InlineSyntax>? inlineSyntaxes;

  final md.ExtensionSet? extensionSet;

  final MarkdownImageBuilder? imageBuilder;

  final MarkdownCheckboxBuilder? checkboxBuilder;

  final MarkdownBulletBuilder? bulletBuilder;

  final Map<String, MarkdownElementBuilder> builders;

  final Map<String, MarkdownPaddingBuilder> paddingBuilders;

  final bool fitContent;

  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  final bool softLineBreak;

  @protected
  Widget build(BuildContext context, List<Widget>? children);

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> implements MarkdownBuilderDelegate {
  List<Widget>? _children;
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void didChangeDependencies() {
    _parseMarkdown();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data || widget.styleSheet != oldWidget.styleSheet) {
      _parseMarkdown();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parseMarkdown() {
    final MarkdownStyleSheet fallbackStyleSheet = kFallbackStyle(context, widget.styleSheetTheme);
    final MarkdownStyleSheet styleSheet = fallbackStyleSheet.merge(widget.styleSheet);

    _disposeRecognizers();

    final md.Document document = md.Document(
      blockSyntaxes: widget.blockSyntaxes,
      inlineSyntaxes: widget.inlineSyntaxes,
      extensionSet: widget.extensionSet ?? md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );

    final List<String> lines = const LineSplitter().convert(widget.data);
    final List<md.Node> astNodes = document.parseLines(lines);

    final MarkdownBuilder builder = MarkdownBuilder(
      delegate: this,
      selectable: widget.selectable,
      styleSheet: styleSheet,
      imageDirectory: widget.imageDirectory,
      imageBuilder: widget.imageBuilder,
      checkboxBuilder: widget.checkboxBuilder,
      bulletBuilder: widget.bulletBuilder,
      builders: widget.builders,
      paddingBuilders: widget.paddingBuilders,
      fitContent: widget.fitContent,
      listItemCrossAxisAlignment: widget.listItemCrossAxisAlignment,
      onSelectionChanged: widget.onSelectionChanged,
      onTapText: widget.onTapText,
      softLineBreak: widget.softLineBreak,
    );

    _children = builder.build(astNodes);
  }

  void _disposeRecognizers() {
    if (_recognizers.isEmpty) {
      return;
    }
    final List<GestureRecognizer> localRecognizers = List<GestureRecognizer>.from(_recognizers);
    _recognizers.clear();
    for (final GestureRecognizer recognizer in localRecognizers) {
      recognizer.dispose();
    }
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () {
        if (widget.onTapLink != null) {
          widget.onTapLink!(text, href, title);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    code = code.replaceAll(RegExp(r'\n$'), '');
    if (widget.syntaxHighlighter != null) {
      return widget.syntaxHighlighter!.format(code);
    }
    return TextSpan(style: styleSheet.code, text: code);
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _children);
}

class MarkdownBody extends MarkdownWidget {

  const MarkdownBody({
    super.key,
    required super.data,
    super.selectable,
    super.styleSheet,
    super.styleSheetTheme = null,
    super.syntaxHighlighter,
    super.onSelectionChanged,
    super.onTapLink,
    super.onTapText,
    super.imageDirectory,
    super.blockSyntaxes,
    super.inlineSyntaxes,
    super.extensionSet,
    super.imageBuilder,
    super.checkboxBuilder,
    super.bulletBuilder,
    super.builders,
    super.paddingBuilders,
    super.listItemCrossAxisAlignment,
    this.shrinkWrap = true,
    super.fitContent = true,
    super.softLineBreak,
  });

  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    if (children!.length == 1 && shrinkWrap) {
      return children.single;
    }
    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: fitContent ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class Markdown extends MarkdownWidget {

  const Markdown({
    super.key,
    required super.data,
    super.selectable,
    super.styleSheet,
    super.styleSheetTheme = null,
    super.syntaxHighlighter,
    super.onSelectionChanged,
    super.onTapLink,
    super.onTapText,
    super.imageDirectory,
    super.blockSyntaxes,
    super.inlineSyntaxes,
    super.extensionSet,
    super.imageBuilder,
    super.checkboxBuilder,
    super.bulletBuilder,
    super.builders,
    super.paddingBuilders,
    super.listItemCrossAxisAlignment,
    this.padding = const EdgeInsets.all(16.0),
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    super.softLineBreak,
  });

  final EdgeInsets padding;

  final ScrollController? controller;

  final ScrollPhysics? physics;

  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    return ListView(
      padding: padding,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children!,
    );
  }
}

@Deprecated('Use [OrderedListWithCheckBoxSyntax] or [UnorderedListWithCheckBoxSyntax]')
class TaskListSyntax extends md.InlineSyntax {

  @Deprecated('Use [OrderedListWithCheckBoxSyntax] or [UnorderedListWithCheckBoxSyntax]')
  TaskListSyntax() : super(_pattern);

  static const String _pattern = r'^ *\[([ xX])\] +';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final md.Element el = md.Element.withTag('input');
    el.attributes['type'] = 'checkbox';
    el.attributes['disabled'] = 'true';
    el.attributes['checked'] = '${match[1]!.trim().isNotEmpty}';
    parser.addNode(el);
    return true;
  }
}

abstract class MarkdownPaddingBuilder {

  void visitElementBefore(md.Element element) {}

  EdgeInsets getPadding() => EdgeInsets.zero;
}
