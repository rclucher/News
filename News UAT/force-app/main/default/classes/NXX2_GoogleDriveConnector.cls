/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_GoogleDriveConnector
* @description  This is connector class, contains method to call Google Drive Rest API.
*/
public class NXX2_GoogleDriveConnector {
    
    /**
    * @name         : uploadFile
    * @description  : Method to upload file in Google Drive using upload rest api
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response of upload rest api
    * @param        : String fileName - Name of the file to be uploaded
    *                 String base64Data - Content of the file in base64
    *                 String fileType - contains the mime type of the file
    *                 String parentFolderId - folder id of the parent folder, under which this file has to be uploaded
    */
    public static String uploadFile(String fileName, String base64Data, String fileType,String parentFolderId) {
        String responseBody = '';
        try{
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            List<NXX2_GoogleAPIDataModel.ParentRequestClass> ppList = new List<NXX2_GoogleAPIDataModel.ParentRequestClass>();
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = parentFolderId;
            ppList.add(parentFolder);
            NXX2_GoogleAPIDataModel.FileRequestClass fc = new NXX2_GoogleAPIDataModel.FileRequestClass();
            fc.title = filename;
            fc.mimeType = filetype;
            fc.parents = ppList;
            String fileDetailsAndContent = Json.serialize(fc);
            String body = NXX2_AppConstants.DELIMITER  +  'Content-Type: application/json\r\n\r\n' + fileDetailsAndContent + NXX2_AppConstants.DELIMITER  
                + 'Content-Type: ' + filetype +   NXX2_AppConstants.TAB_WITH_NEWLINE + 'Content-Transfer-Encoding: base64\r\n' 
                + NXX2_AppConstants.TAB_WITH_NEWLINE + base64Data + NXX2_AppConstants.CLOSE_DELIM;
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('callout:GDriveCredential' +'/upload/drive/v2/files?uploadType=multipart');
            req.setHeader('Content-Type', 'multipart/mixed; boundary="' + NXX2_AppConstants.BOUNDARY + '"');
            req.setHeader('Content-length', String.valueOf(base64Data.length()));
            req.setBody(body);
            req.setMethod('POST');
            
            req.setTimeout(60 * 1000);
            HttpResponse resp = http.send(req);	
            responseBody = resp.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : retriveFiles
    * @description  : Method to retrive list of file in Google Drive using files rest api
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response of list of files in json using files rest api
    * @param        : String folderId - id of the parent folder, under which list of file need to be retrived
    */
    public static String retriveFiles(String folderId){
        String responseBody = '';
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = folderId;
            req.setEndpoint('callout:GDriveCredential' + '/drive/v2/files?corpus=DEFAULT&includeTeamDriveItems=true&projection=FULL&q=%27'+parentFolder.id+'%27%20in%20parents%20and%20trashed%20%3D%20false&supportsTeamDrives=true');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String resp = res.getBody();
            responseBody = res.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : verifyFolderExistOrNot
    * @description  : Method to identify the given folder Id (recordId), exist under parentFolderId folder or not
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response in JSON, which will return the files if exist, it not then empty JSON
    * @param        : String recordId : Folder Id that need to be searched
    *                 String parentFolderId : this the parent folder id, under which folder will be searched
    */
    public Static String verifyFolderExistOrNot(String recordId,String parentFolderId){
        String responseBody = '';
        try{ 
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = parentFolderId;
            req.setEndpoint('callout:GDriveCredential' + '/drive/v3/files?includeTeamDriveItems=true&projection=FULL&q=name%20%3D%20%27'+recordId+'%27%20and%20%27'+parentFolder.id+'%27%20in%20parents%20and%20trashed%3D%20false&supportsTeamDrives=true');
            req.setHeader('Accept','application/json');
            req.setTimeout(60*1000);
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : createFolder
    * @description  : Method to create a new folder with given folderName under parentFolderId folder
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response in JSON, which will return the files if exist, it not then empty JSON
    * @param        : String folderName : Name of the Folder, which will be created 
    *                 String parentFolderId : this the parent folder id, under which folder with folderName will be created.
    */
    public static String createFolder(String folderName, String parentFolderId) { 
        String responseBody = '';
        try{  
            List<NXX2_GoogleAPIDataModel.ParentRequestClass> ppList = new List<NXX2_GoogleAPIDataModel.ParentRequestClass>();
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = parentFolderId;
            ppList.add(parentFolder);
            NXX2_GoogleAPIDataModel.FileRequestClass fc = new NXX2_GoogleAPIDataModel.FileRequestClass();
            fc.title = folderName;
            fc.mimeType = 'application/vnd.google-apps.folder';
            fc.parents = ppList;
            String fileDetailsAndContent = Json.serialize(fc);
            String body = fileDetailsAndContent;
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('callout:GDriveCredential' +'/drive/v2/files');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
            
            req.setTimeout(60 * 1000);
            HttpResponse resp = http.send(req);	
            responseBody = resp.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : validateFolderExistOrNotWithRecordIdIfNotCreateInDrive
    * @description  : Method to check whether recordIdAsFolderName folder exist of not under parentFolderId, if not it will create the folder
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : Will return the folder Id
    * @param        : String recordIdAsFolderName : Name of the Folder, which will be searched or created 
    *                 String parentFolderId : this the parent folder id, under which folder with recordIdAsFolderName will be searched/created.
    */
    public Static String validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(String recordIdAsFolderName, String parentFolderId){
        String responseBody = '';
        String folderId = '';
        try{
            String sObjName = ((Id)recordIdAsFolderName).getSObjectType().getDescribe().getName();
            String query = 'SELECT Name FROM ' + sObjName + ' WHERE Id = \'' + recordIdAsFolderName + '\'';
            sObject sobj = Database.query(query);
            String gDriveResponse = NXX2_GoogleDriveConnector.verifyFolderExistOrNot(((String)sobj.get('Name')),parentFolderId);
            Map<String, Object> metaData = (Map<String, Object>) JSON.deserializeUntyped(gDriveResponse);
            List<Object> responseFileList = (List<Object>)metaData.get('files');
            if(responseFileList!=null && responseFileList.size()>0){
                Map<String, Object> itemData = (Map<String, Object>) responseFileList.get(0);
                folderId = String.valueOf(itemData.get('id'));
            }else{
                gDriveResponse= NXX2_GoogleDriveConnector.createFolder(((String)sobj.get('Name')),ParentFolderId);
                metaData = (Map<String, Object>) JSON.deserializeUntyped(gDriveResponse);
                folderId = String.valueOf(metaData.get('id'));
            }
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return folderId;
    }
    
    /**
    * @name         : deleteFiles
    * @description  : Method to delete the file from google drive
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : Will return the folder Id
    * @param        : String fileId : Id of the file which need to be deleted.
    */
    public static String deleteFiles(String fileId){
        String responseBody = '';
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('DELETE');
            req.setEndpoint('callout:GDriveCredential' + '/drive/v3/files/'+fileId);
            req.setHeader('Accept','application/json');
            req.setTimeout(60*1000);
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
      
    /**
    * @name         : uploadFileInChunks
    * @description  : Method to upload file in Google Drive using upload rest api
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response of upload rest api
    * @param        : String fileName - Name of the file to be uploaded
    *                 String base64Data - Content of the file in base64
    *                 String fileType - contains the mime type of the file
    *                 String parentFolderId - folder id of the parent folder, under which this file has to be uploaded
    */
    public static String uploadFileInChunks(String resumableLocation, String fileName, 
                                            String base64Data, String fileType,
                                            Integer startPosition,Integer endPosition,String fileSize) {
        
        String responseBody = '';
                                                Blob fileContentAsBlob;
        try{
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('PUT');
            req.setEndpoint('callout:GDriveCredential' +'/upload/drive/v3/files?'+resumableLocation);
     	    
            req.setHeader('Content-Type', filetype);
      	    req.setHeader('Content-Range','bytes '+ startPosition+'-'+endPosition+'/*');
            
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            fileContentAsBlob = EncodingUtil.base64Decode(base64Data);
            req.setHeader('Content-Length', String.valueOf(fileContentAsBlob.size()));
            req.setBodyAsBlob(fileContentAsBlob);
            req.setTimeout(60 * 1000);
            HttpResponse resp = http.send(req);	
            //get the list of header names (keys)
            string[] headerkeys = resp.getHeaderKeys();
            //create an object to store your header key-value pairs
            Map<string, string> headers = new map<string, string>(); 
            
            //iterate through they keys, and populate your map
            for(string s : headerkeys){
                headers.put(s,resp.getHeader(s));
                system.debug('header: ' + s + ' value: ' + resp.getHeader(s));
            }
            responseBody = resp.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : 	requestUploadUrl
    * @description  : 	This method will provide resumable URL for the file upload
    * @createdby    : 	Paras Prajapati - 2018-08-17
    * @return       : 	String
    * @param        : 	String fileName, String base64Data, String fileType,
    * 					String parentFolderId,Integer startPosition,
    * 					Integer endPosition,String fileSize
    */
    public static String requestUploadUrl(String fileName, String base64Data, String fileType,
                                                          String parentFolderId,Integer startPosition,
                                                          Integer endPosition,String fileSize){
        Http http = new Http();
        String resumableLocation = ''; 
        try{
            List<NXX2_GoogleAPIDataModel.ParentRequestClass> ppList = new List<NXX2_GoogleAPIDataModel.ParentRequestClass>();
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = parentFolderId;
            ppList.add(parentFolder);
            NXX2_GoogleAPIDataModel.FileRequestForChunkRequestClass fc = new NXX2_GoogleAPIDataModel.FileRequestForChunkRequestClass();
            fc.name = filename;
            fc.mimeType = filetype;
            fc.parents = new List<String>{parentFolderId};//ppList;
            
            String body = Json.serialize(fc); 
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setHeader('X-Upload-Content-Length', fileSize);
            request.setHeader('X-Upload-Content-Type',fileType);
            request.setEndpoint('callout:GDriveCredential' + '/upload/drive/v3/files?uploadType=resumable');
            Integer contentLength = 38;
            request.setHeader('Content-Length', String.valueOf(body.length())); 
            request.setBody(body);
            request.setTimeout(60 * 1000);
            HttpResponse resp = http.send(request);	
            String responseBodyForLocationURL = resp.getBody();
            
            //get the list of header names (keys)
            string[] headerkeys = resp.getHeaderKeys();
            //create an object to store your header key-value pairs
            Map<string, string> headers = new map<string, string>(); 
            
            //iterate through they keys, and populate your map
            for(string s : headerkeys){
                headers.put(s,resp.getHeader(s));
            }
            
            resumableLocation = resp.getHeader('Location');
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }catch (Exception ee){
            System.debug('Message' + ee.getMessage());
            throw ee;
        }
        if(resumableLocation.contains('?')){
            resumableLocation = resumableLocation.substring(resumableLocation.indexOf('?')+1);
        }
        return resumableLocation;
    }
        
    /**
    * @name         : makeFilePublic
    * @description  : Method to make the file public
    * @createdby    : Kamal Sharma - 2018-09-02
    * @return       : string
    * @param        : String fileId : Id of the file which will be updated for public access.
    */
    public static string makeFilePublic(String fileId){
        String responseBody = '';
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('callout:GDriveCredential' + '/drive/v2/files/'+fileId+'/permissions');
            req.setHeader('Accept','application/json');
            req.setHeader('content-type','application/json; charset=UTF-8');
            req.setTimeout(60*1000);
            NXX2_GoogleAPIDataModel.Permissions permission = new NXX2_GoogleAPIDataModel.Permissions();
            permission.role = 'reader';
            permission.type = 'anyone';
            req.setBody(Json.serialize(permission));
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return responseBody;
    }
    
    /**
    * @name         : getFileMetaData
    * @description  : Method to get meta data for a file
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : Will return the folder Id
    * @param        : String fileId : Id of the file which need to be deleted.
    */
    public static String getFileMetaData(String fileId){
        String responseBody = '';
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            //Here we are using V2 Get method, not V3 becuase V3 does not respond with full meta data
            req.setEndpoint('callout:GDriveCredential' + '/drive/v2/files/'+fileId);
            req.setHeader('Accept','application/json');
            req.setTimeout(60*1000);
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }        
        return responseBody;
    }
}