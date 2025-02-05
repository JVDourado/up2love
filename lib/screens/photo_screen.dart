import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_service.dart';

class SharedPhotosScreen extends StatefulWidget {
  const SharedPhotosScreen({super.key});

  @override
  State<SharedPhotosScreen> createState() => _SharedPhotosScreenState();
}

class _SharedPhotosScreenState extends State<SharedPhotosScreen> {
  final TextEditingController _captionController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  XFile? _pickedFile;
  bool _isLoading = false;
  String? _partnerUID;
  String? _partnerUsername;
  List<QueryDocumentSnapshot> _userUploads = [];
  List<QueryDocumentSnapshot> _partnerUploads = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch user uploads (always fetch this, even if partner info fails)
      await _fetchUserUploads(user.uid);

      // Fetch partner info and uploads (if available)
      try {
        final partnerInfo = await _photoService.fetchPartnerInfo(user.uid);
        if (partnerInfo != null) {
          setState(() {
            _partnerUID = partnerInfo['partnerUID'];
            _partnerUsername = partnerInfo['partnerUsername'];
          });

          // Fetch partner uploads if partnerUID is available
          if (_partnerUID != null) {
            await _fetchPartnerUploads(_partnerUID!);
          }
        }
      } catch (e) {
        // If fetching partner info fails, log the error but continue
        print('Failed to fetch partner info: $e');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao buscar dados: $e')),
      );
    }
  }

  Future<void> _fetchUserUploads(String userUID) async {
    try {
      final uploads = await _photoService.fetchUserUploads(userUID);
      setState(() {
        _userUploads = uploads;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao buscar uploads do usuário: $e')),
      );
    }
  }

  Future<void> _fetchPartnerUploads(String partnerUID) async {
    try {
      final uploads = await _photoService.fetchUserUploads(partnerUID);
      setState(() {
        _partnerUploads = uploads;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao buscar uploads do parceiro: $e')),
      );
    }
  }

  Future<void> _pickImageAndShowDialog() async {
    try {
      final pickedFile = await _photoService.pickImage();
      if (pickedFile != null) {
        setState(() => _pickedFile = pickedFile);
        _showUploadDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carregar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pickedFile != null)
              Column(
                children: [
                  Image.file(File(_pickedFile!.path), height: 100),
                  const SizedBox(height: 8),
                ],
              ),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Adicione uma legenda'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _pickedFile = null);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_pickedFile != null) {
                      _uploadPhoto();
                      Navigator.pop(context);
                    }
                  },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Carregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_pickedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final caption = _captionController.text.trim();

      if (caption.isEmpty) {
        throw Exception('Por favor, adicione uma legenda!');
      }

      await _photoService.uploadPhoto(File(_pickedFile!.path), caption);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto carregada com sucesso')),
      );

      setState(() {
        _pickedFile = null;
        _captionController.clear();
      });

      // Refresh the user's uploads after uploading a new photo
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _fetchUserUploads(user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar foto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(String photoId, String photoUrl) async {
    try {
      await _photoService.deletePhoto(photoId, photoUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto deletada com sucesso')),
      );

      // Refresh the user's uploads after deleting a photo
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _fetchUserUploads(user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao deletar foto: $e')),
      );
    }
  }

  Future<void> _editCaption(String photoId, String currentCaption) async {
    final TextEditingController _editCaptionController = TextEditingController(text: currentCaption);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Legenda'),
        content: TextField(
          controller: _editCaptionController,
          decoration: const InputDecoration(labelText: 'Nova legenda'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newCaption = _editCaptionController.text;
              if (newCaption.isNotEmpty) {
                await _photoService.editCaption(photoId, newCaption);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Legenda atualizada com sucesso')),
                );
                Navigator.pop(context);

                // Refresh the user's uploads after editing a caption
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await _fetchUserUploads(user.uid);
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(List<QueryDocumentSnapshot> photos, int index) {
    final pageController = PageController(initialPage: index);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: PageView.builder(
            controller: pageController,
            itemCount: photos.length,
            itemBuilder: (context, pageIndex) {
              final photo = photos[pageIndex];
              final photoId = photo.id;
              final url = photo['url'];
              final caption = photo['caption'] ?? '';
              final isPartnerPhoto = _partnerUploads.contains(photo);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CachedNetworkImage(
                      imageUrl: url,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height * 0.6,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(caption, style: const TextStyle(fontSize: 16)),
                    ),
                    if (isPartnerPhoto) // Add the "Enviado por" tag here
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Enviado por $_partnerUsername',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    if (!isPartnerPhoto) // Only show edit/delete buttons for the current user's photos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editCaption(photoId, caption);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deletePhoto(photoId, url);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUploads = [..._userUploads, ..._partnerUploads];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Galeria',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
            child: _userUploads.isEmpty && _partnerUploads.isEmpty
                ? const Center(child: Text('Sem fotos no momento.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: allUploads.length,
                    itemBuilder: (context, index) {
                      final photo = allUploads[index];
                      final url = photo['url'];

                      return GestureDetector(
                        onTap: () => _showPhotoDialog(allUploads, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImageAndShowDialog,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }
}