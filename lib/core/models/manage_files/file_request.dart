class ManageFileRequest {
  final int? fileId;
  final int? modelId;
  final String? fileBytes;
  final int? offset;
  final String? fileName;
  final String? filePath;
  final String? fileType;
  final String? fileExt;
  final String? fileModelPath;
  final String? fileViewerPath;
  final String? fileViewerByte;
  final bool? isImage;
  final bool? isPdf;
  final String? fileMessage;

  /*
  mandatory:
  modelId which is when the the file is sent to database
  file bytes the file when its turned into bytes.
  file name which is the image name
  file path staticfile
  file model path /whatever
  is image or is pdf


    public async Task<IActionResult> SaveAndUploadFiles(FileModel item)
  {

      var result = ResponseResult.Failed();
      var fileUrl = "";
      await Task.Run(() =>
      {
          try
          {
              // Save the file
              if (item != null)
              {
                  // get the local Folder                           
                  var folderPath = Path.Combine("wwwroot", item.FilePath, item.FileModelPath);

                  // check if director exist; if NO then create.
                  if (!Directory.Exists(folderPath))
                      Directory.CreateDirectory(folderPath);

                  if (item.FileBytes != null)
                  {
                      if (item.FileBytes.Length > 0)
                      {
                          var pathToSave = Path.Combine(Directory.GetCurrentDirectory(), folderPath);
                          {
                              var fileName = item.FileName.Trim('"');
                              var fullPath = Path.Combine(pathToSave, fileName);
                              fileUrl = (item.FilePath + "/" + item.FileModelPath + "/" + fileName);
                              using (var memoryStream = new MemoryStream(item.FileBytes))
                              {
                                  System.IO.File.WriteAllBytes(Path.Combine(folderPath, item.FileName), memoryStream.ToArray());
                              }
                              result = ResponseResult.SuccessProcess(item.FileName + " file(s) uploaded", item.ModelId, fileUrl);
                          }
                      }
                      else
                          result = ResponseResult.Failed(BaseLibrary.DTOS.ResponseType.ProcessFailed, "No file selected", item.ModelId);
                  }
                  else
                      result = ResponseResult.Failed(BaseLibrary.DTOS.ResponseType.ProcessFailed, "No file selected", item.ModelId);
              }
              else
                  result = ResponseResult.Failed(BaseLibrary.DTOS.ResponseType.ProcessFailed, "No file selected", item!.ModelId);

          }
          catch (Exception ex)
          {
              string error = ex.Message;
              if (ex.InnerException != null)
                  error = error + " - " + ex.InnerException.Message;

              result = ResponseResult.Failed(BaseLibrary.DTOS.ResponseType.ProcessFailed, error, item.ModelId);
          }
      });

      return Ok(result);


  }






    public async Task UploadFiles(InputFileChangeEventArgs inputFileChangeEventArgs)
  {
      var file = inputFileChangeEventArgs.File;

      long chunkSize = 400000;
      fileType = file.ContentType;
      MemoryStream ms = new();
      Stream streamFile = file.OpenReadStream();
      if (fileType.Contains("image") || fileType.Contains("Image") || fileType.Contains("jpg") || fileType.Contains("jpeg") || fileType.Contains("pdf"))
      {

          await inputFileChangeEventArgs.File.OpenReadStream().CopyToAsync(ms);
          var bytes = ms.ToArray();
          fileUri = $"data:{fileType};base64,{Convert.ToBase64String(ms.ToArray())}";

          uploadResult = $"Finished loading {file.Size} bytes from {file.Name}";

          if (fileType.Contains("pdf"))
          {
              try
              {
                  ifImage = false;
                  ifpdf = true;
                  pdfUri = "data:application/pdf;base64," + Convert.ToBase64String(ms.ToArray());
              }
              catch (Exception ex)
              {
                  uploadResult = ex.Message;
              }
          }
          else if (fileType.Contains("image") || fileType.Contains("Image") || fileType.Contains("jpg") || fileType.Contains("jpeg"))
          {
              try
              {
                  var resizedFile = await file.RequestImageFileAsync("image/jpg", 300, 300);
                  ms = new();
                  await resizedFile.OpenReadStream().CopyToAsync(ms);
                  bytes = ms.ToArray();
                  ifImage = true;
                  ifpdf = false;
                  ImageUri = $"data:{fileType};base64,{Convert.ToBase64String(ms.ToArray())}";
              }
              catch (Exception ex)
              {
                  uploadResult = ex.Message;
              }
          }

          fileModel.FileId = 1;
          fileModel.ModelId = 100;
          fileModel.FileBytes = bytes;
          fileModel.Offset = chunkSize;
          fileModel.FirstChunk = false;
          fileModel.FileName = file.Name;
          fileModel.FilePath = "StaticFiles";
          fileModel.FileType = file.ContentType;
          fileModel.FileExt = "";
          fileModel.FileModelPath = "attfile";




          try
          {
              maxAllowedFiles = 3;
              string[] fileSplit = file.Name.Split(".");
              string extFile = "";
              if (fileSplit.Count() > 1)
                  extFile = fileSplit[1];

              fileModel.FileName = "newFile" + "." + extFile;
              fileModel.FirstChunk = true;
              var response = await manageFilesService.SaveUploadFile(fileModel);
              if (response.Flag)
              {
                  ImgUrl = response.otherResult;
                  StateHasChanged();
              }
              if (response.Flag)
              {
                  fileModel.FileExt = maxAllowedFiles.ToString();
                  extFile = maxAllowedFiles.ToString();
              }
          }
          catch (Exception ex)
          {
              Console.WriteLine(ex.Message);
          }

          // try
          // {
          //     var response = await manageFilesService.UploadFile(fileModel);
          //     if (response.Flag)
          //     {
          //         ImgUrl = response.otherResult;
          //         StateHasChanged();
          //     }
          // }
          // catch (Exception ex)
          // {
          //     Console.WriteLine(ex.Message);
          // }

          // try
          // {
          //     var response = await manageFilesService.ManageFile(fileModel);
          //     if (response.Flag)
          //     {
          //         ImgUrl = response.otherResult;
          //         StateHasChanged();
          //     }
          // }
          // catch (Exception ex)
          // {
          //     Console.WriteLine(ex.Message);
          // }

          //convert stream to base64
          StateHasChanged();
      }
  }

  */

  ManageFileRequest({
    this.fileId,
    this.modelId,
    this.fileBytes,
    this.offset,
    this.fileName,
    this.filePath,
    this.fileType,
    this.fileExt,
    this.fileModelPath,
    this.fileViewerPath,
    this.fileViewerByte,
    this.isImage,
    this.isPdf,
    this.fileMessage,
  });
  factory ManageFileRequest.fromJson(Map<String, dynamic> json) =>
      ManageFileRequest(
        fileId: json['fileId'],
        modelId: json['modelId'],
        fileBytes: json['fileBytes'],
        offset: json['offset'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        fileType: json['fileType'],
        fileExt: json['fileExt'],
        fileModelPath: json['fileModelPath'],
        fileViewerPath: json['fileViewerPath'],
        fileViewerByte: json['fileViewerByte'],
        isImage: json['isImage'],
        isPdf: json['isPdf'],
        fileMessage: json['fileMessage'],
      );
  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'modelId': modelId,
    'fileBytes': fileBytes,
    'offset': offset,
    'fileName': fileName,
    'filePath': filePath,
    'fileType': fileType,
    'fileExt': fileExt,
    'fileModelPath': fileModelPath,
    'fileViewerPath': fileViewerPath,
    'fileViewerByte': fileViewerByte,
    'isImage': isImage,
    'isPdf': isPdf,
    'fileMessage': fileMessage,
  };
}
