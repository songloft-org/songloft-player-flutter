import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../jsplugin/presentation/providers/jsplugin_provider.dart';
import '../../player/presentation/providers/player_provider.dart';
import '../../player/presentation/queue_page.dart';
import '../../player/presentation/utils/full_player_route.dart';
import '../../player/presentation/widgets/mini_player.dart';

final _pluginPlayerBarProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, entryPath) async {
      final identity = ref.watch(
        jsPluginsProvider.select((plugins) {
          for (final plugin in plugins.value ?? []) {
            if (plugin.entryPath == entryPath && plugin.status == 'active') {
              return (plugin.id, plugin.version, plugin.updatedAt);
            }
          }
          return null;
        }),
      );
      if (identity == null) return false;
      return ref.watch(jsPluginApiProvider).declaresHostPlayerBar(entryPath);
    });

class PluginPlayerLayout extends ConsumerWidget {
  const PluginPlayerLayout({
    super.key,
    required this.entryPath,
    required this.child,
  });

  final String? entryPath;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = entryPath;
    final showBar =
        path != null &&
        ref.watch(_pluginPlayerBarProvider(path)).asData?.value == true;
    return Column(
      children: [Expanded(child: child), if (showBar) const MiniPlayer()],
    );
  }
}

void openPluginPlayerUi(
  BuildContext context,
  WidgetRef ref, {
  required bool queue,
  required bool Function() isActive,
  void Function(bool suspended)? suspendPluginInput,
}) {
  if (!context.mounted) throw StateError('plugin page is no longer active');
  final route = ModalRoute.of(context);
  bool isCurrent() => context.mounted && route?.isCurrent == true && isActive();

  if (!isCurrent()) throw StateError('plugin page is no longer active');
  if (!queue && !ref.read(playerStateProvider).hasSong) {
    throw StateError('no current song');
  }

  // Finish the bridge reply before presenting host UI over the plugin.
  Timer.run(() async {
    if (!isCurrent()) return;
    if (!queue) {
      if (ref.read(playerStateProvider).hasSong) openFullPlayer(context);
      return;
    }
    suspendPluginInput?.call(true);
    try {
      await QueueBottomSheet.show(context);
    } finally {
      suspendPluginInput?.call(false);
    }
  });
}
