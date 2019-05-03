/**
* @author       Paras Prajapat
* @date         2018-11-01
* @className    NXX2_ShareRecordUtility
* @description  This is the helper class for all trigger handlers to handle sharing related logics.
*/
public class NXX2_ShareRecordUtility implements Queueable{
    //Accounts with their related contact roles
    private Map<Id,List<Contact_Role__c>> accountContactRoleMap;
    //All contacts
    private Set<Id> contactIds;
    //All roles
    private Set<String> roles;
    //Contacts and their related active portal users
    private Map<Id,List<User>> contactUserMap;
    //Customer role access records related to roles
    private Map<String,Customer_Role_Access__c> customerRoleAccessMap;
    //Account share records
    private List<AccountShare> accountShareList = new List<AccountShare>();
    //Proof share records
    private List<SocialCampaign__Share> proofShareList = new List<SocialCampaign__Share>();
    //Customer Activity share records
    private List<Customer_Task__Share> customerActivityShareList = new List<Customer_Task__Share>();
    //Profile Id for profile name
    private Map<String,String> profileNameWithProfileIdMap; 
    //Profiles mentioned in contact role access records
    private Set<String> contactRoleAccessCommunityUserProfiles;
    //Accounts and their related contacts
    private Map<Id,List<Id>> accountContactMap;
    //Payer accounts and their related primary account
    private Map<Id,Set<Id>> payerAccountIDAndPrimaryAccountMap;
    //All proof elligible for sharing
    private Set<Id> allProofsIds = new Set<Id>();
    //All customer activity elligible for sharing
    private Set<Id> allCustomerActivitiesIds = new Set<Id>();
    //Contact and their related contact roles
    private Map<Id,List<Contact_Role__c>> contactContactRoleMap;
    //Portal users to be created
    private List<User> listOfUserToCreate = new List<User>();
    //Opportunities
    private Set<Id> setOfOpportunityId;
    //All accounts(primary and payer)
    private Set<Id> setOfPrimaryAndPayerAccountIds;
    //Primary accounts with their related opportunities
    private Map<Id,Set<Id>> primaryAccountsToOpportunityIdMap;
    //Opportunities with their related payer accounts
    private Map<Id,Id> opportunityIdToPayerAccountIdMap;
    //Opportunities with their related proofs
    private Map<Id,Set<Id>> opportunityIdToProofIdMap;
    //Opportunities with their related customer activities
    private Map<Id,Set<Id>> opportunityIdToCustomerActivityIdMap;
    //Payer accounts with their related contact roles
    private Map<Id,List<Contact_Role__c>> payerAccountContactRoleMap;
	//Contacts who have access to my account customer portal
    public Set<Id> newsXtend_My_Account_AccessGivenContacts;
    //Contact Id and contact map
    public Map<Id, Contact> newItems;
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Default Constructor
    * @param        NA
    */
    public NXX2_ShareRecordUtility() {}
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Constructor :  This will be used by NXX2_ProcessMyAccountUser class 
    * 				to do the sharing process after portal user insertion.
    * @param        NA
    */
    public NXX2_ShareRecordUtility(Set<Id> newsXtend_My_Account_AccessGivenContacts,Map<Id, Contact> newItems) {   
        this.newsXtend_My_Account_AccessGivenContacts = newsXtend_My_Account_AccessGivenContacts;
        this.newItems = newItems;
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Batch execute method override :  This will be used by NXX2_ProcessMyAccountUser class 
    * 				to do the sharing process after portal user insertion asynchronously.
    * @param        NA
    * @return       void
    */
	public void execute(QueueableContext context) {
		this.handleNewsXtendMyAccountEnableAccessChanged(newsXtend_My_Account_AccessGivenContacts,newItems);
	}

	/**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will be called from Account Trigger Handler 
    * 				to process Account Sharing for the given accounts.
    * @param        Set<Id> accountIds
    * @return       void
    */
    public void recalculateAccountSharing(Set<Id> accountIds){
        try{
            contactIds = new Set<Id>();
            roles = new Set<String>();
            primaryAccountsToOpportunityIdMap = new Map<Id,Set<Id>>(); 
            setOfOpportunityId = new Set<Id>();
            setOfPrimaryAndPayerAccountIds = new Set<Id>();
            payerAccountIDAndPrimaryAccountMap = new Map<Id,Set<Id>>();
            opportunityIdToPayerAccountIdMap = new Map<Id,Id>();
            fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(accountIds);
            List<Contact_Role__c> conntactRoleList = fetchContactRoles(setOfPrimaryAndPayerAccountIds);
            populateAccountContactRoleMapAndContactIdsAndRoles(conntactRoleList);
            if(roles!=null && roles.size()>0){
                populateContactUserMap();
                populateCustomerRoleAccessMap();
                initializeSharing();  
                insertAccountShareRecords();                 
            }
        }catch(Exception e){
            system.debug('Exception: '+ e.getStackTraceString());
        }
    }
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  1.	This method will be used to Query Opportunities for Payer Accounts and Primary Accounts
    * 					as Owmner can be changed at any lavel (Payer Account or Primary Account).
    * 				2.	Opportunity will be used to fetch Proof and Customer Activitiies records for Sharing.
    * @param        Set<Id> accountIds
    * @return       void
    */
    public void fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(Set<Id> accountIds){
        /**
        * As Sharing will considered (Payer and Primary Account) - below code will fetch all the Opportunity 
        * which are associated to account (Eithe Account is a Primary or acting as Partner).
        * Build Global maps and list - which will be used for furthure processing.
        */        
        List<Opportunity> listOfOpportunity = [Select Payer_Account__c,Payer_Account__r.IsPartner,AccountId,Account.IsPartner from Opportunity where (AccountId IN:  accountIds OR Payer_Account__c IN:accountIds)];
        if(listOfOpportunity!=null && listOfOpportunity.size()>0){
            for(Opportunity opportunity : listOfOpportunity){
                setOfOpportunityId.add(opportunity.Id);
                setOfPrimaryAndPayerAccountIds.add(opportunity.AccountId);
                if(opportunity.Payer_Account__c!=null && opportunity.Payer_Account__c!=opportunity.AccountId){
                    setOfPrimaryAndPayerAccountIds.add(opportunity.Payer_Account__c);
                    if(!payerAccountIDAndPrimaryAccountMap.containsKey(opportunity.Payer_Account__c)){
                        payerAccountIDAndPrimaryAccountMap.put(opportunity.Payer_Account__c, new Set<Id>());
                    }
                    payerAccountIDAndPrimaryAccountMap.get(opportunity.Payer_Account__c).add(opportunity.AccountId);
                    opportunityIdToPayerAccountIdMap.put(opportunity.Id,opportunity.Payer_Account__c);
                }
                if(!primaryAccountsToOpportunityIdMap.containsKey(opportunity.AccountId)){
                    primaryAccountsToOpportunityIdMap.put(opportunity.AccountId, new Set<Id>());
                }
                primaryAccountsToOpportunityIdMap.get(opportunity.AccountId).add(opportunity.Id);
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch all the Contact Roles for Accounts.
    * @param        Set<Id> accountIds
    * @return       List<Contact_Role__c>
    */
    public List<Contact_Role__c> fetchContactRoles(Set<Id> accountIds){
        return [Select Id,Account__c,Account__r.IsPartner,Contact__c,Contact__r.NewsXtend_My_Account_Access__c,Role__c from Contact_Role__c where Contact__r.NewsXtend_My_Account_Access__c=true AND Account__c IN:accountIds];
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch all the Contact Roles for contacts.
    * @param        Set<Id> contactsIdSet
    * @return       List<Contact_Role__c>
    */
    public List<Contact_Role__c> fetchContactRolesBasedOnContactsIds(Set<Id> contactsIdSet){
        return [Select Id,Account__c,Account__r.IsPartner,Contact__c,Contact__r.NewsXtend_My_Account_Access__c,Role__c from Contact_Role__c where Contact__r.NewsXtend_My_Account_Access__c=true AND Contact__c IN:contactsIdSet];
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will validate Contact Roles Records 
    * 				and do the neccessary Data Set Up for Sharing Object as mentioned below:
    * 				1.	roles - This will be used to Query Contact Role Access Records.
    * 				2.	payerAccountContactRoleMap - Keep the Contact Role Records linked to Payer Accounts.
    * 				3.	accountContactRoleMap - This map will be used to provide access to Accounts and other Objects.
    * @param        List<Contact_Role__c> conntactRoleList
    * @return       void
    */
    public void populateAccountContactRoleMapAndContactIdsAndRoles(List<Contact_Role__c> conntactRoleList){
        accountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        payerAccountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        if(conntactRoleList!=null && conntactRoleList.size()>0){
            for(Contact_Role__c contactRole : conntactRoleList){
                contactIds.add(contactRole.Contact__c);
                roles.add(contactRole.Role__c);
                if(payerAccountIDAndPrimaryAccountMap.containsKey(contactRole.Account__c)){
                    if(!payerAccountContactRoleMap.containsKey(contactRole.Account__c)){
                        payerAccountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
                    }
                    payerAccountContactRoleMap.get(contactRole.Account__c).add(contactRole);
                    Set<Id> payerAccountsPrimaryAccountsSet = payerAccountIDAndPrimaryAccountMap.get(contactRole.Account__c);
                    if(payerAccountsPrimaryAccountsSet!=null && payerAccountsPrimaryAccountsSet.size()>0){
                        for(Id primaryAccountId : payerAccountsPrimaryAccountsSet ){
                            if(!accountContactRoleMap.containsKey(primaryAccountId)){
                                accountContactRoleMap.put(primaryAccountId, new List<Contact_Role__c>());
                            }
                            accountContactRoleMap.get(primaryAccountId).add(contactRole);
                        }
                    }
                    if(primaryAccountsToOpportunityIdMap.containsKey(contactRole.Account__c)){
                        if(!accountContactRoleMap.containsKey(contactRole.Account__c)){
                            accountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
                        }
                        accountContactRoleMap.get(contactRole.Account__c).add(contactRole);
                    }
                }else{
                    if(!accountContactRoleMap.containsKey(contactRole.Account__c)){
                        accountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
                    }
                    accountContactRoleMap.get(contactRole.Account__c).add(contactRole);
                }
            }
        }
    }
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will prepare Account Contact Role map and Contact Contact Role maps.
    * @param        List<Contact_Role__c> conntactRoleList
    * @return       void
    */
    public void populateAccountContactRoleMapAndContactIdsAndRolesBasedOnContacts(List<Contact_Role__c> conntactRoleList){
        accountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        if(conntactRoleList!=null && conntactRoleList.size()>0){
            for(Contact_Role__c contactRole : conntactRoleList){
                contactIds.add(contactRole.Contact__c);
                roles.add(contactRole.Role__c);
                if(!accountContactRoleMap.containsKey(contactRole.Account__c)){
                    accountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
                }
                accountContactRoleMap.get(contactRole.Account__c).add(contactRole);
                if(!contactContactRoleMap.containsKey(contactRole.Contact__c)){
                    contactContactRoleMap.put(contactRole.Contact__c, new List<Contact_Role__c>());
                }
                contactContactRoleMap.get(contactRole.Contact__c).add(contactRole);
            }
        }
    }
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch all the user related to the contacts linked to contact Role.
    * @param        NA
    * @return       void
    */
    public void populateContactUserMap(){
        contactUserMap = new Map<Id,List<User>>();
        List<User> Users = [SELECT Id, ContactId,IsActive FROM User WHERE ContactId IN:contactIds AND IsActive = true];
        if(Users!=null && Users.size()>0){
            for(User user : Users){
                if(!contactUserMap.containsKey(user.ContactId)){
                    contactUserMap.put(user.ContactId, new List<User>());
                }
                contactUserMap.get(user.ContactId).add(user);
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Customer Role Acces is configured to provide access to user based on Profile 
    * 				and Role given in Contact Role Records.
    * 				This method will Query Customer_Role_Access__c records based on the Roles available 
    * 				in Contact Role Records and prepare contact Role and Access map.
    * @param        NA
    * @return       void
    */
    public void populateCustomerRoleAccessMap(){
        List<Customer_Role_Access__c> CustomerRoleAccessList = [SELECT Account_Access__c,Contact_Role__c,Community_User_Profile__c,Customer_Activity_Access__c,Proof_Access__c FROM Customer_Role_Access__c WHERE Account_Access__c != 'None' AND Contact_Role__c IN:roles];
        customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        contactRoleAccessCommunityUserProfiles = new Set<String>();
        if(CustomerRoleAccessList!=null && CustomerRoleAccessList.size()>0){
            for(Customer_Role_Access__c customerRoleAccess : CustomerRoleAccessList){
                customerRoleAccessMap.put(customerRoleAccess.Contact_Role__c,customerRoleAccess);
                contactRoleAccessCommunityUserProfiles.add(customerRoleAccess.Community_User_Profile__c);
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will initialize sharing post data setup.
    * @param        NA
    * @return       void
    */
    public void initializeSharing(){
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                if(customerRoleAccess.Account_Access__c != 'None'){
                    populateAccountShareList(contactRole.Contact__c,accountId,customerRoleAccess);
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch all the SocialCampaign__c (Proof) records, these records linked to Opportunity and 
    * 				these Opportunities are related to Accounts Which is linked to contact role records.
    * @param        NA
    * @return       void
    */
    public void fetchProofRecords(){
        //Query All the proof associated to Accounts, so that Proofs Can be shared.
        if(accountContactRoleMap!=null && accountContactRoleMap.size()>0){
            List<SocialCampaign__c> listOfProofRecords = [Select Id, Account__c,Product_Order__r.Order__r.Opportunity__c from SocialCampaign__c where Product_Order__r.Order__r.Opportunity__c IN : setOfOpportunityId AND Visible_To_Customer__c = true];
            if(listOfProofRecords!=null && listOfProofRecords.size()>0){
                for(SocialCampaign__c proof : listOfProofRecords){
                    if(!opportunityIdToProofIdMap.containsKey(proof.Product_Order__r.Order__r.Opportunity__c)){
                        opportunityIdToProofIdMap.put(proof.Product_Order__r.Order__r.Opportunity__c, new Set<Id>());
                    }
                    opportunityIdToProofIdMap.get(proof.Product_Order__r.Order__r.Opportunity__c).add(proof.Id);
                    allProofsIds.add(proof.Id); 
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch all the Customer Activity (Customer_Task__c) records.
    * 				These records linked to Campaign Order/Product Order/Proof 
    * 				which are linked to Opportunity and these Opportunities are related to Accounts 
    * 				Which is linked to contact role records.
    * @param        NA
    * @return       void
    */
    public void fetchCustomerTaskRecords(){
        //Query All the proof associated to Accounts, so that Proofs Can be shared.
        if(accountContactRoleMap!=null && accountContactRoleMap.size()>0){
            List<Customer_Task__c> listOfCustomerTaskRecords = [Select Id,Account__c, Product_Order__r.Order__r.Opportunity__c,Campaign_Order__r.Opportunity__c, Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c from Customer_Task__c WHERE Product_Order__r.Order__r.Opportunity__c IN :setOfOpportunityId OR Campaign_Order__r.Opportunity__c IN :setOfOpportunityId OR Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c IN :setOfOpportunityId];
            if(listOfCustomerTaskRecords!=null && listOfCustomerTaskRecords.size()>0){
                for(Customer_Task__c customerTaskRecord : listOfCustomerTaskRecords){
                    String opportunityId = '';
                    if(customerTaskRecord.Product_Order__c != null && customerTaskRecord.Product_Order__r.Order__r.Opportunity__c!=null){
                        opportunityId = customerTaskRecord.Product_Order__r.Order__r.Opportunity__c;
                    }else if(customerTaskRecord.Campaign_Order__c != null && customerTaskRecord.Campaign_Order__r.Opportunity__c !=null){
                        opportunityId = customerTaskRecord.Campaign_Order__r.Opportunity__c;
                    }else if(customerTaskRecord.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c!=null){
                        opportunityId = customerTaskRecord.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c;
                    }
                    if(opportunityId!=''){
                        if(!opportunityIdToCustomerActivityIdMap.containsKey(opportunityId)){
                            opportunityIdToCustomerActivityIdMap.put(opportunityId, new Set<Id>());
                        }
                        opportunityIdToCustomerActivityIdMap.get(opportunityId).add(customerTaskRecord.Id);
                    }
                    allCustomerActivitiesIds.add(customerTaskRecord.Id); 
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This a utility method, will be used to build AccountShare records list based on the input parameter.
    * @param  contactId          - User will be search based on contactId, to whome account will be shared.
	* @param  accountId          - The Account will be shared
	* @param  customerRoleAccess - Access to user
    * @return       void
    */
    public void populateAccountShareList(Id contactId,Id accountId,Customer_Role_Access__c customerRoleAccess){
        if(contactUserMap.containsKey(contactId)){
            for(User user : contactUserMap.get(contactId)){
                AccountShare accountShare = new AccountShare();
                accountShare.AccountId = accountId;
                accountShare.UserOrGroupId = user.Id;
                if(customerRoleAccess.Account_Access__c == 'Public Read'){
                    accountShare.AccountAccessLevel = 'Read';
                    accountShare.CaseAccessLevel = 'Read';
                    accountShare.OpportunityAccessLevel = 'Read';
                    accountShareList.add(accountShare);
                }else if(customerRoleAccess.Account_Access__c == 'Public Read/Write'){
                    accountShare.AccountAccessLevel = 'Edit';
                    accountShare.CaseAccessLevel = 'Edit';
                    accountShare.OpportunityAccessLevel = 'Edit'; 
                    accountShareList.add(accountShare);
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This a utility method, will be used to build Proof Shared records list based on the input parameter.
    * @param  contactId          - User will be search based on contactId, to whome account will be shared.
	* @param  proofs             - The Proofs will be shared
	* @param  customerRoleAccess - Access to user
    * @return       void
    */
    public void populateProofShareList(Id contactId,Set<Id> proofs,Customer_Role_Access__c customerRoleAccess){ 
        for(User user : contactUserMap.get(contactId)){
            for(Id proofId : proofs){
                SocialCampaign__Share proofShare = new SocialCampaign__Share();
                proofShare.UserOrGroupId = user.Id;
                proofShare.ParentId = proofId;
                proofShare.RowCause = Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c;
                if(customerRoleAccess.Proof_Access__c == 'Public Read'){
                    proofShare.AccessLevel  = 'Read';
                    proofShareList.add(proofShare);
                }else if(customerRoleAccess.Proof_Access__c == 'Public Read/Write'){
                    proofShare.AccessLevel  = 'Edit';
                    proofShareList.add(proofShare);
                }
            }
        }
    }
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This a utility method, will be used to build Customer Activities Shared records list 
    * 				based on the input parameter.
    * @param  contactId          - User will be search based on contactId, to whome account will be shared.
	* @param  proofs             - The Customer Activities will be shared
	* @param  customerRoleAccess - Access to user
    * @return       void
    */
    public void populateCustomerActivityShareList(Id contactId,Set<Id> customerActivities,Customer_Role_Access__c customerRoleAccess){
        customerActivityShareList = new List<Customer_Task__Share>();
        for(User user : contactUserMap.get(contactId)){
            for(Id customerActivityId : customerActivities){
                Customer_Task__Share customerTaskShare = new Customer_Task__Share();
                customerTaskShare.UserOrGroupId = user.Id;
                customerTaskShare.ParentId = customerActivityId;
                customerTaskShare.RowCause = Schema.Customer_Task__Share.RowCause.NewsXtend_My_Account__c;
                if(customerRoleAccess.Customer_Activity_Access__c == 'Public Read'){
                    customerTaskShare.AccessLevel  = 'Read';
                    customerActivityShareList.add(customerTaskShare);
                }else if(customerRoleAccess.Customer_Activity_Access__c == 'Public Read/Write'){
                    customerTaskShare.AccessLevel  = 'Edit';
                    customerActivityShareList.add(customerTaskShare); 
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will fetch profile Id for Profile name mentioned in contact role access records
    * @param  		NA
    * @return       void
    */
    public void fetchProfiles(){
        if( contactRoleAccessCommunityUserProfiles.size()>0){
            profileNameWithProfileIdMap = new  Map<String,String>();
            List<Profile> profileList = [SELECT Id,name FROM profile WHERE name IN :contactRoleAccessCommunityUserProfiles LIMIT 1];
            if(profileList!=null && profileList.size()>0){
                for(Profile profile : profileList){ 
                    if( !profileNameWithProfileIdMap.containsKey(profile.name)){
                        profileNameWithProfileIdMap.put(profile.name,profile.Id);
                    }
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will be called from Contact Role NXX2_Contact_Role_TriggerHandler class.
    * 				This method will handle sharing of below Objects  for My Account Community.
    * @param  		Map<Id, SObject> newItems
    * @return       void
    */
    public void handleContactRoleAfterInsert(Map<Id, SObject> newItems){
        roles = new Set<String>();
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        listOfUserToCreate = new List<User>();
        contactIds = new Set<Id>();
        Set<Id> contactRoleAccountIds = new Set<Id>();
        customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        List<Contact_Role__c> globalContactRoleList=new List<Contact_Role__c>();
        opportunityIdToPayerAccountIdMap=new Map<Id,Id>();
        setOfOpportunityId=new Set<Id>();
        setOfPrimaryAndPayerAccountIds=new Set<Id>();
        payerAccountIDAndPrimaryAccountMap = new Map<Id,Set<Id>>();
        primaryAccountsToOpportunityIdMap=new Map<Id,Set<Id>>();
        opportunityIdToProofIdMap = new Map<Id,Set<Id>>();
        opportunityIdToCustomerActivityIdMap=new Map<Id,Set<Id>>();
        payerAccountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        
        //Fetch all the Contact Records from Contact Roles Records, to vaidate whether all are eligible for Sharing 
        //or not based on NewsXtend_My_Account_Access__c field in contacts.
        //so wheneve customer need an access to My Account community 'NewsXtend_My_Account_Access__c' field 
        //has to be enabled at contacts
        for(Contact_Role__c contactRole : ((Map<Id,Contact_Role__c>)newItems).values()) {
            if(contactRole.Account__c != null && contactRole.Contact__c != null){
                if(!contactContactRoleMap.containsKey(contactRole.Contact__c)){
                    contactContactRoleMap.put(contactRole.Contact__c, new List<Contact_Role__c>());
                }
                contactContactRoleMap.get(contactRole.Contact__c).add(contactRole);
                roles.add(contactRole.Role__c);               
            }
        }
        
        //Check Contacts are allowed to sharing or not, if 'NewsXtend_My_Account_Access__c' is true 
        //then process records else no need to process.
        if(contactContactRoleMap!=null && contactContactRoleMap.size()>0){
            Map<Id,Contact> mapOfContactForNewsExtendAccessRequired = new Map<Id,Contact> ([Select FirstName,LastName,Email,Id,NewsXtend_My_Account_Access__c,AccountId from Contact where Id IN:contactContactRoleMap.keySet() AND AccountId!=null]);    
            if(mapOfContactForNewsExtendAccessRequired!=null && mapOfContactForNewsExtendAccessRequired.size()>0){
                for(Contact contact : ((Map<Id,Contact>)mapOfContactForNewsExtendAccessRequired).values()){
                    if(contact.Email == null){
                        throw new NXX2_ConfigModel.NXX2_Exception('MailId is missing for contact.');
                    }
                    if(contact.NewsXtend_My_Account_Access__c == null || !contact.NewsXtend_My_Account_Access__c){
                        contactContactRoleMap.remove(contact.Id);
                    }
                }
            }
            
            //Build Global maps and List for Sharing  Records.
            //contactRoleAccountIds - These are unique Account Ids linked to the contact Role Records 
            //						  which are considered for process.
            //globalContactRoleList - contains contact role records which are going to be processed.
            if(contactContactRoleMap!=null && contactContactRoleMap.size()>0){
                for(List<Contact_Role__c> contactRoleList : ((Map<Id,List<Contact_Role__c>>)contactContactRoleMap).values()){
                    for(Contact_Role__c contactRole : contactRoleList){
                        globalContactRoleList.add(contactRole); 
                        contactRoleAccountIds.add(contactRole.Account__c);
                    } 
                } 
                
                fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(contactRoleAccountIds);
                populateAccountContactRoleMapAndContactIdsAndRoles(globalContactRoleList);
                startSharingRecords(mapOfContactForNewsExtendAccessRequired,false);
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will be used to prepare Data for AccountShare records based on Contact Roles Records
    * @param  		NA
    * @return       void
    */
    public void populateShareListFormyAccountsObjects(){
        //This for loop will handle creating Sharing records for Account and also for Proof and customer Actitivity records 
        //which are link to Opportunity where the account is a Primary Account
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                if(customerRoleAccessMap!=null && customerRoleAccessMap.size()>0 && customerRoleAccessMap.containsKey(contactRole.Role__c)){
                    Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                    populateAccountShareList(contactRole.Contact__c,accountId,customerRoleAccess);
                    if(primaryAccountsToOpportunityIdMap.containsKey(accountId)){
                        for(Id primaryAccountId : primaryAccountsToOpportunityIdMap.keySet()){
                            Set<Id> opportunityIds = primaryAccountsToOpportunityIdMap.get(primaryAccountId);
                            if(opportunityIds!=null && opportunityIds.size()>0){
                                for(Id opportunityId : opportunityIds){
                                    if(opportunityIdToProofIdMap!=null && opportunityIdToProofIdMap.containsKey(opportunityId)){
                                        populateProofShareList(contactRole.Contact__c,opportunityIdToProofIdMap.get(opportunityId),customerRoleAccess); 
                                    } 
                                    if(opportunityIdToCustomerActivityIdMap!=null && opportunityIdToCustomerActivityIdMap.containsKey(opportunityId)){
                                        populateCustomerActivityShareList(contactRole.Contact__c,opportunityIdToCustomerActivityIdMap.get(opportunityId),customerRoleAccess);
                                    } 
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //This for loop will handle creating Sharing records for Proof and customer Actitivity records 
        //which are link to Opportunity where Opportunity has Payer Accounts.
        if(opportunityIdToPayerAccountIdMap!=null && opportunityIdToPayerAccountIdMap.size()>0){
            for(Id opportunityId : opportunityIdToPayerAccountIdMap.keySet()){
                Id payerAccountId = opportunityIdToPayerAccountIdMap.get(opportunityId);
                if(payerAccountContactRoleMap.containsKey(payerAccountId)){
                    List<Contact_Role__c> contactRoles = payerAccountContactRoleMap.get(payerAccountId);
                    for(Contact_Role__c contactRole : contactRoles){
                        if(customerRoleAccessMap!=null && customerRoleAccessMap.size()>0 && customerRoleAccessMap.containsKey(contactRole.Role__c)){
                            Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                            if(opportunityIdToProofIdMap!=null && opportunityIdToProofIdMap.containsKey(opportunityId)){
                                populateProofShareList(contactRole.Contact__c,opportunityIdToProofIdMap.get(opportunityId),customerRoleAccess); 
                            }
                            if(opportunityIdToCustomerActivityIdMap!=null && opportunityIdToCustomerActivityIdMap.containsKey(opportunityId)){
                                populateCustomerActivityShareList(contactRole.Contact__c,opportunityIdToCustomerActivityIdMap.get(opportunityId),customerRoleAccess);
                            }
                        }
                        
                    }
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will be called by the Contact Role Trigger Handler, 
    * 				whenever contact Role Records gets updated.
    * @param  		Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void HandleContactRoleAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        roles = new Set<String>();
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        listOfUserToCreate = new List<User>();
        contactIds = new Set<Id>();
        Set<Id> contactRoleAccountIds = new Set<Id>();
        List<Contact_Role__c> globalContactRoleList=new List<Contact_Role__c>();
        opportunityIdToPayerAccountIdMap=new Map<Id,Id>();
        setOfOpportunityId=new Set<Id>();
        setOfPrimaryAndPayerAccountIds=new Set<Id>();
        payerAccountIDAndPrimaryAccountMap = new Map<Id,Set<Id>>();
        primaryAccountsToOpportunityIdMap=new Map<Id,Set<Id>>();
        opportunityIdToProofIdMap = new Map<Id,Set<Id>>();
        opportunityIdToCustomerActivityIdMap=new Map<Id,Set<Id>>();
        payerAccountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        List<Account> roleChangedContactRolesRecords = new List<Account>();
        accountContactMap = new Map<Id,List<Id>>();
        Set<String> accountIds = new Set<String>();
        Map<Id,Contact_Role__c> mapOfOldContactRole = ((Map<Id,Contact_Role__c>) oldItems);
        for(Contact_Role__c contactRole : ((Map<Id,Contact_Role__c>)newItems).values()){
            if(contactRole.Role__c != mapOfOldContactRole.get(contactRole.Id).Role__c){           
                if(!accountContactRoleMap.containsKey(contactRole.Account__c)){
                    accountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
                }
                accountContactRoleMap.get(contactRole.Account__c).add(contactRole);
                contactIds.add(contactRole.Contact__c);
                if(!accountContactMap.containsKey(contactRole.Contact__c)){
                    accountContactMap.put(contactRole.Account__c, new List<Id>());
                }
                accountContactMap.get(contactRole.Account__c).add(contactRole.Contact__c);
            }
        }
        fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(accountContactMap.keySet());
        populateContactUserMap();
        fetchProofRecords();
        fetchCustomerTaskRecords();
        manageDeletionOfShareRecords();
        //This method will reinitiate the Sharing process for Contact Roles, post deletion of Share Records.
        handleContactRoleAfterInsert(newItems);
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will called by Contact Role Trigger Handler, when contact Role records get deleted. 
    * 				It will delete all the sharing records link to the contact associated to.
    * @param  		Map<Id, SObject> oldItems
    * @return       void
    */
    public void HandleContactRoleAfterDelete(Map<Id, SObject> oldItems){
        roles = new Set<String>();
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        listOfUserToCreate = new List<User>();
        contactIds = new Set<Id>();
        Set<Id> contactRoleAccountIds = new Set<Id>();
        List<Contact_Role__c> globalContactRoleList=new List<Contact_Role__c>();
        opportunityIdToPayerAccountIdMap=new Map<Id,Id>();
        setOfOpportunityId=new Set<Id>();
        setOfPrimaryAndPayerAccountIds=new Set<Id>();
        payerAccountIDAndPrimaryAccountMap = new Map<Id,Set<Id>>();
        primaryAccountsToOpportunityIdMap=new Map<Id,Set<Id>>();
        opportunityIdToProofIdMap = new Map<Id,Set<Id>>();
        opportunityIdToCustomerActivityIdMap=new Map<Id,Set<Id>>();
        payerAccountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        accountContactMap = new Map<Id,List<Id>>();
        Set<String> accountIds = new Set<String>();
        for(Contact_Role__c contactRole : ((Map<Id,Contact_Role__c>)oldItems).values()){
            if(!accountContactRoleMap.containsKey(contactRole.Account__c)){
                accountContactRoleMap.put(contactRole.Account__c, new List<Contact_Role__c>());
            }
            accountContactRoleMap.get(contactRole.Account__c).add(contactRole);
            contactIds.add(contactRole.Contact__c);
            if(!accountContactMap.containsKey(contactRole.Contact__c)){
                accountContactMap.put(contactRole.Account__c, new List<Id>());
            }
            accountContactMap.get(contactRole.Account__c).add(contactRole.Contact__c);
        }
        populateContactUserMap();
        fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(accountContactMap.keySet());
        fetchProofRecords();
        fetchCustomerTaskRecords();
        manageDeletionOfShareRecords();
    }

	/**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will called by Contact Trigger Handler, when contact records is updated. 
    * 				It will delete all the sharing records 
    * 				if newsXtend_My_Account_AccessGivenContacts field is set to false 
    * 				and will create sharing records if this field is set to true.
    * @param  		Set<Id> newsXtend_My_Account_AccessGivenContacts,Map<Id, Contact> newItems
    * @return       void
    */
    public void handleNewsXtendMyAccountEnableAccessChanged(Set<Id> newsXtend_My_Account_AccessGivenContacts,Map<Id, Contact> newItems){  
        roles = new Set<String>();
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactContactRoleMap = new Map<Id,List<Contact_Role__c>>(); 
        listOfUserToCreate = new List<User>();
        contactIds = new Set<Id>();
        Map<Id,Contact> mapOfNewContact = ((Map<Id,Contact>) newItems);
        Set<Id> contactRoleAccountIds = new Set<Id>();
        customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        List<Contact_Role__c> globalContactRoleList=new List<Contact_Role__c>();
        opportunityIdToPayerAccountIdMap=new Map<Id,Id>();
        setOfOpportunityId=new Set<Id>();
        setOfPrimaryAndPayerAccountIds=new Set<Id>();
        payerAccountIDAndPrimaryAccountMap = new Map<Id,Set<Id>>();
        primaryAccountsToOpportunityIdMap=new Map<Id,Set<Id>>();
        opportunityIdToProofIdMap = new Map<Id,Set<Id>>();
        opportunityIdToCustomerActivityIdMap=new Map<Id,Set<Id>>();
        payerAccountContactRoleMap=new Map<Id,List<Contact_Role__c>>();
        List<Contact_Role__c> conntactRoleList = fetchContactRolesBasedOnContactsIds(newsXtend_My_Account_AccessGivenContacts);
        populateAccountContactRoleMapAndContactIdsAndRolesBasedOnContacts(conntactRoleList);
        fetchPayerAccountsAndPrimaryAccountsLinksToOpportunity(accountContactRoleMap.keySet());
        startSharingRecords(mapOfNewContact,true);
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method is global method and will be used by most of the Sharing related Trigger handlers.
    * 				This atually start Sharing after all the validation is over.
    * @param  		Map<Id,Contact> mapOfContactIDContactRecords,Boolean isFromContactUpdate
    * @return       void
    */
    public void startSharingRecords(Map<Id,Contact> mapOfContactIDContactRecords,Boolean isFromContactUpdate){
        if(roles!=null && roles.size()>0){
            populateCustomerRoleAccessMap();
            fetchProfiles();
            populateContactUserMap();
            prepareCommunityUserAndCreateInSalesforce(mapOfContactIDContactRecords);        
            populateContactUserMap();
            fetchProofRecords();
            fetchCustomerTaskRecords();
            populateShareListFormyAccountsObjects();
            insertProofShareRecords();
            insertCustomerTaskShareRecords();
            insertAccountShareRecords();
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will help, to prepare List Of User, 
    * 				which need to be created in Salesforce, so that they can access My Accounts.
    * @param  		Map<Id,Contact> mapOfNewContact
    * @return       void
    */
    public void prepareCommunityUserAndCreateInSalesforce(Map<Id,Contact> mapOfNewContact){
        Set<Id> contactIdAddedForInsertion = new Set<Id>();
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                if(customerRoleAccessMap!=null && customerRoleAccessMap.size()>0 && customerRoleAccessMap.containsKey(contactRole.Role__c)){ 
                    Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                    if(profileNameWithProfileIdMap!=null && profileNameWithProfileIdMap.containsKey(customerRoleAccess.Community_User_Profile__c)){
                        String profileId = profileNameWithProfileIdMap.get(customerRoleAccess.Community_User_Profile__c);
                        if(!contactUserMap.containsKey(contactRole.Contact__c) && !contactIdAddedForInsertion.contains(contactRole.Contact__c)){
                            listOfUserToCreate.add(createCommunityUserForContacts(mapOfNewContact.get(contactRole.Contact__c),profileId));
                            contactIdAddedForInsertion.add(contactRole.Contact__c);
                        }
                    }
                    
                }
            }
        }
        if(listOfUserToCreate!=null && listOfUserToCreate.size()>0){
            insert listOfUserToCreate;
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will be called from Contact Trigger Handler, as if access is revoked 
    * 				then user associated to contact will get deactivated and 
    * 				they will no more be able to login to My Account.
    * @param  		Set<Id>  newsXtend_My_Account_AccessRemoveContacts
    * @return       void
    */
    @future
    public static void handleNewsXtendMyAccountDiableAccess(Set<Id>  newsXtend_My_Account_AccessRemoveContacts){
        map<Id,User> usermap=new map<Id,User>();
        List<User> Users = [SELECT Id, ContactId,IsActive  FROM User WHERE ContactId IN:newsXtend_My_Account_AccessRemoveContacts];
        if(Users!=null && Users.size()>0){ 
            for(User user : Users){
                user.IsActive = false;
                usermap.put(user.Id,user);
            }
            update Users;    
        } 
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will prepare the User List which are shared with Account,Proof and customer Task 
    * 				and will delete the Share records from these Object.
    * @param  		NA
    * @return       void
    */
    public void manageDeletionOfShareRecords(){
        Map<Id,User> globalUserMap = new Map<Id,User>();
        //Query all the Proof Share Records where 
        if(accountContactMap!=null && accountContactMap.size()>0){
            for(Id accountId : accountContactMap.keySet()){
                List<Id> contactIDs = accountContactMap.get(accountId);
                for(Id contactId : contactIDs){
                    if(contactUserMap!=null && contactUserMap.size()>0 && contactUserMap.containsKey(contactId)){
                        List<User> userList = contactUserMap.get(contactId);
                        if(userList!=null && userList.size()>0){
                            for(User user : userList){
                                if(!globalUserMap.containsKey(user.Id)){
                                    globalUserMap.put(user.Id,user);
                                }
                            }
                        }
                    }
                }
            }
        }
        if(globalUserMap!=null && globalUserMap.size()>0){
            List<Customer_Task__Share> listOfCustomerTaskShareToDelete = fetchCustomerTaskShareRecords(globalUserMap);
            List<SocialCampaign__Share> listOfProofShare = fetchSocialCampaignShareRecords(globalUserMap);
            List<AccountShare> listOfProofShareAccountShare = fetchAccountShareRecords(globalUserMap);
            if(listOfCustomerTaskShareToDelete!=null && listOfCustomerTaskShareToDelete.size()>0){
                deleteCustomerTaskShareRecords(listOfCustomerTaskShareToDelete);
            }
            if(listOfProofShare!=null && listOfProofShare.size()>0){
                deleteProofShareRecords(listOfProofShare);
            }
            if(listOfProofShareAccountShare!=null && listOfProofShareAccountShare.size()>0){
                deleteAccountShareRecords(listOfProofShareAccountShare);
            }
        }
    } 
    
    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will create customer portal user for the given contact and profile.
    * @param  		Contact contactRecord,String profileId
    * @return       User
    */
    public User createCommunityUserForContacts(Contact contactRecord,String profileId){
        User newCommunitiesUser =  new User();
        try {
            //Select community profile that you want to assign
            newCommunitiesUser.contactId=contactRecord.Id;
            //This field will be used to validate whether user created by My Account Sharing 
            newCommunitiesUser.Is_NewsExtend_Created_User__c=true;
            String emailWithSuffix = contactRecord.Email + '.newsxtend';
            newCommunitiesUser.username=emailWithSuffix;
            newCommunitiesUser.firstname=contactRecord.FirstName;
            newCommunitiesUser.lastname=contactRecord.LastName;
            newCommunitiesUser.email=contactRecord.Email;
            newCommunitiesUser.communityNickname = contactRecord.LastName + '_'+Math.random();
            newCommunitiesUser.alias = string.valueof(contactRecord.FirstName.substring(0,1) + contactRecord.LastName.substring(0,1) + Math.random() ).substring(0,5);
            newCommunitiesUser.profileid = profileId;
            newCommunitiesUser.emailencodingkey='ISO-8859-1';
            newCommunitiesUser.languagelocalekey='en_US';
            newCommunitiesUser.localesidkey='en_AU';
            newCommunitiesUser.timezonesidkey='Australia/Sydney';
        }catch(DMLException ex) {
            if(ex.getDMLMessage(0).contains('Duplicate Username')) {
                throw new NXX2_ConfigModel.NXX2_Exception('Unable to create portal user! Duplicate Username.');
            }
        }
        return newCommunitiesUser;
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Query All the Customer Activity Share records Shared to Users.
    * @param  		Map<Id,User> globalUserMap
    * @return       List<Customer_Task__Share>
    */
    public List<Customer_Task__Share> fetchCustomerTaskShareRecords(Map<Id,User> globalUserMap){
        List<Customer_Task__Share> listOfCustomerTaskShare = new List<Customer_Task__Share>();
        if(allCustomerActivitiesIds!=null && allCustomerActivitiesIds.size()>0){
            listOfCustomerTaskShare = [Select Id,UserOrGroupId from Customer_Task__Share 
                                       where UserOrGroupId IN: globalUserMap.keySet() 
                                       AND ParentID IN:allCustomerActivitiesIds 
                                       AND RowCause =: Schema.Customer_Task__Share.RowCause.NewsXtend_My_Account__c];
        }
        return listOfCustomerTaskShare;
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Query All the proof Share records Shared to Users.
    * @param  		Map<Id,User> globalUserMap
    * @return       List<SocialCampaign__Share>
    */
    public List<SocialCampaign__Share> fetchSocialCampaignShareRecords(Map<Id,User> globalUserMap){
        List<SocialCampaign__Share> listOfSocialCampaignShare = new List<SocialCampaign__Share>();
        if(allProofsIds!=null && allProofsIds.size()>0){
            listOfSocialCampaignShare = [Select Id,UserOrGroupId from SocialCampaign__Share 
                                         where UserOrGroupId IN: globalUserMap.keySet() 
                                         AND ParentID IN:allProofsIds 
                                         AND RowCause =: Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c];
        }
        return listOfSocialCampaignShare;
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  Query All the account Share records Shared to Users.
    * @param  		Map<Id,User> globalUserMap
    * @return       List<AccountShare>
    */
    public List<AccountShare> fetchAccountShareRecords(Map<Id,User> globalUserMap){
        return [Select Id,UserOrGroupId from AccountShare 
                where UserOrGroupId IN: globalUserMap.keySet() 
                AND RowCause = 'Manual'] ; 
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will insert account Share Records.
    * @param  		NA
    * @return       void
    */
    public void insertAccountShareRecords(){
        if(accountShareList!=null && accountShareList.size()>0){
            Database.SaveResult[] accountShareList = Database.insert(accountShareList, false);
            for (Database.SaveResult sr : accountShareList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
	/**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will insert Proof Share Records.
    * @param  		NA
    * @return       void
    */
    public void insertProofShareRecords(){
        if(proofShareList!=null && proofShareList.size()>0){
            Database.SaveResult[] listOfInsertedProofShareList = Database.insert(proofShareList, false);
            for (Database.SaveResult sr : listOfInsertedProofShareList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Proof Share. Proof Share ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    } 
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will insert customer activity Share Records.
    * @param  		NA
    * @return       void
    */
    public void insertCustomerTaskShareRecords(){
        if(customerActivityShareList!=null && customerActivityShareList.size()>0){
            Database.SaveResult[] customerTaskShareList = Database.insert(customerActivityShareList, false);
            for (Database.SaveResult sr : customerTaskShareList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted customerTaskShare. customerTaskShare ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will delete the Customer Task Share Records.
    * @param  		List<Customer_Task__Share> listOfCustomerTaskShareToDelete
    * @return       void
    */
    public void deleteCustomerTaskShareRecords(List<Customer_Task__Share> listOfCustomerTaskShareToDelete){
        Database.DeleteResult[] drList = Database.delete(listOfCustomerTaskShareToDelete, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted Customer_Task__Share with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will delete the Proof Share Records.
    * @param  		List<SocialCampaign__Share> listOfProofShare
    * @return       void
    */
    public void deleteProofShareRecords(List<SocialCampaign__Share> listOfProofShare){
        Database.DeleteResult[] drList = Database.delete(listOfProofShare, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted SocialCampaign__Share with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }

    /**
    * @author       Paras Prajapat
    * @date         2019-01-02
    * @description  This method will delete the Account Share Records.
    * @param  		List<AccountShare> listOfAccountShareAccountShare
    * @return       void
    */
    public void deleteAccountShareRecords(List<AccountShare> listOfAccountShareAccountShare){
        Database.DeleteResult[] drList = Database.delete(listOfAccountShareAccountShare, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted AccountShares with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }

}