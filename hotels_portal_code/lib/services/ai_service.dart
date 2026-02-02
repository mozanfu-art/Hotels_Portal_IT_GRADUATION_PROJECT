import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hotel_booking_app/utils/constants.dart';
import '../models/hotel.dart';
import '../models/booking.dart';

class AiService {
  late GenerativeModel _model;
  final List<Map<String, String>> _conversationMemory = [];

  AiService(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(systemInstruction),
    );
  }

  /// Clears the conversation memory (e.g., on logout or new session)
  void clearMemory() {
    _conversationMemory.clear();
  }

  Future<String> getResponse({
    required String userMessage,
    required Map<String, dynamic> aiContext, // unified context
  }) async {
    try {
      // Add user message to conversation memory
      _conversationMemory.add({'role': 'user', 'content': userMessage});

      // Build conversation history (last 10 messages)
      String memoryContext = _conversationMemory
          .take(10)
          .map((msg) {
            return "${msg['role']}: ${msg['content']}";
          })
          .join('\n');

      // Build concise context string
      String context = _buildContext(aiContext: aiContext);

      print('context: $context');

      // Refined prompt for accurate app logic and data
      String prompt =
          '''
Context:
$context

History:
$memoryContext

User: "$userMessage"

Response:
''';

      final GenerateContentResponse response = await _model.generateContent([
        Content.text(prompt),
      ]);

      // Extract valid bot reply
      String botReply;
      if (response.text != null && response.text!.trim().isNotEmpty) {
        botReply = response.text!.trim();
      } else {
        botReply = _fallbackReply(userMessage);
      }

      // Save bot reply to memory
      _conversationMemory.add({'role': 'bot', 'content': botReply});

      return botReply;
    } catch (e) {
      print('AI Service Error: $e');
      final botReply =
          "Sorry, I couldn't process your request. Please check your connection and try again.";
      _conversationMemory.add({'role': 'bot', 'content': botReply});
      return botReply;
    }
  }

  /// Builds a compact string from the unified AI context
  String _buildContext({required Map<String, dynamic> aiContext}) {
    String context = 'Current screen: ${aiContext['screen'] ?? 'unknown'}\n';
    context += 'Logged in: ${aiContext['isLoggedIn'] ?? false}\n';
    if (aiContext['guestName'] != null &&
        (aiContext['guestName'] as String).isNotEmpty) {
      context += 'User: ${aiContext['guestName']}\n';
    }

    if (aiContext['availableHotels'] != null) {
      // Hotels (limit 5 for brevity)
      List<Hotel> hotelsFull = List<Hotel>.from(
        aiContext['availableHotels'] ?? [],
      );
      context += 'Available hotels: ${hotelsFull.length}\n';
      for (var hotel in hotelsFull.take(5)) {
        context += '- ${hotel.hotelName} (City: ${hotel.hotelCity})\n';
      }
    }

    if (aiContext['existingBookings'] != null) {
      // Bookings (limit 3)
      List<Booking> bookingsFull = List<Booking>.from(
        aiContext['existingBookings'] ?? [],
      );
      context += 'User bookings: ${bookingsFull.length}\n';
      for (var booking in bookingsFull.take(3)) {
        context +=
            '- Confirmation code: ${booking.confirmationCode}, Hotel ID: ${booking.hotelName}, Status: ${booking.bookingStatus}, Check-in: ${booking.checkInDate.toString()}, Check-out: ${booking.checkOutDate.toString()}\n';
      }
    }

    return context;
  }

  /// Smart fallback for incomplete or failed responses
  String _fallbackReply(String userMessage) {
    String lower = userMessage.toLowerCase();
    if (lower.contains('search') || lower.contains('hotel')) {
      return "To search for hotels in Sudan, go to the Home screen and tap 'Search Hotels'. Filter by city, price, or amenities.";
    } else if (lower.contains('book') || lower.contains('booking')) {
      return "For bookings, select a hotel, choose rooms, and confirm. No payment needed—it's direct confirmation.";
    } else if (lower.contains('login') || lower.contains('signup')) {
      return "Please use the Welcome screen to log in or sign up first.";
    } else {
      return "I'm here to help with Hotels Portal! Ask about searching hotels, bookings, or app features.";
    }
  }
}
