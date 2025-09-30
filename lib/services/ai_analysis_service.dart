import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for AI-powered analysis using Gemini API
class AIAnalysisService {
  static const String _geminiApiKey = 'AIzaSyAWH1WyfGJE-JdtZRbS2leFRK2yX4TWJu0';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com';

  /// Analyze notification content and generate AI insights
  Future<NotificationAnalysis> analyzeNotification({
    required String appName,
    required String title,
    required String body,
    required String bigText,
    String? subText,
  }) async {
    try {
      // Debug: Log the notification content being analyzed
      print('🤖 Analyzing notification:');
      print('   App: $appName');
      print('   Title: "$title" (length: ${title.length})');
      print('   Body: "$body" (length: ${body.length})');
      print(
          '   SubText: "${subText ?? 'None'}" (length: ${subText?.length ?? 0})');
      print('   BigText: "$bigText" (length: ${bigText.length})');

      // Detect if this is a minimal content notification
      final hasMinimalContent =
          body.isEmpty && (subText?.isEmpty ?? true) && bigText.isEmpty;
      final hasNoContent = title.isEmpty && hasMinimalContent;

      if (hasNoContent) {
        print(
            '❌ CRITICAL: Completely empty notification detected - using intelligent fallback');
        return NotificationAnalysis.fallback(appName, 'Empty notification', '');
      }

      if (hasMinimalContent) {
        print(
            '⚠️ Minimal content detected - only title available, enhancing analysis...');
      }

      final prompt = '''
Analyze this notification and provide a comprehensive analysis:

App: $appName
Title: $title
Body: $body
SubText: ${subText ?? 'None'}
Additional Text: $bigText

CONTEXT: This notification comes from $appName. 

${hasMinimalContent ? '''
IMPORTANT: This notification has minimal content (only title is available). Please:
1. Extract maximum meaning from the title structure and format
2. Use your knowledge of $appName app patterns to infer context
3. For social media titles like "username: action", analyze both the user and action parts
4. Provide relevant suggestions based on the app type even with limited information
''' : 'Analyze ALL available text content above to understand the full context, message, and intent of the notification.'}

SPECIAL INSTRUCTIONS FOR MINIMAL CONTENT:
- If only Title is available, extract maximum meaning from it (e.g., "username: action" format in social media)
- For Instagram notifications, titles often contain "username: content_type" - analyze this pattern
- For social media, even minimal titles can indicate posts, stories, messages, or interactions
- Provide actionable insights even with limited information

Please provide:
1. A clear, concise AI summary (2-3 sentences) - Extract maximum context from title structure and app type
2. Sentiment analysis (positive, negative, neutral)
3. Urgency level (high, medium, low)
4. Whether action is required (true/false)
5. Whether it contains personal information (true/false)
6. Up to 3 practical suggested actions with specific next steps
7. Category classification

IMPORTANT: Use ALL available text content (Title, Body, SubText, Additional Text) to create a comprehensive analysis. If some fields are empty, focus on the available content. For payment apps, suggest actions like "Check account balance" or "Review transaction details". For social media, suggest "Reply to message" or "View full conversation". For emails, suggest "Reply with confirmation" or "Add to calendar".

Even if the notification content seems minimal, provide helpful context-aware suggestions based on the app type and any available information.

Respond ONLY with valid JSON (no markdown formatting):
{
  "summary": "Brief AI summary of the notification",
  "sentiment": "positive|negative|neutral",
  "urgency": "high|medium|low", 
  "requiresAction": true|false,
  "containsPersonalInfo": true|false,
  "category": "Social|Financial|Productivity|Entertainment|General",
  "suggestedActions": [
    {
      "id": "1",
      "title": "Specific Action Title",
      "description": "Clear description of what to do next",
      "icon": "reply|check|payment|calendar|call|message"
    }
  ]
}
''';

      // Try AI analysis with retry logic
      dynamic response;
      int attempts = 0;
      const maxAttempts = 2;

      while (attempts < maxAttempts) {
        try {
          response = await makeRequest(prompt);
          break; // Success, exit retry loop
        } catch (e) {
          attempts++;
          print('🤖 AI Analysis attempt $attempts failed: $e');
          if (attempts >= maxAttempts) {
            print('🤖 All AI analysis attempts failed, using fallback');
            return NotificationAnalysis.fallback(appName, title, body);
          }
          // Wait before retry
          await Future.delayed(Duration(seconds: attempts));
        }
      }

      // Handle both JSON object and string responses
      if (response is Map<String, dynamic>) {
        return NotificationAnalysis.fromJson(response);
      } else if (response is String) {
        // Try to parse the string as JSON
        try {
          final jsonData = jsonDecode(response);
          if (jsonData is Map<String, dynamic>) {
            return NotificationAnalysis.fromJson(jsonData);
          }
        } catch (e) {
          print(
              '🤖 AIAnalysisService: Failed to parse string response as JSON: $e');
        }
      }

      // If we can't parse the response, return fallback
      print('🤖 AIAnalysisService: Unable to parse response, using fallback');
      return NotificationAnalysis.fallback(appName, title, body);
    } catch (e) {
      print('🤖 AIAnalysisService: Error analyzing notification: $e');
      // Return fallback analysis
      return NotificationAnalysis.fallback(appName, title, body);
    }
  }

  /// Analyze call transcript and generate summary with key points
  Future<CallAnalysis> analyzeCall({
    required String contactName,
    required List<TranscriptMessage> transcript,
    required Duration duration,
    required bool isIncoming,
  }) async {
    try {
      final transcriptText =
          transcript.map((msg) => '${msg.speaker}: ${msg.text}').join('\n');

      final prompt = '''
Analyze this phone call transcript and provide a comprehensive analysis:

Contact: $contactName
Duration: ${duration.inMinutes} minutes ${duration.inSeconds % 60} seconds
Call Type: ${isIncoming ? 'Incoming' : 'Outgoing'}

Transcript:
$transcriptText

Please provide:
1. A clear, concise summary of the call (2-3 sentences)
2. 3-5 key points discussed in the call
3. Sentiment analysis (positive, negative, neutral)
4. Urgency level (high, medium, low)
5. Call category (business, personal, support, sales, etc.)
6. Up to 5 action items that should be followed up on
7. Overall call priority level

Focus on identifying important information, decisions made, and follow-up actions needed.

Respond ONLY with valid JSON (no markdown formatting):
{
  "summary": "Brief summary of the call",
  "keyPoints": ["Key point 1", "Key point 2", "Key point 3"],
  "sentiment": "positive|negative|neutral",
  "urgency": "high|medium|low",
  "category": "business|personal|support|sales|other",
  "priority": "urgent|high|medium|low",
  "actionItems": [
    {
      "id": "1",
      "title": "Action item title",
      "description": "Detailed description",
      "dueDate": "YYYY-MM-DD",
      "priority": "high|medium|low"
    }
  ]
}
''';

      final response = await makeRequest(prompt);

      // Handle both JSON object and string responses
      if (response is Map<String, dynamic>) {
        return CallAnalysis.fromJson(response);
      } else if (response is String) {
        try {
          final jsonData = jsonDecode(response);
          if (jsonData is Map<String, dynamic>) {
            return CallAnalysis.fromJson(jsonData);
          }
        } catch (e) {
          print(
              '🤖 AIAnalysisService: Failed to parse call analysis string: $e');
        }
      }

      return CallAnalysis.fallback(contactName, transcript);
    } catch (e) {
      print('Error analyzing call: $e');
      // Return fallback analysis
      return CallAnalysis.fallback(contactName, transcript);
    }
  }

  /// Generate action items from text content
  Future<List<ActionItemSuggestion>> generateActionItems(String content) async {
    try {
      final prompt = '''
Extract actionable tasks from this content:

$content

Please identify specific action items that should be followed up on. Focus on:
- Tasks mentioned explicitly
- Implied follow-up actions
- Deadlines or time-sensitive items
- Commitments made

Respond ONLY with valid JSON (no markdown formatting):
{
  "actionItems": [
    {
      "title": "Task title",
      "description": "Detailed description", 
      "priority": "high|medium|low",
      "dueDate": "YYYY-MM-DD" (if mentioned),
      "category": "call|email|meeting|research|other"
    }
  ]
}
''';

      final response = await makeRequest(prompt);

      Map<String, dynamic>? jsonResponse;
      if (response is Map<String, dynamic>) {
        jsonResponse = response;
      } else if (response is String) {
        try {
          final parsed = jsonDecode(response);
          if (parsed is Map<String, dynamic>) {
            jsonResponse = parsed;
          }
        } catch (e) {
          print(
              '🤖 AIAnalysisService: Failed to parse action items string: $e');
        }
      }

      if (jsonResponse != null) {
        final items = jsonResponse['actionItems'] as List<dynamic>? ?? [];
        return items
            .map((item) => ActionItemSuggestion.fromJson(item))
            .toList();
      }

      // Return empty list if parsing failed
      return [];
    } catch (e) {
      print('Error generating action items: $e');
      return [];
    }
  }

  /// Regenerate summary with specific focus
  Future<String> regenerateSummary({
    required String content,
    required String focusArea,
  }) async {
    try {
      final prompt = '''
Create a new summary for this content with focus on: $focusArea

Content:
$content

Provide a clear, concise summary (2-4 sentences) that highlights the $focusArea aspects.
Return only the summary text, no JSON formatting.
''';

      final response = await makeRequest(prompt);

      if (response is String) {
        // Clean any JSON formatting if present
        String cleanText = response.trim();
        try {
          final parsed = jsonDecode(cleanText);
          if (parsed is Map<String, dynamic> && parsed.containsKey('summary')) {
            return parsed['summary'].toString().trim();
          }
        } catch (e) {
          // If not JSON, return as-is
        }
        return cleanText;
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('summary')) {
          return response['summary'].toString().trim();
        } else if (response.containsKey('text')) {
          return response['text'].toString().trim();
        }
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      print('Error regenerating summary: $e');
      return 'Unable to generate new summary. Please try again.';
    }
  }

  /// Make direct request to Gemini API
  Future<dynamic> makeRequest(String prompt) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };

      print('🤖 AIAnalysisService: Making direct request to Gemini API...');
      print('🤖 AIAnalysisService: Using URL: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      print('🤖 AIAnalysisService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          final generatedText =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          print('🤖 AIAnalysisService: Generated text: $generatedText');

          // Clean the response text and try to parse as JSON
          try {
            String cleanedText = generatedText.trim();

            // Remove markdown code blocks if present
            if (cleanedText.startsWith('```json')) {
              cleanedText = cleanedText.substring(7); // Remove ```json
            }
            if (cleanedText.startsWith('```')) {
              cleanedText = cleanedText.substring(3); // Remove ```
            }
            if (cleanedText.endsWith('```')) {
              cleanedText = cleanedText.substring(
                  0, cleanedText.length - 3); // Remove trailing ```
            }

            // Trim again after removing markdown
            cleanedText = cleanedText.trim();

            print(
                '🤖 AIAnalysisService: Cleaned text for parsing: $cleanedText');

            // Handle truncated responses by attempting to fix common patterns
            if (!cleanedText.endsWith('}') && !cleanedText.endsWith(']')) {
              print(
                  '🤖 AIAnalysisService: Detected truncated response, attempting to fix...');

              // Try to find the last complete field and close the JSON
              int lastCommaIndex = cleanedText.lastIndexOf(',');
              int lastQuoteIndex = cleanedText.lastIndexOf('"');

              if (lastCommaIndex > -1 && lastCommaIndex > lastQuoteIndex) {
                // Remove incomplete field after last comma
                cleanedText = cleanedText.substring(0, lastCommaIndex);
              } else if (lastQuoteIndex > -1) {
                // Find the field name before the incomplete value
                int fieldStartIndex =
                    cleanedText.lastIndexOf('"', lastQuoteIndex - 1);
                if (fieldStartIndex > -1) {
                  int fieldNameStartIndex =
                      cleanedText.lastIndexOf('"', fieldStartIndex - 1);
                  if (fieldNameStartIndex > -1) {
                    cleanedText = cleanedText.substring(0, fieldNameStartIndex);
                  }
                }
              }

              // Ensure proper JSON closure
              int openBraces = '{'.allMatches(cleanedText).length;
              int closeBraces = '}'.allMatches(cleanedText).length;

              while (closeBraces < openBraces) {
                cleanedText += '}';
                closeBraces++;
              }

              print('🤖 AIAnalysisService: Fixed truncated JSON: $cleanedText');
            }

            final jsonResponse = jsonDecode(cleanedText);
            print('🤖 AIAnalysisService: Successfully parsed JSON response');
            return jsonResponse;
          } catch (e) {
            print('🤖 AIAnalysisService: Failed to parse as JSON: $e');
            print('🤖 AIAnalysisService: Original text: $generatedText');
            return generatedText;
          }
        } else {
          throw Exception('Invalid response structure from Gemini API');
        }
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again in a minute.');
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or quota exceeded.');
      } else {
        print('🤖 AIAnalysisService: Error response: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ??
              'Server error: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🤖 AIAnalysisService: Error making request: $e');
      rethrow;
    }
  }
}

/// Data model for notification analysis results
class NotificationAnalysis {
  final String summary;
  final String sentiment;
  final String urgency;
  final bool requiresAction;
  final bool containsPersonalInfo;
  final String category;
  final List<SuggestedActionData> suggestedActions;

  NotificationAnalysis({
    required this.summary,
    required this.sentiment,
    required this.urgency,
    required this.requiresAction,
    required this.containsPersonalInfo,
    required this.category,
    required this.suggestedActions,
  });

  factory NotificationAnalysis.fromJson(Map<String, dynamic> json) {
    return NotificationAnalysis(
      summary: json['summary']?.toString() ?? 'No analysis available',
      sentiment: json['sentiment']?.toString() ?? 'neutral',
      urgency: json['urgency']?.toString() ?? 'medium',
      requiresAction: json['requiresAction'] as bool? ?? false,
      containsPersonalInfo: json['containsPersonalInfo'] as bool? ?? false,
      category: json['category']?.toString() ?? 'General',
      suggestedActions: (json['suggestedActions'] as List<dynamic>?)
              ?.map((action) => SuggestedActionData.fromJson(action))
              .toList() ??
          [],
    );
  }

  factory NotificationAnalysis.fallback(
      String appName, String title, String body) {
    // Create more intelligent fallback based on app type
    String category = 'General';
    List<SuggestedActionData> actions = [];

    if (appName.toLowerCase().contains('instagram') ||
        appName.toLowerCase().contains('com.instagram')) {
      category = 'Social';
      // Parse Instagram title format: "username: action"
      String actionContext =
          title.contains(':') ? title.split(':').last.trim() : title;
      actions = [
        SuggestedActionData(
            id: '1',
            title: 'View Content',
            description: 'Open Instagram to view $actionContext',
            icon: 'message'),
        SuggestedActionData(
            id: '2',
            title: 'Visit Profile',
            description: 'Go to user profile',
            icon: 'message'),
        SuggestedActionData(
            id: '3',
            title: 'Open Instagram',
            description: 'Launch Instagram app',
            icon: 'open'),
      ];
    } else if (appName.toLowerCase().contains('messages') ||
        appName.toLowerCase().contains('whatsapp') ||
        appName.toLowerCase().contains('telegram') ||
        appName.toLowerCase().contains('message')) {
      category = 'Social';

      // Handle empty Messages notifications with more context
      String replyDesc = title.isEmpty
          ? 'Open Messages app to check new messages'
          : 'Open $appName to reply to: ${title.length > 30 ? title.substring(0, 30) + "..." : title}';
      String markReadDesc = title.isEmpty
          ? 'Mark all messages as read'
          : 'Mark conversation as read';

      actions = [
        SuggestedActionData(
            id: '1',
            title: 'Open Messages',
            description: replyDesc,
            icon: 'message'),
        SuggestedActionData(
            id: '2',
            title: 'Mark as Read',
            description: markReadDesc,
            icon: 'check'),
      ];
    } else if (appName.toLowerCase().contains('gmail') ||
        appName.toLowerCase().contains('email') ||
        appName.toLowerCase().contains('mail')) {
      category = 'Productivity';
      actions = [
        SuggestedActionData(
            id: '1',
            title: 'Reply',
            description: 'Reply to email',
            icon: 'reply'),
        SuggestedActionData(
            id: '2',
            title: 'Mark Important',
            description: 'Mark email as important',
            icon: 'check'),
      ];
    } else if (appName.toLowerCase().contains('pay') ||
        appName.toLowerCase().contains('bank') ||
        appName.toLowerCase().contains('upi')) {
      category = 'Financial';
      actions = [
        SuggestedActionData(
            id: '1',
            title: 'Check Balance',
            description: 'View account balance',
            icon: 'payment'),
        SuggestedActionData(
            id: '2',
            title: 'Transaction Details',
            description: 'View transaction details',
            icon: 'check'),
      ];
    } else {
      actions = [
        SuggestedActionData(
            id: '1',
            title: 'Open App',
            description: 'Open $appName to view details',
            icon: 'open'),
      ];
    }

    // Create more intelligent summary based on available content
    String summary;
    if (body.isNotEmpty) {
      summary =
          'Notification from $appName: ${body.length > 50 ? body.substring(0, 50) + "..." : body}';
    } else if (title.contains(':') &&
        appName.toLowerCase().contains('instagram')) {
      // Handle Instagram's "username: action" format
      final parts = title.split(':');
      final username = parts.first.trim();
      final action = parts.length > 1 ? parts.last.trim() : 'activity';
      summary =
          'Instagram notification: $username posted $action. Tap to view their content.';
    } else if (title.isEmpty) {
      // Handle completely empty notifications
      if (appName.toLowerCase().contains('messages')) {
        summary =
            'New message received. Open Messages app to view conversation details.';
      } else if (appName.toLowerCase().contains('whatsapp')) {
        summary = 'New WhatsApp notification. Open app to check messages.';
      } else {
        summary =
            'New notification from $appName. Open the app to view details.';
      }
    } else {
      summary = 'New notification from $appName: $title';
    }

    return NotificationAnalysis(
      summary: summary,
      sentiment: 'neutral',
      urgency: 'medium',
      requiresAction: false,
      containsPersonalInfo: false,
      category: category,
      suggestedActions: actions,
    );
  }
}

/// Data model for call analysis results
class CallAnalysis {
  final String summary;
  final List<String> keyPoints;
  final String sentiment;
  final String urgency;
  final String category;
  final String priority;
  final List<CallActionItem> actionItems;

  CallAnalysis({
    required this.summary,
    required this.keyPoints,
    required this.sentiment,
    required this.urgency,
    required this.category,
    required this.priority,
    required this.actionItems,
  });

  factory CallAnalysis.fromJson(Map<String, dynamic> json) {
    return CallAnalysis(
      summary: json['summary']?.toString() ?? 'No analysis available',
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((point) => point.toString())
              .toList() ??
          [],
      sentiment: json['sentiment']?.toString() ?? 'neutral',
      urgency: json['urgency']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'medium',
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((action) => CallActionItem.fromJson(action))
              .toList() ??
          [],
    );
  }

  factory CallAnalysis.fallback(
      String contactName, List<TranscriptMessage> transcript) {
    return CallAnalysis(
      summary: 'Call with $contactName completed',
      keyPoints: ['Call transcript recorded'],
      sentiment: 'neutral',
      urgency: 'medium',
      category: 'general',
      priority: 'medium',
      actionItems: [],
    );
  }
}

/// Data model for suggested actions
class SuggestedActionData {
  final String id;
  final String title;
  final String description;
  final String icon;

  SuggestedActionData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory SuggestedActionData.fromJson(Map<String, dynamic> json) {
    return SuggestedActionData(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Action',
      description: json['description']?.toString() ?? 'Perform action',
      icon: json['icon']?.toString() ?? 'open',
    );
  }
}

/// Data model for call action items
class CallActionItem {
  final String id;
  final String title;
  final String description;
  final String? dueDate;
  final String priority;

  CallActionItem({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
  });

  factory CallActionItem.fromJson(Map<String, dynamic> json) {
    return CallActionItem(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Action Item',
      description: json['description']?.toString() ?? 'Follow up required',
      dueDate: json['dueDate']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
    );
  }
}

/// Data model for action item suggestions
class ActionItemSuggestion {
  final String title;
  final String description;
  final String priority;
  final String? dueDate;
  final String category;

  ActionItemSuggestion({
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    required this.category,
  });

  factory ActionItemSuggestion.fromJson(Map<String, dynamic> json) {
    return ActionItemSuggestion(
      title: json['title']?.toString() ?? 'Task',
      description: json['description']?.toString() ?? 'Follow up required',
      priority: json['priority']?.toString() ?? 'medium',
      dueDate: json['dueDate']?.toString(),
      category: json['category']?.toString() ?? 'other',
    );
  }
}

// Add these to existing models if not already present
class TranscriptMessage {
  final String speaker;
  final String text;
  final String timestamp;
  final bool isUser;

  TranscriptMessage({
    required this.speaker,
    required this.text,
    required this.timestamp,
    required this.isUser,
  });
}
