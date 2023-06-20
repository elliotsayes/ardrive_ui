import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';

enum RadioButtonState { unchecked, hover, checked, disabled }

class RadioButtonOptions {
  RadioButtonOptions({
    this.value = false,
    this.isEnabled = true,
    required this.text,
    this.textStyle,
    this.content,
  });

  bool value;
  bool isEnabled;
  String text;
  final TextStyle? textStyle;
  final Widget? content;
}

class ArDriveRadioButtonGroup extends StatefulWidget {
  const ArDriveRadioButtonGroup({
    super.key,
    required this.options,
    this.onChanged,
    this.alignment = Alignment.centerLeft,
    required this.builder,
    this.size = 24,
  });

  final List<RadioButtonOptions> options;
  final Function(int, bool)? onChanged;
  final Alignment alignment;
  final Function(int index, ArDriveRadioButton radioButton) builder;
  final double size;

  @override
  State<ArDriveRadioButtonGroup> createState() =>
      _ArDriveRadioButtonGroupState();
}

class _ArDriveRadioButtonGroupState extends State<ArDriveRadioButtonGroup> {
  late final List<ValueNotifier<RadioButtonOptions>> _options;

  @override
  void initState() {
    _options = List.generate(
      widget.options.length,
      (i) => ValueNotifier(
        RadioButtonOptions(
          isEnabled: widget.options[i].isEnabled,
          value: widget.options[i].value,
          text: widget.options[i].text,
          content: widget.options[i].content,
          textStyle: widget.options[i].textStyle,
        ),
      ),
    );

    /// Can't have more than 1 checked at the time
    assert(_options.where((element) => element.value.value).length < 2);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) {
        return Align(
          alignment: widget.alignment,
          child: ValueListenableBuilder(
            builder: (context, t, w) {
              return widget.builder(
                i,
                ArDriveRadioButton(
                  content: _options[i].value.content,
                  size: widget.size,
                  textStyle: _options[i].value.textStyle,
                  isEnabled: _options[i].value.isEnabled,
                  isFromAGroup: true,
                  value: _options[i].value.value,
                  text: _options[i].value.text,
                  onChange: (value) async {
                    if (!value) {
                      return;
                    }

                    for (int j = 0; j < _options.length; j++) {
                      if (j == i) {
                        continue;
                      }
                      if (_options[j].value.value) {
                        _options[j].value = RadioButtonOptions(
                          isEnabled: _options[j].value.isEnabled,
                          value: false,
                          text: _options[j].value.text,
                        );
                      }
                    }

                    _options[i].value = RadioButtonOptions(
                      isEnabled: _options[i].value.isEnabled,
                      value: value,
                      text: _options[i].value.text,
                      content: _options[i].value.content,
                      textStyle: _options[i].value.textStyle,
                    );

                    widget.onChanged?.call(i, value);
                  },
                ),
              );
            },
            valueListenable: _options[i],
          ),
        );
      },
      itemCount: _options.length,
      shrinkWrap: true,
    );
  }
}

class ArDriveRadioButton extends StatefulWidget {
  const ArDriveRadioButton({
    super.key,
    this.value = false,
    this.isEnabled = true,
    required this.text,
    this.onChange,
    this.isFromAGroup = false,
    this.textStyle,
    this.size = 24,
    this.content,
  });

  final bool value;
  final bool isEnabled;
  final String text;
  final Function(bool)? onChange;
  final bool isFromAGroup;
  final TextStyle? textStyle;
  final double size;
  final Widget? content;

  @override
  State<ArDriveRadioButton> createState() => ArDriveRadioButtonState();
}

@visibleForTesting
class ArDriveRadioButtonState extends State<ArDriveRadioButton> {
  @visibleForTesting
  late RadioButtonState state;
  late bool _value;

  @override
  void initState() {
    _verifyState();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ArDriveRadioButton oldWidget) {
    _verifyState();
    setState(() {});
    super.didUpdateWidget(oldWidget);
  }

  void _verifyState() {
    if (!widget.isEnabled) {
      state = RadioButtonState.disabled;
      _value = false;
    } else if (widget.value) {
      state = RadioButtonState.checked;
      _value = true;
    } else {
      state = RadioButtonState.unchecked;
      _value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _radio();
  }

  Widget _radio() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (state == RadioButtonState.disabled) {
            return;
          }
          if (state == RadioButtonState.unchecked) {
            setState(() {
              state = RadioButtonState.checked;
            });
          } else if (state == RadioButtonState.checked &&
              !widget.isFromAGroup) {
            setState(() {
              state = RadioButtonState.unchecked;
            });
          }

          _value = !_value;

          widget.onChange?.call(_value);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: widget.size,
                width: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _color(),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: state == RadioButtonState.checked ||
                            (state == RadioButtonState.disabled && widget.value)
                        ? 10 / 24 * widget.size
                        : 0,
                    width: 10 / 24 * widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _color(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            if (widget.content != null) Flexible(child: widget.content!),
            if (widget.content == null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    widget.text,
                    style: widget.textStyle ??
                        ArDriveTypography.body.bodyRegular(),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Color _color() {
    switch (state) {
      case RadioButtonState.unchecked:
        return ArDriveTheme.of(context).themeData.colors.themeAccentDefault;
      case RadioButtonState.hover:
        return ArDriveTheme.of(context).themeData.colors.themeFgDefault;
      case RadioButtonState.checked:
        return ArDriveTheme.of(context).themeData.colors.themeFgDefault;
      case RadioButtonState.disabled:
        return ArDriveTheme.of(context).themeData.colors.themeFgDisabled;
    }
  }
}
