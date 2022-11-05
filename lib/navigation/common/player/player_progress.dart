import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../extension.dart';
import '../../../media/tracks/tracks_player.dart';
import '../../../providers/player_provider.dart';
import '../../desktop/widgets/slider.dart';
import 'progress_track_container.dart';

/// A seek bar for current position.
class DurationProgressBar extends ConsumerWidget {
  const DurationProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final theme = Theme.of(context).primaryTextTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          trackShape: const UnboundedRoundedRectSliderTrackShape(
            removeAdditionalActiveTrackHeight: true,
          ),
          activeTrackColor: context.colorScheme.onPrimary,
          inactiveTrackColor: context.colorScheme.onPrimary.withOpacity(0.5),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 10,
          ),
          thumbColor: context.colorScheme.onPrimary,
          showValueIndicator: ShowValueIndicator.always,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PlayerProgressSlider(
            builder: (context, widget) {
              final durationText = player.duration?.timeStamp;
              final positionText = player.position?.timeStamp;
              return Row(
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Text(
                        positionText ?? '00:00',
                        style: theme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: widget),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Text(
                        durationText ?? '00:00',
                        style: theme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PlayerProgressSlider extends HookConsumerWidget {
  const PlayerProgressSlider({
    super.key,
    this.builder,
  });

  final Widget Function(BuildContext context, Widget slider)? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTrackingValue = useState<double?>(null);
    final player = ref.read(playerProvider);
    return ProgressTrackingContainer(
      builder: (context) {
        final snapshot = _PlayerProgressSliderSnapshot(
          player: player,
          userTrackingValue: userTrackingValue,
        );
        return builder == null ? snapshot : builder!(context, snapshot);
      },
    );
  }
}

class _PlayerProgressSliderSnapshot extends StatelessWidget {
  const _PlayerProgressSliderSnapshot({
    super.key,
    required this.player,
    required this.userTrackingValue,
  });

  final TracksPlayer player;

  final ValueNotifier<double?> userTrackingValue;

  @override
  Widget build(BuildContext context) {
    final position = player.position?.inMilliseconds.toDouble() ?? 0.0;
    final duration = player.duration?.inMilliseconds.toDouble() ?? 0.0;
    return Slider(
      max: duration,
      value: (userTrackingValue.value ?? position).clamp(
        0.0,
        duration,
      ),
      onChangeStart: (value) => userTrackingValue.value = value,
      onChanged: (value) => userTrackingValue.value = value,
      semanticFormatterCallback: (value) => value.round().toTimeStampString(),
      onChangeEnd: (value) {
        userTrackingValue.value = null;
        player
          ..seekTo(Duration(milliseconds: value.round()))
          ..play();
      },
    );
  }
}
