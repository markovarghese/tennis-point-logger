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

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
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
  int _tab = 0;
  _AppScreen _screen = _AppScreen.setup;

  String _opponentName = '';
  DateTime _matchDate = DateTime.now();
  List<TennisPoint> _points = [];
  TennisPoint _currentPoint = TennisPoint.fresh();
  AppSettings _settings = const AppSettings();
  ScoreState _matchStartScore = const ScoreState();

  void _handleStart(String opponent, DateTime date) {
    AppLog.info('match: start opponent="$opponent" date=${DateFormat('d MMM yyyy').format(date)}');
    setState(() {
      _opponentName = opponent;
      _matchDate = date;
      _points = [];
      _matchStartScore = ScoreState(setsToWin: _settings.format.setsToWin);
      _currentPoint = _freshPointWithDefaults();
      _screen = _AppScreen.entry;
    });
  }

  void _handleFieldChange(String key, bool? val) {
    setState(() {
      _currentPoint = _currentPoint.withField(key, val);
    });
  }

  void _handleNext() {
    final pointToSave = TennisPoint(
      id: _currentPoint.id,
      createdAt: _currentPoint.createdAt,
      myServe: _currentPoint.myServe,
      firstServe: _currentPoint.firstServe,
      doubleFault: _currentPoint.doubleFault,
      serverWon: _currentPoint.serverWon,
      forcedError: _currentPoint.forcedError,
      loserForehand: _currentPoint.loserForehand,
      score: nextScore(_prevScore, _currentPoint, _settings.format),
    );
    setState(() {
      _points = [..._points, pointToSave];
      _currentPoint = _freshPointWithDefaults();
    });
    AppLog.info('match: point #${_points.length} logged');
    _autoSync(pointToSave);
  }

  ScoreState get _prevScore =>
      _points.isEmpty ? _matchStartScore : (_points.last.score ?? _matchStartScore);

  void _recomputeScoresFrom(int startIdx) {
    var prev = startIdx == 0
        ? _matchStartScore
        : (_points[startIdx - 1].score ?? _matchStartScore);
    for (var i = startIdx; i < _points.length; i++) {
      final s = nextScore(prev, _points[i], _settings.format);
      _points[i] = _points[i].withScore(s);
      prev = s;
    }
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
    final prev = _prevScore;
    if (prev.isTiebreak) return null;
    if (prev.ptScore == '0-0') {
      // Start of a new game: find who served the previous game and flip.
      for (var i = _points.length - 1; i >= 0; i--) {
        if (_points[i].serverWon != null) {
          final ms = _points[i].myServe;
          return ms == null ? null : !ms;
        }
      }
      return null;
    }
    // Mid-game: inherit from the most recent effective point.
    for (var i = _points.length - 1; i >= 0; i--) {
      if (_points[i].serverWon != null) return _points[i].myServe;
    }
    return null;
  }

  Future<void> _autoSync(TennisPoint point, {int? index}) async {
    final s = _settings;
    if (s.gsState != GsState.connected) return;

    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(_matchDate);
    final row = point.toCsvRow(dateStr, _opponentName);
    final isUpdate = index != null;

    try {
      if (s.sheetMode == SheetMode.existing && s.selectedSheet != null) {
        if (isUpdate) {
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
          final rowNum = index + 2;
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
        _recomputeScoresFrom(idx);
      });
      _autoSync(_points[idx], index: idx);
    } else {
      AppLog.info('match: point edited (unknown index)');
      setState(() {
        final i = _points.indexWhere((p) => p.id == edited.id);
        if (i != -1) {
          _points[i] = edited;
          _recomputeScoresFrom(i);
        }
      });
    }
  }

  void _handleScoreOverride(ScoreOverride override, int? viewIdx) {
    setState(() {
      final applied = _applyOverride(override);
      if (viewIdx == null) {
        if (_points.isEmpty) {
          _matchStartScore = applied;
        } else {
          _points[_points.length - 1] = _points.last.withScore(applied);
        }
      } else {
        _points[viewIdx] = _points[viewIdx].withScore(applied);
        _recomputeScoresFrom(viewIdx + 1);
      }
    });
  }

  ScoreState _applyOverride(ScoreOverride o) {
    final fmt = _settings.format;
    final inFinalSet = (o.mySets + o.oppSets) == fmt.setsInMatch - 1;
    final atTb = fmt.tiebreakPoints > 0 &&
        o.myGames == fmt.gamesPerSet &&
        o.oppGames == fmt.gamesPerSet;
    final inFinalTb = atTb && inFinalSet && fmt.finalSet != FinalSetType.full;
    final inTiebreak = atTb && !inFinalTb;
    return ScoreState(
      mySets: o.mySets,
      oppSets: o.oppSets,
      myGames: o.myGames,
      oppGames: o.oppGames,
      myPts: 0,
      oppPts: 0,
      ptScore: '0-0',
      isTiebreak: inTiebreak || inFinalTb,
      inFinalTb: inFinalTb,
      matchOver: o.mySets >= fmt.setsToWin || o.oppSets >= fmt.setsToWin,
      setsToWin: _matchStartScore.setsToWin,
    );
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
    if (_screen == _AppScreen.history) {
      return HistoryScreen(
        points: _points,
        opponentName: _opponentName,
        onBack: () => setState(() => _screen = _AppScreen.entry),
        onEditPoint: _handleEditPoint,
      );
    }

    if (_tab == 1) {
      return SettingsScreen(
        settings: _settings,
        onChanged: (s) => setState(() => _settings = s),
      );
    }

    return switch (_screen) {
      _AppScreen.setup => SetupScreen(onStart: _handleStart),
      _AppScreen.entry => _entryWidget(),
      _ => SetupScreen(onStart: _handleStart),
    };
  }

  Widget _entryWidget() {
    return EntryScreen(
      points: _points,
      currentPoint: _currentPoint,
      matchStartScore: _matchStartScore,
      opponentName: _opponentName,
      matchDate: _matchDate,
      format: _settings.format,
      gsState: _settings.gsState,
      onFieldChange: _handleFieldChange,
      onNext: _handleNext,
      onOpenHistory: () => setState(() => _screen = _AppScreen.history),
      onBackToSetup: () => setState(() => _screen = _AppScreen.setup),
      onExport: () => showExportSheet(context, _points, _opponentName, _matchDate),
      onEditPoint: _handleEditPoint,
      onScoreOverride: _handleScoreOverride,
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
