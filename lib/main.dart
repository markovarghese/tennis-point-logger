import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'services/app_log.dart';
import 'services/google_auth_service.dart';
import 'services/score_engine.dart';
import 'theme.dart';
import 'models/point.dart';
import 'models/match_settings.dart';
import 'widgets/score_override_sheet.dart';
import 'widgets/export_sheet.dart';
import 'screens/setup_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await GoogleAuthService.instance.initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AppLog.info('app: started');
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
    AppLog.info('match: start opponent="$opponent" date=${DateFormat('d MMM yyyy').format(date)}');
    setState(() {
      _opponentName = opponent;
      _matchDate = date;
      _points = [];
      _currentPoint = _freshPointWithDefaults();
      _scoreOverride = null;
      _screen = _AppScreen.entry;
    });
  }

  void _handleFieldChange(String key, bool? val) {
    setState(() {
      _currentPoint = _currentPoint.withField(key, val);
    });
  }

  TennisPoint _freshPointWithDefaults() {
    final now = DateTime.now();
    final myServe = _computeMyServeDefault();
    return TennisPoint(
      id: '${now.millisecondsSinceEpoch}_${now.microsecond}',
      createdAt: now,
      myServe: myServe,
      firstServe: true,
      doubleFault: false,
      serverWon: myServe == null ? null : !myServe,
      forcedError: false,
      loserForehand: true,
    );
  }

  bool? _computeMyServeDefault() {
    final score = calcScore(_points, _settings.format);
    if (score.isTiebreak) return null;
    if (score.ptScore == '0-0') {
      final prev = _lastPointOfPreviousGame();
      if (prev?.myServe == null) return null;
      return !prev!.myServe!;
    }
    return _points.isNotEmpty ? _points.last.myServe : null;
  }

  TennisPoint? _lastPointOfPreviousGame() {
    int lastGameEndIdx = -1;
    int prevMyGames = 0, prevOppGames = 0, prevMySets = 0, prevOppSets = 0;
    for (int i = 0; i < _points.length; i++) {
      final s = calcScore(_points.sublist(0, i + 1), _settings.format);
      if (s.myGames + s.oppGames != prevMyGames + prevOppGames ||
          s.mySets + s.oppSets != prevMySets + prevOppSets) {
        lastGameEndIdx = i;
        prevMyGames = s.myGames;
        prevOppGames = s.oppGames;
        prevMySets = s.mySets;
        prevOppSets = s.oppSets;
      }
    }
    return lastGameEndIdx >= 0 ? _points[lastGameEndIdx] : null;
  }

  void _handleNext() {
    final point = _currentPoint;
    setState(() {
      _points = [..._points, point];
      _currentPoint = _freshPointWithDefaults();
    });
    AppLog.info('match: point #${_points.length} logged');
    _autoSync(point);
  }

  Future<void> _autoSync(TennisPoint point, {int? index}) async {
    final s = _settings;
    if (s.gsState != GsState.connected) return;
    if (!s.autoSyncAfterPoint) return;

    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(_matchDate);
    final row = point.toCsvRow(dateStr, _opponentName);
    final isUpdate = index != null;

    try {
      if (s.sheetMode == SheetMode.existing && s.selectedSheet != null) {
        if (isUpdate) {
          // For existing sheets, we don't know the starting row easily without more tracking.
          AppLog.info('sync: update skipped for existing sheet');
        } else {
          await GoogleAuthService.instance.appendToSheet(
            s.selectedSheet!.id,
            [row],
            range: 'LoggerData',
          );
          AppLog.info('sync: ok → existing sheet "${s.selectedSheet!.name}"');
        }
      } else if (s.sheetMode == SheetMode.create && s.sheetsId != null) {
        if (isUpdate) {
          final rowNum = index + 2; // Point 0 is row 2 in template
          await GoogleAuthService.instance.updateRow(s.sheetsId!, 'Logger!A$rowNum', row);
          AppLog.info('sync: ok (update) → logger sheet row $rowNum');
        } else {
          await GoogleAuthService.instance.appendRowToLogger(s.sheetsId!, row);
          AppLog.info('sync: ok (append) → logger sheet');
        }
      }
    } catch (e) {
      AppLog.error('sync: failed', e);
    }
  }

  void _handleEditPoint(TennisPoint edited) {
    final idx = _points.indexWhere((p) => p.id == edited.id);
    if (idx != -1) {
      AppLog.info('match: point #${idx + 1} edited');
      setState(() {
        _points[idx] = edited;
      });
      _autoSync(edited, index: idx);
    } else {
      AppLog.info('match: point edited (unknown index)');
      setState(() {
        _points = _points.map((p) => p.id == edited.id ? edited : p).toList();
      });
    }
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
      _AppScreen.entry => _entryWithFab(),
      _ => SetupScreen(onStart: _handleStart),
    };
  }

  Widget _entryWithFab() {
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
