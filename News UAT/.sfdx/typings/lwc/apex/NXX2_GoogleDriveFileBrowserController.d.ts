declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.fetchProofNumberForGoogleDriveRecord" {
  export default function fetchProofNumberForGoogleDriveRecord(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.uploadFilesInGoogleDrive" {
  export default function uploadFilesInGoogleDrive(param: {fileName: any, base64Data: any, fileType: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.loadFilesFromGoogleDrive" {
  export default function loadFilesFromGoogleDrive(param: {recordId: any, folderId: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.deleteFilesInGoogleDrive" {
  export default function deleteFilesInGoogleDrive(param: {fileIdToBeDeletedFromDrive: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.saveChunk" {
  export default function saveChunk(param: {parentId: any, fileName: any, base64Data: any, contentType: any, fileId: any, fileSize: any, startPosition: any, endPosition: any, recordNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/NXX2_GoogleDriveFileBrowserController.readUploadedFilesFromGoogleDrive" {
  export default function readUploadedFilesFromGoogleDrive(param: {fileId: any}): Promise<any>;
}
