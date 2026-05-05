import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'models/point.dart';
import 'models/match_settings.dart';
import 'widgets/score_override_sheet.dart';
import 'widgets/export_sheet.dart';
import 'screens/setup_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TennisLoggerApp());
}

class TennisLoggerApp extends StatelessWidget {
  const TennisLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Logger',
      theme: buildTheme(),
      home: const _AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum _AppScreen { setup, entry, history }

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _tab = 0; // 0 = Match, 1 = Settings
  _AppScreen _screen = _AppScreen.setup;

  String _opponentName = '';
  DateTime _matchDate = DateTime.now();
  List<TennisPoint> _points = [];
  TennisPoint _currentPoint = TennisPoint.fresh();
  AppSettings _settings = const AppSettings();
  ScoreOverride? _scoreOverride;

  void _handleStart(String opponent, DateTime date) {
    setState(() {
      _opponentName = opponent;
      _matchDate = date;
      _points = [];
      _currentPoint = TennisPoint.fresh();
      _scoreOverride = null;
      _screen = _AppScreen.entry;
    });
  }

  void _handleFieldChange(String key, bool? val) {
    setState(() {
      _currentPoint = _currentPoint.withField(key, val);
    });
  }

  void _handleNext() {
    setState(() {
      _points = [..._points, _currentPoint];
      _currentPoint = TennisPoint.fresh();
    });
  }

  void _handleEditPoint(TennisPoint edited) {
    setState(() {
      _points = _points.map((p) => p.id == edited.id ? edited : p).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
        bottomNavigationBar: _screen != _AppScreen.history
            ? _BottomNav(
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    // History screen covers entire area
    if (_screen == _AppScreen.history) {
      return HistoryScreen(
        points: _points,
        opponentName: _opponentName,
        onBack: () => setState(() => _screen = _AppScreen.entry),
        onEditPoint: _handleEditPoint,
      );
    }

    // Settings tab
    if (_tab == 1) {
      return SettingsScreen(
        settings: _settings,
        onChanged: (s) => setState(() => _settings = s),
      );
    }

    // Match tab
    return switch (_screen) {
      _AppScreen.setup => SetupScreen(onStart: _handleStart),
      _AppScreen.entry => _EntryWithFab(),
      _ => SetupScreen(onStart: _handleStart),
    };
  }

  Widget _EntryWithFab() {
    return EntryScreen(
      points: _points,
      currentPoint: _currentPoint,
      opponentName: _opponentName,
      format: _settings.format,
      gsState: _settings.gsState,
      onFieldChange: _handleFieldChange,
      onNext: _handleNext,
      onOpenHistory: () => setState(() => _screen = _AppScreen.history),
      onBackToSetup: () => setState(() => _screen = _AppScreen.setup),
      onExport: () => showExportSheet(
        context, _points, _opponentName, _matchDate,
        settings: _settings,
      ),
      onEditPoint: _handleEditPoint,
      scoreOverride: _scoreOverride,
      onScoreOverride: (o) => setState(() => _scoreOverride = o),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onChanged,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.secondaryContainer,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sports_tennis_outlined),
          selectedIcon: Icon(Icons.sports_tennis),
          label: 'Match',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
