import 'package:flutter/material.dart';
import 'package:scheduling/main.dart';
import 'package:scheduling/style/color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final String time;
  final bool isMe;

  ChatMessage({required this.text, required this.time, required this.isMe});
}

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _messageController = TextEditingController();
  String _nomeUsuario = '';

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
    if (nomeUsuario != null) {
      setState(() {
        _nomeUsuario = nomeUsuario;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getNomeUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => App(selectedIndex: 3)),
          ),
          icon: Icon(Icons.arrow_back_ios_new, color: ColorsApp.secondaryColor),
        ),
        title: Text(
          'Matheus Stevam',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      endDrawer: Drawer(child: DrawerTab(nomeUsuario: _nomeUsuario)),
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
        child: Wrap(
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Botão circular de enviar / microfone
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: ColorsApp.secondaryColor, //Color(0xFF075E54),
              child: Icon(Icons.send, color: ColorsApp.primaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
