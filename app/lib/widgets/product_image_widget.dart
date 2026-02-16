import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  const ProductImageWidget({
    Key? key,
    this.imageUrl,
    this.size = 50,
    this.borderRadius,
    this.fallbackIcon = Icons.propane_tank,
    this.fallbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final color = fallbackColor ?? Theme.of(context).primaryColor;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(color);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(color);
          },
        ),
      );
    }

    return _buildPlaceholder(color);
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        fallbackIcon,
        color: color,
        size: size * 0.6,
      ),
    );
  }
}

class ProductImageAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const ProductImageAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 25,
    this.fallbackIcon = Icons.propane_tank,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (exception, stackTrace) {},
        child: imageUrl!.isEmpty
            ? Icon(fallbackIcon, size: radius * 1.2)
            : null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        fallbackIcon,
        color: Theme.of(context).primaryColor,
        size: radius * 1.2,
      ),
    );
  }
}

class ProductImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ProductImageThumbnail({
    Key? key,
    this.imageUrl,
    this.width = 80,
    this.height = 80,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? (imageUrl != null ? () => _showFullImage(context) : null),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context),
                )
              : _buildPlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.propane_tank,
        size: width * 0.5,
        color: Colors.grey[400],
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Product Image'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('Failed to load image')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
