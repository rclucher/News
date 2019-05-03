/**
* This class will be called by the File Browser Component
*/ 
/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_GoogleDriveFileBrowserController
* @description  This class will be called by the File Browser Component i.e NXX2GoogleDriveConnector Component.
*/
public class NXX2_GoogleDriveFileBrowserController extends NXX2_LightningReqRespModel{
    
     /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  fetchProofNumberForGoogleDriveRecord : This method will provide proof number for proof id
    * @param        String recordId
    * @return       String
    */
    @AuraEnabled
    public static String fetchProofNumberForGoogleDriveRecord(String recordId){
        return NXX2_SalesforceDataService.getProofNumber(recordId);
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  uploadFilesInGoogleDrive : This method will upload the files Contenent in Google Drive using NXX2_GoogleDriveConnector Class
    * @param        String fileName,String base64Data, String fileType,String parentFolderId
    * @return       Response Body
    */
    @AuraEnabled
    public static GoogleDriveFilesDTO uploadFilesInGoogleDrive(String fileName, String base64Data, String fileType,String recordId){
        GoogleDriveFilesDTO gdriveFilesDto=new GoogleDriveFilesDTO();
        
        /**
* This code will check NXX2_GoogleDriveMyAccountsObjectMapping__mdt meta data, whether any record with folderId Exist or not
* else it will throw an error in screen to create the record.
*/ 
        String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(recordId);
        System.debug('parentFolderId' + parentFolderId);
        
        /**
* validateFolderExistOrNotWithRecordIdIfNotCreateInDrive - This code will check, whether Folder exist or not, if not it will create and return the 
* reference Id (folder Id) from google drive
*/ 
        String folderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordId,parentFolderId);
        System.debug('Folder Id With Record' + folderId);
        /**
*  Calling NXX2_GoogleDriveConnector upload file method, which will actully upload the file in folder
*/ 
        System.debug('base64Data' + base64Data);
        String responseBody = NXX2_GoogleDriveConnector.uploadFile(fileName, base64Data, fileType, folderId);
        gdriveFilesDto=NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
        System.debug('responseBody' + responseBody);
        return gdriveFilesDto; 
    }
    
    /**
* @author       Paras Prajapati
* @date         2018-08-17
* @description  loadFilesFromGoogleDrive : This method will retrive all the files form Google Drive using 
*               NXX2_GoogleDriveConnector Class 
* @param        String parentFolderId
* @return       Response Body
*/
    @AuraEnabled
    public static List<GoogleDriveFilesDTO> loadFilesFromGoogleDrive(String recordId,String folderId){
        /**
* This code will check whether folder exist or not, if not first it will create the folder with Record Id inside Object Folders
*/ 
        List<GoogleDriveFilesDTO> gdriveFilesDtoList=new List<GoogleDriveFilesDTO>();
        try{
            /**
* This code will check NXX2_GoogleDriveMyAccountsObjectMapping__mdt meta data, whether any record with folderId Exist or not
* else it will throw an error in screen to create the record.
*/ 
            String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(recordId);
            String recordsfolderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordId,parentFolderId);
            String responseBody = NXX2_GoogleDriveConnector.retriveFiles(recordsfolderId);
            gdriveFilesDtoList = NXX2_AppUtility.processGoogleDriveResponse(responseBody);
        } catch (Exception e){
            
        } 
        
        return gdriveFilesDtoList;     
    }
    /**
* @author       Paras Prajapati
* @date         2018-08-17
* @description  deleteFilesInGoogleDrive : This method will delete the files form Google Drive using 
*               NXX2_GoogleDriveConnector Class 
* @param        String fileIdToBeDeletedFromDrive
* @return       Response Body
*/
    @AuraEnabled
    public static String deleteFilesInGoogleDrive(String fileIdToBeDeletedFromDrive){
        String responseBody = '';
        try{
            responseBody = NXX2_GoogleDriveConnector.deleteFiles(fileIdToBeDeletedFromDrive);
        } catch (Exception e){
            responseBody = 'ERROR : ' + e.getMessage();
        } 
        return responseBody; 
    }
    
    @AuraEnabled
    public static String saveChunk(Id parentId, String fileName, String base64Data, 
                                   String contentType, String fileId,String fileSize,
                                   String startPosition,String endPosition,String recordNumber) {
                                       /**
*  check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
*  which is save the check data and return the attachemnt Id after insert, 
next time (in else) we are call the appentTOFile() method
for update the attachment with reamins chunks 
*/
                                       integer convertedStartPossition  = integer.valueof(startPosition);
                                       integer convertedEndPosition  = integer.valueof(endPosition);
                                       integer convertedfileSize  = integer.valueof(fileSize);
                                       
                                       System.debug('Testing..');                                       
                                       if (fileId == '') {
                                           fileId = saveTheFile(parentId, fileName, base64Data, contentType,fileSize,convertedStartPossition,convertedEndPosition,recordNumber);
                                       } else {
                                           String UploadedFileId = appendToFile(fileId, parentId, fileName, base64Data, contentType,fileSize,convertedStartPossition,convertedEndPosition,recordNumber);
                                           if (UploadedFileId!=null && UploadedFileId.length()>0) {
                                               fileId=UploadedFileId;
                                               NXX2_GoogleDriveConnector.makeFilePublic(fileId);
                                               
                                           }
                                       }
                                       return fileId;
                                   }
    
    public static String saveTheFile(Id recordID, String fileName, String base64Data, 
                                     String contentType, String fileSize,Integer startPosition,Integer endPosition,String recordNumber) {
                                         
                                         String resumableLocation = '';
                                         GoogleDriveFilesDTO gdriveFilesDto=new GoogleDriveFilesDTO();
                                         String uploadedFileId = '';
                                         
                                         try{
                                             System.debug('Paras');
                                             /**
* This code will check NXX2_GoogleDriveMyAccountsObjectMapping__mdt meta data, whether any record with folderId Exist or not
* else it will throw an error in screen to create the record.
*/ 
                                             String parentFolderId = NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(recordID);
                                             System.debug('parentFolderId' + parentFolderId);
                                             
                                             /**
* validateFolderExistOrNotWithRecordIdIfNotCreateInDrive - This code will check, whether Folder exist or not, if not it will create and return the 
* reference Id (folder Id) from google drive
*/ 
                                             String folderId = NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordID,parentFolderId);
                                             System.debug('Folder Id With Record' + folderId);
                                             System.debug('recordNumber' + recordNumber);
                                             /**
*  Calling NXX2_GoogleDriveConnector upload file method, which will actully upload the file in folder
*/ 
                                             resumableLocation = NXX2_GoogleDriveConnector.requestUploadUrl(fileName, base64Data,contentType,folderId,startPosition,endPosition,fileSize);
                                             
                                             String responseBody = NXX2_GoogleDriveConnector.uploadFileInChunks(resumableLocation,fileName, base64Data,contentType,startPosition,endPosition,fileSize);
                                             System.debug('Testing>>>>>>>>>>'+ responseBody);
                                             /*
* If the file uploaded in first chunk only then it will return the file metadata
*/ 
                                             if(responseBody!=null && responseBody.length()>0){
                                                 System.debug('Response from Post Upload full file');
                                                 gdriveFilesDto=NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
                                                 uploadedFileId = gdriveFilesDto.id;
                                                 resumableLocation = uploadedFileId;
                                                 NXX2_GoogleDriveConnector.makeFilePublic(uploadedFileId);
                                             }
                                             
                                         } catch (Exception e){
                                             
                                         } 
                                         return resumableLocation;
                                     }
    
    /**
* appendToFile This method will be a helper method to load the file in chunks.
* @return   return description
*/
    public static String appendToFile(String fileId, String recordId, String fileName,
                                      String base64Data, String contentType,String fileSize,
                                      Integer startPosition,Integer endPosition,String recordNumber) {
                                          String responseBody = '';
                                          String uploadedFileId = '';
                                          GoogleDriveFilesDTO gdriveFilesDto=new GoogleDriveFilesDTO();
                                          try{
                                              responseBody = NXX2_GoogleDriveConnector.uploadFileInChunks(fileId,fileName, base64Data,contentType,startPosition,endPosition,fileSize);
                                              if(responseBody!=null && responseBody.length()>0){
                                                  System.debug('Response from Post Upload full file');
                                                  gdriveFilesDto=NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
                                                  uploadedFileId = gdriveFilesDto.id;
                                              }
                                              
                                          } catch (CalloutException e){
                                              System.debug('Message' + e.getMessage());
                                              throw e;
                                          } catch (Exception e){
                                              System.debug('Message' + e.getMessage());
                                              throw e;
                                          } 
                                          return uploadedFileId;
                                          
                                      }
    
    /**
* @author       Paras Prajapati
* @date         2018-08-17
* @description  uploadFilesInGoogleDrive : This method will upload the files Contenent in Google Drive using NXX2_GoogleDriveConnector Class
* @param        String fileName,String base64Data, String fileType,String parentFolderId
* @return       Response Body
*/
    @AuraEnabled
    public static GoogleDriveFilesDTO readUploadedFilesFromGoogleDrive(String fileId){
        GoogleDriveFilesDTO gdriveFilesDto=new GoogleDriveFilesDTO();
        
        /**
*  Calling NXX2_GoogleDriveConnector upload file method, which will actully upload the file in folder
*/ 
        String responseBody = NXX2_GoogleDriveConnector.getFileMetaData(fileId);
        gdriveFilesDto=NXX2_AppUtility.processGoogleDriveFileUploadResponse(responseBody);
        System.debug('responseBody' + responseBody);
        return gdriveFilesDto; 
    }
    
    
}