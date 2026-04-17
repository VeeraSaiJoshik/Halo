import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'halo_theme.dart';
import 'aurum_theme.dart';
import 'terminal_theme.dart';
import 'meridian_theme.dart';

final haloThemeTypeProvider = StateProvider<HaloThemeType>(
  (ref) => HaloThemeType.aurum,
);

final haloThemeProvider = Provider<HaloThemeData>((ref) {
  return switch (ref.watch(haloThemeTypeProvider)) {
    HaloThemeType.aurum => AurumTheme(),
    HaloThemeType.terminal => TerminalTheme(),
    HaloThemeType.meridian => MeridianTheme(),
  };
});
