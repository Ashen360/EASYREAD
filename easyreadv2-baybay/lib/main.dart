import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/config/API_KEY.env');
    runApp(const EasyReadApp());
  } catch (e) {
    print('Failed to load .env file: $e');
  }
}

class EasyReadApp extends StatelessWidget {
  const EasyReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dyslexiaFriendlyTheme,
      darkTheme: dyslexiaFriendlyThemeDark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// Light Theme for Dyslexia
final ThemeData dyslexiaFriendlyTheme = ThemeData(
  colorScheme: ColorScheme(
    primary: Colors.blueGrey.shade700,
    primaryContainer: Colors.blueGrey.shade100,
    secondary: Colors.teal.shade700,
    secondaryContainer: Colors.teal.shade100,
    surface: Colors.grey.shade200,
    background: Colors.grey.shade100,
    error: Colors.red.shade700,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontSize: 18.0,
      fontFamily: 'Poppins',
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.0,
      fontFamily: 'Poppins',
      color: Colors.black87,
    ),
  ),
  scaffoldBackgroundColor: Colors.grey.shade100,
);

// Dark Theme for Dyslexia
final ThemeData dyslexiaFriendlyThemeDark = ThemeData(
  colorScheme: ColorScheme(
    primary: Colors.blueGrey.shade300,
    primaryContainer: Colors.blueGrey.shade800,
    secondary: Colors.teal.shade300,
    secondaryContainer: Colors.teal.shade800,
    surface: Colors.grey.shade900,
    background: Colors.grey.shade800,
    error: Colors.red.shade300,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white70,
    onBackground: Colors.white70,
    onError: Colors.black,
    brightness: Brightness.dark,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontSize: 18.0,
      fontFamily: 'Poppins',
      color: Colors.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.0,
      fontFamily: 'Poppins',
      color: Colors.white70,
    ),
  ),
  scaffoldBackgroundColor: Colors.grey.shade800,
);


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Text formatting properties
  double fontSize = 18.0;
  double lineSpacing = 1.5;
  double letterSpacing = 0.5;
  String selectedFont = 'OpenDyslexic';
  Color backgroundColor = const Color(0xFFF5F5DC); // Beige background
  Color textColor = Colors.white;
  bool isBoldText = false;
  bool isDarkMode = false;
  
  // Content
  String inputText = '';
  String outputText = '';
  List<String> highlightedWords = [];
  int highlightIndex = 0;
  
  // TTS
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  double speechRate = 0.5;
  bool isHighlightingEnabled = true;
  
  // Controller for text highlighting
  TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Tab controller
  late TabController _tabController;
  
  // List of available fonts
  final List<String> availableFonts = [
    'OpenDyslexic',
    'Arial',
    'Comic Sans MS',
    'Verdana',
    'Century Gothic',
    'Poppins'
  ];
  
  // Processing state
  bool isProcessing = false;
  
  // Chat history
  List<Map<String, dynamic>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initTTS();
    _loadPreferences();

    // Listen for tab changes
    _tabController.addListener(() {
      setState(() {
        // Clear output when switching tabs
        outputText = '';
        highlightedWords = [];
      });
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _tabController.dispose();
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Initialize text-to-speech
  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(speechRate);
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

// Save chat to history with tags
  void _saveChat(String userMessage, String botResponse, String tag) {
    setState(() {
      chatHistory.insert(0, {
        'user': userMessage,
        'bot': botResponse,
        'tag': tag,
        'timestamp': DateTime.now(),
      });
    });
  }

// Display chat history
void _showChatHistory() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Chat History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: chatHistory.isEmpty
              ? const Center(child: Text('No chat history available.'))
              : ListView.builder(
                  itemCount: chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = chatHistory[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tag: ${chat['tag']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text('You: ${chat['user']}', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('AI: ${chat['bot']}'),
                        Text('${chat['timestamp']}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const Divider(),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Show confirmation dialog BEFORE clearing history
              _showDeleteConfirmation(context);
            },
            child: const Text('Clear History'),
          ),
        ],
      );
    },
  );
}

// Show confirmation dialog before clearing history
void _showDeleteConfirmation(BuildContext parentContext) {
  showDialog(
    context: parentContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete your chat history? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the confirmation dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              chatHistory.clear(); // Clear chat history
              Navigator.of(context).pop(); // Close the confirmation dialog
              Navigator.of(parentContext).pop(); // Close the chat history dialog
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

  
  // Load user preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fontSize = prefs.getDouble('fontSize') ?? 18.0;
      lineSpacing = prefs.getDouble('lineSpacing') ?? 1.5;
      letterSpacing = prefs.getDouble('letterSpacing') ?? 0.5;
      selectedFont = prefs.getString('selectedFont') ?? 'OpenDyslexic';
      speechRate = prefs.getDouble('speechRate') ?? 0.5;
      textColor = Color(prefs.getInt('textColor') ?? Colors.white.value);
      backgroundColor = Color(prefs.getInt('backgroundColor') ?? Colors.grey.shade900.value);
      isBoldText = prefs.getBool('isBoldText') ?? false;
      isHighlightingEnabled = prefs.getBool('isHighlightingEnabled') ?? true;
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }
  
  // Save user preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setDouble('lineSpacing', lineSpacing);
    await prefs.setDouble('letterSpacing', letterSpacing);
    await prefs.setString('selectedFont', selectedFont);
    await prefs.setDouble('speechRate', speechRate);
    await prefs.setInt('textColor', textColor.value);
    await prefs.setInt('backgroundColor', backgroundColor.value);
    await prefs.setBool('isBoldText', isBoldText);
    await prefs.setBool('isHighlightingEnabled', isHighlightingEnabled);
    await prefs.setBool('isDarkMode', isDarkMode);
  }
  
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: 'assets/config/.env');
      runApp(const EasyReadApp());
    } catch (e) {
      print('Failed to load .env file: $e');
    }
  }

  // Call Gemini API for text processing
Future<void> callGeminiAPI(String prompt) async {
  _focusNode.unfocus();

  if (prompt.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter some text')),
    );
    return;
  }

  setState(() {
    isProcessing = true;
    outputText = "Processing your request...";
  });

  final apiKey = dotenv.env['API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    setState(() {
      outputText = 'API key is missing. Please check your .env file.';
      isProcessing = false;
    });
    return;
  }

  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

  final systemPrompt =
      "You are an app that helps students with dyslexia. By providing real-time support, such as text-to-speech and word highlighting, to improve reading comprehension.";
  String fullPrompt;
  String promptTag;

  switch (_tabController.index) {
    case 0:
      fullPrompt =
          "$systemPrompt Answer the following question in simple, clear language suitable for someone with dyslexia: $prompt";
      promptTag = "Ask";
      break;
    case 1:
      fullPrompt =
          "$systemPrompt Please simplify this text to make it easier to read for someone with dyslexia. Use shorter sentences, simpler words, and clear structure: $prompt";
      promptTag = "Simplify";
      break;
    case 2:
      fullPrompt =
          "$systemPrompt Please explain the following text in simple terms suitable for someone with dyslexia. Use clear language and examples: $prompt";
      promptTag = "Explain";
      break;
    case 3:
      fullPrompt =
          "$systemPrompt Please summarize the key points of this text, making it concise and easy to understand for someone with dyslexia: $prompt";
      promptTag = "Summarize";
      break;
    default:
      fullPrompt = "$systemPrompt $prompt";
      promptTag = "General";
  }

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": fullPrompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 800,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responseText = data['candidates'][0]['content']['parts'][0]['text'];

      setState(() {
        outputText = responseText;
        highlightedWords = outputText.split(' ');
        highlightIndex = 0;
        isProcessing = false;

        _saveChat(prompt, responseText, promptTag);
        textController.clear();
        inputText = '';
      });
    } else {
      setState(() {
        outputText = 'Error: Unable to generate text. Please try again.';
        isProcessing = false;
      });
    }
  } catch (e) {
    setState(() {
      outputText = 'Network error: $e';
      isProcessing = false;
    });
  }
}
  
  // Text-to-speech functionality
Future<void> _speak(String text) async {
  if (isSpeaking) {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  } else {
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.speak(text);
    setState(() {
      isSpeaking = true;
    });

    // Start word highlighting if enabled
    if (isHighlightingEnabled) {
      _startWordHighlighting();
    }
  }
}
  
  // Word-by-word highlighting
void _startWordHighlighting() async {
  if (highlightedWords.isEmpty || !isHighlightingEnabled) return;

  highlightIndex = 0;

  for (int i = 0; i < highlightedWords.length; i++) {
    if (!mounted || !isSpeaking || !isHighlightingEnabled) return;

    setState(() {
      highlightIndex = i;
    });

    // Adjust delay dynamically based on speech rate
    final delay = Duration(milliseconds: (500 / speechRate).round());
    await Future.delayed(delay);
  }

  // Reset highlighting after finishing
  if (mounted) {
    setState(() {
      highlightIndex = 0;
    });
  }
}
  
  // Widget for displaying highlighted text
  Widget _buildHighlightedText() {
    if (highlightedWords.isEmpty || !isHighlightingEnabled || !isSpeaking) {
      return Text(
        outputText,
        style: TextStyle(
          fontSize: fontSize,
          height: lineSpacing,
          letterSpacing: letterSpacing,
          fontFamily: selectedFont,
          color: textColor,
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }
    
    return RichText(
      text: TextSpan(
        children: List.generate(
          highlightedWords.length,
          (index) => TextSpan(
            text: '${highlightedWords[index]}${index < highlightedWords.length - 1 ? ' ' : ''}',
            style: TextStyle(
              fontSize: fontSize,
              height: lineSpacing,
              letterSpacing: letterSpacing,
              fontFamily: selectedFont,
              color: index == highlightIndex ? Colors.blue : textColor,
              fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
              backgroundColor: index == highlightIndex ? const Color.fromARGB(255, 255, 230, 0).withOpacity(0.3) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  // Tab widget to show different modes
Widget _buildTabBar() {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(25),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400; // Adjust based on screen width
        return TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: [
            _buildTab(isCompact, Icons.chat_outlined, "Ask"),
            _buildTab(isCompact, Icons.sort_by_alpha, "Simplify"),
            _buildTab(isCompact, Icons.help_outline, "Explain"),
            _buildTab(isCompact, Icons.summarize, "Summarize"),
          ],
        );
      },
    ),
  );
}

Widget _buildTab(bool isCompact, IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        if (!isCompact) ...[
          const SizedBox(width: 8),
          Text(label),
        ],
      ],
    ),
  );
}

  // Modern AI chat-like UI
  @override
  Widget build(BuildContext context) {
    String promptHint = "Ask a question...";
    
    // Different hints based on the selected mode
    switch (_tabController.index) {
      case 0:
        promptHint = "Ask a question...";
        break;
      case 1:
        promptHint = "Enter text to simplify...";
        break;
      case 2:
        promptHint = "Enter text to explain...";
        break;
      case 3:
        promptHint = "Enter text to summarize...";
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyRead'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showChatHistory();
            },
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: outputText.isEmpty 
                ? _buildWelcomeScreen() 
                : _buildOutputScreen(),
            ),
            _buildInputArea(promptHint),
          ],
        ),
      ),
    );
  }
  
  // Welcome screen with instructions
  Widget _buildWelcomeScreen() {
    String welcomeMessage = "";
    String instructionMessage = "";
    
    switch (_tabController.index) {
      case 0:
        welcomeMessage = "Ask me anything";
        instructionMessage = "Type your question and I'll respond in a way that's easy to understand.";
        break;
      case 1:
        welcomeMessage = "Text Simplifier";
        instructionMessage = "Enter complex text, and I'll make it easier to read with simpler words and shorter sentences.";
        break;
      case 2:
        welcomeMessage = "Text Explainer";
        instructionMessage = "Enter difficult text, and I'll explain it with clear language and helpful examples.";
        break;
      case 3:
        welcomeMessage = "Text Summarizer";
        instructionMessage = "Enter long text, and I'll provide a concise summary of the key points.";
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0 ? Icons.chat_bubble_outline :
            _tabController.index == 1 ? Icons.sort_by_alpha :
            _tabController.index == 2 ? Icons.help_outline :
            Icons.summarize,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            welcomeMessage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            instructionMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  // Output screen with AI response
Widget _buildOutputScreen() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: [
        // Response card
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Response header
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.assistant, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'EasyRead Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                        onPressed: () {
                          if (outputText.isNotEmpty) {
                            _speak(outputText);
                          }
                        },
                        tooltip: isSpeaking ? 'Stop Reading' : 'Read Aloud',
                      ),
                      IconButton(
                        icon: Icon(
                          isHighlightingEnabled ? Icons.highlight : Icons.highlight_off,
                          color: isHighlightingEnabled 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            isHighlightingEnabled = !isHighlightingEnabled;
                            _savePreferences();
                          });
                        },
                        tooltip: isHighlightingEnabled ? 'Disable Highlighting' : 'Enable Highlighting',
                      ),
                    ],
                  ),
                ),
                // Response content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: isProcessing
                      ? _buildLoadingIndicator()
                      : SingleChildScrollView(
                          child: _buildHighlightedText(),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  
  // Loading indicator
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Processing your request...',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  
// Modern input area
Widget _buildInputArea(String promptHint) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: promptHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            onChanged: (value) {
              setState(() {
                inputText = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isProcessing ? null : () => callGeminiAPI(inputText),
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
        ),
      ],
    ),
  );
}
  
  // Enhanced settings dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Accessibility Settings'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Text appearance settings
                    _buildSettingsSection(
                      'Text Appearance',
                      [
                        ListTile(
                          title: const Text('Font Size'),
                          subtitle: Slider(
                            value: fontSize,
                            min: 14.0,
                            max: 40.0,
                            divisions: 13,
                            label: fontSize.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                fontSize = value;
                              });
                              this.setState(() {});
                            },
                          ),
                          leading: const Icon(Icons.format_size),
                        ),
                        ListTile(
                          title: const Text('Line Spacing'),
                          subtitle: Slider(
                            value: lineSpacing,
                            min: 1.0,
                            max: 3.0,
                            divisions: 10,
                            label: lineSpacing.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                lineSpacing = value;
                              });
                              this.setState(() {});
                            },
                          ),
                          leading: const Icon(Icons.format_line_spacing),
                        ),
                        ListTile(
                          title: const Text('Letter Spacing'),
                          subtitle: Slider(
                            value: letterSpacing,
                            min: 0.0,
                            max: 3.0,
                            divisions: 15,
                            label: letterSpacing.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                letterSpacing = value;
                              });
                            },
                          ),
                          leading: const Icon(Icons.space_bar),
                        ),
                        ListTile(
                          title: const Text('Font'),
                          subtitle: DropdownButton<String>(
                            value: selectedFont,
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedFont = newValue;
                                });
                                this.setState(() {});
                              }
                            },
                            items: availableFonts.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          leading: const Icon(Icons.font_download),
                        ),
                        SwitchListTile(
                          title: const Text('Bold Text'),
                          value: isBoldText,
                          onChanged: (bool value) {
                            setState(() {
                              isBoldText = value;
                            });
                            this.setState(() {});
                          },
                          secondary: const Icon(Icons.format_bold),
                        ),
                      ],
                    ),
                    
                    // Speech settings
                    _buildSettingsSection(
                      'Speech & Highlighting',
                      [
                        ListTile(
                          title: const Text('Speech Rate'),
                          subtitle: Slider(
                            value: speechRate,
                            min: 0.25,
                            max: 2.0,
                            divisions: 7,
                            label: speechRate.toStringAsFixed(2),
                            onChanged: (value) async{
                              setState(() {
                                speechRate = value;
                              });
                              await flutterTts.setSpeechRate(speechRate);
                              _savePreferences();
                            },
                          ),
                          leading: const Icon(Icons.speed),
                        ),
                        SwitchListTile(
                          title: const Text('Word Highlighting'),
                          subtitle: const Text('Highlight words as they are spoken'),
                          value: isHighlightingEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              isHighlightingEnabled = value;
                            });
                            this.setState(() {});
                          },
                          secondary: const Icon(Icons.highlight),
                        ),
                      ],
                    ),
                    
                    // Colors settings
                    _buildSettingsSection(
                      'Colors',
                      [
                        ListTile(
                          title: const Text('Text Color'),
                          subtitle: const Text('Choose the color of the text'),
                          leading: const Icon(Icons.format_color_text),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: textColor,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showColorPicker(true);
                          },
                        ),
                        ListTile(
                          title: const Text('Background Color'),
                          subtitle: const Text('Choose the background color'),
                          leading: const Icon(Icons.format_color_fill),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showColorPicker(false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _savePreferences();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Settings section builder
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 1,
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  // Enhanced color picker
  void _showColorPicker(bool isTextColor) {
    final theme = Theme.of(context);
    final List<Color> colorOptions = [
      theme.colorScheme.primary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondary,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.surface,
      theme.colorScheme.background,
      theme.colorScheme.error,
      Colors.grey,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isTextColor ? 'Select Text Color' : 'Select Background Color'),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: colorOptions.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isTextColor) {
                        textColor = colorOptions[index];
                      } else {
                        backgroundColor = colorOptions[index];
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorOptions[index],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}