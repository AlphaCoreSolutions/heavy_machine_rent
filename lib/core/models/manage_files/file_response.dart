class ManageFileResponse {
  final int? fileId;
  final String? filePath;
  final String? fileMessage;
  final bool? isImage;
  final bool? isPdf;
  ManageFileResponse({
    this.fileId,
    this.filePath,
    this.fileMessage,
    this.isImage,
    this.isPdf,
  });
  factory ManageFileResponse.fromJson(Map<String, dynamic> json) =>
      ManageFileResponse(
        fileId: json['fileId'],
        filePath: json['filePath'],
        fileMessage: json['fileMessage'],
        isImage: json['isImage'],
        isPdf: json['isPdf'],
      );
  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'filePath': filePath,
    'fileMessage': fileMessage,
    'isImage': isImage,
    'isPdf': isPdf,
  };
}
