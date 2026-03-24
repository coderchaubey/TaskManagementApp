import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_theme.dart';

class DebouncedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String initialValue;

  const DebouncedSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      widget.onSearch(value);
      if (value.isNotEmpty) {
        final results = await ApiService.autocomplete(value);
        if (mounted) {
          setState(() => _suggestions = results);
          if (results.isNotEmpty && _focusNode.hasFocus) {
            _showSuggestionsOverlay();
          } else {
            _hideSuggestions();
          }
        }
      } else {
        _hideSuggestions();
      }
    });
  }

  void _showSuggestionsOverlay() {
    _hideSuggestions();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showSuggestions = false);
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((suggestion) {
                  return _SuggestionTile(
                    title: suggestion['title'] as String,
                    query: _controller.text,
                    onTap: () {
                      _controller.text = suggestion['title'] as String;
                      widget.onSearch(suggestion['title'] as String);
                      _hideSuggestions();
                      _focusNode.unfocus();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceMuted, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.onSurfaceMuted),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                    _hideSuggestions();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String title;
  final String query;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.title,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppTheme.onSurfaceMuted),
            const SizedBox(width: 10),
            Expanded(child: _HighlightedText(text: title, query: query)),
          ],
        ),
      ),
    );
  }
}

/// Highlights the matching portion of text in the autocomplete result
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(color: AppTheme.onSurface));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(text, style: const TextStyle(color: AppTheme.onSurface));
    }

    return RichText(
      text: TextSpan(
        children: [
          if (matchIndex > 0)
            TextSpan(
              text: text.substring(0, matchIndex),
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0x226C63FF),
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(
              text: text.substring(matchIndex + query.length),
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
        ],
      ),
    );
  }
}