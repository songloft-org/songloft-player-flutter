import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

/// 播放控制按钮组
class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeekBy;
  final bool canSeek;
  final double size;
  final bool isBuffering;
  final bool showGlow;
  final bool useRoundedRect;

  const PlayControls({
    super.key,
    required this.isPlaying,
    this.hasPrev = true,
    this.hasNext = true,
    this.onPlay,
    this.onPause,
    this.onPrev,
    this.onNext,
    this.onSeekBy,
    this.canSeek = false,
    this.size = 48,
    this.isBuffering = false,
    this.showGlow = false,
    this.useRoundedRect = false,
  });

  @override
  Widget build(BuildContext context) {
    final seekBy = onSeekBy;
    if (seekBy == null) return _buildTransport(context, size, 8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final playSizeFloor = math.min(size, width / 5);
        final sideSize = math.min(
          size <= 40 ? 44.0 : 48.0,
          (width - playSizeFloor) / 4,
        );
        final playSize = math.min(size, width - 4 * sideSize);
        final gap = ((width - playSize - 4 * sideSize) / 4).clamp(0.0, 8.0);
        return _buildTransport(
          context,
          playSize,
          gap,
          sideSize: sideSize,
          seekBy: seekBy,
        );
      },
    );
  }

  Widget _buildTransport(
    BuildContext context,
    double playSize,
    double gap, {
    double? sideSize,
    ValueChanged<Duration>? seekBy,
  }) {
    final theme = Theme.of(context);
    final iconSize =
        sideSize == null
            ? size * 0.5
            : math.min(sideSize, size <= 40 ? 22.0 : 28.0);
    final trackStyle = IconButton.styleFrom(
      fixedSize: sideSize == null ? null : Size.square(sideSize),
      minimumSize: sideSize == null ? null : Size.square(sideSize),
      padding: sideSize == null ? null : EdgeInsets.zero,
      tapTargetSize: sideSize == null ? null : MaterialTapTargetSize.shrinkWrap,
      foregroundColor: theme.colorScheme.onSurface,
      disabledForegroundColor: theme.colorScheme.onSurface.withValues(
        alpha: 0.38,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: hasPrev ? onPrev : null,
          icon: Icon(Icons.skip_previous_rounded, size: iconSize),
          tooltip: AppLocalizations.of(context).playerPrevious,
          style: trackStyle,
        ),
        SizedBox(width: gap),
        if (seekBy != null) ...[
          SeekStepButton(
            forward: false,
            onSeekBy: canSeek ? seekBy : null,
            size: sideSize!,
          ),
          SizedBox(width: gap),
        ],
        _buildPlayPauseButton(context, playSize),
        SizedBox(width: gap),
        if (seekBy != null) ...[
          SeekStepButton(
            forward: true,
            onSeekBy: canSeek ? seekBy : null,
            size: sideSize!,
          ),
          SizedBox(width: gap),
        ],
        IconButton(
          onPressed: hasNext ? onNext : null,
          icon: Icon(Icons.skip_next_rounded, size: iconSize),
          tooltip: AppLocalizations.of(context).playerNext,
          style: trackStyle,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, double size) {
    final theme = Theme.of(context);
    final borderRadius =
        useRoundedRect ? AppRadius.xxlAll : BorderRadius.circular(size);

    Widget button;

    if (isBuffering) {
      button = Semantics(
        label: AppLocalizations.of(context).playerBufferingSemantic,
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: borderRadius,
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: EdgeInsets.all(size * 0.25),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      button = Semantics(
        button: true,
        label:
            isPlaying
                ? AppLocalizations.of(context).playerPause
                : AppLocalizations.of(context).playerPlay,
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: isPlaying ? onPause : onPlay,
            borderRadius: borderRadius,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: size * 0.6,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      );
    }

    if (!showGlow) return ClipRRect(borderRadius: borderRadius, child: button);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow:
            isPlaying ? AppEffects.primaryGlow(theme.colorScheme.primary) : [],
      ),
      child: button,
    );
  }
}

class SeekStepButton extends StatelessWidget {
  final bool forward;
  final ValueChanged<Duration>? onSeekBy;
  final double size;

  const SeekStepButton({
    super.key,
    required this.forward,
    required this.onSeekBy,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final seekBy = onSeekBy;
    return IconButton(
      onPressed:
          seekBy == null
              ? null
              : () => seekBy(Duration(seconds: forward ? 10 : -10)),
      icon: Icon(
        forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
        size: math.min(size, 28),
      ),
      tooltip: forward ? l10n.playerSeekForward : l10n.playerSeekBackward,
      style: IconButton.styleFrom(
        minimumSize: Size.square(size),
        fixedSize: Size.square(size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

/// 紧凑版播放控制按钮（仅播放/暂停）
class CompactPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final double size;
  final bool isBuffering;

  const CompactPlayButton({
    super.key,
    required this.isPlaying,
    this.onPlay,
    this.onPause,
    this.size = 40,
    this.isBuffering = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isBuffering) {
      return Semantics(
        label: AppLocalizations.of(context).playerBufferingSemantic,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: isPlaying ? onPause : onPlay,
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: size * 0.6,
      ),
      tooltip:
          isPlaying
              ? AppLocalizations.of(context).playerPause
              : AppLocalizations.of(context).playerPlay,
      style: IconButton.styleFrom(foregroundColor: theme.colorScheme.primary),
    );
  }
}
