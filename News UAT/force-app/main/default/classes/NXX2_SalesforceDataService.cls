/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_SalesforceDataService
* @description  This class will provide salesforce related data to other NXX2_* classes.
*/
public without sharing class NXX2_SalesforceDataService extends NXX2_ConfigModel{
    
    /**
    * @name         : getSocialAdTypes
    * @description  : return social ad types
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @param        : NA
    * @return       : List<SocialAdType>
    */
    public static List<SocialAdType> getSocialAdTypes() {
        Map<String, List<String>> adTypesWithCreatives = NXX2_AppUtility.getDependentOptions(SocialAd__c.Creative_Type__c, SocialAd__c.Ad_Type__c);
        Map<String, List<String>> adTypesWithButtons = NXX2_AppUtility.getDependentOptions(SocialAd__c.Button_Type__c, SocialAd__c.Ad_Type__c);
        Map<String,SocialAdCreativeType> adCreativeTypes = getSocialAdCreativeTypes();
        List<socialAdType> socialAdTypeList = new List<socialAdType>();
        SocialAdType sAdType;
        for(String adType : adTypesWithCreatives.keySet()){
            sAdType = new SocialAdType();
            sAdType.adType = adType;
            sAdType.buttons = adTypesWithButtons.get(adType);
            sAdType.creativeTypes = new List<SocialAdCreativeType>();
            for(String creativeType : adTypesWithCreatives.get(adType)){
                sAdType.creativeTypes.add(adCreativeTypes.get(creativeType));
            }
            socialAdTypeList.add(sAdType);
        }
        return socialAdTypeList;
    }
    
    /**
    * @name         : getSocialAdCreativeTypes
    * @description  : return social ad types
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @return       : Map<String,SocialAdCreativeType>
    * @param        : NA
    */
    public static Map<String,SocialAdCreativeType> getSocialAdCreativeTypes() {
        StaticResource sr= [select id, body from StaticResource Where Name = :NXX2_AppConstants.STATIC_RESOURCE_NAME_SOCIAL_AD_CREATIVE_TYPE];
    	String allContents = sr.body.toString();
    	return (Map<String,SocialAdCreativeType>)JSON.deserialize(allContents, Map<String,SocialAdCreativeType>.class);
    }
    
    /**
    * @name         : findMataDataIsConfiguredForRespectiveObjectOrNot - 
    * @description  : return Google Drive folder Id
    *                1.Find Object API Name with respect to the record Id
    *                2.Query NXX2_GoogleDriveMyAccountsObjectMapping__mdt records to match if Google Drive folder is exist or not
    *                 if yes then return the folder id for processing.
    * @createdby    : Paras - 16 Aug 2018
    * @return       : return Google Drive folder Id
    * @param        : Salesforce Record Id
    */
    public static String findMataDataIsConfiguredForRespectiveObjectOrNot(String recordIdOrPrefix){
        String googleDriveFolderIdMappedToObjectName = '';
        try{
            Id recordId = recordIdOrPrefix;
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            List<NXX2_GoogleDriveMyAccountsObjectMapping__mdt> nxx2_GoogleDriveMyAccountsObjectMappingList = [SELECT MasterLabel, 
                                                                                 QualifiedApiName, 
                                                                                 GoogleDriveFolderId__c FROM NXX2_GoogleDriveMyAccountsObjectMapping__mdt  where MasterLabel = :sObjName];
            if(nxx2_GoogleDriveMyAccountsObjectMappingList!=null && nxx2_GoogleDriveMyAccountsObjectMappingList.size()>0){
                googleDriveFolderIdMappedToObjectName = nxx2_GoogleDriveMyAccountsObjectMappingList.get(0).GoogleDriveFolderId__c;
            }
        }catch(Exception e){
            System.debug(e);
        }
        return googleDriveFolderIdMappedToObjectName;
    }
    
    /**
    * @name         : getCustomerTaskLists
    * @description  : return social ad types
    * @createdby    : Paras Prajapati - 12th Sept 2018
    * @return       : List<Customer_Task__c>
    * @param        : NA
    */
    public static List<Customer_Task__c> getCustomerTaskLists(String parentRecordId,String parentObject,Boolean isExternalUser) {
        User loogedInUser=fetchLoggedInUsersDetails();
        List<Customer_Task__c> listOfCustomerTask=null;
        Set<Id> sharedCustomerActivities = new Set<Id>();
        if(parentObject!=null && parentObject.length()>0){ 
            if(parentObject=='SocialCampaign__c'){
                if(isExternalUser){
                    for(Customer_Task__Share customerTaskShare : [SELECT ParentId FROM Customer_Task__Share WHERE UserOrGroupId = :loogedInUser.Id AND Parent.Social_Campaign__c = :parentRecordId]){
                        sharedCustomerActivities.add(customerTaskShare.ParentId);
                    }
                    listOfCustomerTask= [Select id,Name,Type__c,Comments__c,Due_Date__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Social_Campaign__c=:parentRecordId AND Status__c IN ('With Client','Completed') AND Id IN :sharedCustomerActivities];
                }else{
                    listOfCustomerTask= [Select id,Name,Type__c,Comments__c,Due_Date__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Social_Campaign__c=:parentRecordId];
                }
            }else if(parentObject=='Order__c'){
                listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c ,Account__c from Customer_Task__c where Campaign_Order__c=:parentRecordId];
            }else if(parentObject=='Product_Order__c'){
                listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Product_Order__c=:parentRecordId];
            }else if(parentObject=='Account'){
                if(isExternalUser){
                    for(Customer_Task__Share customerTaskShare : [SELECT ParentId FROM Customer_Task__Share WHERE UserOrGroupId = :loogedInUser.Id AND Parent.Account__c = :parentRecordId]){
                        sharedCustomerActivities.add(customerTaskShare.ParentId);
                    }
                    listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Account__c=:parentRecordId AND Status__c IN ('With Client','Completed') AND Id IN :sharedCustomerActivities];
                }else{
                    listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Account__c=:parentRecordId];
                }
            }else if(parentObject=='CommunityHomeTasks'){
                /**
                * As Customer Task Account Id field store only 15 digit, need to truncate the Parent Record ids last three
                * Character to Query Task Related to Account
                */ 
                if(isExternalUser){
                    List<String> accountIdsList = getMyAccounts(String.valueOf(loogedInUser.Id));
                    if(accountIdsList!=null && accountIdsList.size()>0){
                        for(Customer_Task__Share customerTaskShare : [SELECT ParentId FROM Customer_Task__Share WHERE UserOrGroupId = :loogedInUser.Id AND Parent.Account__c = :accountIdsList]){
                            sharedCustomerActivities.add(customerTaskShare.ParentId);
                        }
                        listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Account__c=:accountIdsList AND Status__c IN ('With Client','Completed') AND Id IN :sharedCustomerActivities];
                    }    
                }else{
                    Map<Id,Account> accounts = new Map<Id,Account>([SELECT ID FROM Account LIMIT 1000]);
                    if(accounts != null && accounts.size() > 0){
                        listOfCustomerTask= [Select id,Name,Type__c,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Account__c=:accounts.keySet() LIMIT 2000];
                    }
                }
            }else{
                listOfCustomerTask= [Select id,Name,Due_Date__c,Comments__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c];
            }
        }else{
            List<String> accountIdsList = getMyAccounts(String.valueOf(loogedInUser.Id));
            if(accountIdsList!=null && accountIdsList.size()>0){
                listOfCustomerTask= [Select id,Name,Type__c,Comments__c,Due_Date__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c,Account__c from Customer_Task__c where Account__c IN :accountIdsList];
            }
        }
        return listOfCustomerTask;
    }

	/**
    * @name         : getAccountsLists
    * @description  : return User
    * @createdby    : Kamal Sharma - 13th Sept 2018
    * @return       : List<Account>
    * @param        : List<String> accountIdList
    */
    public static List<Account> getAccountsLists(List<String> accountIdList) {
        List<Account> listOfMyAccounts = [Select id,Name,RecordType.Name from Account where ID IN:accountIdList];
        return listOfMyAccounts;
    }

    /**
    * @name         : fetchLoggedInUsersDetails
    * @description  : return User
    * @createdby    : Kamal Sharma - 13th Sept 2018
    * @return       : User
    * @param        : NA
    */
    public static User fetchLoggedInUsersDetails(){ 
        User loggedInUserDetails = null;
        List<User> userDetails = [SELECT Id, ContactId,UserType, Contact.AccountId, Contact.Account.Name FROM User WHERE Id = :UserInfo.getUSerId()];
        if(userDetails!=null && userDetails.size()>0){
            loggedInUserDetails = userDetails.get(0);
        }
        return loggedInUserDetails;
    }        

    /**
    * @name         : getMyAccounts
    * @description  : This method will fetch all the accounts which are shared to the logged in user
    * @createdby    : Paras Prajapati - 10th Sept 2018
    * @return       : List<String> - Accounts Ids
    * @param        : String userId
    */
    public static List<String> getMyAccounts(String userId) { 
        System.debug('Current Logged In User' + UserInfo.getUSerId()); 
        List<String> accountsIdList=new List<String>();
        List<AccountShare> listOfSharedAccounts = [Select Id,AccountId,UserOrGroupId,RowCause from AccountShare  where  UserOrGroupId=:userId];
        if(listOfSharedAccounts!=null && listOfSharedAccounts.size()>0){
               for(AccountShare sharedAccounts : listOfSharedAccounts){
                    accountsIdList.add(String.valueOf(sharedAccounts.AccountId));
               }
        }
         return accountsIdList; 
    }

    /**
    * @name         : updateCustomerTask
    * @description  : This method will update customer activity status to completed
    * @createdby    : Paras Prajapati - 10th Sept 2018
    * @return       : String
    * @param        : String customerTaskId
    */
    public static String updateCustomerTask(String customerTaskId){
        String updateStatusMessage = '';
        List<Customer_Task__c> customerTaskList = [Select Id,Status__c from Customer_Task__c where Id=:customerTaskId];
        if(customerTaskList!=null && customerTaskList.size()>0){
            for(Customer_Task__c customerTask : customerTaskList){
                customerTask.Status__c = 'Completed';
            }
        }
        update customerTaskList;
        /**
        * Mark Proof status to Approved.
        */
        List<Database.SaveResult> results = Database.update(customerTaskList, false);
        for(Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                updateStatusMessage = 'Updated Status successfully for  ID ' + sr.getId();
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug(err.getMessage());
                    updateStatusMessage = 'Error: '+ err.getStatusCode() + ' ' + err.getMessage();
                    break;
                    
                }
            }
        }
        return  updateStatusMessage;
    }

    /**
    * @name         : getProofNumber
    * @description  : return socialCampaignNumber
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : String
    * @param        : String recordId
    */
    public static String getProofNumber(String recordId){
        String socialCampaignNumber = '';
        List<SocialCampaign__c> listOfProofs = [Select Id,Social_Campaign_Number__c from SocialCampaign__c where Id=:recordId];
        if(listOfProofs!=null && listOfProofs.size()>0){
           socialCampaignNumber=listOfProofs.get(0).Social_Campaign_Number__c;
        }
        return socialCampaignNumber;
    }
    
    /**
    * @name         : getPayerAccountOpportunities
    * @description  : return opportunities for the given payer accounts
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : List<Opportunity>
    * @param        : List<String> accountIdList
    */
    public Static List<Opportunity> getPayerAccountOpportunities(List<String> accountIdList){
       List<Opportunity> payerAccountOpportunities = [Select id,AccountId, Payer_Account__c from Opportunity where Payer_Account__c IN:accountIdList];
       return payerAccountOpportunities;
    }
    
    /**
    * @name         : getPayerAccountOpportunities
    * @description  : return opportunities for the given payer accounts
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : List<Opportunity>
    * @param        : List<String> accountIdList
    */
    public Static List<Opportunity> getPrimareyAccountOpportunities(List<String> accountIdList){
       List<Opportunity> primareyAccountOpportunities = [Select id,AccountId, Payer_Account__c from Opportunity where AccountId IN:accountIdList];
       return primareyAccountOpportunities;
    }
    
    /**
    * @name         : getProofRecordsAssocatedToAccounts
    * @description  : return proofs for the given accounts
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : List<SocialCampaign__c>
    * @param        : Set<String> accuntIdSet
    */
    public Static List<SocialCampaign__c> getProofRecordsAssocatedToAccounts(Set<String> accuntIdSet){
        List<SocialCampaign__c> socialCampaignList = [Select Id,Account__c from SocialCampaign__c where Account__c IN:accuntIdSet];
        return socialCampaignList;
    }
    
    /**
    * @name         : fetchAllContactRolesLinkedToContact
    * @description  : return contact roles linked to the given contact id
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : List<Contact_Role__c>
    * @param        : String contactId
    */
    public Static List<Contact_Role__c> fetchAllContactRolesLinkedToContact(String contactId) {
        Boolean isUserActive = true; 
        List<Contact_Role__c> listOfContactRole = null;
        if(contactId!=null && contactId.length()>0){
         listOfContactRole = [Select Account__c,Contact__c,Role__c from Contact_Role__c where Contact__c=:contactId AND Is_Active__c=:isUserActive];
        }
        return listOfContactRole;
    }

    /**
    * @name         : fetchContactsDetails
    * @description  : return contact details for the given contact ids
    * @createdby    : Paras Prajapati - 27th Sept 2018
    * @return       : List<Contact>
    * @param        : List<String> contactIds
    */
    public Static List<Contact> fetchContactsDetails(List<String> contactIds){ 
        return [Select Id,FirstName,LastName from Contact where Id IN:contactIds];
    }
}