/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_GoogleDriveFileBrowserController
* @description  Controller class, will be used by the NXX2_MyAccountHomePageContainer Component 
*/
public with sharing class NXX2_AccountListController{
	/**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getAllAccessibleAccount : This method returns all the Contacts Accounts for which proofs exist
    * @param        String contactId(contactId Logged In User Contact Id)
    * @return       NXX2_LightningReqRespModel.AccountResponse(List Of Accounts related to Contact)
    */
    @AuraEnabled
	public static NXX2_LightningReqRespModel.AccountResponse getAllAccessibleAccount(String contactId){  
        List<Account> listOfAccounts = new List<Account>();
        NXX2_LightningReqRespModel.AccountResponse accountResponse = new NXX2_LightningReqRespModel.AccountResponse();
        Boolean isEnabled = false;
        if(contactId!=null && contactId.length()>0){
            //Fetch the User which is related the Contact Id
            isEnabled = FeatureManagement.checkPermission('User_Has_Access_To_Search_Contact_In_Community');
            listOfAccounts = [Select id,Name,RecordType.Name from Account LIMIT 1000];
        }
        accountResponse.accountList = listOfAccounts;
        accountResponse.isUserHasSearchAccessToContact = isEnabled;
        return accountResponse;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getLoggedInUserContact : This method returns logged in user details
    * @param        NA
    * @return       String
    */
    @AuraEnabled
    public static String getLoggedInUserContact(){
        return NXX2_SalesforceDataService.fetchLoggedInUsersDetails().ContactId; 
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getIconName : This method will provide icon name for given sObject.
    * @param        String sObjectName
    * @return       String
    */
    @AuraEnabled
    public static String getIconName(String sObjectName){
          return NXX2_AppUtility.getIconName(sObjectName);
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getAccountsListAccessibleToCustomer This method will be called from MY Account List Component.
    * @param        NA
    * @return       NXX2_LightningReqRespModel.AccountResponse
    */
    @AuraEnabled
    public static NXX2_LightningReqRespModel.AccountResponse getAccountsListAccessibleToCustomer(){
        List<Account> listOfAccounts = new List<Account>();
        NXX2_LightningReqRespModel.AccountResponse accountResponse = new NXX2_LightningReqRespModel.AccountResponse();
		User loggedInUser = NXX2_SalesforceDataService.fetchLoggedInUsersDetails(); 
        //This permission will enable user to Search contact and its related Accounts in community home page.
        Boolean isEnabled = FeatureManagement.checkPermission('User_Has_Access_To_Search_Contact_In_Community');
        //Fetch All the Accounts Shared with Users, using AccountShare Records
        /*List<String> accessibleAccountIdsList=NXX2_SalesforceDataService.getMyAccounts(String.valueOf(loggedInUser.Id));
        if(accessibleAccountIdsList!=null && accessibleAccountIdsList.size()>0){
          listOfAccounts =  NXX2_SalesforceDataService.getAccountsLists(accessibleAccountIdsList);
        }*/
        listOfAccounts = [Select id,Name,RecordType.Name from Account LIMIT 1000];
        accountResponse.accountList = listOfAccounts;
        accountResponse.isUserHasSearchAccessToContact = isEnabled;
        return accountResponse;    
    } 
}