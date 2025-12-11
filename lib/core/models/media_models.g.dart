// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaAsset _$MediaAssetFromJson(Map<String, dynamic> json) => MediaAsset(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  conversationId: json['conversation_id'] as String?,
  s3Path: json['s3_path'] as String,
  mediaType: $enumDecode(_$MediaTypeEnumMap, json['media_type']),
  analysis: json['analysis'] == null
      ? null
      : ImageAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
  transcript: json['transcript'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MediaAssetToJson(MediaAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      if (instance.conversationId case final value?) 'conversation_id': value,
      's3_path': instance.s3Path,
      'media_type': _$MediaTypeEnumMap[instance.mediaType]!,
      if (instance.analysis?.toJson() case final value?) 'analysis': value,
      if (instance.transcript case final value?) 'transcript': value,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MediaTypeEnumMap = {
  MediaType.image: 'image',
  MediaType.video: 'video',
  MediaType.audio: 'audio',
};

ImageAnalysis _$ImageAnalysisFromJson(Map<String, dynamic> json) =>
    ImageAnalysis(
      caption: json['caption'] as String,
      objects:
          (json['objects'] as List<dynamic>?)
              ?.map((e) => DetectedObject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ocrText: json['ocr_text'] as String?,
    );

Map<String, dynamic> _$ImageAnalysisToJson(ImageAnalysis instance) =>
    <String, dynamic>{
      'caption': instance.caption,
      'objects': instance.objects.map((e) => e.toJson()).toList(),
      if (instance.ocrText case final value?) 'ocr_text': value,
    };

DetectedObject _$DetectedObjectFromJson(Map<String, dynamic> json) =>
    DetectedObject(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: json['bounding_box'] == null
          ? null
          : BoundingBox.fromJson(json['bounding_box'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DetectedObjectToJson(
  DetectedObject instance,
) => <String, dynamic>{
  'label': instance.label,
  'confidence': instance.confidence,
  if (instance.boundingBox?.toJson() case final value?) 'bounding_box': value,
};

BoundingBox _$BoundingBoxFromJson(Map<String, dynamic> json) => BoundingBox(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  width: (json['width'] as num).toDouble(),
  height: (json['height'] as num).toDouble(),
);

Map<String, dynamic> _$BoundingBoxToJson(BoundingBox instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

VideoSummary _$VideoSummaryFromJson(Map<String, dynamic> json) => VideoSummary(
  title: json['title'] as String,
  highlights: (json['highlights'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  transcript: json['transcript'] as String,
  duration: (json['duration'] as num).toInt(),
);

Map<String, dynamic> _$VideoSummaryToJson(VideoSummary instance) =>
    <String, dynamic>{
      'title': instance.title,
      'highlights': instance.highlights,
      'transcript': instance.transcript,
      'duration': instance.duration,
    };
