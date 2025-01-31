import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/home_service.dart';
import 'mood_screen.dart';
import 'photo_screen.dart';
import 'planner_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'partner_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final HomeScreenService _homeScreenService = HomeScreenService();

  @override
  Widget build(BuildContext context) {
    final userUID = _homeScreenService.getCurrentUserUID();

    if (userUID == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Up2Love'),
          centerTitle: true,
          backgroundColor: Colors.pink,
        ),
        body: const Center(child: Text('Autenticação necessária!')),
      );
    }

    final profilePicFuture = _homeScreenService.getUserProfilePic(userUID);
    final partnerUIDFuture = _homeScreenService.getPartnerUID(userUID);
    final partnerProfilePicFuture = partnerUIDFuture.then(
      (partnerUID) => _homeScreenService.getPartnerProfilePic(partnerUID),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Up2Love'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FutureBuilder<String?>(
            // User profile pic
            future: profilePicFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError || !snapshot.hasData) {
                return const Icon(Icons.person);
              } else {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(snapshot.data!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildCard(
                  context,
                  'Mood do momento',
                  EmotionTrackerScreen(),
                  Icons.mood,
                  'Diga como você se sente.',
                ),
                _buildCard(
                  context,
                  'Galeria',
                  SharedPhotosScreen(),
                  Icons.photo,
                  'Compartilhe e veja momentos juntos!',
                ),
                _buildCard(
                  context,
                  'Planejador de Dates',
                  DatePlannerScreen(),
                  Icons.calendar_today,
                  'Planeje e organize seu próximo date!',
                ),
                _buildCard(
                  context,
                  'Notas privadas',
                  SecretNotesScreen(userUID: userUID),
                  Icons.note,
                  'Compartilhe seus pensamentos mais íntimos.',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () => _promptForMessage(context, userUID),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(blurRadius: 5, color: Colors.black26)
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.message, color: Colors.white, size: 40),
                    SizedBox(width: 5),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: FutureBuilder<String?>(
              // Partner profile pic
              future: partnerProfilePicFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const CircleAvatar(
                      radius: 28, backgroundColor: Colors.grey);
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PartnerScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(snapshot.data!),
                    ),
                  );
                }
              },
            ),
          ),
          // Positioned thought balloon, separate from partner button
          Positioned(
            bottom: 70, // Ajuste o espaço para posicionar o balão mais alto
            left:
                50, // Ajuste a posição à esquerda em relação ao botão do parceiro
            child: FutureBuilder<DocumentSnapshot<Object?>?>(
              future: _homeScreenService
                  .getPartnerMessage(userUID), // Buscar a mensagem do parceiro
              builder: (context, messageSnapshot) {
                if (messageSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox();
                } else if (messageSnapshot.hasData &&
                    messageSnapshot.data != null) {
                  // Recuperar a mensagem do parceiro dos dados
                  String message = messageSnapshot.data!['message'] ?? '';
                  if (message.isEmpty) {
                    message =
                        "Nenhuma mensagem por hoje"; // Mensagem padrão do sistema
                  }
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(blurRadius: 3, color: Colors.black26)
                      ],
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _promptForMessage(BuildContext context, String userUID) async {
    TextEditingController messageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Digite uma mensagem para seu parceiro(a):"),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(hintText: 'Sua mensagem aqui'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              String message = messageController.text.trim();
              if (message.isNotEmpty) {
                await _homeScreenService.sendMessageToPartner(userUID, message);
                // Show message as thought balloon
                Navigator.pop(context);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, Widget screen,
      IconData icon, String description) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        },
        child: ListTile(
          leading: Icon(icon, size: 40, color: Colors.pink),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          subtitle: Text(description),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
