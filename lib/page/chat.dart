import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/requests/endpoints.dart';
import 'package:scheduling/style/color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ChatMessage {
  final String text;
  final String time;
  final bool isMe;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
    this.imageBytes,
  });
}

class Chat extends StatefulWidget {
  final String? initialText;
  final Uint8List? initialImage;

  const Chat({super.key, this.initialText, this.initialImage});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _messageController = TextEditingController();
  String _nomeUsuario = '';
  String _companyName = '';

  List<dynamic> quickMessages = [];

  final List<ChatMessage> _messages = [
    ChatMessage(text: "Oi! Tudo bem?", time: "14:00", isMe: false),
    ChatMessage(
      text: "Opa! Tudo ótimo, e com você?",
      time: "14:01",
      isMe: true,
    ),
    ChatMessage(
      text: "Estou testando esse layout em Flutter.",
      time: "14:01",
      isMe: true,
    ),
    ChatMessage(
      text: "Ficou muito parecido com o original! 🚀",
      time: "14:02",
      isMe: false,
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text,
          time:
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  Future<void> getNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeUsuario = prefs.getString('nome_usuario');
    final companyName = prefs.getString('company_name');
    if (nomeUsuario != null && companyName != null) {
      setState(() {
        _nomeUsuario = nomeUsuario;
        _companyName = companyName;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getNomeUsuario();
    getResponses();
    if (widget.initialText != null || widget.initialImage != null) {
      _messages.add(
        ChatMessage(
          text: widget.initialText ?? '',
          time:
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          isMe: true,
          imageBytes: widget.initialImage,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.primaryColor.withOpacity(0.2),
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorsApp.secondaryColor, size: 30),
        backgroundColor: ColorsApp.primaryColor,
        surfaceTintColor: ColorsApp.primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => App(selectedIndex: 3)),
          ),
          icon: Icon(Icons.arrow_back_ios_new, color: ColorsApp.secondaryColor),
        ),
        title: Text(
          'Matheus Stevam',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorsApp.secondaryColor,
          ),
        ),
      ),
      endDrawer: Drawer(
        child: DrawerTab(nomeUsuario: _nomeUsuario, companyName: _companyName),
      ),
      body: Column(
        children: [
          // Área das mensagens
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Barra de digitação inferior
          _buildInputArea(),
        ],
      ),
    );
  }

  // Componente do Balão de Mensagem
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          // Verde claro para "mim", branco para o "outro"
          color: message.isMe
              ? ColorsApp.secondaryColor
              : ColorsApp.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: message.isMe
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: message.isMe
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsApp.secondaryColor,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.memory(
                  message.imageBytes!,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: message.isMe
                        ? ColorsApp.primaryColor
                        : ColorsApp.secondaryColor,
                  ),
                ),
                Text(
                  message.time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Componente do Campo de Entrada de Texto
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ColorsApp.primaryColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: ColorsApp.secondaryColor,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: "Mensagem",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: () {},
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.list_alt, color: Colors.grey),
                    onSelected: (value) {
                      _messageController.text = value;
                    },
                    itemBuilder: (context) {
                      return quickMessages.map<PopupMenuEntry<String>>((item) {
                        return PopupMenuItem<String>(
                          value: item['content'],
                          child: Text(item['title']),
                        );
                      }).toList();
                    },
                  ),
                  const SizedBox(width: 5),
                  // Botão circular de enviar / microfone
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          ColorsApp.secondaryColor, //Color(0xFF075E54),
                      child: Icon(
                        Icons.send,
                        color: ColorsApp.primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getResponses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = dotenv.env['BASE_URL'];
      final response = await http.post(
        Uri.parse('$baseUrl${Endpoints.list}'),
        headers: {
          'Authorization': 'Bearer ${prefs.getString('access_token')}',
          'Content-Type': 'application/json',
          'X-TENANT-ID': "${prefs.getString("tenant_id")}",
        },
        body: jsonEncode({
          'q':
              "SELECT * FROM quick_responses WHERE company_id = '${prefs.getString('company_id')}'",
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        quickMessages = (data['results'] as List).map((item) {
          return {'title': item['title'], 'content': item['content']};
        }).toList();
        setState(() {});
      } else {
        log('Erro ao obter respostas: ${response.body}');
      }
    } catch (e) {
      log('Erro ao obter respostas: $e');
    }
  }
}
