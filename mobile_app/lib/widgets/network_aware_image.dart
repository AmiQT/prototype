import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/network_service.dart';

class NetworkAwareImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableProgressiveLoading;

  const NetworkAwareImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableProgressiveLoading = true,
  });

  @override
  State<NetworkAwareImage> createState() => _NetworkAwareImageState();
}

class _NetworkAwareImageState extends State<NetworkAwareImage> {
  final NetworkService _networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    // Get optimized image URL based on network conditions
    final optimizedUrl = _getOptimizedImageUrl();

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) =>
          widget.errorWidget ?? _buildFallbackImage(),
      // Optimize caching for mobile data
      memCacheWidth: _networkService.isOnMobile ? 400 : null,
      memCacheHeight: _networkService.isOnMobile ? 300 : null,
      // Progressive loading for slow connections
      progressIndicatorBuilder: widget.enableProgressiveLoading
          ? (context, url, progress) =>
              _buildProgressIndicator(progress as ImageChunkEvent?)
          : null,
    );
  }

  String _getOptimizedImageUrl() {
    // If on mobile data, request lower quality images
    if (_networkService.isOnMobile) {
      // Add quality parameters to URL if your backend supports it
      final uri = Uri.parse(widget.imageUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['quality'] = 'medium';
      queryParams['width'] = '800';

      return uri.replace(queryParameters: queryParams).toString();
    }

    return widget.imageUrl;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Image failed to load',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a fallback image when network image fails
  Widget _buildFallbackImage() {
    // Try to use a local asset image as fallback
    try {
      return Image.asset(
        'assets/images/default_profile.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildProgressIndicator(ImageChunkEvent? progress) {
    if (progress == null) {
      return _buildPlaceholder();
    }

    final progressValue = progress.expectedTotalBytes != null
        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
        : null;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            if (progressValue != null)
              Text(
                '${(progressValue * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Data usage warning widget
class DataUsageWarning extends StatelessWidget {
  final VoidCallback onProceed;
  final VoidCallback onCancel;
  final String message;

  const DataUsageWarning({
    super.key,
    required this.onProceed,
    required this.onCancel,
    this.message = 'This action may use significant mobile data. Continue?',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Data Usage Warning'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onProceed,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// Network status indicator
class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator({super.key});

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  final NetworkService _networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    if (!_networkService.isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.red,
        child: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'No internet connection',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_networkService.isOnMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.orange[100],
        child: Row(
          children: [
            Icon(Icons.signal_cellular_4_bar,
                color: Colors.orange[800], size: 16),
            const SizedBox(width: 8),
            Text(
              'Using mobile data - Data saver mode active',
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
