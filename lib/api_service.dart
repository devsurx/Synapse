import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000')); 
  // Note: 10.0.2.2 is the special address to reach your computer's localhost from an Android Emulator.
  // Use your computer's IP address if testing on a real physical phone.

  Future<void> uploadNote() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      // 2. Prepare the file for sending
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path!, filename: file.name),
      });

      // 3. Send to FastAPI
      try {
        var response = await _dio.post("/upload-note/", data: formData);
        print("Upload successful: ${response.data}");
      } catch (e) {
        print("Error uploading file: $e");
      }
    }
  }
}