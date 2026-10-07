import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import '_functions_io.dart' if (dart.library.js_interop) '_functions_web.dart';
import 'style_sheet.dart';
import 'widget.dart';

final List<String> _kBlockTags = <String>[
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
  'pre',
  'ol',
  'ul',
  'hr',
  'table',
  'thead',
  'tbody',
  'tr',
  'section',
];

const List<String> _kListTags = <String>['ul', 'ol'];

bool _isBlockTag(String? tag) => _kBlockTags.contains(tag);

bool _isListTag(String tag) => _kListTags.contains(tag);

class _BlockElement {
  _BlockElement(this.tag);

  final String? tag;
  final List<Widget> children = <Widget>[];

  int nextListIndex = 0;
}

class _TableElement {
  final List<TableRow> rows = <TableRow>[];
}

class _InlineElement {
  _InlineElement(this.tag, {this.style});

  final String? tag;

  final TextStyle? style;

  final List<Widget> children = <Widget>[];
}

abstract class MarkdownBuilderDelegate {

  BuildContext get context;

  GestureRecognizer createLink(String text, String? href, String title);

  TextSpan formatText(MarkdownStyleSheet styleSheet, String code);
}

class MarkdownBuilder implements md.NodeVisitor {

  MarkdownBuilder({
    required this.delegate,
    required this.selectable,
    required this.styleSheet,
    required this.imageDirectory,
    required this.imageBuilder,
    required this.checkboxBuilder,
    required this.bulletBuilder,
    required this.builders,
    required this.paddingBuilders,
    required this.listItemCrossAxisAlignment,
    this.fitContent = false,
    this.onSelectionChanged,
    this.onTapText,
    this.softLineBreak = false,
  });

  final MarkdownBuilderDelegate delegate;

  final bool selectable;

  final MarkdownStyleSheet styleSheet;

  final String? imageDirectory;

  final MarkdownImageBuilder? imageBuilder;

  final MarkdownCheckboxBuilder? checkboxBuilder;

  final MarkdownBulletBuilder? bulletBuilder;

  final Map<String, MarkdownElementBuilder> builders;

  final Map<String, MarkdownPaddingBuilder> paddingBuilders;

  final bool fitContent;

  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  final MarkdownOnSelectionChangedCallback? onSelectionChanged;

  final VoidCallback? onTapText;

  final bool softLineBreak;

  final List<String> _listIndents = <String>[];
  final List<_BlockElement> _blocks = <_BlockElement>[];
  final List<_TableElement> _tables = <_TableElement>[];
  final List<_InlineElement> _inlines = <_InlineElement>[];
  final List<GestureRecognizer> _linkHandlers = <GestureRecognizer>[];
  String? _currentBlockTag;
  String? _lastVisitedTag;
  bool _isInBlockquote = false;

  List<Widget> build(List<md.Node> nodes) {
    _listIndents.clear();
    _blocks.clear();
    _tables.clear();
    _inlines.clear();
    _linkHandlers.clear();
    _isInBlockquote = false;

    builders.forEach((String key, MarkdownElementBuilder value) {
      if (value.isBlockElement()) {
        _kBlockTags.add(key);
      }
    });

    _blocks.add(_BlockElement(null));

    for (final md.Node node in nodes) {
      assert(_blocks.length == 1);
      node.accept(this);
    }

    _addAnonymousBlockIfNeeded();

    assert(_tables.isEmpty);
    assert(_inlines.isEmpty);
    assert(!_isInBlockquote);
    return _blocks.single.children;
  }

  @override
  bool visitElementBefore(md.Element element) {
    final String tag = element.tag;
    _currentBlockTag ??= tag;
    _lastVisitedTag = tag;

    if (builders.containsKey(tag)) {
      builders[tag]!.visitElementBefore(element);
    }

    if (paddingBuilders.containsKey(tag)) {
      paddingBuilders[tag]!.visitElementBefore(element);
    }

    int? start;
    final bool isBlock = _isBlockTag(tag) || (builders.containsKey(tag) && builders[tag]!.isBlockElement());
    if (isBlock) {
      _addAnonymousBlockIfNeeded();
      if (_isListTag(tag)) {
        _listIndents.add(tag);
        if (element.attributes['start'] != null) {
          start = int.parse(element.attributes['start']!) - 1;
        }
      } else if (tag == 'blockquote') {
        _isInBlockquote = true;
      } else if (tag == 'table') {
        _tables.add(_TableElement());
      } else if (tag == 'tr') {
        final int length = _tables.single.rows.length;
        Decoration? decoration = styleSheet.tableCellsDecoration;

        if (length == 0) {
          decoration = styleSheet.tableHeadCellsDecoration ?? styleSheet.tableCellsDecoration;
        } else if (length.isEven) {
          decoration = styleSheet.tableCellsDecoration;
        } else {
          decoration = null;
        }
        _tables.single.rows.add(TableRow(
          decoration: decoration,

          children: <Widget>[],
        ));
      }
      final _BlockElement bElement = _BlockElement(tag);
      if (start != null) {
        bElement.nextListIndex = start;
      }
      _blocks.add(bElement);
    } else {
      if (tag == 'a' && !builders.containsKey('a')) {
        final String? text = extractTextFromElement(element);

        if (text == null) {
          return false;
        }
        final String? destination = element.attributes['href'];
        final String title = element.attributes['title'] ?? '';

        _linkHandlers.add(
          delegate.createLink(text, destination, title),
        );
      }

      _addParentInlineIfNeeded(_blocks.last.tag);

      if (element.tag == 'td' && element.children != null && element.children!.isEmpty) {
        element.children!.add(md.Text(''));
      }

      final TextStyle? parentStyle = _inlines.last.style;
      final TextStyle? tagStyle = styleSheet.styles[tag];
      _inlines.add(_InlineElement(tag, style: parentStyle != null ? parentStyle.merge(tagStyle) : tagStyle));
    }

    return true;
  }

  String? extractTextFromElement(md.Node element) {
    return element is md.Element && (element.children?.isNotEmpty ?? false)
        ? element.children!.map((md.Node e) => e is md.Text ? e.text : extractTextFromElement(e)).join()
        : (element is md.Element && (element.attributes.isNotEmpty) ? element.attributes['alt'] : '');
  }

  @override
  void visitText(md.Text text) {

    if (_blocks.last.tag == null) {
      return;
    }

    _addParentInlineIfNeeded(_blocks.last.tag);

    String trimText(String text) {

      final RegExp leadingSpacesPattern = RegExp(r'^ *');

      final RegExp softLineBreakPattern = RegExp(r' ?\n *');

      if (const <String>['ul', 'ol', 'li', 'p', 'br'].contains(_lastVisitedTag)) {
        text = text.replaceAll(leadingSpacesPattern, '');
      }

      if (softLineBreak) {
        return text;
      }
      return text.replaceAll(softLineBreakPattern, ' ');
    }

    Widget? child;
    if (_blocks.isNotEmpty && builders.containsKey(_blocks.last.tag)) {
      child = builders[_blocks.last.tag!]!.visitText(text, styleSheet.styles[_blocks.last.tag!]);
    } else if (_blocks.last.tag == 'pre') {
      child = _ScrollControllerBuilder(
          builder: (BuildContext context, ScrollController preScrollController, Widget? child) {
            return Scrollbar(
              controller: preScrollController,
              child: SingleChildScrollView(
                controller: preScrollController,
                scrollDirection: Axis.horizontal,
                padding: styleSheet.codeblockPadding,
                child: child,
              ),
            );
          },
          child: _buildRichText(delegate.formatText(styleSheet, text.text)));
    } else {
      child = _buildRichText(
        TextSpan(
          style: _isInBlockquote ? styleSheet.blockquote : _inlines.last.style,
          text: trimText(text.text),
          recognizer: _linkHandlers.isNotEmpty ? _linkHandlers.last : null,
        ),
        textAlign: _textAlignForBlockTag(_currentBlockTag),
      );
    }
    if (child != null) {
      _inlines.last.children.add(child);
    }

    _lastVisitedTag = null;
  }

  @override
  void visitElementAfter(md.Element element) {
    final String tag = element.tag;

    final bool isBlock = _isBlockTag(tag) || (builders.containsKey(tag) && builders[tag]!.isBlockElement());
    if (isBlock) {
      _addAnonymousBlockIfNeeded();

      final _BlockElement current = _blocks.removeLast();

      Widget defaultChild() {
        if (current.children.isNotEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: fitContent ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: current.children,
          );
        } else {
          return const SizedBox();
        }
      }

      Widget child = builders[tag]?.visitElementAfterWithContext(
            delegate.context,
            element,
            styleSheet.styles[tag],
            _inlines.isNotEmpty ? _inlines.last.style : null,
          ) ??
          defaultChild();

      if (_isListTag(tag)) {
        assert(_listIndents.isNotEmpty);
        _listIndents.removeLast();
      } else if (tag == 'li') {
        if (_listIndents.isNotEmpty) {
          if (element.children!.isEmpty) {
            element.children!.add(md.Text(''));
          }
          Widget bullet;
          final dynamic el = element.children![0];
          if (el is md.Element && el.attributes['type'] == 'checkbox') {
            final bool val = el.attributes.containsKey('checked');
            bullet = _buildCheckbox(val);
          } else {
            bullet = _buildBullet(_listIndents.last);
          }
          child = Row(
            mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
            textBaseline: listItemCrossAxisAlignment == MarkdownListItemCrossAxisAlignment.start ? null : TextBaseline.alphabetic,
            crossAxisAlignment: listItemCrossAxisAlignment == MarkdownListItemCrossAxisAlignment.start ? CrossAxisAlignment.start : CrossAxisAlignment.baseline,
            children: <Widget>[
              SizedBox(
                width: styleSheet.listIndent! + styleSheet.listBulletPadding!.left + styleSheet.listBulletPadding!.right,
                child: bullet,
              ),
              Flexible(
                fit: fitContent ? FlexFit.loose : FlexFit.tight,
                child: child,
              )
            ],
          );
        }
      } else if (tag == 'table') {
        if (styleSheet.tableColumnWidth is FixedColumnWidth || styleSheet.tableColumnWidth is IntrinsicColumnWidth) {
          child = _ScrollControllerBuilder(
            builder: (BuildContext context, ScrollController tableScrollController, Widget? child) {
              return Scrollbar(
                controller: tableScrollController,
                thumbVisibility: styleSheet.tableScrollbarThumbVisibility,
                child: SingleChildScrollView(
                  controller: tableScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: styleSheet.tablePadding,
                  child: child,
                ),
              );
            },
            child: _buildTable(),
          );
        } else {
          child = _buildTable();
        }
      } else if (tag == 'blockquote') {
        _isInBlockquote = false;
        child = DecoratedBox(
          decoration: styleSheet.blockquoteDecoration!,
          child: Padding(
            padding: styleSheet.blockquotePadding!,
            child: child,
          ),
        );
      } else if (tag == 'pre') {
        child = Container(
          clipBehavior: Clip.hardEdge,
          decoration: styleSheet.codeblockDecoration,
          child: child,
        );
      } else if (tag == 'hr') {
        child = Container(decoration: styleSheet.horizontalRuleDecoration);
      }

      _addBlockChild(child);
    } else {
      final _InlineElement current = _inlines.removeLast();
      final _InlineElement parent = _inlines.last;
      EdgeInsets padding = EdgeInsets.zero;

      if (paddingBuilders.containsKey(tag)) {
        padding = paddingBuilders[tag]!.getPadding();
      }

      if (builders.containsKey(tag)) {
        final Widget? child = builders[tag]!.visitElementAfterWithContext(
          delegate.context,
          element,
          styleSheet.styles[tag],
          parent.style,
        );
        if (child != null) {
          if (current.children.isEmpty) {
            current.children.add(child);
          } else {
            current.children[0] = child;
          }
        }
      } else if (tag == 'img') {

        current.children.add(_buildPadding(
          padding,
          _buildImage(
            element.attributes['src']!,
            element.attributes['title'],
            element.attributes['alt'],
          ),
        ));
      } else if (tag == 'br') {
        current.children.add(_buildRichText(const TextSpan(text: '\n')));
      } else if (tag == 'th' || tag == 'td') {
        final bool isHeaderCell = tag == 'th';
        TextAlign? align;
        final String? alignAttribute = element.attributes['align'];
        if (alignAttribute == null) {
          align = tag == 'th' ? styleSheet.tableHeadAlign : TextAlign.left;
        } else {
          switch (alignAttribute) {
            case 'left':
              align = TextAlign.left;
            case 'center':
              align = TextAlign.center;
            case 'right':
              align = TextAlign.right;
          }
        }
        final Widget child = _buildTableCell(
          _mergeInlineChildren(current.children, align),
          textAlign: align,
          isHeader: isHeaderCell,
        );
        _tables.single.rows.last.children.add(child);
      } else if (tag == 'a') {
        if (!builders.containsKey('a')) {
          _linkHandlers.removeLast();
        }
      } else if (tag == 'sup') {
        final Widget c = current.children.last;
        TextSpan? textSpan;
        if (c is Text && c.textSpan is TextSpan) {
          textSpan = c.textSpan! as TextSpan;
        } else if (c is SelectableText && c.textSpan is TextSpan) {
          textSpan = c.textSpan;
        }
        if (textSpan != null) {
          final Widget richText = _buildRichText(
            TextSpan(
              recognizer: textSpan.recognizer,
              text: element.textContent,
              style: textSpan.style?.copyWith(
                fontFeatures: <FontFeature>[
                  const FontFeature.enable('sups'),
                  if (styleSheet.superscriptFontFeatureTag != null) FontFeature.enable(styleSheet.superscriptFontFeatureTag!),
                ],
              ),
            ),
          );
          current.children.removeLast();
          current.children.add(richText);
        }
      }

      if (current.children.isNotEmpty) {
        parent.children.addAll(current.children);
      }
    }
    if (_currentBlockTag == tag) {
      _currentBlockTag = null;
    }
    _lastVisitedTag = tag;
  }

  Widget _buildTable() {
    final Table table = Table(
      defaultColumnWidth: styleSheet.tableColumnWidth!,
      defaultVerticalAlignment: styleSheet.tableVerticalAlignment,
      border: styleSheet.tableBorder,
      children: _tables.removeLast().rows,
    );

    final BorderRadiusGeometry? borderRadius = styleSheet.tableBorder?.borderRadius;
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: table,
      );
    }

    return table;
  }

  Widget _buildImage(String src, String? title, String? alt) {
    final List<String> parts = src.split('#');
    if (parts.isEmpty) {
      return const SizedBox();
    }

    final String path = parts.first;
    double? width;
    double? height;
    if (parts.length == 2) {
      final List<String> dimensions = parts.last.split('x');
      if (dimensions.length == 2) {
        width = double.tryParse(dimensions[0]);
        height = double.tryParse(dimensions[1]);
      }
    }

    final Uri? uri = Uri.tryParse(path);

    if (uri == null) {
      return const SizedBox();
    }

    Widget child;
    if (imageBuilder != null) {
      child = imageBuilder!(uri, title, alt);
    } else {
      child = kDefaultImageBuilder(uri, imageDirectory, width, height);
    }

    if (_linkHandlers.isNotEmpty) {
      final TapGestureRecognizer recognizer = _linkHandlers.last as TapGestureRecognizer;
      return GestureDetector(onTap: recognizer.onTap, child: child);
    } else {
      return child;
    }
  }

  Widget _buildCheckbox(bool checked) {
    if (checkboxBuilder != null) {
      return checkboxBuilder!(checked);
    }
    return Padding(
      padding: styleSheet.listBulletPadding!,
      child: Icon(
        checked ? Icons.check_box : Icons.check_box_outline_blank,
        size: styleSheet.checkbox!.fontSize,
        color: styleSheet.checkbox!.color,
      ),
    );
  }

  Widget _buildBullet(String listTag) {
    final int index = _blocks.last.nextListIndex;
    final bool isUnordered = listTag == 'ul';

    if (bulletBuilder != null) {
      return Padding(
        padding: styleSheet.listBulletPadding!,
        child: bulletBuilder!(
          MarkdownBulletParameters(
            index: index,
            style: isUnordered ? BulletStyle.unorderedList : BulletStyle.orderedList,
            nestLevel: _listIndents.length - 1,
          ),
        ),
      );
    }

    if (isUnordered) {
      return Padding(
        padding: styleSheet.listBulletPadding!,
        child: Text(
          '•',
          textAlign: TextAlign.center,
          style: styleSheet.listBullet,
        ),
      );
    }

    return Padding(
      padding: styleSheet.listBulletPadding!,
      child: Text(
        '${index + 1}.',
        textAlign: TextAlign.right,
        style: styleSheet.listBullet,
      ),
    );
  }

  Widget _buildTableCell(List<Widget?> children, {TextAlign? textAlign, bool isHeader = false}) {
    final EdgeInsets cellPadding = isHeader && styleSheet.tableHeadCellsPadding != null ? styleSheet.tableHeadCellsPadding! : styleSheet.tableCellsPadding!;

    final TextStyle cellStyle = isHeader && styleSheet.tableHead != null ? styleSheet.tableHead! : styleSheet.tableBody!;

    return TableCell(
      child: Padding(
        padding: cellPadding,
        child: DefaultTextStyle(
          style: cellStyle,
          textAlign: textAlign,
          child: Wrap(
            alignment: switch (textAlign) {
              TextAlign.left => WrapAlignment.start,
              TextAlign.center => WrapAlignment.center,
              TextAlign.right => WrapAlignment.end,
              _ => WrapAlignment.start,
            },
            children: children as List<Widget>,
          ),
        ),
      ),
    );
  }

  Widget _buildPadding(EdgeInsets padding, Widget child) {
    if (padding == EdgeInsets.zero) {
      return child;
    }

    return Padding(padding: padding, child: child);
  }

  void _addParentInlineIfNeeded(String? tag) {
    if (_inlines.isEmpty) {
      _inlines.add(_InlineElement(
        tag,
        style: tag != null ? styleSheet.styles[tag] : null,
      ));
    }
  }

  void _addBlockChild(Widget child) {
    final _BlockElement parent = _blocks.last;
    if (parent.children.isNotEmpty) {
      parent.children.add(SizedBox(height: styleSheet.blockSpacing));
    }
    parent.children.add(child);
    parent.nextListIndex += 1;
  }

  void _addAnonymousBlockIfNeeded() {
    if (_inlines.isEmpty) {
      return;
    }

    WrapAlignment blockAlignment = WrapAlignment.start;
    TextAlign textAlign = TextAlign.start;
    EdgeInsets textPadding = EdgeInsets.zero;
    if (_isBlockTag(_currentBlockTag)) {
      blockAlignment = _wrapAlignmentForBlockTag(_currentBlockTag);
      textAlign = _textAlignForBlockTag(_currentBlockTag);
      textPadding = _textPaddingForBlockTag(_currentBlockTag);

      if (paddingBuilders.containsKey(_currentBlockTag)) {
        textPadding = paddingBuilders[_currentBlockTag]!.getPadding();
      }
    }

    final _InlineElement inline = _inlines.single;
    if (inline.children.isNotEmpty) {
      final List<Widget> mergedInlines = _mergeInlineChildren(
        inline.children,
        textAlign,
      );
      final Wrap wrap = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: blockAlignment,
        children: mergedInlines,
      );

      if (textPadding == EdgeInsets.zero) {
        _addBlockChild(wrap);
      } else {
        final Padding padding = Padding(padding: textPadding, child: wrap);
        _addBlockChild(padding);
      }
    }

    _inlines.clear();
  }

  Iterable<InlineSpan> _getInlineSpansFromSpan(InlineSpan span) {

    if (span is! TextSpan || span.children == null) {
      return <InlineSpan>[span];
    }

    final Iterable<InlineSpan> spans = span.children!.map((InlineSpan childSpan) {
      if (childSpan is TextSpan) {
        return TextSpan(
          text: childSpan.text,
          recognizer: childSpan.recognizer,
          semanticsLabel: childSpan.semanticsLabel,
          style: childSpan.style?.merge(span.style),
        );
      } else {
        return childSpan;
      }
    });

    return spans;
  }

  InlineSpan? _getInlineSpanFromText(Widget widget) => switch (widget) { SelectableText() => widget.textSpan, Text() => widget.textSpan, RichText() => widget.text, _ => null };

  List<Widget> _mergeInlineChildren(
    List<Widget> children,
    TextAlign? textAlign,
  ) {

    final List<Widget> mergedWidgets = <Widget>[];

    bool lastIsText = false;
    for (final Widget child in children) {
      final InlineSpan? currentSpan = _getInlineSpanFromText(child);
      final bool currentIsText = currentSpan != null;

      if (!currentIsText) {

        mergedWidgets.add(child);
        lastIsText = false;
        continue;
      }

      List<InlineSpan> spans = <InlineSpan>[];

      if (lastIsText) {

        spans.addAll(_getInlineSpansFromSpan(_getInlineSpanFromText(mergedWidgets.removeLast())!));
      }

      spans.addAll(_getInlineSpansFromSpan(currentSpan));
      spans = _mergeSimilarTextSpans(spans);

      final Widget mergedWidget;

      if (spans.isEmpty) {

        mergedWidget = child;
      } else {
        final InlineSpan first = spans.first;
        final TextSpan textSpan = (spans.length == 1 && first is TextSpan) ? first : TextSpan(children: spans);
        mergedWidget = _buildRichText(textSpan, textAlign: textAlign);
      }

      mergedWidgets.add(mergedWidget);
      lastIsText = true;
    }

    return mergedWidgets;
  }

  TextAlign _textAlignForBlockTag(String? blockTag) {
    final WrapAlignment wrapAlignment = _wrapAlignmentForBlockTag(blockTag);
    switch (wrapAlignment) {
      case WrapAlignment.start:
        return TextAlign.start;
      case WrapAlignment.center:
        return TextAlign.center;
      case WrapAlignment.end:
        return TextAlign.end;
      case WrapAlignment.spaceAround:
        return TextAlign.justify;
      case WrapAlignment.spaceBetween:
        return TextAlign.justify;
      case WrapAlignment.spaceEvenly:
        return TextAlign.justify;
    }
  }

  WrapAlignment _wrapAlignmentForBlockTag(String? blockTag) {
    switch (blockTag) {
      case 'p':
        return styleSheet.textAlign;
      case 'h1':
        return styleSheet.h1Align;
      case 'h2':
        return styleSheet.h2Align;
      case 'h3':
        return styleSheet.h3Align;
      case 'h4':
        return styleSheet.h4Align;
      case 'h5':
        return styleSheet.h5Align;
      case 'h6':
        return styleSheet.h6Align;
      case 'ul':
        return styleSheet.unorderedListAlign;
      case 'ol':
        return styleSheet.orderedListAlign;
      case 'blockquote':
        return styleSheet.blockquoteAlign;
      case 'pre':
        return styleSheet.codeblockAlign;
      case 'hr':
        break;
      case 'li':
        break;
    }
    return WrapAlignment.start;
  }

  EdgeInsets _textPaddingForBlockTag(String? blockTag) {
    switch (blockTag) {
      case 'p':
        return styleSheet.pPadding!;
      case 'h1':
        return styleSheet.h1Padding!;
      case 'h2':
        return styleSheet.h2Padding!;
      case 'h3':
        return styleSheet.h3Padding!;
      case 'h4':
        return styleSheet.h4Padding!;
      case 'h5':
        return styleSheet.h5Padding!;
      case 'h6':
        return styleSheet.h6Padding!;
    }
    return EdgeInsets.zero;
  }

  List<InlineSpan> _mergeSimilarTextSpans(List<InlineSpan> textSpans) {
    if (textSpans.length < 2) {
      return textSpans;
    }

    final List<InlineSpan> mergedSpans = <InlineSpan>[];

    for (int index = 1; index < textSpans.length; index++) {
      final InlineSpan previous = mergedSpans.isEmpty ? textSpans.first : mergedSpans.removeLast();
      final InlineSpan nextChild = textSpans[index];

      final bool previousIsTextSpan = previous is TextSpan;
      final bool nextIsTextSpan = nextChild is TextSpan;
      if (!previousIsTextSpan || !nextIsTextSpan) {
        mergedSpans.addAll(<InlineSpan>[previous, nextChild]);
        continue;
      }

      final bool matchStyle = nextChild.recognizer == previous.recognizer && nextChild.semanticsLabel == previous.semanticsLabel && nextChild.style == previous.style;

      if (matchStyle) {
        mergedSpans.add(TextSpan(
          text: previous.toPlainText() + nextChild.toPlainText(),
          recognizer: previous.recognizer,
          semanticsLabel: previous.semanticsLabel,
          style: previous.style,
        ));
      } else {
        mergedSpans.addAll(<InlineSpan>[previous, nextChild]);
      }
    }

    return mergedSpans;
  }

  Widget _buildRichText(TextSpan text, {TextAlign? textAlign, String? key}) {

    final Key k = key == null ? UniqueKey() : Key(key);
    if (selectable) {
      return SelectableText.rich(
        text,
        textScaler: styleSheet.textScaler,
        textAlign: textAlign ?? TextAlign.start,
        onSelectionChanged: onSelectionChanged != null ? (TextSelection selection, SelectionChangedCause? cause) => onSelectionChanged!(text.text, selection, cause) : null,
        onTap: onTapText,
        key: k,
      );
    } else {
      return Text.rich(
        text,
        textScaler: styleSheet.textScaler,
        textAlign: textAlign ?? TextAlign.start,
        key: k,
      );
    }
  }
}

class _ScrollControllerBuilder extends StatefulWidget {
  const _ScrollControllerBuilder({
    required this.builder,
    this.child,
  });

  final ValueWidgetBuilder<ScrollController> builder;

  final Widget? child;

  @override
  State<_ScrollControllerBuilder> createState() => _ScrollControllerBuilderState();
}

class _ScrollControllerBuilderState extends State<_ScrollControllerBuilder> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller, widget.child);
  }
}
