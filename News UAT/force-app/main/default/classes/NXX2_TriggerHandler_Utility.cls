/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_TriggerHandler_Utility
* @description  This is the helper class for all trigger handlers to handle sharing logic.
*/
public virtual class NXX2_TriggerHandler_Utility {
    //Existing portal user
    public Set<Id> userIds;
    //Account(Payer or primary) and it's related primary account.
    //User of payer/primary account will have access to related primary account.
    public Map<Id,Set<Id>> accountsToPrimaryAccountsMap;
    //Contact roles related to accounts
    public Map<Id,List<Contact_Role__c>> accountContactRoleMap;
    //Contact in contact role and role in contact role map
    public Map<Id,String> contactToRoleMap;
    //All Contacts
    public Set<Id> contactIds;
    //All Roles
    public Set<String> roles;
    //Users related to contacts
    public Map<Id,List<User>> contactUserMap;
    //Customer role access for the given role
    public Map<String,Customer_Role_Access__c> customerRoleAccessMap;
    //Profile mentioned in contact role access record
    //This will be used for new portal user
    public Set<String> contactRoleAccessCommunityUserProfiles;
    //Profile Id related to Profile name
    public Map<String,String> profileNameWithProfileIdMap; 
    //Account shared with portal users
    public List<AccountShare> accountShareList;
    //Proof shared with portal users
    public List<SocialCampaign__Share> proofShareList;
    //Customer activity shared with portal users
    public List<Customer_Task__Share> customerActivityShareList;
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will populate the map which will have payer/primary accounts 
    * 				with their related primary account.
    * @param        Set<Id> opportunityIds,Set<Id> accountIds
    * @return       Set<Id>
    */
    public Set<Id> populateAccountsToPrimaryAccountsMap(Set<Id> opportunityIds,Set<Id> accountIds){
        accountsToPrimaryAccountsMap = new Map<Id,Set<Id>>();
        Map<Id,Opportunity> opportunities = new Map<Id,Opportunity> ();
        if(opportunityIds != null){
            opportunities = new Map<Id,Opportunity> ([SELECT Payer_Account__c,AccountId 
                                                      FROM Opportunity 
                                                      WHERE Id IN :opportunityIds]);
        }else if(accountIds != null){
            opportunities = new Map<Id,Opportunity>([SELECT Payer_Account__c,AccountId 
                                                     FROM Opportunity 
                                                     WHERE Payer_Account__c IN :accountIds OR AccountId IN :accountIds]);
        }
        for(Opportunity opportunity : opportunities.values()){
            if(opportunity.AccountId != null){
                if(!accountsToPrimaryAccountsMap.containsKey(opportunity.AccountId)){
                    accountsToPrimaryAccountsMap.put(opportunity.AccountId, new Set<Id>());
                }
                accountsToPrimaryAccountsMap.get(opportunity.AccountId).add(opportunity.AccountId);
                if(opportunity.Payer_Account__c != null){
                    if(!accountsToPrimaryAccountsMap.containsKey(opportunity.Payer_Account__c)){
                        accountsToPrimaryAccountsMap.put(opportunity.Payer_Account__c, new Set<Id>());
                    }
                    accountsToPrimaryAccountsMap.get(opportunity.Payer_Account__c).add(opportunity.AccountId);
                }
            }
        }
        return opportunities.keySet();
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will get contact roles for the given accounts 
    * 				and will populate below mentioned four variables:
    * 				1.	accountContactRoleMap - Contact roles related to account
    * 				2.	contactToRoleMap - Role related to contact
    * 				3.	contactIds - all contacts in fetched contact roles
    * 				4.	roles - all roles in fetched contact roles
    * @param        Set<Id> accountIds
    * @return       void
    */
    public void populateContactRoleDataForTheAccounts(Set<Id> accountIds){
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactToRoleMap = new Map<Id,String>();
        contactIds = new Set<Id>();
        roles = new Set<String>();
        List<Contact_Role__c> conntactRoles = [SELECT Id,Account__c,Contact__c,Role__c 
                                               FROM Contact_Role__c WHERE Account__c IN:accountIds 
                                               AND Contact__r.NewsXtend_My_Account_Access__c = true];
        for(Contact_Role__c contactRole : conntactRoles){
            String accountID = contactRole.Account__c;
            contactIds.add(contactRole.Contact__c);
            roles.add(contactRole.Role__c);
            contactToRoleMap.put(contactRole.Contact__c,contactRole.Role__c);
            if(!accountContactRoleMap.containsKey(accountID)){
                accountContactRoleMap.put(accountID, new List<Contact_Role__c>());
            }
            accountContactRoleMap.get(accountID).add(contactRole);
        }  
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will get contact roles for the given roles 
    * 				and will populate below mentioned three variables:
    * 				1.	accountContactRoleMap - Contact roles related to account
    * 				2.	contactToRoleMap - Role related to contact
    * 				3.	contactIds - all contacts in fetched contact roles
    * @param        Set<String> roles
    * @return       void
    */
    public void populateContactRoleDataForTheRoles(Set<String> roles){
        accountContactRoleMap = new Map<Id,List<Contact_Role__c>>();
        contactToRoleMap = new Map<Id,String>();
        contactIds = new Set<Id>();
        List<Contact_Role__c> conntactRoles = [SELECT Id,Account__c,Contact__c,Role__c 
                                               FROM Contact_Role__c WHERE Role__c IN:roles 
                                               AND Contact__r.NewsXtend_My_Account_Access__c = true];
        for(Contact_Role__c contactRole : conntactRoles){
            String accountID = contactRole.Account__c;
            contactIds.add(contactRole.Contact__c);
            contactToRoleMap.put(contactRole.Contact__c,contactRole.Role__c);
            if(!accountContactRoleMap.containsKey(accountID)){
                accountContactRoleMap.put(accountID, new List<Contact_Role__c>());
            }
            accountContactRoleMap.get(accountID).add(contactRole);
        }  
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will populate the map which will have contact with their related active portal users.
    * @param        NA
    * @return       void
    */
    public void populateContactUserMap(){
        contactUserMap = new Map<Id,List<User>>();
        userIds = new Set<Id>();
        List<User> Users = [SELECT Id, ContactId, IsActive  FROM User 
                            WHERE ContactId IN:contactIds AND userType Like 'customer%'];
        for(User user : Users){
            userIds.add(user.Id);
            if(!contactUserMap.containsKey(user.ContactId)){
                contactUserMap.put(user.ContactId, new List<User>());
            }
            contactUserMap.get(user.ContactId).add(user);
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will create portal users for the contacts who do not have any active portal user.
    * @param        NA
    * @return       void
    */
    public void createCommunityUserForContacts(){
        fetchProfiles();
        List<Contact> contacts = [SELECT Email,FirstName,LastName FROM Contact WHERE Id IN :contactIds];
        List<User> usersToInsert = new List<User>();
        User newCommunitiesUser;
        for(Contact contact : contacts){
            String role = contactToRoleMap.get(contact.Id);
            Customer_Role_Access__c roleAccess; 
            Id profileId;
            if(role != null){
                roleAccess = customerRoleAccessMap.get(role);
                if(roleAccess != null){
                    profileId = profileNameWithProfileIdMap.get(roleAccess.Community_User_Profile__c);
                }
            }
            if(profileId != null){
                newCommunitiesUser =  new User();
                newCommunitiesUser.contactId=contact.Id;
                newCommunitiesUser.username=contact.Email;
                newCommunitiesUser.firstname=contact.FirstName;
                newCommunitiesUser.lastname=contact.LastName;
                newCommunitiesUser.email=contact.Email;
                newCommunitiesUser.communityNickname = contact.LastName + '_'+Math.random();
                newCommunitiesUser.alias = string.valueof(contact.FirstName.substring(0,1) + contact.LastName.substring(0,1) + Math.random() ).substring(0,5);
                newCommunitiesUser.profileid = profileId;
                newCommunitiesUser.emailencodingkey='ISO-8859-1';
                newCommunitiesUser.languagelocalekey='en_US'; 
                newCommunitiesUser.localesidkey='en_AU';
                newCommunitiesUser.timezonesidkey='Australia/Sydney';
                usersToInsert.add(newCommunitiesUser);
                contactUserMap.put(contact.Id, new List<User>());
                contactUserMap.get(contact.Id).add(newCommunitiesUser);
            }
        }
        if(usersToInsert.size() > 0){
            insert usersToInsert;
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will populate customer role access for the roles fetched earlier.
    * @param        NA
    * @return       void
    */
    public void populateCustomerRoleAccessMap(){
        List<Customer_Role_Access__c> CustomerRoleAccessList = [SELECT Account_Access__c,Contact_Role__c,
                                                                Community_User_Profile__c,Customer_Activity_Access__c,
                                                                Proof_Access__c FROM Customer_Role_Access__c 
                                                                WHERE Contact_Role__c IN:roles];
        customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        contactRoleAccessCommunityUserProfiles = new Set<String>();
        for(Customer_Role_Access__c customerRoleAccess : CustomerRoleAccessList){
            customerRoleAccessMap.put(customerRoleAccess.Contact_Role__c,customerRoleAccess);
            contactRoleAccessCommunityUserProfiles.add(customerRoleAccess.Community_User_Profile__c);
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share account with portal users for the given contact.
    * @param        Id contactId,Id accountId,Customer_Role_Access__c customerRoleAccess
    * @return       void
    */
    public void populateAccountShareList(Id contactId,Id accountId,Customer_Role_Access__c customerRoleAccess){
        if(contactUserMap.containsKey(contactId)){
            for(User user : contactUserMap.get(contactId)){
                if(accountsToPrimaryAccountsMap.containsKey(accountId) && user.IsActive){
                    for(Id primaryAccountId : accountsToPrimaryAccountsMap.get(accountId)){
                        AccountShare accountShare = new AccountShare();
                        accountShare.AccountId = primaryAccountId;
                        accountShare.UserOrGroupId = user.Id;
                        if(customerRoleAccess.Account_Access__c == 'Public Read Only'){
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
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share proof with portal users for the given contact.
    * @param        Id contactId,Set<Id> proofs,Customer_Role_Access__c customerRoleAccess
    * @return       void
    */
    public void populateProofShareList(Id contactId,Set<Id> proofs,Customer_Role_Access__c customerRoleAccess){
        if(contactUserMap.containsKey(contactId)){
            for(User user : contactUserMap.get(contactId)){
                if(user.IsActive){
                    for(Id proofId : proofs){
                        SocialCampaign__Share proofShare = new SocialCampaign__Share();
                        proofShare.UserOrGroupId = user.Id;
                        proofShare.ParentId = proofId;
                        proofShare.RowCause = Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c;
                        if(customerRoleAccess.Proof_Access__c == 'Public Read'){
                            proofShare.AccessLevel  = 'Read';
                        }else if(customerRoleAccess.Proof_Access__c == 'Public Read/Write'){
                            proofShare.AccessLevel  = 'Edit';
                        }
                        proofShareList.add(proofShare);
                    }
                }
            }
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share customer activity with portal users for the given contact.
    * @param        Id contactId,Set<Id> proofs,Customer_Role_Access__c customerRoleAccess
    * @return       void
    */
    public void populateCustomerActivityShareList(Id contactId,Set<Id> customerActivities,Customer_Role_Access__c customerRoleAccess){
        if(contactUserMap.containsKey(contactId)){
            for(User user : contactUserMap.get(contactId)){
                if(user.IsActive){
                    for(Id customerActivityId : customerActivities){
                        Customer_Task__Share customerTaskShare = new Customer_Task__Share();
                        customerTaskShare.UserOrGroupId = user.Id;
                        customerTaskShare.ParentId = customerActivityId;
                        customerTaskShare.RowCause = Schema.Customer_Task__Share.RowCause.NewsXtend_My_Account__c;
                        if(customerRoleAccess.Customer_Activity_Access__c == 'Public Read'){
                            customerTaskShare.AccessLevel  = 'Read';
                        }else if(customerRoleAccess.Customer_Activity_Access__c == 'Public Read/Write'){
                            customerTaskShare.AccessLevel  = 'Edit';
                        }
                        customerActivityShareList.add(customerTaskShare);
                    }
                }
            }
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will populate profile Id for the Profile Name related to 
    * 				contact role access records fetched earlier.
    * @param        NA
    * @return       void
    */
    public void fetchProfiles(){
        if(contactRoleAccessCommunityUserProfiles.size()>0){
            profileNameWithProfileIdMap = new Map<String,String>();
            List<Profile> profileList = [SELECT Id,name FROM profile WHERE name IN :contactRoleAccessCommunityUserProfiles];
            for(Profile profile : profileList){ 
                if(!profileNameWithProfileIdMap.containsKey(profile.name)){
                    profileNameWithProfileIdMap.put(profile.name,profile.Id);
                }
            }
        }
    }
}