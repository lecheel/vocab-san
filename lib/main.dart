import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';
import 'package:vocab_jp/providers/audio_service.dart';
import 'package:vocab_jp/utils/keyboard_handler.dart';
import 'package:vocab_jp/widgets/file_list_view.dart';
import 'package:vocab_jp/widgets/practice_view.dart';
import 'package:vocab_jp/widgets/settings_view.dart';
import 'package:vocab_jp/widgets/app_settings_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => AudioService()),
      ],
      child: const VocabSanApp(),
    ),
  );
}

class VocabSanApp extends StatelessWidget {
  const VocabSanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab-San', // This can stay the same, it's just a display title
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // UPDATED: Now calls a single, more comprehensive initialization method
    // in AppState which handles loading settings and resuming the last session.
    await Provider.of<AppState>(context, listen: false).initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const HomePage();
    } else {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // UPDATED: Tab controller length is now 4
    _tabController = TabController(length: 4, vsync: this); 
    Provider.of<AppState>(context, listen: false).tabController = _tabController;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);

    return KeyboardHandler(
      focusNode: _focusNode,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Vocab-San'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                // UPDATED: Added a new Tab
                Tab(icon: Icon(Icons.download), text: "Packs"), // Renamed for clarity
                Tab(icon: Icon(Icons.psychology), text: "Practice"),
                Tab(icon: Icon(Icons.audiotrack), text: "Playback"), // Renamed for clarity
                Tab(icon: Icon(Icons.settings), text: "App Settings"), // The new tab
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              // UPDATED: Added the new view
              FileListView(),
              PracticeView(),
              SettingsView(), // This is the playback settings view
              AppSettingsView(), // This is our new app settings view
            ],
          ),
        ),
      ),
    );
  }
}
