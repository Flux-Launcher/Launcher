import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MarkdownStyleSheet {

  MarkdownStyleSheet({
    this.a,
    this.p,
    this.pPadding,
    this.code,
    this.h1,
    this.h1Padding,
    this.h2,
    this.h2Padding,
    this.h3,
    this.h3Padding,
    this.h4,
    this.h4Padding,
    this.h5,
    this.h5Padding,
    this.h6,
    this.h6Padding,
    this.em,
    this.strong,
    this.del,
    this.blockquote,
    this.img,
    this.checkbox,
    this.blockSpacing,
    this.listIndent,
    this.listBullet,
    this.listBulletPadding,
    this.tableHead,
    this.tableBody,
    this.tableHeadAlign,
    this.tablePadding,
    this.tableBorder,
    this.tableColumnWidth,
    this.tableScrollbarThumbVisibility,
    this.tableCellsPadding,
    this.tableCellsDecoration,
    this.tableHeadCellsPadding,
    this.tableHeadCellsDecoration,
    this.tableVerticalAlignment = TableCellVerticalAlignment.middle,
    this.blockquotePadding,
    this.blockquoteDecoration,
    this.codeblockPadding,
    this.codeblockDecoration,
    this.horizontalRuleDecoration,
    this.textAlign = WrapAlignment.start,
    this.h1Align = WrapAlignment.start,
    this.h2Align = WrapAlignment.start,
    this.h3Align = WrapAlignment.start,
    this.h4Align = WrapAlignment.start,
    this.h5Align = WrapAlignment.start,
    this.h6Align = WrapAlignment.start,
    this.unorderedListAlign = WrapAlignment.start,
    this.orderedListAlign = WrapAlignment.start,
    this.blockquoteAlign = WrapAlignment.start,
    this.codeblockAlign = WrapAlignment.start,
    this.superscriptFontFeatureTag,
    @Deprecated('Use textScaler instead.') this.textScaleFactor,
    TextScaler? textScaler,
  })  : assert(
          textScaler == null || textScaleFactor == null,
          'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
        ),
        textScaler = textScaler ??

            (textScaleFactor == null ? null : TextScaler.linear(textScaleFactor)),
        _styles = <String, TextStyle?>{
          'a': a,
          'p': p,
          'li': p,
          'code': code,
          'pre': p,
          'h1': h1,
          'h2': h2,
          'h3': h3,
          'h4': h4,
          'h5': h5,
          'h6': h6,
          'em': em,
          'strong': strong,
          'del': del,
          'blockquote': blockquote,
          'img': img,
          'table': p,
          'th': tableHead,
          'tr': tableBody,
          'td': tableBody,
        };

  factory MarkdownStyleSheet.fromTheme(ThemeData theme) {
    assert(theme.textTheme.bodyMedium?.fontSize != null);
    return MarkdownStyleSheet(
      a: const TextStyle(color: Colors.blue),
      p: theme.textTheme.bodyMedium,
      pPadding: EdgeInsets.zero,
      code: theme.textTheme.bodyMedium!.copyWith(
        backgroundColor: theme.cardTheme.color,
        fontFamily: 'monospace',
        fontSize: theme.textTheme.bodyMedium!.fontSize! * 0.85,
      ),
      h1: theme.textTheme.headlineSmall,
      h1Padding: EdgeInsets.zero,
      h2: theme.textTheme.titleLarge,
      h2Padding: EdgeInsets.zero,
      h3: theme.textTheme.titleMedium,
      h3Padding: EdgeInsets.zero,
      h4: theme.textTheme.bodyLarge,
      h4Padding: EdgeInsets.zero,
      h5: theme.textTheme.bodyLarge,
      h5Padding: EdgeInsets.zero,
      h6: theme.textTheme.bodyLarge,
      h6Padding: EdgeInsets.zero,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      blockquote: theme.textTheme.bodyMedium,
      img: theme.textTheme.bodyMedium,
      checkbox: theme.textTheme.bodyMedium!.copyWith(
        color: theme.primaryColor,
      ),
      blockSpacing: 8.0,
      listIndent: 24.0,
      listBullet: theme.textTheme.bodyMedium,
      listBulletPadding: const EdgeInsets.only(right: 4),
      tableHead: const TextStyle(fontWeight: FontWeight.w600),
      tableBody: theme.textTheme.bodyMedium,
      tableHeadAlign: TextAlign.center,
      tablePadding: const EdgeInsets.only(bottom: 4.0),
      tableBorder: TableBorder.all(
        color: theme.dividerColor,
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      tableCellsDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.all(8.0),
      blockquoteDecoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(2.0),
      ),
      codeblockPadding: const EdgeInsets.all(8.0),
      codeblockDecoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(2.0),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 5.0,
            color: theme.dividerColor,
          ),
        ),
      ),
    );
  }

  factory MarkdownStyleSheet.fromCupertinoTheme(CupertinoThemeData theme) {
    assert(theme.textTheme.textStyle.fontSize != null);
    return MarkdownStyleSheet(
      a: theme.textTheme.textStyle.copyWith(
        color: theme.brightness == Brightness.dark ? CupertinoColors.link.darkColor : CupertinoColors.link.color,
      ),
      p: theme.textTheme.textStyle,
      pPadding: EdgeInsets.zero,
      code: theme.textTheme.textStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: theme.textTheme.textStyle.fontSize! * 0.85,
      ),
      h1: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: theme.textTheme.textStyle.fontSize! + 10,
      ),
      h1Padding: EdgeInsets.zero,
      h2: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: theme.textTheme.textStyle.fontSize! + 8,
      ),
      h2Padding: EdgeInsets.zero,
      h3: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: theme.textTheme.textStyle.fontSize! + 6,
      ),
      h3Padding: EdgeInsets.zero,
      h4: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: theme.textTheme.textStyle.fontSize! + 4,
      ),
      h4Padding: EdgeInsets.zero,
      h5: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: theme.textTheme.textStyle.fontSize! + 2,
      ),
      h5Padding: EdgeInsets.zero,
      h6: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w500,
      ),
      h6Padding: EdgeInsets.zero,
      em: theme.textTheme.textStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      strong: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
      del: theme.textTheme.textStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      blockquote: theme.textTheme.textStyle,
      img: theme.textTheme.textStyle,
      checkbox: theme.textTheme.textStyle.copyWith(
        color: theme.primaryColor,
      ),
      blockSpacing: 8,
      listIndent: 24,
      listBullet: theme.textTheme.textStyle,
      listBulletPadding: const EdgeInsets.only(right: 4),
      tableHead: theme.textTheme.textStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      tableBody: theme.textTheme.textStyle,
      tableHeadAlign: TextAlign.center,
      tablePadding: const EdgeInsets.only(bottom: 8),
      tableBorder: TableBorder.all(color: CupertinoColors.separator, width: 0),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      tableCellsDecoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6.color,
      ),
      blockquotePadding: const EdgeInsets.all(16),
      blockquoteDecoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6.color,
        border: Border(
          left: BorderSide(
            color: theme.brightness == Brightness.dark ? CupertinoColors.systemGrey4.darkColor : CupertinoColors.systemGrey4.color,
            width: 4,
          ),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(8),
      codeblockDecoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6.color,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark ? CupertinoColors.systemGrey4.darkColor : CupertinoColors.systemGrey4.color,
          ),
        ),
      ),
    );
  }

  factory MarkdownStyleSheet.largeFromTheme(ThemeData theme) {
    return MarkdownStyleSheet(
      a: const TextStyle(color: Colors.blue),
      p: theme.textTheme.bodyMedium,
      pPadding: EdgeInsets.zero,
      code: theme.textTheme.bodyMedium!.copyWith(
        backgroundColor: theme.cardTheme.color,
        fontFamily: 'monospace',
        fontSize: theme.textTheme.bodyMedium!.fontSize! * 0.85,
      ),
      h1: theme.textTheme.displayMedium,
      h1Padding: EdgeInsets.zero,
      h2: theme.textTheme.displaySmall,
      h2Padding: EdgeInsets.zero,
      h3: theme.textTheme.headlineMedium,
      h3Padding: EdgeInsets.zero,
      h4: theme.textTheme.headlineSmall,
      h4Padding: EdgeInsets.zero,
      h5: theme.textTheme.titleLarge,
      h5Padding: EdgeInsets.zero,
      h6: theme.textTheme.titleMedium,
      h6Padding: EdgeInsets.zero,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      blockquote: theme.textTheme.bodyMedium,
      img: theme.textTheme.bodyMedium,
      checkbox: theme.textTheme.bodyMedium!.copyWith(
        color: theme.primaryColor,
      ),
      blockSpacing: 8.0,
      listIndent: 24.0,
      listBullet: theme.textTheme.bodyMedium,
      listBulletPadding: const EdgeInsets.only(right: 4),
      tableHead: const TextStyle(fontWeight: FontWeight.w600),
      tableBody: theme.textTheme.bodyMedium,
      tableHeadAlign: TextAlign.center,
      tablePadding: const EdgeInsets.only(bottom: 4.0),
      tableBorder: TableBorder.all(
        color: theme.dividerColor,
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      tableCellsDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.all(8.0),
      blockquoteDecoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(2.0),
      ),
      codeblockPadding: const EdgeInsets.all(8.0),
      codeblockDecoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(2.0),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 5.0,
            color: theme.dividerColor,
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet copyWith({
    TextStyle? a,
    TextStyle? p,
    EdgeInsets? pPadding,
    TextStyle? code,
    TextStyle? h1,
    EdgeInsets? h1Padding,
    TextStyle? h2,
    EdgeInsets? h2Padding,
    TextStyle? h3,
    EdgeInsets? h3Padding,
    TextStyle? h4,
    EdgeInsets? h4Padding,
    TextStyle? h5,
    EdgeInsets? h5Padding,
    TextStyle? h6,
    EdgeInsets? h6Padding,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? blockquote,
    TextStyle? img,
    TextStyle? checkbox,
    double? blockSpacing,
    double? listIndent,
    TextStyle? listBullet,
    EdgeInsets? listBulletPadding,
    TextStyle? tableHead,
    TextStyle? tableBody,
    TextAlign? tableHeadAlign,
    EdgeInsets? tablePadding,
    TableBorder? tableBorder,
    TableColumnWidth? tableColumnWidth,
    bool? tableScrollbarThumbVisibility,
    EdgeInsets? tableCellsPadding,
    Decoration? tableCellsDecoration,
    EdgeInsets? tableHeadCellsPadding,
    Decoration? tableHeadCellsDecoration,
    TableCellVerticalAlignment? tableVerticalAlignment,
    EdgeInsets? blockquotePadding,
    Decoration? blockquoteDecoration,
    EdgeInsets? codeblockPadding,
    Decoration? codeblockDecoration,
    Decoration? horizontalRuleDecoration,
    WrapAlignment? textAlign,
    WrapAlignment? h1Align,
    WrapAlignment? h2Align,
    WrapAlignment? h3Align,
    WrapAlignment? h4Align,
    WrapAlignment? h5Align,
    WrapAlignment? h6Align,
    WrapAlignment? unorderedListAlign,
    WrapAlignment? orderedListAlign,
    WrapAlignment? blockquoteAlign,
    WrapAlignment? codeblockAlign,
    String? superscriptFontFeatureTag,
    @Deprecated('Use textScaler instead.') double? textScaleFactor,
    TextScaler? textScaler,
  }) {
    assert(
      textScaler == null || textScaleFactor == null,
      'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
    );

    final TextScaler? newTextScaler = textScaler ?? (textScaleFactor == null ? this.textScaler : null);
    final double? nextTextScaleFactor = textScaleFactor ?? (textScaler == null ? this.textScaleFactor : null);
    return MarkdownStyleSheet(
      a: a ?? this.a,
      p: p ?? this.p,
      pPadding: pPadding ?? this.pPadding,
      code: code ?? this.code,
      h1: h1 ?? this.h1,
      h1Padding: h1Padding ?? this.h1Padding,
      h2: h2 ?? this.h2,
      h2Padding: h2Padding ?? this.h2Padding,
      h3: h3 ?? this.h3,
      h3Padding: h3Padding ?? this.h3Padding,
      h4: h4 ?? this.h4,
      h4Padding: h4Padding ?? this.h4Padding,
      h5: h5 ?? this.h5,
      h5Padding: h5Padding ?? this.h5Padding,
      h6: h6 ?? this.h6,
      h6Padding: h6Padding ?? this.h6Padding,
      em: em ?? this.em,
      strong: strong ?? this.strong,
      del: del ?? this.del,
      blockquote: blockquote ?? this.blockquote,
      img: img ?? this.img,
      checkbox: checkbox ?? this.checkbox,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      listIndent: listIndent ?? this.listIndent,
      listBullet: listBullet ?? this.listBullet,
      listBulletPadding: listBulletPadding ?? this.listBulletPadding,
      tableHead: tableHead ?? this.tableHead,
      tableBody: tableBody ?? this.tableBody,
      tableHeadAlign: tableHeadAlign ?? this.tableHeadAlign,
      tablePadding: tablePadding ?? this.tablePadding,
      tableBorder: tableBorder ?? this.tableBorder,
      tableColumnWidth: tableColumnWidth ?? this.tableColumnWidth,
      tableScrollbarThumbVisibility: tableScrollbarThumbVisibility,
      tableCellsPadding: tableCellsPadding ?? this.tableCellsPadding,
      tableCellsDecoration: tableCellsDecoration ?? this.tableCellsDecoration,
      tableHeadCellsPadding: tableHeadCellsPadding ?? this.tableHeadCellsPadding,
      tableHeadCellsDecoration: tableHeadCellsDecoration ?? this.tableHeadCellsDecoration,
      tableVerticalAlignment: tableVerticalAlignment ?? this.tableVerticalAlignment,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
      blockquoteDecoration: blockquoteDecoration ?? this.blockquoteDecoration,
      codeblockPadding: codeblockPadding ?? this.codeblockPadding,
      codeblockDecoration: codeblockDecoration ?? this.codeblockDecoration,
      horizontalRuleDecoration: horizontalRuleDecoration ?? this.horizontalRuleDecoration,
      textAlign: textAlign ?? this.textAlign,
      h1Align: h1Align ?? this.h1Align,
      h2Align: h2Align ?? this.h2Align,
      h3Align: h3Align ?? this.h3Align,
      h4Align: h4Align ?? this.h4Align,
      h5Align: h5Align ?? this.h5Align,
      h6Align: h6Align ?? this.h6Align,
      unorderedListAlign: unorderedListAlign ?? this.unorderedListAlign,
      orderedListAlign: orderedListAlign ?? this.orderedListAlign,
      blockquoteAlign: blockquoteAlign ?? this.blockquoteAlign,
      codeblockAlign: codeblockAlign ?? this.codeblockAlign,
      superscriptFontFeatureTag: superscriptFontFeatureTag ?? this.superscriptFontFeatureTag,
      textScaler: newTextScaler,
      textScaleFactor: nextTextScaleFactor,
    );
  }

  MarkdownStyleSheet merge(MarkdownStyleSheet? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      a: a!.merge(other.a),
      p: p!.merge(other.p),
      pPadding: other.pPadding,
      code: code!.merge(other.code),
      h1: h1!.merge(other.h1),
      h1Padding: other.h1Padding,
      h2: h2!.merge(other.h2),
      h2Padding: other.h2Padding,
      h3: h3!.merge(other.h3),
      h3Padding: other.h3Padding,
      h4: h4!.merge(other.h4),
      h4Padding: other.h4Padding,
      h5: h5!.merge(other.h5),
      h5Padding: other.h5Padding,
      h6: h6!.merge(other.h6),
      h6Padding: other.h6Padding,
      em: em!.merge(other.em),
      strong: strong!.merge(other.strong),
      del: del!.merge(other.del),
      blockquote: blockquote!.merge(other.blockquote),
      img: img!.merge(other.img),
      checkbox: checkbox!.merge(other.checkbox),
      blockSpacing: other.blockSpacing,
      listIndent: other.listIndent,
      listBullet: listBullet!.merge(other.listBullet),
      listBulletPadding: other.listBulletPadding,
      tableHead: tableHead!.merge(other.tableHead),
      tableBody: tableBody!.merge(other.tableBody),
      tableHeadAlign: other.tableHeadAlign,
      tablePadding: other.tablePadding,
      tableBorder: other.tableBorder,
      tableColumnWidth: other.tableColumnWidth,
      tableScrollbarThumbVisibility: other.tableScrollbarThumbVisibility,
      tableCellsPadding: other.tableCellsPadding,
      tableCellsDecoration: other.tableCellsDecoration,
      tableHeadCellsPadding: other.tableHeadCellsPadding,
      tableHeadCellsDecoration: other.tableHeadCellsDecoration,
      tableVerticalAlignment: other.tableVerticalAlignment,
      blockquotePadding: other.blockquotePadding,
      blockquoteDecoration: other.blockquoteDecoration,
      codeblockPadding: other.codeblockPadding,
      codeblockDecoration: other.codeblockDecoration,
      horizontalRuleDecoration: other.horizontalRuleDecoration,
      textAlign: other.textAlign,
      h1Align: other.h1Align,
      h2Align: other.h2Align,
      h3Align: other.h3Align,
      h4Align: other.h4Align,
      h5Align: other.h5Align,
      h6Align: other.h6Align,
      unorderedListAlign: other.unorderedListAlign,
      orderedListAlign: other.orderedListAlign,
      blockquoteAlign: other.blockquoteAlign,
      codeblockAlign: other.codeblockAlign,
      textScaleFactor: other.textScaleFactor,
      superscriptFontFeatureTag: other.superscriptFontFeatureTag,

      textScaler: other.textScaleFactor == null ? other.textScaler : null,
    );
  }

  final TextStyle? a;

  final TextStyle? p;

  final EdgeInsets? pPadding;

  final TextStyle? code;

  final TextStyle? h1;

  final EdgeInsets? h1Padding;

  final TextStyle? h2;

  final EdgeInsets? h2Padding;

  final TextStyle? h3;

  final EdgeInsets? h3Padding;

  final TextStyle? h4;

  final EdgeInsets? h4Padding;

  final TextStyle? h5;

  final EdgeInsets? h5Padding;

  final TextStyle? h6;

  final EdgeInsets? h6Padding;

  final TextStyle? em;

  final TextStyle? strong;

  final TextStyle? del;

  final TextStyle? blockquote;

  final TextStyle? img;

  final TextStyle? checkbox;

  final double? blockSpacing;

  final double? listIndent;

  final TextStyle? listBullet;

  final EdgeInsets? listBulletPadding;

  final TextStyle? tableHead;

  final TextStyle? tableBody;

  final TextAlign? tableHeadAlign;

  final EdgeInsets? tablePadding;

  final TableBorder? tableBorder;

  final TableColumnWidth? tableColumnWidth;

  final bool? tableScrollbarThumbVisibility;

  final EdgeInsets? tableCellsPadding;

  final Decoration? tableCellsDecoration;

  final EdgeInsets? tableHeadCellsPadding;

  final Decoration? tableHeadCellsDecoration;

  final TableCellVerticalAlignment tableVerticalAlignment;

  final EdgeInsets? blockquotePadding;

  final Decoration? blockquoteDecoration;

  final EdgeInsets? codeblockPadding;

  final Decoration? codeblockDecoration;

  final Decoration? horizontalRuleDecoration;

  final WrapAlignment textAlign;

  final WrapAlignment h1Align;

  final WrapAlignment h2Align;

  final WrapAlignment h3Align;

  final WrapAlignment h4Align;

  final WrapAlignment h5Align;

  final WrapAlignment h6Align;

  final WrapAlignment unorderedListAlign;

  final WrapAlignment orderedListAlign;

  final WrapAlignment blockquoteAlign;

  final WrapAlignment codeblockAlign;

  final TextScaler? textScaler;

  @Deprecated('Use textScaler instead.')
  final double? textScaleFactor;

  final String? superscriptFontFeatureTag;

  Map<String, TextStyle?> get styles => _styles;
  Map<String, TextStyle?> _styles;

  @override

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != MarkdownStyleSheet) {
      return false;
    }
    return other is MarkdownStyleSheet &&
        other.a == a &&
        other.p == p &&
        other.pPadding == pPadding &&
        other.code == code &&
        other.h1 == h1 &&
        other.h1Padding == h1Padding &&
        other.h2 == h2 &&
        other.h2Padding == h2Padding &&
        other.h3 == h3 &&
        other.h3Padding == h3Padding &&
        other.h4 == h4 &&
        other.h4Padding == h4Padding &&
        other.h5 == h5 &&
        other.h5Padding == h5Padding &&
        other.h6 == h6 &&
        other.h6Padding == h6Padding &&
        other.em == em &&
        other.strong == strong &&
        other.del == del &&
        other.blockquote == blockquote &&
        other.img == img &&
        other.checkbox == checkbox &&
        other.blockSpacing == blockSpacing &&
        other.listIndent == listIndent &&
        other.listBullet == listBullet &&
        other.listBulletPadding == listBulletPadding &&
        other.tableHead == tableHead &&
        other.tableBody == tableBody &&
        other.tableHeadAlign == tableHeadAlign &&
        other.tablePadding == tablePadding &&
        other.tableBorder == tableBorder &&
        other.tableColumnWidth == tableColumnWidth &&
        other.tableCellsPadding == tableCellsPadding &&
        other.tableCellsDecoration == tableCellsDecoration &&
        other.tableHeadCellsPadding == tableHeadCellsPadding &&
        other.tableHeadCellsDecoration == tableHeadCellsDecoration &&
        other.tableVerticalAlignment == tableVerticalAlignment &&
        other.blockquotePadding == blockquotePadding &&
        other.blockquoteDecoration == blockquoteDecoration &&
        other.codeblockPadding == codeblockPadding &&
        other.codeblockDecoration == codeblockDecoration &&
        other.horizontalRuleDecoration == horizontalRuleDecoration &&
        other.textAlign == textAlign &&
        other.h1Align == h1Align &&
        other.h2Align == h2Align &&
        other.h3Align == h3Align &&
        other.h4Align == h4Align &&
        other.h5Align == h5Align &&
        other.h6Align == h6Align &&
        other.unorderedListAlign == unorderedListAlign &&
        other.orderedListAlign == orderedListAlign &&
        other.blockquoteAlign == blockquoteAlign &&
        other.codeblockAlign == codeblockAlign &&
        other.superscriptFontFeatureTag == superscriptFontFeatureTag &&
        other.textScaler == textScaler;
  }

  @override

  int get hashCode {
    return Object.hashAll(<Object?>[
      a,
      p,
      pPadding,
      code,
      h1,
      h1Padding,
      h2,
      h2Padding,
      h3,
      h3Padding,
      h4,
      h4Padding,
      h5,
      h5Padding,
      h6,
      h6Padding,
      em,
      strong,
      del,
      blockquote,
      img,
      checkbox,
      blockSpacing,
      listIndent,
      listBullet,
      listBulletPadding,
      tableHead,
      tableBody,
      tableHeadAlign,
      tablePadding,
      tableBorder,
      tableColumnWidth,
      tableCellsPadding,
      tableCellsDecoration,
      tableHeadCellsPadding,
      tableHeadCellsDecoration,
      tableVerticalAlignment,
      blockquotePadding,
      blockquoteDecoration,
      codeblockPadding,
      codeblockDecoration,
      horizontalRuleDecoration,
      textAlign,
      h1Align,
      h2Align,
      h3Align,
      h4Align,
      h5Align,
      h6Align,
      unorderedListAlign,
      orderedListAlign,
      blockquoteAlign,
      codeblockAlign,
      textScaler,
      textScaleFactor,
      superscriptFontFeatureTag,
    ]);
  }
}
