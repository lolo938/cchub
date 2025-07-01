import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/logger_service.dart';

/// A widget that displays cached network images with loading states and error handling
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheKey,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? cacheKey;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheKey: cacheKey,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) {
        LoggerService.warning('Failed to load image: $url', error);
        return errorWidget ?? _buildErrorWidget();
      },
      httpHeaders: const {
        'User-Agent': 'ChildcareHub Mobile App',
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 48,
      ),
    );
  }
}

/// A circular cached image widget for avatars
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.cacheKey,
  });

  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      placeholder: placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: errorWidget ?? _buildDefaultErrorWidget(),
      cacheKey: cacheKey,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius * 0.8,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: radius * 0.8,
        color: Colors.grey,
      ),
    );
  }
}

/// A cached image with hero animation support
class CachedHeroImage extends StatelessWidget {
  const CachedHeroImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
  });

  final String imageUrl;
  final String heroTag;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: GestureDetector(
        onTap: onTap,
        child: CachedImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// A grid of cached images with loading states
class CachedImageGrid extends StatelessWidget {
  const CachedImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.borderRadius,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final BorderRadius? borderRadius;
  final void Function(String imageUrl, int index)? onImageTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = imageUrls[index];
        return GestureDetector(
          onTap: () => onImageTap?.call(imageUrl, index),
          child: CachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
            cacheKey: 'grid_image_$index',
          ),
        );
      },
    );
  }
}

/// Utility class for managing cached images
class CachedImageManager {
  /// Clear all cached images
  static Future<void> clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache("");
      LoggerService.info('Image cache cleared successfully');
    } catch (e) {
      LoggerService.error('Failed to clear image cache', e);
    }
  }

  /// Clear a specific image from cache
  static Future<void> clearImageFromCache(String imageUrl) async {
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      LoggerService.debug('Cleared image from cache: $imageUrl');
    } catch (e) {
      LoggerService.error('Failed to clear image from cache: $imageUrl', e);
    }
  }

  /// Preload images for better performance
  static Future<void> preloadImage(
      String imageUrl, BuildContext context) async {
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
      LoggerService.debug('Preloaded image: $imageUrl');
    } catch (e) {
      LoggerService.warning('Failed to preload image: $imageUrl', e);
    }
  }

  /// Preload multiple images
  static Future<void> preloadImages(
      List<String> imageUrls, BuildContext context) async {
    final futures = imageUrls.map((url) => preloadImage(url, context));
    await Future.wait(futures);
  }
}
