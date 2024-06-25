import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_text_flutter/src/extensions/item_span_default_config.dart';
import 'package:smart_text_flutter/smart_text_flutter.dart';

/// The smart text which automatically detect links in text and renders them
class SmartText extends StatefulWidget {
  const SmartText(
    this.text, {
    super.key,
    this.config,
    this.addressConfig,
    this.dateTimeConfig,
    this.emailConfig,
    this.phoneConfig,
    this.mentionConfig,
    this.urlConfig,
    this.strutStyle,
    this.locale,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.selectionColor,
    this.semanticsLabel,
    this.softWrap,
    this.textHeightBehavior,
    this.textScaler,
    this.textWidthBasis,
  });

  /// The text to linkify
  /// This text will be classified and the links will be highlighted
  final String text;

  /// The configuration for setting the [TextStyle] and onClicked method
  /// This affects the whole text
  final ItemSpanConfig? config;

  /// The configuration for setting the [TextStyle] and what happens when the address link is clicked
  final ItemSpanConfig? addressConfig;

  /// The configuration for setting the [TextStyle] and what happens when the phone link is clicked
  final ItemSpanConfig? phoneConfig;

  /// The configuration for setting the [TextStyle] and what happens when the url is clicked
  final ItemSpanConfig? urlConfig;

  /// The configuration for setting the [TextStyle] and what happens when the date time is clicked
  final ItemSpanConfig? dateTimeConfig;

  /// The configuration for setting the [TextStyle] and what happens when the email link is clicked
  final ItemSpanConfig? emailConfig;

  /// The configuration for setting the [TextStyle] and what happens when the mention link is clicked
  final ItemSpanConfig? mentionConfig;

  final StrutStyle? strutStyle;

  final TextAlign? textAlign;

  final TextDirection? textDirection;

  final Locale? locale;

  final bool? softWrap;

  final TextOverflow? overflow;

  final TextScaler? textScaler;

  final int? maxLines;

  final String? semanticsLabel;

  final TextWidthBasis? textWidthBasis;

  final ui.TextHeightBehavior? textHeightBehavior;

  final Color? selectionColor;

  @override
  State<SmartText> createState() => _SmartTextState();
}

class _SmartTextState extends State<SmartText> {
  late Future<List<ItemSpan>> classifyTextFuture;

  @override
  void initState() {
    super.initState();

    classifyTextFuture = getItemSpans();
  }

  @override
  void didUpdateWidget(covariant SmartText oldWidget) {
    if (oldWidget.text != widget.text) classifyTextFuture = getItemSpans();

    super.didUpdateWidget(oldWidget);
  }

  Future<List<ItemSpan>> getItemSpans() async {
    return SmartTextFlutter.classifyText(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemSpan>>(
      future: classifyTextFuture,
      builder: (context, snapshot) {
        List<InlineSpan> inlineSpanList = [];
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          inlineSpanList.addAll(getTextInlineSpans(ItemSpan(
            text: widget.text,
            type: ItemSpanType.text,
            rawValue: widget.text,
          )));
        } else {
          for (final span in snapshot.data!) {
            switch (span.type) {
              case ItemSpanType.text:
                inlineSpanList.addAll(getTextInlineSpans(span));
              case ItemSpanType.address:
                inlineSpanList.add(TextSpan(
                  text: span.text,
                  style: span.defaultConfig.textStyle?.merge(
                    widget.addressConfig?.textStyle,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => _handleItemSpanTap(span, widget.addressConfig),
                ));
              case ItemSpanType.email:
                inlineSpanList.add(TextSpan(
                  text: span.text,
                  style: span.defaultConfig.textStyle?.merge(
                    widget.emailConfig?.textStyle,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => _handleItemSpanTap(span, widget.emailConfig),
                ));
              case ItemSpanType.phone:
                inlineSpanList.add(TextSpan(
                  text: span.text,
                  style: span.defaultConfig.textStyle?.merge(
                    widget.phoneConfig?.textStyle,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => _handleItemSpanTap(span, widget.phoneConfig),
                ));
              case ItemSpanType.datetime:
                inlineSpanList.add(TextSpan(
                  text: span.text,
                  style: span.defaultConfig.textStyle?.merge(
                    widget.dateTimeConfig?.textStyle,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => _handleItemSpanTap(span, widget.dateTimeConfig),
                ));
              case ItemSpanType.url:
                inlineSpanList.add(TextSpan(
                  text: span.text,
                  style: span.defaultConfig.textStyle?.merge(
                    widget.urlConfig?.textStyle,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _handleItemSpanTap(span, widget.urlConfig),
                ));
            }
          }
        }
        return Text.rich(
          TextSpan(
            children: inlineSpanList,
            style: const TextStyle().merge(widget.config?.textStyle),
          ),
          strutStyle: widget.strutStyle,
          locale: widget.locale,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          selectionColor: widget.selectionColor,
          semanticsLabel: widget.semanticsLabel,
          softWrap: widget.softWrap,
          textDirection: widget.textDirection,
          textHeightBehavior: widget.textHeightBehavior,
          textScaler: widget.textScaler,
          textWidthBasis: widget.textWidthBasis,
        );
      },
    );
  }

  void _handleItemSpanTap(ItemSpan span, ItemSpanConfig? config) {
    if (config?.onClicked != null) {
      config?.onClicked?.call(span.rawValue);
    } else {
      span.defaultConfig.onClicked?.call(span.rawValue);
    }
  }

  List<String> splitMentioned(String input) {
    RegExp regex = RegExp(r"((^)|(( )+))@\w+(($)|(( )+))");
    Iterable<Match> matches = regex.allMatches(input);
    List<String> parts = [];
    int lastEnd = 0;
    for (Match match in matches) {
      int start = match.start;
      int end = match.end;
      if (start > lastEnd) {
        parts.add(input.substring(lastEnd, start));
      }
      parts.add(input.substring(start, end));
      lastEnd = end;
    }
    if (lastEnd < input.length) {
      parts.add(input.substring(lastEnd));
    }
    return parts;
  }

  List<InlineSpan> getTextInlineSpans(ItemSpan span) {
    return splitMentioned(span.text).map((text) {
      if (text.trim().startsWith('@')) {
        final int leftPadding = text.length - text.trimLeft().length;
        final int rightPadding = text.length - text.trimRight().length;
        return TextSpan(
          text: List.generate(leftPadding, (_) => " ").join(),
          children: [
            TextSpan(
              text: text.trim(),
              style: span.defaultConfig.textStyle?.merge(
                widget.mentionConfig?.textStyle,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _handleItemSpanTap(
                      ItemSpan(
                        text: text.trim(),
                        type: span.type,
                        rawValue: text.trim(),
                      ),
                      widget.mentionConfig,
                    ),
            ),
            TextSpan(
              text: List.generate(rightPadding, (_) => " ").join(),
            )
          ],
          style: span.defaultConfig.textStyle?.merge(
            widget.config?.textStyle,
          ),
        );
      }
      return TextSpan(
        text: text,
        style: span.defaultConfig.textStyle?.merge(
          widget.config?.textStyle,
        ),
      );
    }).toList();
  }
}
