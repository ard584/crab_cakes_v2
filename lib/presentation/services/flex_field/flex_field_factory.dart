import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_prototype/domain/entities/settings/field_config.dart';

class FlexFieldFactory {
  static Widget createField({
    required FlexFieldConfig config,
    required TextEditingController controller,
    InputDecoration? baseDecoration,
  }) {

    //check whether or not this is a drop down
    if(config.settings.useDropdown) {
      return _buildAutocompleteField(config, controller, baseDecoration);

    } else if (config.dataType == 'INTEGER' || config.dataType == 'REAL') {
      return _buildNumericField(config, controller, baseDecoration);

    } else {

      return _buildTextField(config, controller, baseDecoration);
    }
  }

  static Widget _buildAutocompleteField(
  FlexFieldConfig config,
  TextEditingController controller,
  InputDecoration? baseDecoration,
) {
  return _FlexAutocompleteField(
    config: config,
    controller: controller,
    baseDecoration: baseDecoration,
  );
}
  
  static Widget _buildNumericField(
    FlexFieldConfig config,
    TextEditingController controller, 
    InputDecoration? baseDecoration, 
  ) {
    final isReal = config.dataType == 'REAL';

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: isReal,
        signed: false,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isReal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      decoration: (baseDecoration ?? const InputDecoration()).copyWith(
        labelText: config.label,
        hintText: config.defaultValue,
        helperText: config.settings.helpText,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (config.settings.isRequired && text.isEmpty) {
          return 'This field is required';
        }

        if (text.isEmpty) return null;

        final number = num.tryParse(text);
        if (number == null) {
          return 'Enter a valid number';
        }

        if (config.settings.minValue != null && number < config.settings.minValue!) {
          return 'Must be at least ${config.settings.minValue}';
        }

        if (config.settings.maxValue != null && number > config.settings.maxValue!) {
          return 'Must be at most ${config.settings.maxValue}';
        }

        return null;
      });
    }


  static Widget _buildTextField(
    FlexFieldConfig config,
    TextEditingController controller, 
    InputDecoration? baseDecoration, 
  ) {
      TextInputType keyboardType = TextInputType.text;

      // TODO: Allow for injectable styling other than hint and label text
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: (baseDecoration ?? InputDecoration()).copyWith(
          labelText: config.label,
          hintText: config.defaultValue,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (config.settings.isRequired && text.isEmpty) {
            return 'This field is required';
          }

          return null;
        },
      );

  }
}


//Class for the autocomplete field. Note, that this needs to be stateful because
//because components like the focus node need to be owned by the field instance
class _FlexAutocompleteField extends StatefulWidget {
  final FlexFieldConfig config;
  final TextEditingController controller;
  final InputDecoration? baseDecoration;

  const _FlexAutocompleteField({
    required this.config,
    required this.controller,
    required this.baseDecoration,
  });

  @override
  State<_FlexAutocompleteField> createState() => _FlexAutocompleteFieldState();
}

class _FlexAutocompleteFieldState extends State<_FlexAutocompleteField> {
  late final FocusNode _focusNode;
  bool _suppressOptions = false;

  // The options currently being shown for the user's text.
  List<String> _currentOptions = const [];

  // The currently highlighted option in the popup, if any.
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'Autocomplete(${widget.config.label})');

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _suppressOptions) {
        setState(() {
          _suppressOptions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _getFilteredOptions(String query) {
  final q = query.trim().toLowerCase();
  final normalizedQuery = _normalizeDropdownValue(query).toLowerCase();
  final all = widget.config.settings.options;

  if (q.isEmpty) return all;

  final hasExactMatch = all.any(
    (o) =>
        _normalizeDropdownValue(o).toLowerCase() == normalizedQuery ||
        o.trim().toLowerCase() == q,
  );

  if (hasExactMatch) {
    return [];
  }

  bool optionStartsWith(String option) {
    final rawOption = option.toLowerCase();
    final normalizedOption = _normalizeDropdownValue(option).toLowerCase();

    return rawOption.startsWith(q) || normalizedOption.startsWith(q);
  }

  bool optionContains(String option) {
    final rawOption = option.toLowerCase();
    final normalizedOption = _normalizeDropdownValue(option).toLowerCase();

    return rawOption.contains(q) || normalizedOption.contains(q);
  }

  final starts = all.where(optionStartsWith);

  final contains = all.where(
    (o) => !optionStartsWith(o) && optionContains(o),
  );

  return [...starts, ...contains];
}

  void _commitSelection(String value) {
    final normalizedValue = _normalizeDropdownValue(value);

    _suppressOptions = true;

    widget.controller.value = TextEditingValue(
      text: normalizedValue,
      selection: TextSelection.collapsed(offset: normalizedValue.length),
    );
  }

  void _commitSelectionAndMoveNext(BuildContext context, String value) {
    setState(() {
      _commitSelection(value);
      _currentOptions = const [];
      _highlightedIndex = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).nextFocus();
    });
  }

  KeyEventResult _handleKeyEvent(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCommitKey =
        event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if (!isCommitKey) return KeyEventResult.ignored;

    if (_currentOptions.isEmpty) {
      return KeyEventResult.ignored;
    }

    final selectedIndex = (_highlightedIndex != null &&
            _highlightedIndex! >= 0 &&
            _highlightedIndex! < _currentOptions.length)
        ? _highlightedIndex!
        : 0;

    _commitSelectionAndMoveNext(context, _currentOptions[selectedIndex]);
    return KeyEventResult.handled;
  }

  String? _validator(String? value) {
    final text = value?.trim() ?? '';

    if (widget.config.settings.isRequired && text.isEmpty) {
      return 'This field is required';
    }

    if (text.isEmpty) return null;

    // Optional: enforce that typed text must match one of the dropdown options.
    if (widget.config.settings.useDropdown &&
        !widget.config.settings.options.any(
          (o) => _normalizeDropdownValue(o).toLowerCase() ==
              _normalizeDropdownValue(text).toLowerCase(),
        )) {
      return 'Select a valid option';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.baseDecoration ?? const InputDecoration())
        .copyWith(
          labelText: widget.config.label,
          hintText: widget.config.defaultValue,
          helperText: widget.config.settings.helpText,
        );

    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (TextEditingValue textEditingValue) {

        //checking whether or not the user already selected an option
        if(_suppressOptions) {
          _currentOptions = const [];
          _highlightedIndex = null;
          return const Iterable<String>.empty();
        }

        final results = _getFilteredOptions(textEditingValue.text);
        _currentOptions = results;

        // Reset highlight when the option list changes.
        if (_highlightedIndex != null &&
            _highlightedIndex! >= results.length) {
          _highlightedIndex = results.isEmpty ? null : 0;
        }

        return results;
      },
      onSelected: _commitSelection,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) => _handleKeyEvent(context, event),
          child: TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) {
              if (_suppressOptions) {
                setState(() {
                  _suppressOptions = false;
                });
              }
            },
            controller: textController,
            focusNode: focusNode,
            decoration: decoration,
            validator: _validator,
            onFieldSubmitted: (_) {
              if (_currentOptions.isNotEmpty) {
                final selectedIndex = (_highlightedIndex != null &&
                        _highlightedIndex! >= 0 &&
                        _highlightedIndex! < _currentOptions.length)
                    ? _highlightedIndex!
                    : 0;

                _commitSelection(_currentOptions[selectedIndex]);
              } else {
                focusNode.nextFocus();
              }
            },
          ),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        final optionList = options.toList(growable: false);
        _currentOptions = optionList;

        if (optionList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220,
                minWidth: 250,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                itemBuilder: (context, index) {
                  final option = optionList[index];

                  return _AutocompleteOptionTile(
                    index: index,
                    option: option,
                    onSelected: onSelected,
                    onHighlightChanged: (highlighted) {
                      if (highlighted && _highlightedIndex != index) {
                        // Post-frame avoids state changes during build.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _highlightedIndex = index;
                            });
                          }
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AutocompleteOptionTile extends StatelessWidget {
  final int index;
  final String option;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onHighlightChanged;

  const _AutocompleteOptionTile({
    required this.index,
    required this.option,
    required this.onSelected,
    required this.onHighlightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = AutocompleteHighlightedOption.of(context) == index;
    onHighlightChanged(highlighted);

    return InkWell(
      onTap: () => onSelected(option),
      child: Container(
        color: highlighted
            ? Theme.of(context).focusColor.withOpacity(0.20)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(option),
      ),
    );
  }
}




// Basic type for figuring out correct field config
// TODO: Determine if this is redundant compared to Attribute model
class FlexFieldConfig {
  final String label;
  // TODO: make dataType into an enum
  final String dataType;
  final String? defaultValue;

  final FieldConfig settings;


  FlexFieldConfig({
    required this.label,
    required this.dataType,
    required this.settings,
    this.defaultValue,
  });
}





//================================ HELPER FUNCTIONS ============================
String _normalizeDropdownValue(String value) {
  return value.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
}