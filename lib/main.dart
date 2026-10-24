import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF176B58);
    return MaterialApp(
      title: 'Yerel Zeka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          primary: forest,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F7F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4EAE6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: forest, width: 1.5),
          ),
        ),
      ),
      home: const ChatPage(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;
  final String content;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final TextEditingController _serverController;
  late final TextEditingController _modelController;
  final List<ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    _serverController = TextEditingController(text: 'http://$host:11434');
    _modelController = TextEditingController(text: 'llama3.2');
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _serverController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestedPrompt]) async {
    final prompt = (suggestedPrompt ?? _inputController.text).trim();
    if (prompt.isEmpty || _sending) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: prompt));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final baseUrl = _serverController.text.trim().replaceFirst(
        RegExp(r'/+$'),
        '',
      );
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _modelController.text.trim(),
              'messages': [
                for (final message in _messages)
                  {'role': message.role, 'content': message.content},
              ],
              'stream': false,
            }),
          )
          .timeout(const Duration(minutes: 3));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error'] ?? 'HTTP ${response.statusCode}');
      }

      final content = (data['message'] as Map<String, dynamic>?)?['content'];
      if (content is! String || content.isEmpty) {
        throw const FormatException('Ollama boş yanıt döndürdü.');
      }
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: content));
      });
    } catch (error) {
      if (!mounted) return;
      final details = error is http.ClientException || error is FormatException
          ? error.toString()
          : error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content:
                'Bağlantı kurulamadı. Sunucu adresini, Ollama’nın ağ erişimini ve seçili modeli kontrol et.\n\n$details',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ollama bağlantısı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serverController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Sunucu adresi',
                hintText: 'http://192.168.1.10:11434',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'llama3.2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F2EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.forum_rounded, color: Color(0xFF176B58)),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yerel Zeka',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'OLLAMA  /  YEREL SOHBET',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.7,
                    color: Color(0xFF73817A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bağlantı ayarları',
            onPressed: _sending ? null : _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EDEA)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTyping();
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F2EC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF176B58),
                size: 31,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ne düşünüyorsun?',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${_modelController.text} modeli kendi cihazında yanıtlasın.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718078), fontSize: 15),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 9,
              children: [
                _suggestion('Bir fikir üret'),
                _suggestion('Kodumu açıkla'),
                _suggestion('Kısa bir hikâye yaz'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE1E8E3)),
      onPressed: _sending ? null : () => _sendMessage(text),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF176B58) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE6ECE8)),
        ),
        child: SelectableText(
          message.content,
          style: TextStyle(
            height: 1.45,
            fontSize: 15,
            color: isUser ? Colors.white : const Color(0xFF26342D),
          ),
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 4, 14, 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EDEA))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Mesajını yaz...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton.filled(
                tooltip: 'Gönder',
                onPressed: _sending ? null : () => _sendMessage(),
                icon: _sending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF176B58),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
