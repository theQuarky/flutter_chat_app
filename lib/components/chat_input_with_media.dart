import 'dart:io';
import 'package:chat_app/services/ApiService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chat_app/services/ChatService.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class ChatInputWithMedia extends StatefulWidget {
  final String chatId;
  final String recipientUserId;
  final ChatService chatService;

  const ChatInputWithMedia(
      {Key? key,
      required this.chatId,
      required this.chatService,
      required this.recipientUserId})
      : super(key: key);

  @override
  _ChatInputWithMediaState createState() => _ChatInputWithMediaState();
}

class _ChatInputWithMediaState extends State<ChatInputWithMedia> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  ApiService _apiService = ApiService();
  final _audioRecorder = Record();
  bool _isRecording = false;
  String? _recordedFilePath;

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    bool hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      Directory tempDir = await getTemporaryDirectory();
      _recordedFilePath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        path: _recordedFilePath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
      );
      setState(() => _isRecording = true);
    } else {
      print("Audio recording permission not granted");
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _sendAudio(path);
      }
    }
  }

  Future<void> _sendAudio(String path) async {
    String mediaUrl = await widget.chatService
        .uploadMedia(File(path), widget.chatId, 'audio');
    await widget.chatService.sendMediaMessage(widget.chatId, mediaUrl, 'audio');
    _apiService.sendNotification(
        recipientUserId: widget.recipientUserId,
        type: 'audio',
        chatId: widget.chatId);
  }

  Future<void> _sendMediaMessage(String mediaType) async {
    FilePickerResult? result;
    if (mediaType == 'photo') {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        result = FilePickerResult([
          PlatformFile(
            path: image.path,
            name: image.name,
            size: await image.length(),
          )
        ]);
      }
    } else if (mediaType == 'video') {
      result = await FilePicker.platform.pickFiles(type: FileType.video);
    }

    if (result != null) {
      File file = File(result.files.single.path!);
      String mediaUrl =
          await widget.chatService.uploadMedia(file, widget.chatId, mediaType);
      await widget.chatService
          .sendMediaMessage(widget.chatId, mediaUrl, mediaType);
      _apiService.sendNotification(
          recipientUserId: widget.recipientUserId,
          type: mediaType,
          chatId: widget.chatId);
    }
  }

  void _sendTextMessage() {
    if (_messageController.text.isNotEmpty) {
      widget.chatService
          .sendPermanentMessage(widget.chatId, _messageController.text);
      _apiService.sendNotification(
          recipientUserId: widget.recipientUserId,
          type: 'text',
          body: _messageController.text,
          chatId: widget.chatId);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () => _showAttachmentOptions(context),
            color: Colors.grey[600],
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () => _sendMediaMessage('photo'),
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: Icon(
                _isRecording
                    ? Icons.stop
                    : (_messageController.text.isEmpty
                        ? Icons.mic
                        : Icons.send),
                color: Colors.white,
              ),
            ),
          ),
          IconButton(onPressed: _sendTextMessage, icon: Icon(Icons.send))
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMediaMessage('photo');
                  }),
              ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMediaMessage('video');
                  }),
              // Add more options as needed
            ],
          ),
        );
      },
    );
  }
}
