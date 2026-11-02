import 'package:equatable/equatable.dart';
import '../../../models/shade_mode.dart';
import '../../../models/slider_style.dart';

class ShadeLayoutState extends Equatable {
  final ShadeMode shadeMode;
  final SliderStyle sliderStyle;
  final int splitTabIndex;
  final bool isUnifiedQsExpanded;
  final bool isEditMode;
  final String? selectedTileId;
  final bool isSmartUnorganized;
  final int shadeOpenEpoch;

  const ShadeLayoutState({
    this.shadeMode = ShadeMode.unified,
    this.sliderStyle = SliderStyle.continuousPill,
    this.splitTabIndex = 1,
    this.isUnifiedQsExpanded = false,
    this.isEditMode = false,
    this.selectedTileId,
    this.isSmartUnorganized = false,
    this.shadeOpenEpoch = 0,
  });

  ShadeLayoutState copyWith({
    ShadeMode? shadeMode,
    SliderStyle? sliderStyle,
    int? splitTabIndex,
    bool? isUnifiedQsExpanded,
    bool? isEditMode,
    String? selectedTileId,
    bool clearSelectedTileId = false,
    bool? isSmartUnorganized,
    int? shadeOpenEpoch,
  }) {
    return ShadeLayoutState(
      shadeMode: shadeMode ?? this.shadeMode,
      sliderStyle: sliderStyle ?? this.sliderStyle,
      splitTabIndex: splitTabIndex ?? this.splitTabIndex,
      isUnifiedQsExpanded: isUnifiedQsExpanded ?? this.isUnifiedQsExpanded,
      isEditMode: isEditMode ?? this.isEditMode,
      selectedTileId: clearSelectedTileId
          ? null
          : (selectedTileId ?? this.selectedTileId),
      isSmartUnorganized: isSmartUnorganized ?? this.isSmartUnorganized,
      shadeOpenEpoch: shadeOpenEpoch ?? this.shadeOpenEpoch,
    );
  }

  @override
  List<Object?> get props => [
        shadeMode,
        sliderStyle,
        splitTabIndex,
        isUnifiedQsExpanded,
        isEditMode,
        selectedTileId,
        isSmartUnorganized,
        shadeOpenEpoch,
      ];
}
