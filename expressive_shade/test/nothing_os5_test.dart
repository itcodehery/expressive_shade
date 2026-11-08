import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expressive_shade/features/notifications/notification_group_card.dart';
import 'package:expressive_shade/features/shade_modes/common/shade_tiles_grid.dart';
import 'package:expressive_shade/features/shade_modes/nothing_os5/bento_grid_packer.dart';
import 'package:expressive_shade/features/shade_modes/nothing_os5/nothing_os5_edit_view.dart';
import 'package:expressive_shade/models/font_config.dart';
import 'package:expressive_shade/models/notification_model.dart';
import 'package:expressive_shade/models/qs_tile_model.dart';
import 'package:expressive_shade/models/shade_mode.dart';
import 'package:expressive_shade/providers/shade_state_provider.dart';
import 'package:expressive_shade/theme/m3_expressive_theme.dart';

void main() {
  test('ShadeMode includes NothingOS 5 and treats it as split-like', () {
    expect(ShadeMode.values.contains(ShadeMode.nothingOs5), isTrue);
    expect(ShadeMode.nothingOs5.displayName, 'NothingOS 5');
    expect(ShadeMode.nothingOs5.isSplitLike, isTrue);
  });

  test('TileSize supports 1x1, 1x2, and 2x2 with JSON persistence', () {
    const baseTile = QsTileModel(
      id: 'wifi',
      title: 'Internet',
      icon: Icons.wifi,
      isWide: true,
    );

    expect(baseTile.tileSize, TileSize.size1x2);
    expect(baseTile.tileSize.next, TileSize.size2x2);
    expect(baseTile.tileSize.next.next, TileSize.size1x1);

    final tile2x2 = baseTile.copyWith(tileSize: TileSize.size2x2);
    expect(tile2x2.is2x2, isTrue);
    expect(tile2x2.isWide, isTrue);
    expect(tile2x2.tileSize.rowSpan, 2);
    expect(tile2x2.tileSize.colSpan, 2);

    final restored = QsTileModel.fromJson(tile2x2.toJson());
    expect(restored.tileSize, TileSize.size2x2);
    expect(restored.is2x2, isTrue);
  });

  test('NothingOS 5 2D Bento Grid packer places 1x1, 1x2, and 2x2 without overlap', () {
    final tiles = [
      QsTileModel.defaultTiles[0].copyWith(tileSize: TileSize.size1x2),
      QsTileModel.defaultTiles[1].copyWith(tileSize: TileSize.size1x2),
      QsTileModel.defaultTiles[2].copyWith(tileSize: TileSize.size2x2),
      QsTileModel.defaultTiles[3].copyWith(tileSize: TileSize.size1x1),
      QsTileModel.defaultTiles[4].copyWith(tileSize: TileSize.size1x1),
    ];

    final result = packNothingOs5BentoGrid(tiles, includeSystemControls: true);
    expect(result.totalRows, greaterThanOrEqualTo(4));

    final Set<String> occupiedCells = {};
    for (final p in result.placements) {
      for (int dr = 0; dr < p.rowSpan; dr++) {
        for (int dc = 0; dc < p.colSpan; dc++) {
          final key = '${p.row + dr}_${p.col + dc}';
          expect(occupiedCells.contains(key), isFalse,
              reason: 'Overlapping cell at $key');
          occupiedCells.add(key);
        }
      }
    }
  });

  testWidgets('Switching NothingOS 5 tile between 1x2, 2x2, and 1x1 animates without BoxDecoration or overflow errors',
      (WidgetTester tester) async {
    List<QsTileModel> currentTiles = List.from(QsTileModel.defaultTiles);
    const colors = ExpressiveThemeColors.defaultTheme;
    final font = FontConfig.availableFonts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return NothingOs5EditView(
                tiles: currentTiles,
                selectedTileId: currentTiles.first.id,
                colors: colors,
                font: font,
                onTileTap: (_) {},
                onCycleSizeTap: (id) {
                  setState(() {
                    final idx = currentTiles.indexWhere((t) => t.id == id);
                    currentTiles[idx] = currentTiles[idx]
                        .copyWith(tileSize: currentTiles[idx].tileSize.next);
                  });
                },
                onSetExactSize: (id, size) {
                  setState(() {
                    final idx = currentTiles.indexWhere((t) => t.id == id);
                    currentTiles[idx] =
                        currentTiles[idx].copyWith(tileSize: size);
                  });
                },
                onAddTile: (_) {},
                onRemoveTile: (_) {},
                onReorder: (_, _) {},
                onReset: () {},
                onDone: () {},
              );
            },
          ),
        ),
      ),
    );

    // Tap 2x2 -> pump frames -> Tap 1x1 -> pump frames -> Tap 1x2 -> pump frames
    await tester.tap(find.text('2×2').first);
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.tap(find.text('1×1').first);
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.tap(find.text('1×2').first);
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
  });

  test('Volume, Brightness, and Audio Modes switcher are movable in NothingOS 5 Bento Grid', () {
    // Move Volume, Brightness, and Audio Modes to the very top of the tile list
    final reordered = [
      QsTileModel.nothingVolumeControl,
      QsTileModel.nothingBrightnessControl,
      QsTileModel.nothingRingerControl,
      ...QsTileModel.defaultTiles.where((t) => !t.isNothingOsSystemControl),
    ];

    final packed = packNothingOs5BentoGrid(reordered);
    final volPlacement = packed.placements
        .firstWhere((p) => p.type == BentoItemType.volumeSlider);
    final brightPlacement = packed.placements
        .firstWhere((p) => p.type == BentoItemType.brightnessSlider);
    final ringerPlacement = packed.placements
        .firstWhere((p) => p.type == BentoItemType.ringerPill);

    // Volume (2x1) and Brightness (2x1) placed at row 0, cols 0 and 1; Ringer (1x2) at row 0, col 2..3
    expect(volPlacement.row, 0);
    expect(volPlacement.col, 0);
    expect(brightPlacement.row, 0);
    expect(brightPlacement.col, 1);
    expect(ringerPlacement.row, 0);
    expect(ringerPlacement.col, 2);
  });

  test('Standard 2D Bento Grid packs two 1x1 tiles and one 2x2 tile into 2 rows without overflow', () {
    final tiles = [
      QsTileModel.defaultTiles[0].copyWith(tileSize: TileSize.size1x1), // 1x1
      QsTileModel.defaultTiles[1].copyWith(tileSize: TileSize.size1x1), // 1x1
      QsTileModel.defaultTiles[2].copyWith(tileSize: TileSize.size2x2), // 2x2 (Do Not Disturb)
    ];

    final pages = packTilesIntoBentoPages(
      tiles,
      avoidSpanningCollapsedBoundary: true,
    );
    expect(pages.length, 1);
    expect(pages.first.totalRows, 2);
  });

  testWidgets('NotificationGroupCard with long package appName does not overflow on the right',
      (WidgetTester tester) async {
    final notifications = [
      const NotificationModel(
        id: '1',
        packageName: 'com.google.android.apps.tasks',
        appName: 'com.google.android.apps.tasks',
        title: 'Meeting at 8pm',
        content: 'From yesterday',
        timeAgo: '2:00 pm',
        appIcon: Icons.notifications_rounded,
        appColor: Colors.blue,
      ),
      const NotificationModel(
        id: '2',
        packageName: 'com.google.android.apps.tasks',
        appName: 'com.google.android.apps.tasks',
        title: 'Send Mom 2k',
        content: 'From yesterday',
        timeAgo: '7:30 pm',
        appIcon: Icons.notifications_rounded,
        appColor: Colors.blue,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: NotificationGroupCard(
              notifications: notifications,
              colors: ExpressiveThemeColors.defaultTheme,
              font: FontConfig.availableFonts.first,
              onDismiss: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('Each ShadeMode maintains its own unique tile layout and 2x2 is restricted to NothingOS 5', () {
    final provider = ShadeStateProvider();

    // 1. Configure NothingOS 5 layout: set DND to 2x2 and reorder first two tiles
    provider.setShadeMode(ShadeMode.nothingOs5);
    provider.setTileExactSize('dnd', TileSize.size2x2);
    provider.reorderTile(0, 2);

    expect(
      provider.tiles.firstWhere((t) => t.id == 'dnd').tileSize,
      TileSize.size2x2,
    );

    // 2. Switch to Android 17 Split shade: its layout is completely independent and has no 2x2
    provider.setShadeMode(ShadeMode.split);
    expect(
      provider.tiles.firstWhere((t) => t.id == 'dnd').tileSize,
      TileSize.size1x2,
    );
    expect(provider.tiles.first.id, 'wifi');

    // Attempting to set 2x2 in Android 17 Split shade clamps to 1x2
    provider.setTileExactSize('dnd', TileSize.size2x2);
    expect(
      provider.tiles.firstWhere((t) => t.id == 'dnd').tileSize,
      TileSize.size1x2,
    );

    // Resize wifi to 1x1 in Split shade
    provider.setTileExactSize('wifi', TileSize.size1x1);
    expect(
      provider.tiles.firstWhere((t) => t.id == 'wifi').tileSize,
      TileSize.size1x1,
    );

    // 3. Switch to Unified shade: its wifi tile is still 1x2
    provider.setShadeMode(ShadeMode.unified);
    expect(
      provider.tiles.firstWhere((t) => t.id == 'wifi').tileSize,
      TileSize.size1x2,
    );

    // 4. Switch back to NothingOS 5: its 2x2 DND tile and custom order are preserved
    provider.setShadeMode(ShadeMode.nothingOs5);
    expect(
      provider.tiles.firstWhere((t) => t.id == 'dnd').tileSize,
      TileSize.size2x2,
    );
  });
}
