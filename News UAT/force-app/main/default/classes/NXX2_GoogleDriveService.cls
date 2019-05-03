//
// Class Name: NXX2_GoogleStorageService
// 2nd Aug 2018   Kamal Sharma 
//
public class NXX2_GoogleDriveService extends NXX2_GoogleAPIDataModel{
    public String saveSingleFile(String recordId,String fileName,String fileContent,String fileType){
        String fileId;
		try{
            String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(recordId);
            String folderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordId,parentFolderId);
            String responseBody = NXX2_GoogleDriveConnector.uploadFile(fileName,fileContent,fileType,folderId);
            NXX2_LightningReqRespModel.GoogleDriveFilesDTO gdriveFilesDto = 
                NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
            String UploadedFileId = gdriveFilesDto.id;
            if(UploadedFileId != null && UploadedFileId.length() > 0){
                fileId = UploadedFileId;
                String share = NXX2_GoogleDriveConnector.makeFilePublic(UploadedFileId);
            }
        }
        catch(Exception e){
            
        }
        return fileId;
    }
       /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  saveFileInChunk : This method will save file in chunk.
    * @param        String recordId,String fileName,String fileContent,String fileType,
                    String fileId,String fileSize,Integer startPosition,Integer endPosition
    * @return       String
    */
    public String saveFileInChunk(String recordId,String fileName,String fileContent,String fileType,
                                         String fileId,String fileSize,Integer startPosition,Integer endPosition){
        NXX2_LightningReqRespModel.GoogleDriveFilesDTO gdriveFilesDto;
		try{
            if(fileId == ''){
                String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(recordId);
                String folderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordId,
                                                                                                                   parentFolderId);
                fileId = NXX2_GoogleDriveConnector.requestUploadUrl(fileName, fileContent, fileType, folderId, startPosition,endPosition,fileSize);
			}
            String responseBody = NXX2_GoogleDriveConnector.uploadFileInChunks(fileId,fileName, fileContent, 
                                                                               fileType,startPosition,endPosition,fileSize);
            if(responseBody != null && responseBody.length() > 0){
                gdriveFilesDto=NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
                String UploadedFileId = gdriveFilesDto.id;
                if(UploadedFileId != null && UploadedFileId.length() > 0){
                    fileId = UploadedFileId;
                }
            }
        }
        catch(Exception e){
            
        }
        return fileId;
    }
        /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  fetchFilesForSocialAd : This method will retrive all the files form Google Drive for the given social ad id.
    * @param        String socilAdRecordId
    * @return       List<GoogleDriveFilesDTO>
    */
    @AuraEnabled
    public static List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO> fetchFilesForSocialAd(String socilAdRecordId){
        List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO> gdriveFilesDtoList=new List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO>();
        try{
            String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(socilAdRecordId);
            String recordsfolderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(socilAdRecordId,parentFolderId);
            String responseBody = NXX2_GoogleDriveConnector.retriveFiles(recordsfolderId);
            gdriveFilesDtoList = NXX2_AppUtility.processGoogleDriveResponse(responseBody);
        } catch (Exception e){
            
        } 
        return gdriveFilesDtoList;     
    }
}