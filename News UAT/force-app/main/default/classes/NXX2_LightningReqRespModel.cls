/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_ConfigModel
* @description  This class have wrapper classes to provide formatted data to client side(Aura Components).
*/
public virtual class NXX2_LightningReqRespModel extends NXX2_GoogleAPIDataModel{
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	SocialAdWithContent
    * @description  Wrapper classes to provide formatted data for Social Ad with content.
    */
    public class SocialAdWithContent{
        @AuraEnabled
        public SocialAd__c socialAd;
        @AuraEnabled
        public List<SocialAdContent> contents;
        @AuraEnabled
        public SocialAd__c socialForm;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	SocialAdContent
    * @description  Wrapper classes to provide formatted data for Social Ad content.
    */
    public class SocialAdContent{
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Decimal size;
        @AuraEnabled
        public String adHeadline;
        @AuraEnabled
        public String adLink;
        @AuraEnabled
        public String adNewsfeedDesc;
        @AuraEnabled
        public String content;
        @AuraEnabled
        public String fileURL;
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String GoogleDriveFileId;
        @AuraEnabled
        public Boolean hasEmbedLink;
        @AuraEnabled 
        public String downloadUrl;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	GoogleDriveFilesDTO
    * @description  Wrapper classes to provide formatted data for Google drive file details.
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
    * @date         2018-05-25
    * @className	CustomerTaskDTO
    * @description  Wrapper classes to provide formatted data for customer activity.
    */
    public class CustomerTaskDTO{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String dueDate;
        @AuraEnabled
        public String productOrder;
        @AuraEnabled
        public String socialCampaign;
        @AuraEnabled
        public String campaignOrder;
        @AuraEnabled
        public String warningColor;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Customer_Task__c Customer_Task; 
        @AuraEnabled
        public Boolean isUserHasCreateAccessToTask;

    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	customerTaskResponse
    * @description  Wrapper classes to provide formatted data for customer activity response.
    */
    public class customerTaskResponse{
        @AuraEnabled
        public List<CustomerTaskDTO> customerTaskDTOList;
        @AuraEnabled 
        public Boolean isUserHasCreateAccessToTask;

    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	AccountDTO
    * @description  Wrapper classes to provide formatted data for account.
    */
    public class AccountDTO{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String Name;
    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	AccountResponse
    * @description  Wrapper classes to provide formatted data for account response.
    */
    public class AccountResponse{
        @AuraEnabled
        public List<Account> accountList;
        @AuraEnabled 
        public Boolean isUserHasSearchAccessToContact;

    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	SocialAdHistoryResponse
    * @description  Wrapper classes to provide formatted data for social ad history response.
    */
    public class SocialAdHistoryResponse{
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public Boolean IsDeleted;
        @AuraEnabled
        public String ParentId;
        @AuraEnabled
        public String Field;
        @AuraEnabled
        public String OldValue;
        @AuraEnabled
        public String NewValue;
        @AuraEnabled
        public DateTime createdDate;
    }
}