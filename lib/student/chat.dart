import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'message_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

/// Simple message model (UI only)
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatPageState extends State<ChatPage> {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  bool _loading = false;

  String? _pdfText;
  String? _pdfFileName;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: '', // ⚠️ Required
    );

    _chatSession = _model.startChat();
  }

  // ================= PDF PICK + EXTRACT =================

  Future<void> _pickPdfAndExtractText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();

    setState(() {
      _pdfText = text;
      _pdfFileName = result.files.single.name;
    });

    _scrollDown();
  }

  // ================= SEND MESSAGE =================

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 1️⃣ Show ONLY what user typed
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _loading = true;
    });

    try {
      // 2️⃣ Hidden AI prompt (NOT shown in UI)
      final aiPrompt = _pdfText == null
          ? message
          : '''
You are an assistant that answers questions using ONLY the document below.

Document:
$_pdfText

User question:
$message
''';

      final response =
          await _chatSession.sendMessage(Content.text(aiPrompt));

      if (response.text != null) {
        setState(() {
          _messages.add(
            ChatMessage(text: response.text!, isUser: false),
          );
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      _textController.clear();
      _textFieldFocus.requestFocus();
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Gemini'),
      ),
      body: Column(
        children: [
          // PDF banner
          if (_pdfFileName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.green.shade100,
              child: Text(
                '📄 $_pdfFileName loaded',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageWidget(
                  text: msg.text,
                  isFromUser: msg.isUser,
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _pickPdfAndExtractText,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFieldFocus,
                    decoration: _inputDecoration(),
                    onSubmitted: _sendChatMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'Ask something...',
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
