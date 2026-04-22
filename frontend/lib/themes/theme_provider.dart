import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'halo_theme.dart';
import 'golden_theme.dart';
import 'terminal_theme.dart';
import 'meridian_theme.dart';
import 'blue_theme.dart';
import 'green_theme.dart';
import 'pink_theme.dart';
import 'red_theme.dart';

final haloThemeTypeProvider = StateProvider<HaloThemeType>(
  (ref) => HaloThemeType.golden,
);

final haloThemeProvider = Provider<HaloThemeData>((ref) {
  return switch (ref.watch(haloThemeTypeProvider)) {
    HaloThemeType.golden   => GoldenTheme(),
    HaloThemeType.terminal => TerminalTheme(),
    HaloThemeType.meridian => MeridianTheme(),
    HaloThemeType.blue     => BlueTheme(),
    HaloThemeType.green    => GreenTheme(),
    HaloThemeType.pink     => PinkTheme(),
    HaloThemeType.red      => RedTheme(),
  };
});

List<HaloThemeData> themes = [
  GoldenTheme(), 
  BlueTheme(), 
  GreenTheme(), 
  PinkTheme(), 
  RedTheme()
];