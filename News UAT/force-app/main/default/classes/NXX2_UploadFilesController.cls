/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_UploadFilesController
* @description  This class have functionality related to file upload into google drive.
*/
public class NXX2_UploadFilesController {
    /**
    * @name         : saveSingleFile
    * @description  : This will be called from client side to upload single file.
    * @createdby    : Kamal Sharma - 24th Aug 2018
    * @return       : String
    * @param        : String parentId,String fileName,String fileContent,String fileType
    */
    @AuraEnabled
    public static String saveSingleFile(String recordId,String fileName,String fileContent,String fileType){
        String fileId;
        NXX2_GoogleDriveService service = new NXX2_GoogleDriveService();
        fileId = service.saveSingleFile(recordId,fileName,fileContent,fileType);
        return fileId;
    }
    
    /**
    * @name         : saveFileInChunk
    * @description  : This will be called from client side to upload a file in chunk.
    * @createdby    : Kamal Sharma - 24th Aug 2018
    * @return       : String
    * @param        : String parentId,String fileName,String fileContent,String fileType
    * @param		: String fileId,String fileSize,String startPosition,String endPosition
    */
    @AuraEnabled
    public static String saveFileInChunk(String recordId,String fileName,String fileContent,String fileType,
                                         String fileId,String fileSize,String startPosition,String endPosition){
        NXX2_GoogleDriveService service = new NXX2_GoogleDriveService();
        fileId = service.saveFileInChunk(recordId, fileName, fileContent, fileType, fileId, 
                                         fileSize, Integer.valueOf(startPosition), Integer.valueOf(endPosition));
   		return fileId;
    }
}