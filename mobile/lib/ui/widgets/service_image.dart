import 'package:flutter/material.dart';

class ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ServiceImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasValidImage = _hasValidImage();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: hasValidImage
            ? _buildNetworkImage()
            : _buildDefaultImage(),
      ),
    );
  }

  bool _hasValidImage() {
    if (imageUrl == null || imageUrl!.isEmpty) return false;
    try {
      Uri.parse(imageUrl!);
      return imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: width,
          height: height,
          color: Colors.grey[100],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erreur chargement image: $error');
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width < 100 ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.blue[200]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(width < 100 ? 15 : 20),
              ),
              child: Icon(
                Icons.business_center,
                size: width < 100 ? 20 : 32,
                color: Colors.blue[600],
              ),
            ),
            if (height > 60) ...[
              SizedBox(height: width < 100 ? 4 : 8),
              Text(
                'Service',
                style: TextStyle(
                  fontSize: width < 100 ? 10 : 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}