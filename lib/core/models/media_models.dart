import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'message.dart';

part 'media_models.g.dart';

/// Media asset stored in cloud storage
@JsonSerializable()
class MediaAsset extends Equatable {
  const MediaAsset({
    required this.id,
    required this.userId,
    this.conversationId,
    required this.s3Path,
    required this.mediaType,
    this.analysis,
    this.transcript,
    required this.createdAt,
  });

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'conversation_id')
  final String? conversationId;

  @JsonKey(name: 's3_path')
  final String s3Path;

  @JsonKey(name: 'media_type')
  final MediaType mediaType;

  final ImageAnalysis? analysis;

  final String? transcript;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory MediaAsset.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetFromJson(json);

  Map<String, dynamic> toJson() => _$MediaAssetToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        conversationId,
        s3Path,
        mediaType,
        analysis,
        transcript,
        createdAt
      ];
}

/// Image analysis results from Vision API
@JsonSerializable()
class ImageAnalysis extends Equatable {
  const ImageAnalysis({
    required this.caption,
    this.objects = const [],
    this.ocrText,
  });

  /// Generated caption describing the image
  final String caption;

  /// Detected objects with confidence scores
  final List<DetectedObject> objects;

  /// Extracted text from OCR (if present)
  @JsonKey(name: 'ocr_text')
  final String? ocrText;

  factory ImageAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ImageAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$ImageAnalysisToJson(this);

  /// Returns objects filtered by confidence threshold (70%)
  List<DetectedObject> get filteredObjects =>
      objects.where((obj) => obj.confidence >= 0.70).toList();

  @override
  List<Object?> get props => [caption, objects, ocrText];
}

/// Detected object in an image
@JsonSerializable()
class DetectedObject extends Equatable {
  const DetectedObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  /// Object label/name
  final String label;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Bounding box coordinates (optional)
  @JsonKey(name: 'bounding_box')
  final BoundingBox? boundingBox;

  factory DetectedObject.fromJson(Map<String, dynamic> json) =>
      _$DetectedObjectFromJson(json);

  Map<String, dynamic> toJson() => _$DetectedObjectToJson(this);

  @override
  List<Object?> get props => [label, confidence, boundingBox];
}

/// Bounding box for detected objects
@JsonSerializable()
class BoundingBox extends Equatable {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory BoundingBox.fromJson(Map<String, dynamic> json) =>
      _$BoundingBoxFromJson(json);

  Map<String, dynamic> toJson() => _$BoundingBoxToJson(this);

  @override
  List<Object?> get props => [x, y, width, height];
}

/// Video summary generated from transcription
@JsonSerializable()
class VideoSummary extends Equatable {
  const VideoSummary({
    required this.title,
    required this.highlights,
    required this.transcript,
    required this.duration,
  });

  /// Generated title (max 20 words)
  final String title;

  /// 4 bullet-point highlights
  final List<String> highlights;

  /// Full transcript
  final String transcript;

  /// Video duration in seconds
  final int duration;

  factory VideoSummary.fromJson(Map<String, dynamic> json) =>
      _$VideoSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$VideoSummaryToJson(this);

  /// Returns duration as Duration object
  Duration get durationObject => Duration(seconds: duration);

  /// Validates title is within word limit
  bool get isTitleValid => title.split(' ').length <= 20;

  /// Validates highlights count
  bool get hasValidHighlights => highlights.length == 4;

  @override
  List<Object?> get props => [title, highlights, transcript, duration];
}
