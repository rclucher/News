declare module "@salesforce/apex/NXX2_UploadFilesController.saveSingleFile" {
  export default function saveSingleFile(param: {recordId: any, fileName: any, fileContent: any, fileType: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_UploadFilesController.saveFileInChunk" {
  export default function saveFileInChunk(param: {recordId: any, fileName: any, fileContent: any, fileType: any, fileId: any, fileSize: any, startPosition: any, endPosition: any}): Promise<any>;
}
