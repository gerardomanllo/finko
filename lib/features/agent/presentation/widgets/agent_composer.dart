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
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final caption = _controller.text.trim();
    _controller.clear();
    await widget.onSendImage(File(picked.path), caption: caption.isEmpty ? null : caption);
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
    final path = '${dir.path}/finko_agent_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() => _recording = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: l10n.agentAttachImage,
              onPressed: widget.busy ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
            ),
            IconButton(
              tooltip: l10n.agentRecordVoice,
              onPressed: widget.busy ? null : _toggleVoice,
              icon: Icon(_recording ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
              color: _recording ? theme.colorScheme.error : null,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                enabled: !widget.busy,
                decoration: InputDecoration(
                  hintText: l10n.agentComposerHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: l10n.agentSend,
              onPressed: widget.busy ? null : _sendText,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
