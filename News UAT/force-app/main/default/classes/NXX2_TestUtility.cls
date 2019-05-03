/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className    NXX2_TestUtility
* @description  This class will provide test data for NXX2_* test classes in collabration with TestDataFactory.
*/
@isTest
public class NXX2_TestUtility {
        /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide csmso__Product_Node__c record for testing.
    * @param        Integer numberOfRecord
    * @return       List<csmso__Product_Node__c>
    */
    public static List<csmso__Product_Node__c> createProductNodes(Integer numberOfRecord){
        List<csmso__Product_Node__c> nodes = new List<csmso__Product_Node__c>();
        csmso__Product_Node__c  productNode;
        Id recordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName()
            .get('Xtend Product').getRecordTypeId();
        for(Integer i = 0; i < numberOfRecord; i++){
            productNode = new csmso__Product_Node__c();
            productNode.Name = 'Test' + i;
            productNode.RecordTypeId = recordTypeId;
            productNode.csmso__Media_Types__c = 'Digital';
            if(Math.Mod(i,2) == 0){
                productNode.Product_Line__c = 'Social';
            }else{
                productNode.Product_Line__c = 'Display';
            }
            nodes.add(productNode);
        }
        insert nodes;
        return nodes;
    }
    
        /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide csmso__Product_Node__c record for testing.
    * @param        Integer numberOfRecord
    * @return       List<csmso__Product_Node__c>
    */
    public static List<csmso__Product_Node__c> createProductNodesForProductLine(String productLine){
        List<csmso__Product_Node__c> nodes = new List<csmso__Product_Node__c>();
        csmso__Product_Node__c  productNode;
        Id recordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName()
            .get('Xtend Product').getRecordTypeId();
        productNode = new csmso__Product_Node__c();
        productNode.Name = 'Test';
        productNode.RecordTypeId = recordTypeId;
        productNode.csmso__Media_Types__c = 'Digital';
        productNode.Product_Line__c = productLine;
        nodes.add(productNode);
        insert nodes;
        return nodes;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Product_Order__c record without product node for testing.
    * @return       Product_Order__c
    */
    public static Product_Order__c createProductOrderWithoutNode(){
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        insert opportunities;
        Order__c campaignOrder = new Order__c();
        campaignOrder.Opportunity__c = opportunities[0].Id;
        campaignOrder.Campaign_Customer_Contact__c = contacts[0].id; 
         campaignOrder.Account__c = accounts[0].id; 
        insert campaignOrder;
        Product_Order__c productOrder = new Product_Order__c();
        productOrder.Order__c = campaignOrder.id;
        insert productOrder;
        List<Product_Order__c> productOrders = [SELECT Name,Order__c FROM Product_Order__c WHERE Id = :productOrder.Id];
        if(productOrders.size() > 0){
            productOrder = productOrders[0];
        }
        return productOrder;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Task record for testing.
    * @param        List<Id> whatIds,Id ownerId
    * @return       List<Task>
    */
    public static List<Task> createMultipleSObjectTasks(List<Id> whatIds,Id ownerId){
        List<Task> tasks = new List<Task>();
        Task task;
        for(Id whatId : whatIds){
            task = new Task(
                ActivityDate = Date.today(),
                whatId = whatId,
                OwnerId = ownerId);
            tasks.add(task);
        }
        insert tasks;
        return tasks;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-29
    * @description  This method will provide Creative__c record for testing.
    * @param        Id productOrderId, String creativeSource
    * @return       Creative__c
    */
    public static Creative__c createCreative(Id productOrderId, String creativeSource)
    {
        Creative__c creative = new Creative__c(Name = 'Test Creative', 
                                               Product_Order__c = productOrderId,
                                               Creative_Source__c = creativeSource
                                              );
        insert creative;
        return creative;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Product_Order__c record for testing.
    * @param        Integer numberOfRecord
    * @return       List<Product_Order__c>
    */
    public static List<Product_Order__c> createProductOrder(Integer numberOfRecord){
        List<Product_Order__c> orders = new List<Product_Order__c>();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        insert opportunities;
        Order__c campaignOrder = new Order__c();
        campaignOrder.Opportunity__c = opportunities[0].Id;
        campaignOrder.Campaign_Customer_Contact__c = contacts[0].id; 
        campaignOrder.Account__c = accounts[0].id; 
        insert campaignOrder;
        List<csmso__Product_Node__c> nodes = createProductNodes(numberOfRecord);
        Product_Order__c productOrder;
        for(Integer i = 0; i < numberOfRecord; i++){
            productOrder = new Product_Order__c();
            productOrder.Order__c = campaignOrder.id;
            productOrder.Product_Node__c = nodes[i].Id;
            productOrder.Status__c = 'In Progress';
            orders.add(productOrder);
        }
        insert orders;
        return orders;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Product_Order__c record for testing.
    * @param        Integer numberOfRecord,Id campaignOrderId
    * @return       List<Product_Order__c>
    */
    public static List<Product_Order__c> createProductOrder(Integer numberOfRecord,Id campaignOrderId){
        List<Product_Order__c> orders = new List<Product_Order__c>();
        Product_Order__c productOrder;
        for(Integer i = 0; i < numberOfRecord; i++){
            productOrder = new Product_Order__c();
            productOrder.Order__c = campaignOrderId;
            productOrder.Status__c = 'In Progress';
            orders.add(productOrder);
        }
        insert orders;
        return orders;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Product_Order__c record with product node for testing.
    * @param        Id campaignOrderId,List<csmso__Product_Node__c> nodes
    * @return       List<Product_Order__c>
    */
    public static List<Product_Order__c> createProductOrderWithProductNodes(Id campaignOrderId,List<csmso__Product_Node__c> nodes){
        List<Product_Order__c> orders = new List<Product_Order__c>();
        Product_Order__c productOrder;
        for(csmso__Product_Node__c node : nodes){
            productOrder = new Product_Order__c();
            productOrder.Order__c = campaignOrderId;
            productOrder.Status__c = 'Draft';
            productOrder.Product_Node__c = node.Id;
            orders.add(productOrder);
        }
        insert orders;
        return orders;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Order__c record for testing.
    * @param        Id opportunityId, Id contactId, Id accountId
    * @return       Order__c
    */
    public static Order__c createCampaignOrder(Id opportunityId, Id contactId, Id accountId){
        Order__c campaignOrder = new Order__c();
        campaignOrder.Opportunity__c = opportunityId;
        campaignOrder.Campaign_Customer_Contact__c = contactId; 
        campaignOrder.Account__c = accountId; 
        insert campaignOrder;
        return campaignOrder;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Contact_Role__c record for testing.
    * @param        Id contactId, Id accountId, String roleName
    * @return       List<Contact_Role__c>
    */
    public static List<Contact_Role__c> createContactRole(Id contactId, List<Account> accounts, String roleName){
        List<Contact_Role__c> roles = new List<Contact_Role__c>();
        Contact_Role__c role;
        for(Account account : accounts){
            role = new Contact_Role__c();
            role.Contact__c = contactId; 
            role.Account__c = account.Id; 
            role.Role__c = roleName;
            role.HasOptedInOfEmail__c = true;
            roles.add(role);
        }
        insert roles;
        return roles;
    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will provide Task record for testing.
    * @param        String subject,String recordType,Id sObjectId
    * @return       Task
    */
    public static Task createTasks(String subject,String recordType,Id sObjectId)
    {
        System.debug('subject' + subject);
                System.debug('recordType' + recordType);

        System.debug('sObjectId' + sObjectId);

        Task task = new Task(
            ActivityDate = Date.today(),
            whatId = sObjectId,
            Subject = subject);
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName()
            .get(recordType).getRecordTypeId();
        task.RecordTypeId = recordTypeId;
        return task;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-29
    * @description  This method will provide Creative__c record for testing.
    * @param        List<Product_Order__c> orders
    * @return       List<Creative__c>
    */
    public static List<Creative__c> createCreative(List<Product_Order__c> orders)
    {
        List<Creative__c> creatives = new List<Creative__c>();
        Creative__c creative;
        for(Product_Order__c order : orders){
            creative = new Creative__c(Name = 'Test Creative', 
                                       Product_Order__c = order.Id,
                                       Creative_Source__c = 'Premedia'
                                      );
            creatives.add(creative);
        }
        insert creatives;
        return creatives;
    }

    /**
    * @author       Kamal Sharma
    * @date         2018-05-29
    * @description  This method will provide proof record for testing.
    * @param        Id productOrderId
    * @return       SocialCampaign__c
    */
    public static SocialCampaign__c createProof(Id productOrderId){
       SocialCampaign__c proof = new SocialCampaign__c(
                                       Product_Order__c = productOrderId,
                                       Status__c='New',
                                        Visible_To_Customer__c = true,
           Proof_Name__c = 'Test'
                                      );
        insert proof;
        return proof; 
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-29
    * @description  This method will provide proof record for testing.
    * @param        List<Product_Order__c> pos
    * @return       List<SocialCampaign__c>
    */
    public static List<SocialCampaign__c> createProofs(List<Product_Order__c> pos){
        List<SocialCampaign__c> proofs = new List<SocialCampaign__c>();
        for(Product_Order__c po : pos){
            SocialCampaign__c proof = new SocialCampaign__c(
                Product_Order__c = po.Id,
                Status__c = 'New',
                Visible_To_Customer__c = true
            );
            proofs.add(proof);
            proof = new SocialCampaign__c(
                Product_Order__c = po.Id,
                Status__c = 'Approved'
            );
            proofs.add(proof);
            proof = new SocialCampaign__c(
                Product_Order__c = po.Id,
                Status__c = 'In Review'
            );
            proofs.add(proof);
        }
        insert proofs;
        return proofs; 
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide csmso__Product_Node__c record of specific product line for testing.
    * @param        Integer numberOfRecord,String productLine
    * @return       List<csmso__Product_Node__c>
    */
    public static List<csmso__Product_Node__c> createProductNodesForSpecificProductLine(Integer numberOfRecord,String productLine){
        List<csmso__Product_Node__c> nodes = new List<csmso__Product_Node__c>();
        csmso__Product_Node__c  productNode;
        Id recordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName()
            .get('Xtend Product').getRecordTypeId();
        for(Integer i = 0; i < numberOfRecord; i++){
            productNode = new csmso__Product_Node__c();
            productNode.Name = 'Test' + i;
            productNode.csmso__Media_Types__c = 'Digital';
            productNode.Product_Line__c = productLine;
            nodes.add(productNode);
        }
        insert nodes;
        return nodes;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide Product_Order__c record with specific node for testing.
    * @param        Integer numberOfRecord,String productLine
    * @return       List<Product_Order__c>
    */
    public static List<Product_Order__c> createProductOrderWithSpecificNode(Integer numberOfRecord,String productLine){
        List<Product_Order__c> orders = new List<Product_Order__c>();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        insert opportunities;
        Order__c campaignOrder = new Order__c();
        campaignOrder.Opportunity__c = opportunities[0].Id;
        campaignOrder.Campaign_Customer_Contact__c = contacts[0].id; 
        campaignOrder.Account__c = accounts[0].id; 
        insert campaignOrder;
        List<csmso__Product_Node__c> nodes = createProductNodesForSpecificProductLine(numberOfRecord,productLine);
        Product_Order__c productOrder;
        for(Integer i = 0; i < numberOfRecord; i++){
            productOrder = new Product_Order__c();
            productOrder.Order__c = campaignOrder.id;
            productOrder.Product_Node__c = nodes[i].Id;
            productOrder.Status__c = 'In Progress';
            orders.add(productOrder);
        }
        insert orders;
        return orders;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide Customer_Task__c record for testing.
    * @param        List<SocialCampaign__c> proofList
    * @return       List<Customer_Task__c>
    */
    public static List<Customer_Task__c> createCustomerActivity(List<SocialCampaign__c> proofList){
        List<Customer_Task__c> listOfCustomerTask=new List<Customer_Task__c>();
        Id recordTypeId = Schema.SObjectType.Customer_Task__c.getRecordTypeInfosByName().get('Proof Customer Activity').getRecordTypeId();
        for(SocialCampaign__c proof:proofList){
            Customer_Task__c Customer_Task = new Customer_Task__c();
            Customer_Task.Type__c='Upload Creative Assets';
            Customer_Task.Due_Date__c=Date.today(); 
            Customer_Task.Status__c='New';
            Customer_Task.RecordTypeId = recordTypeId;
            Customer_Task.Social_Campaign__c=proof.Id;
            listOfCustomerTask.add(Customer_Task);
            Customer_Task = new Customer_Task__c();
            Customer_Task.Type__c='Approve and Review Your Display Ads';
            Customer_Task.Due_Date__c=Date.today(); 
            Customer_Task.Status__c='New';
            Customer_Task.RecordTypeId = recordTypeId;
            Customer_Task.Social_Campaign__c=proof.Id;
            listOfCustomerTask.add(Customer_Task);
            Customer_Task = new Customer_Task__c();
            Customer_Task.Type__c='Approve and Review Your Facebook Ads';
            Customer_Task.Due_Date__c=Date.today(); 
            Customer_Task.Status__c='With Client';
            Customer_Task.RecordTypeId = recordTypeId;
            Customer_Task.Social_Campaign__c=proof.Id;
            listOfCustomerTask.add(Customer_Task);
        }
        insert listOfCustomerTask;
        return listOfCustomerTask;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide Customer_Task__c record for the given product order.
    * @param        List<Product_Order__c> productOrderList
    * @return       List<Customer_Task__c>
    */
    public static List<Customer_Task__c> createCustomerActivityForProductOrder(List<Product_Order__c> productOrderList){
        List<Customer_Task__c> listOfCustomerTask=new List<Customer_Task__c>();
        Id recordTypeId = Schema.SObjectType.Customer_Task__c.getRecordTypeInfosByName().get('Product Order Customer Activity').getRecordTypeId();
        for(Product_Order__c productOrder:productOrderList){
            Customer_Task__c Customer_Task = new Customer_Task__c();
            Customer_Task.Type__c='Upload Creative Assets';
            Customer_Task.Due_Date__c=Date.today(); 
            Customer_Task.Status__c='New';
            Customer_Task.RecordTypeId = recordTypeId;
            Customer_Task.Product_Order__c=productOrder.Id;
            listOfCustomerTask.add(Customer_Task);
        }
        insert listOfCustomerTask;
        return listOfCustomerTask;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide Customer_Task__c record for the given campaign order.
    * @param        List<Order__c> campaignOrderList
    * @return       List<Customer_Task__c>
    */
    public static List<Customer_Task__c> createCustomerActivityForCampaignOrder(List<Order__c> campaignOrderList){
        List<Customer_Task__c> listOfCustomerTask=new List<Customer_Task__c>();
        Id recordTypeId = Schema.SObjectType.Customer_Task__c.getRecordTypeInfosByName().get('Campaign Order Customer Activity').getRecordTypeId();
        for(Order__c campaignOrder:campaignOrderList){
            Customer_Task__c Customer_Task = new Customer_Task__c();
            Customer_Task.Type__c='Upload Creative Assets';
            Customer_Task.Due_Date__c=Date.today(); 
            Customer_Task.Status__c='New';
            Customer_Task.RecordTypeId = recordTypeId;
            Customer_Task.Campaign_Order__c=campaignOrder.Id;
            listOfCustomerTask.add(Customer_Task);
        }
        insert listOfCustomerTask;
        return listOfCustomerTask;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide Customer_Role_Access__c record for testing.
    * @param        List<String> roles
    * @return       List<Customer_Role_Access__c>
    */
    public static List<Customer_Role_Access__c> createCustomerRoleAccess(List<String> roles){
        Set<String> contactRoles = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Customer_Role_Access__c.Contact_Role__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            contactRoles.add(f.getValue());
        }
        List<Customer_Role_Access__c> customerRoleAccesLsit= new List<Customer_Role_Access__c>();
        Customer_Role_Access__c customerRoleAccess;
        for(String role : roles){
            if(contactRoles.contains(role)){
                customerRoleAccess = new Customer_Role_Access__c();
                customerRoleAccess.Account_Access__c = 'Public Read';
                customerRoleAccess.Community_User_Profile__c = 'NewsXtend My Account Community Read Only Login';
                customerRoleAccess.Contact_Role__c = role;
                customerRoleAccess.Customer_Activity_Access__c = 'Public Read';
                customerRoleAccess.Proof_Access__c = 'Public Read';
                customerRoleAccesLsit.add(customerRoleAccess);
            }
        }
        return customerRoleAccesLsit;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide proof ad record for testing.
    * @param        List<SocialCampaign__c> proofList
    * @return       List<SocialAd__c>
    */
    public static List<SocialAd__c> createProofAd(List<SocialCampaign__c> proofList){
        List<SocialAd__c> listOfSocialAd=new List<SocialAd__c>();
        for(SocialCampaign__c proof:proofList){
            SocialAd__c socialAd = new SocialAd__c();
            socialAd.Ad_Headline__c='Social Ad';
            socialAd.Ad_Link__c ='www.test.com'; 
            socialAd.Ad_Type__c ='Brand Awareness';
            socialAd.Display_Ad_Link__c='New';
            socialAd.Creative_Type__c='Single image';
            socialAd.Button_Type__c ='Download';
            socialAd.Ad_Text__c='Test Text'; 
            socialAd.Social_Campaign__c=proof.Id;
            listOfSocialAd.add(socialAd);
        }
        insert listOfSocialAd;
        return listOfSocialAd;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-09-25
    * @description  This method will provide proof ad content record for testing.
    * @param        List<SocialAd__c> proofAdList
    * @return       List<Social_Ad_Content__c>
    */
    public static List<Social_Ad_Content__c> createProofAdContent(List<SocialAd__c> proofAdList){
        List<Social_Ad_Content__c> listOfSocialAdContent=new List<Social_Ad_Content__c>();
        for(SocialAd__c proofAd:proofAdList){
            Social_Ad_Content__c social_Ad_Content = new Social_Ad_Content__c();
            social_Ad_Content.Ad_Headline__c='Social Ad';
            social_Ad_Content.Ad_Link__c='www.test.com';
            social_Ad_Content.Display_Order__c=1.0;
            social_Ad_Content.File_Name__c='testFile';
            social_Ad_Content.File_Size__c=10;
            social_Ad_Content.File_Type__c='image/jpeg';
            social_Ad_Content.GoogleDrive_File_Id__c='test';
            social_Ad_Content.Social_Ad__c=proofAd.Id;
            listOfSocialAdContent.add(social_Ad_Content);
        }
        insert listOfSocialAdContent;
        return listOfSocialAdContent;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-09-25
    * @description  This method will create a record of PortalUser.
    * @param        Contact contact
    * @return       User
    */
    public static User createPortalUser(Contact contact){
        Profile profile = [SELECT Id,name FROM profile WHERE name = 'NewsXtend My Account Community Read Only Login'];
        User newCommunitiesUser =  new User();
        newCommunitiesUser.contactId=contact.Id;
        newCommunitiesUser.username=contact.Email + '.newsxtend';
        newCommunitiesUser.firstname=contact.FirstName;
        newCommunitiesUser.lastname=contact.LastName;
        newCommunitiesUser.email=contact.Email;
        newCommunitiesUser.communityNickname = contact.LastName + '_'+Math.random();
        newCommunitiesUser.alias = string.valueof(contact.FirstName.substring(0,1) + contact.LastName.substring(0,1) + Math.random() ).substring(0,5);
        newCommunitiesUser.profileid = profile.Id;
        newCommunitiesUser.emailencodingkey='ISO-8859-1';
        newCommunitiesUser.languagelocalekey='en_US'; 
        newCommunitiesUser.localesidkey='en_AU';
        newCommunitiesUser.timezonesidkey='Australia/Sydney';
        insert newCommunitiesUser;
        return newCommunitiesUser;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-09-25
    * @description  This method will create a record of feed comment.
    * @param        Id ParentId,String comment
    * @return       FeedComment
    */
    public static FeedComment createFeedComment(Id ParentId,String comment){
        FeedItem item = new FeedItem(ParentId = ParentId,body = 'Test',type = 'TextPost');
        insert item;
        FeedComment feedComment =  new FeedComment();
        feedComment.feedItemId = item.Id;
        feedComment.CommentBody = comment;
        insert feedComment;
        return feedComment;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-09-25
    * @description  This method will create a record of custom setting to diable all NXX2 triggers.
    * @param        NA
    * @return       void
    */
    public static void disableAllTriggerDuringTesting(){
        NXX2_TriggerSettings__c cs = new NXX2_TriggerSettings__c();
        cs.Name='Test1';
        cs.AccountTriggerDisabled__c = true; 
        cs.ContactTriggerDisabled__c = true; 
        cs.CustomerActivityTriggerDisabled__c =true; 
        cs.CustomerRoleAccessTriggerDisabled__c =true;
        cs.OpportunityTriggerDisabled__c =true; 
        cs.ProofTriggerDisabled__c = true;
        cs.FeedCommentTriggerDisabled__c = false;
        cs.UserTriggerDisabled__c = true;
        insert cs;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-09-25
    * @description  This method will create a record of NXX2_Proofs_Setting__c.
    * @param        NA
    * @return       void
    */
    public static void insertProofSetting(){
        NXX2_Proofs_Setting__c  cs = new NXX2_Proofs_Setting__c ();
        cs.Name='Test1';
        cs.Approve_Task_After_X_Days__c = 3; 
        cs.Number_Of_Approval_Email_To_Sent__c = 3;
        insert cs;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_Task_Staging__c.
    * @param        NA
    * @return       void
    */
    public static void insertStagingTasks(List<Product_Order__c> pos){
        List<NXX2_Task_Staging__c> stagingTasks = new List<NXX2_Task_Staging__c>();
        for(Product_Order__c po : pos){
            stagingTasks.add(new NXX2_Task_Staging__c(
                Campaign_Id__c = po.id + 'prooftest',
                External_Id__c = po.id + 'tasktest',
                Type__c = po.Fulfillment_Type__c == 'Display' ? 'DISPLAY_PROOF' : 'SOCIAL_PROOF',
                Product_Order__c = po.Name
            ));
        }
        insert stagingTasks;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_Proof_Staging__c.
    * @param        NA
    * @return       List<NXX2_Proof_Staging__c>
    */
    public static List<NXX2_Proof_Staging__c> insertStagingProofs(List<Product_Order__c> pos){
        List<NXX2_Proof_Staging__c> stagingProofs = new List<NXX2_Proof_Staging__c>();
        for(Product_Order__c po : pos){
            stagingProofs.add(new NXX2_Proof_Staging__c(
                External_Id__c = po.id + 'prooftest',
                Name = po.Name + '-test'
            ));
        }
        insert stagingProofs;
        return stagingProofs;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_ProofAd_Staging__c.
    * @param        NA
    * @return       List<NXX2_ProofAd_Staging__c>
    */
    public static List<NXX2_ProofAd_Staging__c> insertStagingProofAds(List<Product_Order__c> pos){
        List<NXX2_ProofAd_Staging__c> stagingProofAds = new List<NXX2_ProofAd_Staging__c>();
        for(Product_Order__c po : pos){
            stagingProofAds.add(new NXX2_ProofAd_Staging__c(
                Campaign_Id__c = po.id + 'prooftest',
                Headline__c = 'headline-test',
                Type__c = 'LEAD_GENERATION',
                Creative_Type__c = 'SLIDESHOW',
                External_Id__c = po.id + 'proofAdtest',
                Link__c = 'https://test.com',
                Link_Desc__c = 'test',
                Full_Text__c = 'test'
            ));
        }
        insert stagingProofAds;
        return stagingProofAds;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_Asset_Staging__c.
    * @param        NA
    * @return       void
    */
    public static void insertStagingAssets(List<NXX2_ProofAd_Staging__c> proofAds,List<NXX2_Proof_Staging__c> proofs,Boolean forProof){
        List<NXX2_Asset_Staging__c> stagingAssets = new List<NXX2_Asset_Staging__c>();
        if(forProof){
            for(NXX2_Proof_Staging__c proof : proofs){
                stagingAssets.add(new NXX2_Asset_Staging__c(
                    Campaign_Id__c = proof.External_Id__c,
                    Headline__c = 'headline-test',
                    Parent_Id__c = proof.External_Id__c,
                    Content_Type__c = 'image/png',
                    External_Id__c = proof.id,
                    File_Name__c = 'test',
                    GUID__c = 'test',
                    Google_File_Id__c = 'test'
                ));
            }
        }else{
            for(NXX2_ProofAd_Staging__c proofAd : proofAds){
                stagingAssets.add(new NXX2_Asset_Staging__c(
                    Campaign_Id__c = proofAd.Campaign_Id__c,
                    Headline__c = 'headline-test',
                    Parent_Id__c = proofAd.External_Id__c,
                    Content_Type__c = 'image/png',
                    External_Id__c = proofAd.id,
                    File_Name__c = 'test',
                    GUID__c = 'test',
                    Google_File_Id__c = 'test'
                ));
            }
        }
        insert stagingAssets;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_SocialForm_Staging__c.
    * @param        NA
    * @return       void
    */
    public static void insertStagingSocialForm(List<NXX2_ProofAd_Staging__c> proofAds){
        List<NXX2_SocialForm_Staging__c> stagingSocialForms = new List<NXX2_SocialForm_Staging__c>();
        for(NXX2_ProofAd_Staging__c proofAd : proofAds){
            stagingSocialForms.add(new NXX2_SocialForm_Staging__c(
                Campaign_Id__c = proofAd.Campaign_Id__c,
                Thankyou_Url__c = 'image/png',
                External_Id__c = proofAd.id + 'socialform',
                SocialForm_Name__c = 'test',
                Privacy_Url__c = 'test',
                Client_Criteria__c = 'test'
            ));
        }
        insert stagingSocialForms;
    }
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_Task_Staging__c.
    * @param        NA
    * @return       void
    */
    public static void insertErrorStagingTasks(List<Product_Order__c> pos){
        List<NXX2_Task_Staging__c> stagingTasks = new List<NXX2_Task_Staging__c>();
        for(Product_Order__c po : pos){
            stagingTasks.add(new NXX2_Task_Staging__c(
                Campaign_Id__c = po.id + 'prooftest',
                External_Id__c = po.id + 'tasktest',
                Has_Merged__c = true,
                Processing_Status__c = 'Error',
                Error_Message__c = 'Exception Occured!',
                Type__c = po.Fulfillment_Type__c == 'Display' ? 'DISPLAY_PROOF' : 'SOCIAL_PROOF',
                Product_Order__c = po.Name
            ));
        }
        insert stagingTasks;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_Proof_Staging__c.
    * @param        NA
    * @return       List<NXX2_Proof_Staging__c>
    */
    public static List<NXX2_Proof_Staging__c> insertErrorStagingProofs(List<Product_Order__c> pos){
        List<NXX2_Proof_Staging__c> stagingProofs = new List<NXX2_Proof_Staging__c>();
        for(Product_Order__c po : pos){
            stagingProofs.add(new NXX2_Proof_Staging__c(
                External_Id__c = po.id + 'prooftest',
                Has_Merged__c = true,
                Processing_Status__c = 'Error',
                Error_Message__c = 'Exception Occured!',
                Name = po.Name + '-test'
            ));
        }
        insert stagingProofs;
        return stagingProofs;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_ProofAd_Staging__c.
    * @param        NA
    * @return       List<NXX2_ProofAd_Staging__c>
    */
    public static List<NXX2_ProofAd_Staging__c> insertErrorStagingProofAds(List<Product_Order__c> pos){
        List<NXX2_ProofAd_Staging__c> stagingProofAds = new List<NXX2_ProofAd_Staging__c>();
        for(Product_Order__c po : pos){
            stagingProofAds.add(new NXX2_ProofAd_Staging__c(
                Campaign_Id__c = po.id + 'prooftest',
                Headline__c = 'headline-test',
                Type__c = 'LEAD_GENERATION',
                Creative_Type__c = 'SLIDESHOW',
                External_Id__c = po.id + 'proofAdtest',
                Link__c = 'https://test.com',
                Link_Desc__c = 'test',
                Full_Text__c = 'test',
                Has_Merged__c = true,
                Processing_Status__c = 'Error',
                Error_Message__c = 'No related social ad'
            ));
        }
        insert stagingProofAds;
        return stagingProofAds;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
* @description  This method will create records of NXX2_Asset_Staging__c.
* @param        NA
* @return       void
*/
    public static void insertErrorStagingAssets(List<NXX2_ProofAd_Staging__c> proofAds,List<NXX2_Proof_Staging__c> proofs,Boolean forProof){
        List<NXX2_Asset_Staging__c> stagingAssets = new List<NXX2_Asset_Staging__c>();
        if(forProof){
            for(NXX2_Proof_Staging__c proof : proofs){
                stagingAssets.add(new NXX2_Asset_Staging__c(
                    Campaign_Id__c = proof.External_Id__c,
                    Headline__c = 'headline-test',
                    Parent_Id__c = proof.External_Id__c,
                    Content_Type__c = 'image/png',
                    External_Id__c = proof.id,
                    File_Name__c = 'test',
                    GUID__c = 'test',
                    Google_File_Id__c = 'test',
                    Has_Merged__c = true,
                    Processing_Status__c = 'Error',
                    Error_Message__c = 'Parent Id do not have any related object.'
                ));
            }
        }else{
            for(NXX2_ProofAd_Staging__c proofAd : proofAds){
                stagingAssets.add(new NXX2_Asset_Staging__c(
                    Campaign_Id__c = proofAd.Campaign_Id__c,
                    Headline__c = 'headline-test',
                    Parent_Id__c = proofAd.External_Id__c,
                    Content_Type__c = 'image/png',
                    External_Id__c = proofAd.id,
                    File_Name__c = 'test',
                    GUID__c = 'test',
                    Google_File_Id__c = 'test',
                    Has_Merged__c = true,
                    Processing_Status__c = 'Error',
                    Error_Message__c = 'Parent Id do not have any related object.'
                ));
            }
        }
        insert stagingAssets;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  This method will create records of NXX2_SocialForm_Staging__c.
    * @param        NA
    * @return       void
    */
    public static void insertErrorStagingSocialForm(List<NXX2_ProofAd_Staging__c> proofAds){
        List<NXX2_SocialForm_Staging__c> stagingSocialForms = new List<NXX2_SocialForm_Staging__c>();
        for(NXX2_ProofAd_Staging__c proofAd : proofAds){
            stagingSocialForms.add(new NXX2_SocialForm_Staging__c(
                Campaign_Id__c = proofAd.Campaign_Id__c,
                Thankyou_Url__c = 'image/png',
                External_Id__c = proofAd.id + 'socialform',
                SocialForm_Name__c = 'test',
                Privacy_Url__c = 'test',
                Client_Criteria__c = 'test',
                Has_Merged__c = true,
                Processing_Status__c = 'Error',
                Error_Message__c = 'No related social ad'
            ));
        }
        insert stagingSocialForms;
    }
}