import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontConfig {
  final String id;
  final String name;
  final String sampleText;
  final TextStyle Function({TextStyle? textStyle, Color? color, FontWeight? fontWeight, double? fontSize}) textStyleBuilder;

  const FontConfig({
    required this.id,
    required this.name,
    required this.sampleText,
    required this.textStyleBuilder,
  });

  static List<FontConfig> get availableFonts => [
    FontConfig(
      id: 'system',
      name: 'System Default',
      sampleText: 'Device Native Typography',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => (textStyle ?? const TextStyle()).copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Plus Jakarta Sans',
      name: 'Plus Jakarta Sans',
      sampleText: 'Modern Expressive UI',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.plusJakartaSans(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Outfit',
      name: 'Outfit',
      sampleText: 'Geometric & Friendly',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.outfit(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Inter',
      name: 'Inter',
      sampleText: 'Precision Interface',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.inter(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Poppins',
      name: 'Poppins',
      sampleText: 'Soft Rounded Pill',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.poppins(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Urbanist',
      name: 'Urbanist',
      sampleText: 'Sleek & Contemporary',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.urbanist(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Roboto',
      name: 'Roboto',
      sampleText: 'Android Stock Classic',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.roboto(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
    FontConfig(
      id: 'Space Grotesk',
      name: 'Space Grotesk',
      sampleText: 'Futuristic & Expressive',
      textStyleBuilder: ({textStyle, color, fontWeight, fontSize}) => GoogleFonts.spaceGrotesk(
        textStyle: textStyle,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    ),
  ];

  static FontConfig defaultFont = availableFonts.firstWhere((f) => f.id == 'Plus Jakarta Sans');
}
