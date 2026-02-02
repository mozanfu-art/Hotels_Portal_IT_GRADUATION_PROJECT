import 'package:flutter/material.dart';
import 'package:hotel_booking_app/utils/constants.dart';

class FooterWrapper extends StatefulWidget {
  final Widget child; // The page content

  const FooterWrapper({super.key, required this.child});

  @override
  State<FooterWrapper> createState() => _FooterWrapperState();
}

class _FooterWrapperState extends State<FooterWrapper> {
  final ScrollController _controller = ScrollController();
  bool _showFooter = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final atBottom =
          _controller.position.pixels >=
          _controller.position.maxScrollExtent - 20;
      if (atBottom && !_showFooter) {
        setState(() => _showFooter = true);
      } else if (!atBottom && _showFooter) {
        setState(() => _showFooter = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _controller,
          child: Column(
            children: [
              widget.child,
              const SizedBox(height: 100), // Space for footer to appear
            ],
          ),
        ),
        if (_showFooter)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 60,
              color: const Color(0xFF004D40),
              child: Center(
                child: Text(
                  footerText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        width: double.infinity,
        height: 60,
        color: const Color(0xFF004D40),
        child: Center(
          child: Text(
            footerText,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
