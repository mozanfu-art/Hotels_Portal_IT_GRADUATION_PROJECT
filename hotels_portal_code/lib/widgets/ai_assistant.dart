import 'package:flutter/material.dart';
import 'package:hotel_booking_app/services/booking_service.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class Message {
  final String sender; // 'user' or 'bot'
  final String text;

  Message({required this.sender, required this.text});
}

class ScalableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const ScalableButton({required this.child, this.onPressed, super.key});

  @override
  _ScalableButtonState createState() => _ScalableButtonState();
}

class _ScalableButtonState extends State<ScalableButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_scale),
        child: widget.child,
      ),
    );
  }
}

class MovingButton extends StatefulWidget {
  final Widget child;

  const MovingButton({required this.child, super.key});

  @override
  _MovingButtonState createState() => _MovingButtonState();
}

class _MovingButtonState extends State<MovingButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> {
  bool isOpen = false;
  bool hasConversationStarted = false;
  List<Message> messages = [
    Message(
      sender: 'bot',
      text:
          "Hello! I'm PortalPal, your personal guide. How can I help you find the perfect hotel in Sudan today?",
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode =
      FocusNode(); // NEW: Add FocusNode for managing focus
  AiService? _aiService;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    _aiService = AiService(geminiApiKey);

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose(); // NEW: Dispose of FocusNode
    super.dispose();
  }

  void _onAuthChanged() {
    if (!authProvider.isLoggedIn) {
      clearMemory();
    }
  }

  void clearMemory() {
    setState(() {
      messages = [
        Message(
          sender: 'bot',
          text:
              "Hello! I'm PortalPal, your personal guide. How can I help you find the perfect hotel in Sudan today?",
        ),
      ];
      hasConversationStarted = false;
      isOpen = false;
    });
  }

  void handleSendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userMessage = _controller.text.trim();
    setState(() {
      messages.add(Message(sender: 'user', text: userMessage));
      _controller.clear();
      _focusNode.unfocus(); // NEW: Lose focus to ensure visual clear and reset
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    if (!hasConversationStarted) {
      setState(() => hasConversationStarted = true);
    }

    _aiService ??= AiService(geminiApiKey);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String currentRoute = ModalRoute.of(context)?.settings.name ?? '/unknown';

      Map<String, dynamic> aiContext = {
        'screen': currentRoute,
        'isLoggedIn': authProvider.isLoggedIn,
      };

      if (authProvider.isLoggedIn) {
        Provider.of<BookingProvider>(context, listen: false);

        Guest? currentUser = authProvider.currentGuest;

        HotelService hotelService = HotelService();
        BookingService bookingService = BookingService();

        List<Booking> userBookings = await bookingService.getBookingsByGuest(
          currentUser!.guestId,
        );

        Map<String, dynamic> hotelsResult = await hotelService.getAllHotels(
          limit: 1000,
        );

        aiContext.addAll({
          'guestName': '${currentUser.fName} ${currentUser.lName}',
          'availableHotels': hotelsResult['hotels'],
          'existingBookings': userBookings,
        });
      }

      String botResponse = await _aiService!.getResponse(
        userMessage: userMessage,
        aiContext: aiContext,
      );

      setState(() {
        messages.add(Message(sender: 'bot', text: botResponse));
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (e, s) {
      print(s);
      print('Error: $e');
      setState(() {
        messages.add(
          Message(
            sender: 'bot',
            text:
                "I'm sorry, but I can't help with that right now. Our admin team will contact you via email shortly.",
          ),
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedScale(
            scale: isOpen ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 800),
            child: MovingButton(
              child: ScalableButton(
                onPressed: () => setState(() => isOpen = true),
                child: FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.smart_toy, size: 32),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedScale(
            scale: isOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.bottomRight,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                height: 448,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Icon(
                              Icons.smart_toy,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'PortalPal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Your Gemini AI Assistant in Hotels Portal.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => isOpen = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: messages.map((message) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment: message.sender == 'user'
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (message.sender == 'bot')
                                      CircleAvatar(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        radius: 16,
                                        child: Icon(
                                          Icons.smart_toy,
                                          size: 16,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          maxWidth: 256,
                                        ),
                                        decoration: BoxDecoration(
                                          color: message.sender == 'user'
                                              ? Theme.of(
                                                  context,
                                                ).secondaryHeaderColor
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: SelectableText(
                                          message.text,
                                          style: TextStyle(
                                            color: message.sender == 'user'
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSecondary
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Ask something...',
                                border: OutlineInputBorder(),
                              ),
                              controller: _controller,
                              maxLines: 1,
                              onSubmitted: (_) => handleSendMessage(),
                              textInputAction: TextInputAction.send,
                              enableInteractiveSelection: true,
                              toolbarOptions: ToolbarOptions(
                                copy: true,
                                paste: true,
                                selectAll: true,
                              ),
                              focusNode: _focusNode,
                              autofocus: true, // NEW: Attach the FocusNode
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, size: 20),
                            onPressed: handleSendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
