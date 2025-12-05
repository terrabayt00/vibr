import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/helpers/storage_helper.dart';

class ImageCard extends StatelessWidget {
  final String path;

  const ImageCard({super.key, required this.path});

  Future<String> _loadImage() async {
    final DbHelper storageService = DbHelper();
    String url = await storageService.getImageUrl(path);
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadImage(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Показує індикатор завантаження
        } else if (snapshot.hasError) {
          return const Icon(
            Icons.error,
            color: Colors.red,
          ); // Відображає помилку
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          String imageUrl = snapshot.data!;
          return Column(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
              IconButton(
                tooltip: 'Link for download',
                onPressed: () {
                  StorageHelper().launchLink(imageUrl);
                },
                icon: const Icon(Icons.download),
              ),
            ],
          );
        } else {
          return const Text('No image found.'); // Якщо URL порожній
        }
      },
    );
  }
}
