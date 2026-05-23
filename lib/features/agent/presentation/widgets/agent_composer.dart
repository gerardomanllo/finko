import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../../l10n/app_localizations.dart';

class AgentComposer extends StatefulWidget {
  const AgentComposer({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    this.busy = false,
  });

  final Future<void> Function(String text) onSendText;
  final Future<void> Function(File file, {String? caption}) onSendImage;
  final Future<void> Function(File file) onSendVoice;
  final bool busy;

  @override
  State<AgentComposer> createState() => _AgentComposerState();
}

class _AgentComposerState extends State<AgentComposer> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  bool _recording = false;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    _controller.clear();
    await widget.onSendText(text);
  }

  Future<void> _pickImage() async {
    if (widget.busy) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final caption = _controller.text.trim();
    _controller.clear();
    await widget.onSendImage(
      File(picked.path),
      caption: caption.isEmpty ? null : caption,
    );
  }

  Future<void> _toggleVoice() async {
    if (widget.busy) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) {
        await widget.onSendVoice(File(path));
      }
      return;
    }
    if (!await _recorder.hasPermission()) return;
    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/finko_agent_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _recording = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ComposerIconButton(
                tooltip: l10n.agentAttachImage,
                icon: Icons.image_outlined,
                onPressed: widget.busy ? null : _pickImage,
              ),
              _ComposerIconButton(
                tooltip: l10n.agentRecordVoice,
                icon: _recording
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none_outlined,
                color: _recording ? theme.colorScheme.error : null,
                onPressed: widget.busy ? null : _toggleVoice,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !widget.busy,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: l10n.agentComposerHint,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.busy
                      ? null
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                          ],
                        ),
                  color: widget.busy ? theme.disabledColor : null,
                ),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  tooltip: l10n.agentSend,
                  onPressed: widget.busy ? null : _sendText,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: color,
      visualDensity: VisualDensity.compact,
    );
  }
}
