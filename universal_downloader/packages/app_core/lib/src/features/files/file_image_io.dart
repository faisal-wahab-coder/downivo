import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_library/media_library.dart';

Widget? libraryFileImage(
  LibraryFile file, {
  double? width,
  double? height,
  int? cacheWidth,
  BoxFit fit = BoxFit.cover,
  FilterQuality filterQuality = FilterQuality.low,
  Widget? errorFallback,
}) {
  return Image.file(
    File(file.path),
    width: width,
    height: height,
    fit: fit,
    cacheWidth: cacheWidth,
    filterQuality: filterQuality,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => errorFallback ?? const SizedBox.shrink(),
  );
}
