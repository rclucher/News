/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_GoogleAPIDataModel
* @description  This class have wrapper classes to parse Google Drive Rest API Response.
*/
public virtual class NXX2_GoogleAPIDataModel extends NXX2_ConfigModel{
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	ParentRequestClass
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class ParentRequestClass {
        public String id;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	FolderRequestClass
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class FolderRequestClass {
        public String title;
        public String mimeType;
        public List<ParentRequestClass> parents;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	Permissions
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class Permissions {
        public String role;
        public String type;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	FileRequestClass
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class FileRequestClass {
        public String title;
        public String mimeType;
        public List<ParentRequestClass> parents;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	FileRequestForChunkRequestClass
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class FileRequestForChunkRequestClass {
        public String name;
        public String mimeType;
        public List<String> parents;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	GoogleDriveFilesDTO
    * @description  Warpper class parse Google Drive Rest API Response.
    */
    public class GoogleDriveFilesDTO{
        @AuraEnabled 
        public String id {get;set;}
        @AuraEnabled 
        public String thumbnailLink{get;set;}
        @AuraEnabled 
        public String title{get;set;}
        @AuraEnabled 
        public String createdDate{get;set;}
        @AuraEnabled 
        public String downloadUrl{get;set;}
        @AuraEnabled 
        public String mimeType{get;set;}
        @AuraEnabled 
        public String displayUrl{get;set;}
         @AuraEnabled 
        public String embedLink{get;set;}
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-07
    * @className	moveFileResponse
    * @description  Warpper class to parse Google Drive Rest API Response for moving files.
    */
    public class moveFileResponse {
        public String kind;
        public String name;
        public String id;
        public String mimeType;
    }
}