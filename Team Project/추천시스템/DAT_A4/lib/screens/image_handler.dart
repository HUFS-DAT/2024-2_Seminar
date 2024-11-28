import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/api_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ImageHandler {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _selectedImages = [];
  List<String> _imageDescriptions = [];

  List<String> get selectedImages => _selectedImages;
  List<String> get imageDescriptions => _imageDescriptions;

  /// 이미지를 선택
  Future<bool> pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.length == 5) {
        _selectedImages = images.map((image) => image.path).toList();
        return true;
      } else {
        return false; // 5장 미만 선택 시 false 반환
      }
    } catch (e) {
      debugPrint("이미지 선택 중 오류 발생: $e");
      return false;
    }
  }

  /// 이미지 크기 조정 및 Base64 변환
  Future<List<String>> resizeAndConvertToBase64() async {
    List<String> base64Images = [];

    for (final imagePath in _selectedImages) {
      try {
        if (kIsWeb) {
          // 웹 환경에서 이미지 읽기
          final XFile webImage = XFile(imagePath);
          final Uint8List imageData = await webImage.readAsBytes();
          final originalImage = img.decodeImage(imageData);
          if (originalImage == null) throw Exception("이미지 디코딩 실패");

          // 이미지 크기 조정
          final resizedImage =
              img.copyResize(originalImage, width: 512, height: 512);

          // Base64 변환
          final base64Image = base64Encode(img.encodeJpg(resizedImage));
          base64Images.add(base64Image);
        } else {
          // 모바일/데스크톱 환경
          final imageFile = File(imagePath);
          final originalImage = img.decodeImage(await imageFile.readAsBytes());
          if (originalImage == null) throw Exception("이미지 디코딩 실패");

          final resizedImage =
              img.copyResize(originalImage, width: 512, height: 512);
          final base64Image = base64Encode(img.encodeJpg(resizedImage));
          base64Images.add(base64Image);
        }
      } catch (e) {
        debugPrint("이미지 크기 조정 및 변환 오류: $e");
        base64Images.add(""); // 오류 발생 시 빈 문자열 추가
      }
    }

    return base64Images;
  }

  /// 이미지 크기 조정
  Future<File> _resizeImage(File imageFile, int maxWidth, int maxHeight) async {
    final originalImage = img.decodeImage(await imageFile.readAsBytes());
    if (originalImage == null) throw Exception("이미지 디코딩 실패");

    final resized =
        img.copyResize(originalImage, width: maxWidth, height: maxHeight);
    final resizedFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(resized));
    return resizedFile;
  }

  /// 선택한 이미지 및 결과 초기화
  void clearImages() {
    _selectedImages.clear();
  }

  /// 이미지 미리보기
  Widget buildImagePreview(String path) {
    return kIsWeb
        ? Image.network(
            path,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          );
  }
}
