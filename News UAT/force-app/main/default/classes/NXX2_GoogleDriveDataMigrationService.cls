public class NXX2_GoogleDriveDataMigrationService {
        /**
    * @name         : retriveFiles
    * @description  : Method to retrive list of file in Google Drive using files rest api
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response of list of files in json using files rest api
    * @param        : String folderId - id of the parent folder, under which list of file need to be retrived
    */
    public static String retriveFiles(String folderId,String teamDriveId,String namedCredential){
        String responseBody = '';
        List<NXX2_LightningReqRespModel.GoogleDriveFilesDTO> gdriveFilesDtoList;
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint('callout:' + namedCredential + '/drive/v2/files?corpora=teamDrive&includeTeamDriveItems=true&projection=FULL&teamDriveId='+teamDriveId+'&q=%27'+folderId+'%27%20in%20parents%20and%20trashed%20%3D%20false&supportsTeamDrives=true');
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
            gdriveFilesDtoList = NXX2_AppUtility.processGoogleDriveResponse(responseBody);
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return gdriveFilesDtoList.size() > 0 ? gdriveFilesDtoList.get(0).Id : null;
    }
    
    /**
    * @name         : verifyFolderExistOrNot
    * @description  : Method to identify the given folder Id (recordId), exist under parentFolderId folder or not
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response in JSON, which will return the files if exist, it not then empty JSON
    * @param        : String recordId : Folder Id that need to be searched
    *                 String parentFolderId : this the parent folder id, under which folder will be searched
    */
    public Static String verifyFolderExistOrNot(String recordId,String parentFolderId, String namedCredential){
        String responseBody = '';
        String folderId;
        try{ 
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            NXX2_GoogleAPIDataModel.ParentRequestClass parentFolder = new NXX2_GoogleAPIDataModel.ParentRequestClass();
            parentFolder.id = parentFolderId;
            req.setEndpoint('callout:' + namedCredential + '/drive/v3/files?includeTeamDriveItems=true&projection=FULL&q=name%20%3D%20%27'+recordId+'%27%20and%20%27'+parentFolder.id+'%27%20in%20parents%20and%20trashed%3D%20false&supportsTeamDrives=true');
            req.setHeader('Accept','application/json');
            req.setTimeout(60*1000);
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
            Map<String, Object> metaData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> responseFileList = (List<Object>)metaData.get('files');
            if(responseFileList!=null && responseFileList.size()>0){
                Map<String, Object> itemData = (Map<String, Object>) responseFileList.get(0);
                folderId = String.valueOf(itemData.get('id'));
            }
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return folderId;
    }
    
    /**
    * @name         : createFolder
    * @description  : Method to create a new folder with given folderName under parentFolderId folder
    * @createdby    : Paras Prajapati - 2018-08-17
    * @return       : will return the response in JSON, which will return the files if exist, it not then empty JSON
    * @param        : String folderName : Name of the Folder, which will be created 
    *                 String parentFolderId : this the parent folder id, under which folder with folderName will be created.
    */
    public static String createFolder(String folderName, String parentFolderId, String namedCredential) { 
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
            req.setEndpoint('callout:' + namedCredential +'/drive/v2/files');
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
    public Static String validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(String recordIdAsFolderName, String parentFolderId, String namedCredential){
        String responseBody = '';
        String folderId;
        try{
            String sObjName = ((Id)recordIdAsFolderName).getSObjectType().getDescribe().getName();
            String query = 'SELECT Name FROM ' + sObjName + ' WHERE Id = \'' + recordIdAsFolderName + '\'';
            sObject sobj = Database.query(query);
            system.debug('*****Proof Ad Name*****'+((String)sobj.get('Name')));
            folderId = verifyFolderExistOrNot(((String)sobj.get('Name')),parentFolderId,namedCredential);
            if(folderId == null){
                String gDriveResponse= createFolder(((String)sobj.get('Name')),ParentFolderId,namedCredential);
                Map<String, Object> metaData = (Map<String, Object>) JSON.deserializeUntyped(gDriveResponse);
                folderId = String.valueOf(metaData.get('id'));
            }
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return folderId;
    }
    
        /**
    * @name         : copyFile
    * @description  : Method to copy a file to a perticular folder
    * @createdby    : Kamal Sharma - 2019-02-14
    * @return       : will return file id if file is copied successfully
    * @param        : String fileId,String folderId
    */
    public static String copyFile(String fileId,String folderId,String namedCredential){
        NXX2_GoogleAPIDataModel.moveFileResponse parsedResponse;
        String responseBody;
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setHeader('Accept','application/json');
            req.setHeader('content-type','application/json; charset=UTF-8');
            req.setEndpoint('callout:' + namedCredential + '/drive/v3/files/'+fileId+'/copy?supportsTeamDrives=true');
            req.setTimeout(60*1000);
            String requestBody = '{"parents": ["'+ folderId +'"]}';
            req.setHeader('Content-Length', String.valueOf(requestBody.length())); 
            req.setBody(requestBody);
            Http h = new Http();
            HttpResponse res = h.send(req);
            responseBody = res.getBody();
            parsedResponse = (NXX2_GoogleAPIDataModel.moveFileResponse)JSON.deserialize(responseBody, NXX2_GoogleAPIDataModel.moveFileResponse.class);
        } catch (CalloutException e){
            System.debug('Message' + e.getMessage());
            throw e;
        }
        return parsedResponse.id;
    }
    
    public static String processFileMigration(String recordId,String folderName){
        String sObjName = ((Id)recordId).getSObjectType().getDescribe().getName();
        String parentFolderId;
        String teamDriveParentFolderId;
        String namedCredential = 'GDriveCredential';
        String googleDriveFileId;
        List<NXX2_Config_For_Data_Migration__mdt> dataMigrationConfig = [SELECT Doing_Testing__c, Named_Credential__c,
                                                                         ProofAd_Folder_Id__c, Proof_Folder_Id__c,
                                                                         Team_Drive_Parent_Folder_Id__c
                                                                         FROM NXX2_Config_For_Data_Migration__mdt 
                                                                         where QualifiedApiName = 'Config_To_Test_Data_Migration'];
        if(dataMigrationConfig.size() > 0 && dataMigrationConfig.get(0).Doing_Testing__c){
            parentFolderId = sObjName == 'SocialAd__c' ? dataMigrationConfig.get(0).ProofAd_Folder_Id__c : dataMigrationConfig.get(0).Proof_Folder_Id__c;
        	namedCredential = dataMigrationConfig.get(0).Named_Credential__c;
            teamDriveParentFolderId = dataMigrationConfig.get(0).Team_Drive_Parent_Folder_Id__c;
        }else{
            List<NXX2_GoogleDriveMyAccountsObjectMapping__mdt> nxx2_GoogleDriveMyAccountsObjectMappingList = [SELECT MasterLabel, 
                                                                                                              QualifiedApiName, 
                                                                                                              GoogleDriveFolderId__c 
                                                                                                              FROM NXX2_GoogleDriveMyAccountsObjectMapping__mdt 
                                                                                                              where MasterLabel = :sObjName];
            if(nxx2_GoogleDriveMyAccountsObjectMappingList!=null && nxx2_GoogleDriveMyAccountsObjectMappingList.size()>0){
                parentFolderId = nxx2_GoogleDriveMyAccountsObjectMappingList.get(0).GoogleDriveFolderId__c;
            }
        }
        String folderId = verifyFolderExistOrNot(folderName,teamDriveParentFolderId,namedCredential);
        system.debug('*****folderId*****'+folderId);
        if(folderId != null){
            String fileId = retriveFiles(folderId,teamDriveParentFolderId,namedCredential);
            system.debug('*****fileId*****'+fileId);
            if(fileId != null){
                String targetFolderId = validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(recordId,parentFolderId,namedCredential);
            	system.debug('*****targetFolderId*****'+targetFolderId);
                googleDriveFileId = copyFile(fileId,targetFolderId,namedCredential);
            }
        }
        return googleDriveFileId;
    }
}