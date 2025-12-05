class MessageModel {
  final String id;
  final SenderModel sender;
  final RecipientModel recipient;
  final DateTime timestamp;
  final String content;
  final MessageType type;
  final String? attachment;
  const MessageModel({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.timestamp,
    required this.content,
    required this.type,
    this.attachment,
  });
}

class SenderModel {
  final String id;
  final String name;

  const SenderModel({
    required this.id,
    required this.name,
  });
}

class RecipientModel {
  final String id;
  final String name;

  const RecipientModel({
    required this.id,
    required this.name,
  });
}

enum MessageType { text, image, audio, video }
