import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> processImage(ImageSource source) async {
    try {
      // Request camera permission
      if (source == ImageSource.camera) {
        var status = await Permission.camera.request();
        if (status.isDenied) {
          throw Exception('Camera permission denied');
        }
      }

      // Pick image
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return '';

      // Convert image to InputImage
      final inputImage = InputImage.fromFilePath(image.path);

      // Process image with ML Kit
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      print('Error processing image: $e');
      return '';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}