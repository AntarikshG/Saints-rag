import 'dart:async';
import 'package:flutter/material.dart';

class RotatingBanner extends StatefulWidget {
  final List<String> imagePaths;
  final double aspectRatio;
  final Duration interval;

  const RotatingBanner({
    required this.imagePaths,
    this.aspectRatio = 16 / 7,
    this.interval = const Duration(seconds: 7),
    Key? key,
  }) : super(key: key);

  @override
  _RotatingBannerState createState() => _RotatingBannerState();
}

class _RotatingBannerState extends State<RotatingBanner> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(widget.interval, (timer) {
      if (_controller.hasClients) {
        _currentPage = (_currentPage + 1) % widget.imagePaths.length;
        _controller.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            widget.imagePaths[index],
            fit: BoxFit.cover,
          ),
        ),
        onPageChanged: (index) => _currentPage = index,
      ),
    );
  }
}

