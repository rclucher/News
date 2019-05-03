/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Bluewolf.com
 * Description: This class contains data creating and other utility methods for Test Classes
 * History:
 *
 * 2016-01-15  Atul Gupta  Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - NONE
 // 2018-04-27  David Scullion - added Reveune Group for Account creation and Opportunity Creation
 // 2018-10-03  Hari Kundrapu - added createEmmaRecords to create records in EMMA_Readership_and_Circulation_Data__c
 // 2019-03-20  David Scullion - added values for Ringlead DMS Status fields for Leads and Contacts to resolve SFE-1069
 ---------------------------------------------------------*/
@isTest
public class TestDataFactory 
{
    
    //SFE-766 2015-11-24 atul.gupta@bluewolfgroup.com - Bulk Exception Record creation
    public static List<Exception_Record__c> createExceptionRecords(Integer numberOfrecords, String actionType){
        
        List<Exception_Record__c> exceptionRecordsList = new List<Exception_Record__c>();
        
        for(Integer i = 0; i < numberOfrecords; i++){
            Exception_Record__c rec = new Exception_Record__c();
            rec.Action_Type__c = actionType;//'TCSTAS';
            exceptionRecordsList.add(rec);
        }
        return exceptionRecordsList;
    }
    
    //SFE-766 2015-11-25 atul.gupta@bluewolfgroup.com - create single Case
    public static Case createSingleCase(String recordTypeStr, String accntId){
        Case caseOne = new Case();
        caseOne.RecordtypeId =  recordTypeStr;
        caseOne.AccountId = accntId;
        return caseOne;
    }
    
     // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
        //Bulk Exception Record creation with Account Id
    public static List<Exception_Record__c> createExceptionRecords(Integer numberOfrecords, String actionType, Id accountId){
        
        List<Exception_Record__c> exceptionRecordsList = new List<Exception_Record__c>();
        
        for(Integer i = 0; i < numberOfrecords; i++){
            Exception_Record__c rec = new Exception_Record__c();
            rec.Action_Type__c = 'TCSTAS';
            rec.Account__c = accountId;            
            exceptionRecordsList.add(rec);
        }
        return exceptionRecordsList;
    }    
    
    // Attachment creation
    public static List<Attachment> createAttachment(Integer numberOfAttachments, String contentType, String parentId)
    {
        Blob b = Blob.valueOf('Test Data');  
        
        List<Attachment> attachments = new List<Attachment>();
        
        for(Integer i = 0; i < numberOfAttachments; i++)
        {
            Attachment attachment = new Attachment();
            attachment.Name = 'test attachment';
            attachment.Description = 'this is a test attachment';
            attachment.ContentType = contentType;
            attachment.ParentId = parentId;
            attachment.Body = b;
            attachments.add(attachment);
        }
        
        return attachments;
    }       
    
    //Account creation
    public static List<Account> createAccounts( Integer numberOfAccounts, boolean isPersonAccount) {
        List<Account> accounts = new List<Account>();
        for ( Integer i = 0 ; i < numberOfAccounts ; i++ ) {
            
            Account tmpAccount = new Account();
            
            if(isPersonAccount)
            {
                tmpAccount.firstname = 'Test Account ';
                tmpAccount.lastname = i + ' Account';
                tmpAccount.PersonEmail = 'noreplay' + i + '@email.com';
                tmpAccount.PersonMailingStreet = i + 'Holst Rd';
                tmpAccount.PersonMailingCity = 'Testville';
                tmpAccount.PersonMailingState = 'NSW';
                tmpAccount.PersonMailingPostalCode = '200' + i;                
            }
            else
            {
                
                tmpAccount.Name = 'Test Account ' + String.valueOf(i);
                tmpAccount.BillingPostalCode='2000';
                tmpAccount.BillingCountry = 'Australia';
                tmpAccount.BillingState = 'NSW';
                tmpAccount.BillingCity = 'Sydney';
                tmpAccount.BillingStreet = 'George Street';
                tmpAccount.DPID_Primary_Address__c = '555' + String.valueOf(i);
                tmpAccount.AccountNumber = '12345678901';
                tmpAccount.Phone = '61021234567' + String.valueOf(i);
                tmpAccount.Revenue_Group__c = 'Classified - Marketplace';
                tmpAccount.No_Parent_Account__c = true;
            } 
            
            tmpAccount.Total_Customer_Spend__c = 0;
            tmpAccount.Total_Agency_Spend__c = 0;
            tmpAccount.Total_Group_Spend__c = 0;
            
            accounts.add( tmpAccount);            
        }
        return accounts;
    }
    
    // create single account for TGS and TCS testing
    public static Account createSingleAccount(Account parentAcct, decimal hierarchyLevel, String recordTypeId, decimal tcs, decimal tas)
    {
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.Phone = '123456789';
        acct.Revenue_Group__c = 'Classified - Employment';
        acct.Type = 'Account Managed';
        acct.Account_Type__c = ' General';
        acct.Hierarchy_Level_Test__c = hierarchyLevel;
        if(recordTypeId != null)
        {
            acct.RecordTypeId = recordTypeId;
        }
        if(parentAcct != null)
        {
            acct.ParentId = parentAcct.Id;
        }
        else
        {
            acct.No_Parent_Account__c = true;
        }
        
        if(tas != null)
        {
            acct.Total_Agency_Spend__c = tas;
        }
        else
        {
            acct.Total_Agency_Spend__c = 0;
        }
        
        if(tcs != null)
        {
            acct.Total_Customer_Spend__c = tcs;
        }
        else
        {
            acct.Total_Customer_Spend__c = 0;
        }
        
        acct.Total_Group_Spend__c = 0;
        
        acct.Account_Last_Modified__c = datetime.now();
        return acct;
    }
    
    // create single account
    public static List<Account> createAccounts(Integer numOfAccts, String recordTypeId)
    {
        List<Account> accounts = new List<Account>();
        
        for(Integer i = 0; i < numOfAccts; i++)
        {
            Account acct = new Account();
            acct.Name = 'Test Account';
            acct.Phone = '123456789';
            acct.Revenue_Group__c = 'Classified - Employment';
            acct.Type = 'Account Managed';
            acct.Account_Type__c = ' General';
            if(recordTypeId != null)
            {
                acct.RecordTypeId = recordTypeId;
            }
            acct.No_Parent_Account__c = true;
            acct.Total_Customer_Spend__c = 0;
            acct.Total_Agency_Spend__c = 0;
            acct.Total_Group_Spend__c = 0;
            accounts.add(acct);
        }
        return accounts;
    }
    
    // recursively create child accounts related to certain parent account
    public static List<Account> createChildAccounts(List<Account> allAccounts, List<Account> parentAccts, Integer numOfChildren,
                                                    decimal currentLevel, decimal totalLevel, String recordTypeId,
                                                    decimal tcs, decimal tas)
    {
        if(allAccounts != null)
        {
            List<Account> childAccounts = new List<Account>();
            
            for(Account parentAcct : parentAccts)
            {
                for(Integer i = 0; i < numOfChildren; i++)
                {
                    childAccounts.add(TestDataFactory.createSingleAccount(parentAcct, currentLevel, recordTypeId, tcs, tas));
                }
            }
            
            insert childAccounts;
            
            if(currentLevel != null && totalLevel != null &&  currentLevel < totalLevel)
            {
                allAccounts.addAll(TestDataFactory.createChildAccounts(allAccounts, childAccounts,
                                                                       numOfChildren, ++currentLevel, totalLevel, recordTypeId, tcs, tas));
            }
            return childAccounts;
        }
        return null;
    }
    
    /* Added by Darshan Gosar on 27 Nov */
    public static List<Task> createTasks( Integer numberOfTasks, String taskType, Id whatId, Boolean insertFlag)
    {
        List<Task> tasks = new List<Task>();
        
        for ( Integer i = 0 ; i < numberOfTasks ; i++ )
        {
            Task t = new Task(ActivityDate = Date.today().addDays(i));
            t.type = taskType;
            t.WhatId = whatId;
            tasks.add(t);
        }
        
        if(insertFlag)
            insert tasks;
        return tasks;
    }
    
    public static List<Task> createTasks( Integer numberOfTasks)
    {
        List<Task> tasks = new List<Task>();
        
        for ( Integer i = 0 ; i < numberOfTasks ; i++ )
        {
            Task t = new Task(
                ActivityDate = Date.today().addDays(i));
            tasks.add(t);
        }
        
        insert tasks;
        return tasks;
    }
    
    public static List<Lead> createLeads(Integer numberOfLeads)
    {
        List<Lead> leads = new List<Lead>();
        
        for ( Integer i = 0 ; i < numberOfLeads ; i++ )
        {
            Lead ld = new Lead (FirstName = 'sampler', LastName = 'sampleContact' + i);
            ld.Phone = '041211155' + i;
            ld.MobilePhone = '041211166' + i;
            ld.RingLead_DMS_Status__c = 'pending';
            
            leads.add(ld);
        }
        
        return leads;
    }
    
    
    public static List<Contact> createContacts(Integer numberOfContacts, Account account)
    {
        List<Contact> contacts = new List<Contact>();
        
        for ( Integer i = 0 ; i < numberOfContacts ; i++ )
        {
            Contact c = new Contact(
                FirstName = 'User',
                LastName = 'Test ' + String.valueOf(i),
                AccountId = account.Id,
                Title = 'Test title',
                Contact_Status__c = 'Active',
                Email = 'test'+i+'@test.test',
                RingLead_DMS_Status__c = 'pending'
            );
            
            contacts.add(c);
        }
        
        return contacts;
    }
    
    public static List<UserRole> createUserRoles(Integer numberOfRoles)
    {
        List<UserRole> userRoles = new List<UserRole>();
        
        for ( Integer i = 0 ; i < numberOfRoles ; i++ )
        {
            UserRole userRole = new UserRole();
            userRole.Name = 'test role ' + String.valueOf(i);
            userRoles.add(userRole);
        }
        
        insert userRoles;
        return userRoles;
    }
    
    public static List<User> createUsers( Integer numberOfUsers, String profileName, 
                                         List<UserRole> userRoles, Boolean manageAllWalkin, Boolean isForecastEnabledUser)
    {
        List<User> users = new List<User>();
        String profileId = [Select p.Id From Profile p where name = :profileName LIMIT 1].id;
        
        for ( Integer i = 0 ; i < numberOfUsers ; i++ )
        {
            
            Double r = Math.random() * 1000;
            User tmpUser = new User(    firstname = 'User',
                                    lastname = i + r.intValue() + ' TestUser',
                                    alias = 'tu' + i+ r.intValue(),
                                    Username = 'testuser' + i + r.intValue() +  '@email.com.au.newscorp',
                                    CommunityNickname = 'testuser' + i + r.intValue() + 'AtemailDotComAu',
                                    Email = 'user' + i+ r.intValue() + '@email.com.au',
                                    TimeZoneSidKey = 'GMT',
                                    LocaleSidKey = 'en_AU',
                                    EmailEncodingKey = 'ISO-8859-1',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = profileId,
                                    Network_Username__c = 'testuser' + i + r.intValue()
                                   );
            
            if(userRoles != null && userRoles.size() > 0)
                tmpUser.UserRoleId = userRoles[0].Id;
            
            tmpUser.ForecastEnabled = isForecastEnabledUser;
            tmpUser.IsActive = true;
            users.add(tmpUser);
        }
        
        return users;
    }
    
    public static User createUser(String profileName, String lastName, String firstName, 
                                  UserRole userRole, Boolean manageAllWalkin, Boolean isForecastEnabledUser)
    {
        String profileId = [Select p.Id From Profile p where name = :profileName LIMIT 1].id;
        
        Double r = Math.random() * 1000;
        User user = new User();
        
        user.lastName = lastName;
        user.firstName = firstName;
        user.alias = 'sinTUser';
        user.Username = 'singleTestUser@email.com';
        user.CommunityNickname = 'sinTUser';
        user.Email = 'singleTestUser@email.com';
        user.TimeZoneSidKey = 'GMT';
        user.LocaleSidKey = 'en_AU';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.ProfileId = profileId;
        user.Network_Username__c = 'sinTUser';
        
        if(userRole != null)
            user.UserRoleId = userRole.Id;
        
        user.ForecastEnabled = isForecastEnabledUser;
        user.IsActive = true;
        
        return user;
    }
    
    public static List<Group> createGroups(Integer numberOfGroups, String groupType)
    {
        List<Group> groups = new List<Group>();
        
        for ( Integer i = 0 ; i < numberOfGroups ; i++ )
        {
            Group g = new Group();
            g.Name = 'Queue User ' + i;
            g.Email = 'queue' + i + '@email.com';
            g.Type = groupType;
            groups.add(g);
        }
        insert groups;
        return groups;
    }
    
    public static List<Case> createCases(Integer numOfCases, Opportunity opportunity, Booking__c booking)
    {
        List<Case> cases = new List<Case>();
        
        for(Integer i = 0; i < numOfCases; i++)
        {
            Case c = new Case();
            if(opportunity != null)
            {
                c.Opportunity__c = opportunity.Id;
            }
            if(booking != null)
            {
                c.Booking__c = booking.Id;
            }
            cases.add(c);
        }
        
        return cases;
    }
    
    public static EmailMessage createEmailMessage(Case c, String toAddress)
    {
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.ParentId = c.Id;
        emailMessage.FromAddress = 'test@email.com';
        emailMessage.ToAddress = toAddress;
        emailMessage.TextBody = 'test body';
        return emailMessage;
    }
    
    public static void createEmailCaseOriginMappings(List<Group> groups)
    {
        List<Email_Case_Origin_Mapping__c> emailCaseOriginMappings = new List<Email_Case_Origin_Mapping__c>();
        
        for(Group g : groups)
        {
            Email_Case_Origin_Mapping__c emailCaseOriginMapping = new Email_Case_Origin_Mapping__c();
            emailCaseOriginMapping.Name = g.Name;
            emailCaseOriginMapping.Case_Origin__c = 'Email - Inbound for Routing';
            emailCaseOriginMapping.Email__c = g.Email;
            // 2015-11-17 SFE-688 - Added new mandatory field 'Email_Alias__c'
            emailCaseOriginMapping.Email_Alias__c = g.Email;
            emailCaseOriginMapping.External_Id__c = g.Name;
            emailCaseOriginMappings.add(emailCaseOriginMapping);
        }
        
        insert emailCaseOriginMappings;
    }
    
    public static List<Portfolio__c> createPortfolios(List<Account> accounts, List<User> users)
    {
        List<Portfolio__c> portofolios = new List<Portfolio__c>();
        
        for(Account a : accounts)
        {
            for(User u : users)
            {
                Portfolio__c portfolio = new Portfolio__c();
                portfolio.Account__c = a.Id;
                portfolio.User__c = u.Id;
                portfolio.Team_Role__c = 'Sales Manager';
                portofolios.add(portfolio);
            }
        }
        
        insert portofolios;
        return portofolios;
    }
    
    
    public static List<Product2> createProducts(Integer numberOfProducts)
    {
        return createProducts(numberOfProducts, null);
    }
    
    
    public static List<Product2> createProducts(Integer numberOfProducts, String cyberAdDivision)
    {
        List<Product2> products = new List<Product2>();
        
        // 2015-11-23 SFE-766 louis.wang@bluewolf.com
        //  - Make Product2.Exernal_Id__c (workflow) unique, if this funciton is called more than once in a Test Class, so it won't error out.
        String randomString = string.valueOf(Math.random());

        for ( Integer i = 0 ; i < numberOfProducts ; i++ )
        {
            String iString = String.valueof(i);
            String description;
            if(Math.mod(i, 2) == 1)
                description = 'Test Odd Description';
            else
                description = 'Test Even Description';
            

            Product2 product = new Product2(   Name = 'Test Product ' + iString,
                                            Family = 'Family ' + iString + randomString,
                                            Category__c = 'Category ' + iString,
                                            Region__c = 'Region ' + iString,
                                            Description = description,
                                            IsActive = true,
                                            IsTest__c = true,
                                            CanUseRevenueSchedule = true);
            
            if(cyberAdDivision!=null)
            {
                product.Booking_System__c = 'CyberAd ' + cyberAdDivision;
            }
            
            
            products.add(product);
        }
        insert products;
        return products;
    }
    
    public static List<Product2> createProductsWithFamily(Integer numberOfProducts)
    {
        // get list of product families
        List<String> productFamilies = new List<String>();
        
        for( Schema.PicklistEntry f : Product2.Family.getDescribe().getPicklistValues())
        {
            productFamilies.add(f.getLabel());
        }
        
        system.debug('===productFamilies=== ' + productFamilies);
        
        List<Product2> products = new List<Product2>();
        
        for ( Integer i = 0 ; i < numberOfProducts ; i++ )
        {
            String iString = String.valueof(i);
            String description;
            if(Math.mod(i, 2) == 1)
                description = 'Test Odd Description';
            else
                description = 'Test Even Description';
            
            Integer familyIndex = Math.mod(i, 4);
            
            Product2 product = new Product2 (
                Name = 'Test Product ' + iString,
                Family = productFamilies.get(familyIndex),
                Category__c = 'Category ' + iString,
                Region__c = 'Region ' + iString,
                Description = description,
                IsActive = true,
                IsTest__c = true,
                CanUseRevenueSchedule = true
            );
            
            products.add(product);
        }
        return products;
    }
    
    public static List<String> createStringList(Integer numOfElements, String preName)
    {
        List<String> stringList = new List<String>();
        
        for ( Integer i = 0 ; i < numOfElements ; i++ )
        {
            String stringElement = preName + String.valueOf(i);
            stringList.add(stringElement);
        }
        
        return stringList;
    }
    
    // TODO: remove this test method later
    public static List<Opportunity> createOpportunities(Integer numberOfOpportunities, Pricebook2 pricebook, Account account)
    {
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for ( Integer i = 0 ; i < numberOfOpportunities ; i++ )
        {
            Opportunity opportunity = new Opportunity(
                Name = 'Test Opportunity ' + String.valueof(i),
                CloseDate = date.today().addDays(i),
                StageName = 'Qualify Opportunity',
                Classification__c = 'New Business',
                Description = 'Test Opportunity',
                Revenue_Group__c = 'House',
                Is_Test__c = true,
                Campaign_Start_Date__c = date.today().addMonths(1)
            );
            
            if(pricebook != null)
            {
                opportunity.Pricebook2Id = pricebook.Id;
                
            }
            //SFE-766 2015-11-26 atul.gupta@bluewolfgroup.com - added the else condition
            else{
                opportunity.Pricebook2Id = Test.getStandardPricebookId();
            }
            
            if(account != null)
            {
                opportunity.AccountId = account.Id;
            }
            
            opportunities.add(opportunity);
        }
        return opportunities;
    }
    
    public static List<Opportunity> createOpportunitiesNew(Integer numberOfOpportunities, Id pricebookId, Account account)
    {
        List<Opportunity> output = createOpportunities_withContact(numberOfOpportunities, pricebookId, account, null);
        return output;
    }

    // 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    public static List<Opportunity> createOpportunities_withContact(Integer numberOfOpportunities, Id pricebookId, Account account, Contact cont)
    {
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for ( Integer i = 0 ; i < numberOfOpportunities ; i++ )
        {
            Opportunity opportunity = new Opportunity(
                Name = 'Test Opportunity ' + String.valueof(i),
                CloseDate = date.today().addDays(i),
                StageName = 'Qualify Opportunity',
                Classification__c = 'New Business',
                Description = 'Test Opportunity',
                Is_Test__c = true,
                Campaign_Start_Date__c = date.today().addMonths(1)
            );
            
            if(pricebookId != null)
            {
                opportunity.Pricebook2Id = pricebookId;
            }
            
            if(account != null)
            {
                opportunity.AccountId = account.Id;
            }

            if(cont != null)
            {
                opportunity.Contact__c = cont.Id;
            }
            
            opportunities.add(opportunity);
        }
        return opportunities;
    }
    
    public static void createAddressValidationErrorMessage()
    {
        List<Address_Validation_Error_Message__c> messages = new List<Address_Validation_Error_Message__c>();
        
        Address_Validation_Error_Message__c message = new Address_Validation_Error_Message__c();
        message.Name = 'City';
        message.Message__c = 'Suburb cannot be empty';
        message.External_Id__c = '54564561';
        messages.add(message);
        
        message = new Address_Validation_Error_Message__c();
        message.Name = 'Country';
        message.Message__c = 'Country cannot be empty';
        message.External_Id__c = '54564562';
        messages.add(message);
        
        message = new Address_Validation_Error_Message__c();
        message.Name = 'PostalCode';
        message.Message__c = 'Postcode cannot be empty';
        message.External_Id__c = '54564563';
        messages.add(message);
        
        message = new Address_Validation_Error_Message__c();
        message.Name = 'State';
        message.Message__c = 'State cannot be empty';
        message.External_Id__c = '54564564';
        messages.add(message);
        
        message = new Address_Validation_Error_Message__c();
        message.Name = 'Street';
        message.Message__c = 'Street cannot be empty';
        message.External_Id__c = '54564565';
        messages.add(message);
        
        insert messages;
    }
    
    public static List<OpportunityLineItem> createOpportunityLineItems(List<Opportunity> opportunities,
                                                                       List<Product2> products,
                                                                       List<PricebookEntry> pricebookEntries,
                                                                       Id salesOrderId)
    {
        Map<String, String> priceBookEntryIdMapByProductId = new Map<String, String>();
        
        // Updated by Bohao Chen on 30/05/2014
        // Need to check if pricebook is standard pricebook
        List<PricebookEntry> entryList = [Select Id, Pricebook2Id, Pricebook2.IsStandard, Product2Id From PricebookEntry Where Id IN: pricebookEntries];
        
        system.debug('@entryList: ' + entryList);
        
        String staPricebookId = Test.getStandardPricebookId();

        for(PricebookEntry pbEntry : entryList)
        {        
            system.debug('@is standard pricebook? ' + pbEntry.Pricebook2.IsStandard);
            
            //if(pbEntry.Pricebook2.IsStandard) // Updated by Bohao Chen on 30/05/2014
            if(pbEntry.Pricebook2Id == staPricebookId)
            {
                priceBookEntryIdMapByProductId.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        
        
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        
        for(Opportunity opportunity : opportunities)
        {
            for(Product2 p : products)
            {
                OpportunityLineItem opprtLineItem = new OpportunityLineItem(
                    UnitPrice = 2000,
                    PricebookEntryId = priceBookEntryIdMapByProductId.get(p.Id),
                    OpportunityId = opportunity.Id,
                    of_Periods__c = 1,
                    Is_Test__c = true,
                    ServiceDate = Date.today(),
                    Quantity = 1);
                
                if(salesOrderId != null)
                {
                    opprtLineItem.Sales_Order__c = salesOrderId;
                }
                opportunityLineItems.add(opprtLineItem);
            }
        }
        
        return opportunityLineItems;
    }
    
    public static List<OpportunityLineItemSchedule> createOpportunityLineItemSchedules(Integer numOfScheduleItems, List<OpportunityLineItem> opptyLineItems, Date startDate)
    {
        List<OpportunityLineItemSchedule> oliss = new List<OpportunityLineItemSchedule>();
        
        for(OpportunityLineItem opptyLineItem : opptyLineItems)
        {
            for(Integer i = 0; i < numOfScheduleItems; i++)
            {
                OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                olis.Revenue = 100;
                olis.OpportunityLineItemId = opptyLineItem.Id;
                olis.ScheduleDate = startDate.addDays(7 * i);
                olis.Type = 'Revenue';
                oliss.add(olis);
            }
        }
        return oliss;
    }
    
    public static List<PricebookEntry> createPricebookEntryData (Pricebook2 standard, Pricebook2 newPricebook, List<Product2> products)
    {
        List<PricebookEntry> pricebooksList = new List<PricebookEntry>();
        
        PricebookEntry one, ret;

        // added by Tim Fabros 19 / 08 / 2014
        // added standard pricebook
        Id stdPricebookId = Test.getStandardPricebookId();

        for(Product2 p : products)
        {
            if(standard <> null){
                one = new PricebookEntry();
                system.debug('@@newPricebook : ' + newPricebook);
                one.pricebook2Id = standard.Id;
                one.product2id = p.id;
                one.unitprice = 1249.0;
                one.isactive = true;            
                pricebooksList.add(one);
            }
            ret = new PricebookEntry();
            if(newPricebook <> null){
                ret.pricebook2Id = newPricebook.Id; 
            }else{
                ret.pricebook2Id = stdPricebookId;
            }
            ret.product2id = p.id;
            ret.unitprice = 1250.0;
            ret.isactive = true;
            pricebooksList.add(ret);
            
        }
        system.debug('@@pricebooksList : '+ pricebooksList);
        insert pricebooksList;
        return pricebooksList;
    }

    //SFE-766 2015-12-17 atul.gupta@bluewolfgroup.com - to get rid of seeAllData reference from Pricebook Entry code 
       // Referenced by SalesOrderCreateBookingv2_ControlX_Test Class
    public static List<Pricebook2> createCustomPricebookData_Standard(){       
        
        List<Pricebook2> pricebookList = new List<Pricebook2>();        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Name = 'Standard Price Book';
        pricebook.Description = 'Price Book 2009 Products';
        pricebook.IsActive = true;
        pricebookList.add(pricebook);
        
        pricebook = new Pricebook2();
        pricebook.Name = 'Test Pricebook 2';
        pricebook.Description = 'Price Book 2009 Products 2';
        pricebook.IsActive = true;
        pricebookList.add(pricebook);
        
        insert pricebookList;
        
        return pricebookList;
    }
    
    // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
        // New methods createCustomPricebookData & createPricebookEntryData without seeAllData is added & previous methods are removed  
    public static List<Pricebook2> createCustomPricebookData(){       
        
        List<Pricebook2> pricebookList = new List<Pricebook2>();        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Name = 'Test Pricebook';
        pricebook.Description = 'Price Book 2009 Products';
        pricebook.IsActive = true;
        pricebookList.add(pricebook);
        
        pricebook = new Pricebook2();
        pricebook.Name = 'Test Pricebook 2';
        pricebook.Description = 'Price Book 2009 Products 2';
        pricebook.IsActive = true;
        pricebookList.add(pricebook);
        
        insert pricebookList;
        
        return pricebookList;
    }
    
    public static List<PricebookEntry> createPricebookEntryData (Pricebook2 newPricebook, List<Product2> products)
    {
        List<PricebookEntry> pricebooksList = new List<PricebookEntry>();
        
        PricebookEntry one, ret;

        Id stdPricebookId = Test.getStandardPricebookId();
        
        
        for(Product2 p : products)
        {
            one = new PricebookEntry();
            one.pricebook2Id = stdPricebookId; 
            one.product2id = p.id;
            one.unitprice = 1249.0;
            one.isactive = true;            
            pricebooksList.add(one);
            
            if(newPricebook <> null){
                ret = new PricebookEntry();
                ret.pricebook2Id = newPricebook.id;
                ret.product2id = p.id;
                ret.unitprice = 1250.0;
                ret.isactive = true;
                pricebooksList.add(ret);
            }
        }
        
        insert pricebooksList; 
        return pricebooksList;
    }
    
    public static Pricebook2 customPriceBook()
    {
        // Create a custom price book
        Pricebook2 customPriceBook = new Pricebook2(Name= 'Test Pricebook 2', Description = 'Price Book 2009 Products 2', isActive=true);
        insert customPriceBook;
        return customPriceBook;
    }
    
    public static List<PricebookEntry> createPricebookEntryDataNew (List<Product2> products, Pricebook2 customPriceBook)
    {
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id stdPricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> pricebooksList = new List<PricebookEntry>();
        
        PricebookEntry one, ret;
        
        for(Product2 p : products)
        {
            one = new PricebookEntry();
            one.pricebook2Id = stdPricebookId;
            one.product2id = p.id;
            one.unitprice = 1249.0;
            one.isactive = true;            
            pricebooksList.add(one);
            
            ret = new PricebookEntry();
            ret.pricebook2Id = customPriceBook.Id;
            ret.product2id = p.id;
            ret.unitprice = 1250.0;
            ret.isactive = true;
            pricebooksList.add(ret);
            
        }
        
        insert pricebooksList;
        return pricebooksList;
    }
    
    public static map<id,list<CyberAd_User_Credential__c>> createCyberAdUserCredentials( Integer numberOfcredentialsPerUser, list<User> users) {
        map<id,list<CyberAd_User_Credential__c>> userCredentials = new map<id,list<CyberAd_User_Credential__c>>();
        
        for (User u : users)
        {
            for ( Integer i = 0 ; i < numberOfcredentialsPerUser ; i++ ) {
                CyberAd_User_Credential__c tmpUserCredential =
                    new CyberAd_User_Credential__c( User__c = u.id,
                                                   CyberAd_Username__c = 'CyberAdUser' + i,
                                                   CyberAd_Password__c = 'PsW#123' + i,
                                                   Division__c = 'tu' + i,
                                                   Database__c = 'DB' + i,
                                                   Publication__c = 'PB' + i
                                                  );
                if(userCredentials.containsKey(u.id))
                {
                    userCredentials.get(u.id).add(tmpUserCredential);
                }
                else
                {
                    userCredentials.put(u.id,new list<CyberAd_User_Credential__c>{tmpUserCredential});
                }
            }
        }
        return userCredentials;
        
    }
    
    public static void createContactChangeCodes()
    {
        List<Contact_Change_Code__c> contactChangeCodes = new List<Contact_Change_Code__c>();
        
        Contact_Change_Code__c c = new Contact_Change_Code__c();
        
        c.Name = 'A';
        c.Type_Full_Name__c = 'Account Name';
        c.External_Id__c = '54656451';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'AJ';
        c.Type_Full_Name__c = 'Account Name;Job Title';
        c.External_Id__c = '54656452';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'AJS';
        c.Type_Full_Name__c = 'Account Name;Job Title;Status';
        c.External_Id__c = '54656453';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'AS';
        c.Type_Full_Name__c = 'Account Name;Status';
        c.External_Id__c = '54656454';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'J';
        c.Type_Full_Name__c = 'Job Title';
        c.External_Id__c = '54656455';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'JS';
        c.Type_Full_Name__c = 'Job Title;Status';
        c.External_Id__c = '54656456';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'NA';
        c.Type_Full_Name__c = '';
        c.External_Id__c = '54656457';
        contactChangeCodes.add(c);
        
        c = new Contact_Change_Code__c();
        c.Name = 'S';
        c.Type_Full_Name__c = 'Status';
        c.External_Id__c = '54656458';
        contactChangeCodes.add(c);
        
        insert contactChangeCodes;
    }
    
    public static External_Account__c createExternalAccount()
    {
        list<Account> accts = createAccounts( 1, false);
        insert accts;
        
        return  createExternalAccount(accts[0],'Booking_Account', 'T8743264238324', null);
    }

    public static External_Account__c createExternalAccount(Account acct, String recordTypeDeveloperName, String accountNo, External_Account__c parentAccount)
    {
        // 2014-11-13 louis.wang@bluewolf.com - This function ensure the existing function call still works (with 4 parameters).
        return createExternalAccount(acct, recordTypeDeveloperName, accountNo, parentAccount, true);
    }
    
    public static External_Account__c createExternalAccount(Account acct, String recordTypeDeveloperName, String accountNo, External_Account__c parentAccount, boolean toCommitToDB)
    {
        // 2014-11-13 louis.wang@bluewolf.com - Added additional parameter to differentiate whether to commit to DB.
        recordType rt = [SELECT id from RecordType WHERE developerName = :recordTypeDeveloperName AND sObjectType = 'External_Account__c' LIMIT 1];
        External_Account__c ea = new External_Account__c();
      //  External_Account__c eaTest = [select id from External_Account__c Limit 1];
        ea.RecordType = rt;
        ea.Web_Account__c = false;
        ea.Suburb__c = 'Surry Hills';
        ea.Street__c = '2 Holt St';
        ea.Status__c = 'Active';
        ea.Status_As_At__c = System.today();
        ea.State__c = 'NSW';
        
      //  ea.BSA__c = eaTest.Id;
        ea.Post_Code__c = '2010';
        ea.Phone__c = '1234567890';
        ea.Order_Required__c = false;
        ea.name = 'Test External Account';
        ea.First_Name__c = 'Joe';
        ea.Last_Name__c = 'Baraka';
        ea.GST_Exempt__c = false;
        ea.External_Id__c = accountNo;
        ea.Email_Address__c = 'j.baraka@email.com.tt';
        ea.Customer_Account__c = acct.id;
        //ea.BSA__c = acct.id;
        ea.Country__c = 'Australia';
        ea.Confirm_All_Bookings__c = false;
        ea.Account_Type__c = 'Established';
        ea.ABN_Number__c = '82000529457';
        ea.Account_Type__c = 'Ad Agency';
        ea.Status__c = 'Active';
        ea.Account_No__c = accountNo;
        ea.Division__c = 'NWN';
        ea.GBA_Phone_Area_Code__c = 1;
        
        if(parentAccount!=null)
            ea.External_Account__c = parentAccount.id;
    
        if(toCommitToDB)    
            insert ea;

        return ea;
    }
    
    
    public static Sales_Order__c createSalesOrder(String sourceSystem)
    {
        list<Account> accts = createAccounts( 5, false);
        insert accts;
        
        Sales_Order__c s = new Sales_Order__c();
        s.Ad_Taker__c           =   createUsers(1, 'System Administrator', null, null, false)[0].id;
        s.Advertiser_Account__c =   accts[0].id;
        s.Booking_Division__c   =   'GA';
        s.Booking_Type__c       =   'Billign';
        s.Comments__c           =   'Comments';
        s.Creative_Account__c   =   accts[1].id;
        List<Contact> c1 = createContacts(1, accts[1]); //VALIDATION: Sales Order: Placer Account IDEQUALSPlacer Contact: Account Name ID
        insert c1;
        s.Creative_Contact__c   =   c1[0].Id;
        s.External_Account__c   =   createExternalAccount().id;
        s.Payer_Account__c      =   accts[2].id;
        s.Placer_Account__c     =   accts[3].id;
        s.Planner_Account__c    =   accts[4].id;
        List<Contact> c2 = createContacts(1, accts[3]); //VALIDATION: Sales Order: Placer Account IDEQUALSPlacer Contact: Account Name ID
        insert c2;
        s.Contact__c            =   c2[0].Id;
        s.Source_System__c      =   sourceSystem;
        //s.Source_System__c      =   'Cyber';
        s.Status__c             =   'Booking';
        s.Status_As_Of__c       =   system.now();
        s.Type__c               =   'Sales Order';
        
        
        System.debug('*** createSalesOrder:' + s);
        
        insert s;
        return s;
    }
    
    public static List<Sales_Order__c> createSalesOrders(Integer numOfSalesOrders, Account payerAccount,
                                                         Account advertiserAccount, Account placerAccount,
                                                         Contact contact, String bookingSystem)
    {
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
        
        for(Integer i = 0; i < numOfSalesOrders; i++)
        {
            Sales_Order__c salesOrder = new Sales_Order__c();
            if(advertiserAccount != null)
            {
                salesOrder.Advertiser_Account__c = advertiserAccount.Id;
            }
            if(payerAccount != null)
            {
                salesOrder.Payer_Account__c = payerAccount.Id;
            }
            
            if(placerAccount != null)
            {
                salesOrder.Placer_Account__c = placerAccount.Id;
            }
            
            if(contact != null)
            {
                salesOrder.Contact__c = contact.Id;
            }
            
            if(String.isNotBlank(bookingSystem))
            {
                salesOrder.Source_System__c = bookingSystem;
            }
            
            salesOrder.External_Id__c = String.valueOf(math.random());
            
            salesOrders.add(salesOrder);
        }
        
        return salesOrders;
    }
    
    public static Booking__c createBooking(Sales_Order__c so)
    {
        
        Booking__c booking = new Booking__c();

        // added by Tim Fabros 02 / 09 / 2014 - SFE-581
        booking.Name                        = '1234567890';
        booking.Sales_Order__c              =   so.id;
        booking.Booking_Number__c           =   '1234567890';
        booking.CyberAd_AdType__c           =   'Billing';
        booking.Source_System__c            =   'CyberAd';
        //booking.Last_Expiry_Appearance__c =   System.today();
        booking.Third_Party_Created__c      =   System.now();
        booking.Total_Cost_Cyber__c         =   100;
        booking.Run_Schedule__c             =   'Ch234';
        booking.Booked_Point__c             =   'GA';
        booking.External_Id__c              =   'T-test';
        booking.External_Account__c         =   so.External_Account__c;
        
        insert booking;
        return booking;
    }
    
    public static Booking__c createBooking(Sales_Order__c so, Boolean doInsert)
    {
        Booking__c booking = new Booking__c();
        // added by Tim Fabros 02 / 09 / 2014 - SFE-581
        booking.Name                        = '1234567890';
        booking.Sales_Order__c              =   so.id;
        booking.Booking_Number__c           =   '1234567890';
        booking.CyberAd_AdType__c           =   'Billing';
        booking.Source_System__c            =   'CyberAd';
        //booking.Last_Expiry_Appearance__c =   System.today();
        booking.Third_Party_Created__c      =   System.now();
        booking.Total_Cost_Cyber__c         =   100;
        booking.Run_Schedule__c             =   'Ch234';
        booking.Booked_Point__c             =   'GA';
        booking.External_Id__c              =   'T-test';
        booking.External_Account__c         =   so.External_Account__c;
        if(doInsert)        
            insert booking;
        return booking;
    }
    
    public static List<Booking__c> createBookings(Integer numOfBookings, List<Sales_Order__c> salesOrders)
    {
        List<Booking__c> bookings = new List<Booking__c>();
        
        for(Integer i = 0; i < numOfBookings && i < salesOrders.size(); i++)
        {
            Booking__c booking = new Booking__c();
            // added by Tim Fabros 02 / 09 / 2014 - SFE-581
            booking.Name = '2132' + i;
            booking.Sales_Order__c = salesOrders[i].Id;
            booking.Booking_Number__c = '2132' + i;
            booking.External_Id__c = String.valueOf(math.random() * 1000);
            booking.Advertiser_Account__c = salesOrders[i].Advertiser_Account__c;
            booking.Sales_Rep__c = 'sinTUser';
            
            bookings.add(booking);
        }
        
        return bookings;
    }
    
    public static List<Booking__c> createBookings(Integer numOfBookings, Sales_Order__c salesOrder)
    {
        return TestDataFactory.createBookings(numOfBookings, salesOrder, null, null);
    }
    
    public static List<Booking__c> createBookings(Integer numOfBookings, Sales_Order__c salesOrder,
                                                  String bookingDivision, String bookingSystem)
    {
        List<Booking__c> bookings = new List<Booking__c>();
        
        for(Integer i = 0; i < numOfBookings; i++)
        {
            Booking__c booking = new Booking__c();
            // added by Tim Fabros 02 / 09 / 2014 - SFE-581
            booking.Name = '2132' + i;
            booking.Sales_Order__c = salesOrder.Id;
            booking.Booking_Number__c = '2132' + i;
            booking.Advertiser_Account__c = salesOrder.Advertiser_Account__c;
            booking.CyberAd_Division__c = 'ADV';
            booking.External_Id__c = String.valueOf(math.random() * 1000);
            
            if(String.isNotBlank(bookingDivision))
                booking.CyberAd_Division__c = bookingDivision;
            
            if(String.isNotBlank(bookingSystem))
                booking.Source_System__c = bookingSystem;
            
            bookings.add(booking);
        }
        
        return bookings;
    }
    
    public static List<Booking__c> createBookings(Integer numOfBookings, List<Sales_Order__c> salesOrders, 
                                                  List<User> users)
    {
        List<Booking__c> bookings = new List<Booking__c>();
        
        for(Integer i = 0; i < numOfBookings && i < salesOrders.size(); i++)
        {
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = salesOrders[i].Id;
            booking.Booking_Number__c = '2132' + i;
            booking.External_Id__c = String.valueOf(math.random() * 1000);
            if(users != null)
            {
                booking.Sales_Rep__c = users[i].Network_Username__c;
                booking.Ad_Taker__c = users[i].Network_Username__c;
            }
            bookings.add(booking);
        }
        
        return bookings;
    }
    
    public static List<Booking_Line_Item__c> createBookingLineItems(Integer numOfBookingLines, Booking__c booking)
    {
        return createBookingLineItems( numOfBookingLines,  booking,  null, null);
    }
    
    
    
    public static List<Booking_Line_Item__c> createBookingLineItems(Integer numOfBookingLines, Booking__c booking, Product2 product, List<Product2> products)
    {
        List<Booking_Line_Item__c> bookinglines = new List<Booking_Line_Item__c>();
        
        for(Integer i = 0; i < numOfBookingLines; i++)
        {
            Booking_Line_Item__c bookingLine = new Booking_Line_Item__c();
            bookingLine.Is_Test__c = true;
            bookingLine.Gross_Price__c = 1000;
            bookingLine.Run_Date__c = date.today(); //Hari Kundrapu Added +i to keep run Date for all days
            bookingLine.Booking__c = booking.Id;
            bookingLine.Publication__c = 'pubC' + String.valueOf(i);
            bookingLine.Ad_Type__c = 'type ' + String.valueOf(i);
            
            bookingLine.Division__c = 'NWN';
            bookingLine.Classification__c = 'General News 6';
            bookingLine.Til_Cancelled__c = false;             
            if(product != null)
            {               
                bookingLine.Product__c = product.Id;
            }
            
            if(product == null && products != null && products.size() > 0)
            {
                bookingLine.Product__c = products[i].Id;
            }
            
            bookinglines.add(bookingLine);
        }
        return bookinglines;
    }
    
    public static List<CampaignMember> createCampaignMembers(Integer numOfCampaignMembers, List<Contact> contacts, Campaign campaign)
    {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        // NOTE: it is better to keep contacts and numOfCampaignMembers same size
        if(contacts != null && contacts.size() < numOfCampaignMembers)
        {
            numOfCampaignMembers = contacts.size();
        }
        
        for(Integer i = 0; i < numOfCampaignMembers; i++)
        {
            CampaignMember campaignMember = new CampaignMember();
            campaignMember.ContactId = contacts[i].Id;
            campaignMember.CampaignId = campaign.Id;
            campaignMember.LeadId=null;
            campaignMember.Account__c = contacts[i].AccountId;
            campaignMember.Status = 'Open';
            campaignMember.Locked_By__c = null;
            campaignMember.Call_Count__c = 0;
            campaignMember.Call_Back_Date__c =null;
            campaignMembers.add(campaignMember);
        }
        
        return campaignMembers;
    }
    
    
    public static List<CampaignMember> createCampaignMembers(Integer numOfCampaignMembers, List<Lead> leads, Campaign campaign)
    {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        // NOTE: it is better to keep contacts and numOfCampaignMembers same size
        if(leads != null && leads.size() < numOfCampaignMembers)
        {
            numOfCampaignMembers = leads.size();
        }
        
        for(Integer i = 0; i < numOfCampaignMembers; i++)
        {
            CampaignMember campaignMember = new CampaignMember();
            campaignMember.CampaignId = campaign.Id;
            campaignMember.LeadId=leads[i].id;
            campaignMember.Status = 'Open';
            campaignMember.Locked_By__c = null;
            campaignMember.Call_Count__c = 0;
            campaignMember.Call_Back_Date__c =null;
            campaignMembers.add(campaignMember);
        }
        
        return campaignMembers;
    }
    
    
    public static list<Campaign_Response__c> createCampaignResponses(integer numOFCampaignResponses, list<CampaignMember> members)
    {
        
        list<Campaign_Response__c> crList = new list<Campaign_Response__c>();
        for(CampaignMember m :members)
        {
            for(Integer i = 0; i<numOFCampaignResponses; i++)
            {
                Campaign_Response__c cr = new Campaign_Response__c();
                cr.Response_Type__c = 'Follow Up';
                cr.Response_Subtype__c = 'Decision Maker Unavailable';
                cr.Call_Attempt__c = i + 1;
                cr.Campaign__c = m.CampaignId;
                cr.Contact__c = m.contactId;
                cr.Lead__c = m.LeadId;
                cr.Response_Comment__c = 'This is a test.';
                crList.add(cr);
            }       
        }
        return crList;
    }
    
    
    public static List<Publication_Product__c> createPublicationProducts(List<String> publications, 
                                                                         //List<String> adTypes, 
                                                                         String adType,
                                                                         List<Product2> products,
                                                                         List<String> publicationCodes)
    {
        List<Publication_Product__c> publicationProducts = new List<Publication_Product__c>();
        
        Integer i = 0;
        for(Product2 p : products)
        {
            Publication_Product__c publicationProduct = new Publication_Product__c();
            publicationProduct.Product__c = p.Id;
            publicationProduct.Publication__c = publications[i];
            publicationProduct.Active__c = true;
            publicationProduct.Ad_Type__c = adType;
            publicationProduct.Publication_Code__c = publicationCodes[i];
            publicationProducts.add(publicationProduct);
            i++;
        }
        
        return publicationProducts;
    }
    
    public static List<Publication_Product__c> createPublicationProducts(List<Product2> products, List<String> publications, List<String> publicationCodes, List<String> adTypes)
    {
        List<Publication_Product__c> publicationProducts = new List<Publication_Product__c>();
        
        Integer i = 0;
        for(Product2 p : products)
        {
            Integer j = 0;
            for(String publication : publications)
            {
                Publication_Product__c publicationProduct = new Publication_Product__c();
                publicationProduct.Product__c = p.Id;
                publicationProduct.Active__c = true;
                publicationProduct.Publication__c = publication;
                publicationProduct.Publication_Code__c = publicationCodes[j]; 
                publicationProduct.Ad_Type__c = adTypes[i];
                publicationProducts.add(publicationProduct);
                j++;
            }
            i++;
        }
        
        return publicationProducts;
    }
    
    public static List<Campaign> createCampaigns(Integer numOfCampaigns)
    {
        return createCampaigns(numOfCampaigns, 'Retention', 'NWN');
    }
    
    public static List<Campaign> createCampaigns(Integer numOfCampaigns, String campaignType, String division)
    {
        List<Campaign> campaigns = new List<Campaign>();
        
        for(Integer i = 0; i < numOfCampaigns; i++)
        {
            Campaign campaign = new Campaign();
            campaign.Name = 'Test Campaign ' + String.valueOf(i);
            campaign.Max_Call_Attempts__c = 10;
            campaign.Type = campaignType;
            campaign.Publication_Division__c = division;
            campaign.IsActive = true;
            campaigns.add(campaign);
        }
        
        return campaigns;
    }
    
    public static list<CyberAd_User_Credential__c> createdCyberAdUserCredentialOne() 
    {
        list<CyberAd_User_Credential__c> cl = new list<CyberAd_User_Credential__c>();
        
        User selectedUser = [select id, Profile.Name, ProfileId  from User where id =:UserInfo.getUserId()];
        
        System.runAs(SelectedUser) {
            
            system.debug('SelectedUser:' + SelectedUser);
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = UserInfo.getUserId(),
                RecordTypeId = Schema.SObjectType.CyberAd_User_Credential__c.getRecordTypeInfosByName().get('AdPoint').getRecordTypeId()
                ));
             
            insert cl;
        }   
        return cl;
        
    }

    //create single CyberAd_User_Credential__c record
    public static list<CyberAd_User_Credential__c> createdCyberAdUserCredentialOne(Id userId)
    { 
        map<string,id> rtIds = new map<string,id>(); 
        list<CyberAd_User_Credential__c> cl = new list<CyberAd_User_Credential__c>();
        
        User selectedUser = [select id, Profile.Name, ProfileId  from User where id =:userId];
        
        System.runAs(SelectedUser) {
            
            system.debug('SelectedUser:' + SelectedUser);
            
            for(recordType rt : [Select id, developerName from RecordType where sObjectType='CyberAd_User_Credential__c'])
            {
                rtIds.put(rt.developerName,rt.id);
            }
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = userId,
                RecordTypeId=rtIds.get('CyberSell'),
                Publication__c='',
                Division__c='NMG;PST;DV5;DV6;DV7',
                Database__c='',
                CyberSell_Divisions__c='NWN;CGT',
                CyberAd_Username__c='',
                CyberAd_Password__c='',
                Create_GBA_Types__c='NFSS'));           
                
                //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - removed dead code
            insert cl;
            system.debug('@@cl : '+ cl);
        }   
        return cl;
        
    }


    /***** create external system user credential records for testing classes ***/
    public static list<CyberAd_User_Credential__c> createdCyberAdUserCredentials()
    { 
        return createdCyberAdUserCredentials(UserInfo.getUserId());
    }
    
    public static list<CyberAd_User_Credential__c> createdCyberAdUserCredentials(Id userId)
    { 
        map<string,id> rtIds = new map<string,id>(); 
        list<CyberAd_User_Credential__c> cl = new list<CyberAd_User_Credential__c>();
        
        User selectedUser = [select id, Profile.Name, ProfileId  from User where id =:userId];
        
        System.runAs(SelectedUser) {
            
            system.debug('SelectedUser:' + SelectedUser);
            
            for(recordType rt : [Select id, developerName from RecordType where sObjectType='CyberAd_User_Credential__c'])
            {
                rtIds.put(rt.developerName,rt.id);
            }
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = userId,
                RecordTypeId=rtIds.get('CyberAd'),
                Publication__c='DTM',
                Division__c='NWN',
                Database__c='NWNCGT',
                CyberSell_Divisions__c='',
                CyberAd_Username__c='CCLTL',
                CyberAd_Password__c='CCLTL',
                Create_GBA_Types__c=''));
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = userId,
                RecordTypeId=rtIds.get('CyberSell'),
                Publication__c='',
                Division__c='NMG;PST;DV5;DV6;DV7',
                Database__c='',
                CyberSell_Divisions__c='NWN;CGT',
                CyberAd_Username__c='',
                CyberAd_Password__c='',
                Create_GBA_Types__c='NFSS'));           
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = userId,
                RecordTypeId=rtIds.get('CyberSell'),
                Publication__c='',
                Division__c='CAT;DV1;DV2;DV3',
                Database__c='',
                CyberSell_Divisions__c='NWN;CGT',
                CyberAd_Username__c='',
                CyberAd_Password__c='',
                Create_GBA_Types__c='Sales'));  
            
            cl.add( new CyberAd_User_Credential__c(
                User__c = userId,
                RecordTypeId=rtIds.get('AdPoint'))); 
            
            insert cl;
            system.debug('@@cl : '+ cl);
        }   
        return cl;
        
    }
    /***** create external system user credential records for testing classes ***/
    
    public static list<Genera_Revenue_Groups__c> createCustomSettingGeneraRevenueGroups()
    {
        list<Genera_Revenue_Groups__c> grgL = new list<Genera_Revenue_Groups__c>();
        grgL.add(NEW Genera_Revenue_Groups__c (name='Retail',Account_Revenue_Group_Value__c='Retail', External_Id__c='1423'));
        grgL.add(NEW Genera_Revenue_Groups__c (name='Amusements',Account_Revenue_Group_Value__c='Amusements', External_Id__c='1234'));
        grgL.add(NEW Genera_Revenue_Groups__c (name='Real Estate',Account_Revenue_Group_Value__c='Real Estate', External_Id__c='5548'));
        grgL.add(NEW Genera_Revenue_Groups__c (name='Employment',Account_Revenue_Group_Value__c='Employment', External_Id__c='6897'));
        
        insert grgL;
        return grgL;
    }
    
    
    
    public static list<Genera_Account_Type_Mapping__c> createCustomSettingGeneraAccountTypeMapping()
    {   
        list<Genera_Account_Type_Mapping__c> gatm = new list<Genera_Account_Type_Mapping__c>();
        
        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'ABN Exempt',
                                                       Value__c = 'ABNEXMT',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = false,
                                                       isABNrequired__c = false,
                                                       Owning_Credit_Division__c = 'Y',
                                                       Request_Account_Divisions__c = 'Y'));
        
        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'Ad Agency',
                                                       Value__c = 'AGENCY',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = false,
                                                       isABNrequired__c = true,
                                                       Owning_Credit_Division__c = 'NATIONAL',
                                                       Request_Account_Divisions__c = 'ALL'));
        
        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'Client of Ad Agency',
                                                       Value__c = 'CL',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = true,
                                                       Parent__c = 'Ad Agency',
                                                       isABNrequired__c = false,
                                                       Owning_Credit_Division__c = 'N',
                                                       Request_Account_Divisions__c = 'N'));

        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'Contra',
                                                       Value__c = 'VAL1',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = true,
                                                       isABNrequired__c = false,
                                                       Owning_Credit_Division__c = 'N',
                                                       Request_Account_Divisions__c = 'N'));

        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'Request for Established',
                                                       Value__c = 'VAL2',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = true,
                                                       Parent__c = 'Ad Agency1',
                                                       isABNrequired__c = false,
                                                       Owning_Credit_Division__c = 'N',
                                                       Request_Account_Divisions__c = 'N'));
        
        insert gatm;                                                
        return gatm;
    }
    
    public static List<Revenue_Schedule__c> createRevenueSchedules(List<Product2> products, Integer numOfRevenueSchedule, 
                                                                   Boolean isTarget, Date initialStartDate, List<User> users)
    {
        List<Revenue_Schedule__c> revenueSchedules = new List<Revenue_Schedule__c>();
        
        Date startDate = initialStartDate;
        
        Integer a = 0;
        
        for(User u : users)
        {
            
            for(Product2 product : products)
            {
                startDate = initialStartDate;
                
                for(Integer i = 1; i <= numOfRevenueSchedule; i++)
                {
                    Revenue_Schedule__c crs = new Revenue_Schedule__c();
                    crs.Product__c = product.Id;
                    crs.Rev_Date__c = startDate;
                    crs.OwnerId = u.Id;
                    crs.Rev_Amount__c = 100;
                    crs.External_ID__c = String.valueOf(a);
                    
                    if(isTarget)
                    {
                        crs.Reporting_Type_L1__c = 'Target';
                    }
                    
                    revenueSchedules.add(crs);
                    
                    startDate = startDate.addDays(7);
                    a++;
                }
            }
        }
        return revenueSchedules;
    }
    
    public static list<Division_Info__c> createDivisionInformation()
    {
        list<Division_Info__c> l = new list<Division_Info__c>();
        
        l.add(new Division_Info__c( Name    =   'ADN',
                                   External_ID__c = 'ADN',
                                   ABN__c  =   '77 007 872 997',
                                   Address__c ='31 Waymouth Street Adelaide SA 5000',
                                   Disclaimer__c='131 841',
                                   SwitchBoard__c='The accuracy of the ad and any further corr...'));
        
        
        
        l.add(new Division_Info__c( Name    =   'CNG',
                                   External_ID__c = 'CNG',
                                   ABN__c  =   '98 008 438 828',
                                   Address__c ='Level 3, 407 Elizabeth Street Surry Hills ',
                                   Disclaimer__c='13 19 79 ',
                                   SwitchBoard__c='The accuracy of the ad and any further corr...'));
        
        l.add(new Division_Info__c( Name    =   'NWN',
                                   External_ID__c = 'NWN',            
                                   ABN__c  =   '61 009 661 778',
                                   Address__c ='Level 3, 407 Elizabeth Street Surry Hills',
                                   Disclaimer__c='9288 2000',
                                   SwitchBoard__c='The accuracy of the ad and any further corr...'));
        
        l.add(new Division_Info__c( Name    =   'GCP',
                                   External_ID__c = 'GCP',
                                   ABN__c  =   '61 009 661 778',
                                   Address__c ='41 Campbell St, Bowen Hills. QLD 4006',
                                   Disclaimer__c='1300 112 345',
                                   SwitchBoard__c='The accuracy of the ad and any further corr...'));
        
        return l;
    }
    
    //Updated to include "Default Sales Rep" custom setting record
    public static void createFaxSystemParameters()
    {
        List<SystemParameters__c> faxParams = new List<SystemParameters__c>();
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultCoverPageId';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = '4';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultFromText';
        faxParam.Description__c = 'The from text of the fax cover page';
        faxParam.External_Id__c = 'FaxDefaultFromText';
        faxParam.Value__c = 'NEWS CORP';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxSendConfirmationTo';
        faxParam.Description__c = 'Default email to receive fax confirmation';
        faxParam.External_Id__c = 'FaxSendConfirmationTo';
        faxParam.Value__c = 'developers@bluewolf.com';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultPaperFormat';
        faxParam.Description__c = 'Fax default paper format. Valid values are "Letter", "Legal", "A4", "Default"';
        faxParam.External_Id__c = 'FaxDefaultPaperFormat';
        faxParam.Value__c = 'A4';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultResolution';
        faxParam.Description__c = 'Fax resolution. valid values are "204x98" or "204x196"';
        faxParam.External_Id__c = 'FaxDefaultResolution';
        faxParam.Value__c = '204x196';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxUserId';
        faxParam.Description__c = 'MyFax user id';
        faxParam.External_Id__c = 'FaxUserId';
        faxParam.Value__c = '5418797';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxUserPassword';
        faxParam.Description__c = 'Fax user password';
        faxParam.External_Id__c = 'FaxUserPassword';
        faxParam.Value__c = 'newsfaxt3st';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'test user password';
        faxParam.External_Id__c = 'testUserPassword';
        faxParam.Value__c = Userinfo.getUserId();
        faxParams.add(faxParam);
        
        insert faxParams;
    }
    
    public static Campaign_Influence__c createCampaignInfluence(String campaignId, String opportunityId, Boolean primaryCampaign)
    {
        Campaign_Influence__c campaignInfluence = new Campaign_Influence__c();
        
        campaignInfluence.Opportunity__c    = opportunityId;
        campaignInfluence.Campaign__c       = campaignId;
        campaignInfluence.Influence__c      = 5;
        campaignInfluence.Is_Primary_Campaign__c = primaryCampaign;
        
        return campaignInfluence;
    }
    
    public static void createRevenueSchedulePatterns()
    {
        List<Revenue_Schedule_Pattern__c> revenueSchedulePatterns = new List<Revenue_Schedule_Pattern__c>();
        
        Revenue_Schedule_Pattern__c every2Weeks = new Revenue_Schedule_Pattern__c();
        every2Weeks.Name = 'Every 2 Weeks';
        every2Weeks.Pattern__c = '10';
        every2Weeks.Frequency__c = 'Week';
        every2Weeks.External_Id__c = 'Every 2 Weeks';
        revenueSchedulePatterns.add(every2Weeks);
        
        Revenue_Schedule_Pattern__c every3Weeks = new Revenue_Schedule_Pattern__c();
        every3Weeks.Name = 'Every 3 Weeks';
        every3Weeks.Pattern__c = '100';
        every3Weeks.Frequency__c = 'Week';
        every3Weeks.External_Id__c = 'Every 3 Weeks';
        revenueSchedulePatterns.add(every3Weeks);
        
        Revenue_Schedule_Pattern__c every4Weeks = new Revenue_Schedule_Pattern__c();
        every4Weeks.Name = 'Every 4 Weeks';
        every4Weeks.Pattern__c = '1000';
        every4Weeks.Frequency__c = 'Week';
        every4Weeks.External_Id__c = 'Every 4 Weeks';        
        revenueSchedulePatterns.add(every4Weeks);
        
        Revenue_Schedule_Pattern__c monthly = new Revenue_Schedule_Pattern__c();
        monthly.Name = 'Monthly';
        monthly.Pattern__c = '1';
        monthly.Frequency__c = 'Month';
        monthly.External_Id__c = 'Monthly';        
        revenueSchedulePatterns.add(monthly);
        
        Revenue_Schedule_Pattern__c weekly = new Revenue_Schedule_Pattern__c();
        weekly.Name = 'Weekly';
        weekly.Pattern__c = '1';
        weekly.Frequency__c = 'Week';
        weekly.External_Id__c = 'Weekly';        
        revenueSchedulePatterns.add(weekly);
        
        insert revenueSchedulePatterns;
    }

    public static Industry_Code__c createIndustryCode()
    {
        Industry_Code__c industryCode = new Industry_Code__c();

        industryCode.Name                       = 'Accommodation and Food Services (Accommodation)';
        industryCode.Class__c                   = 'Accommodation';
        industryCode.Class_Code_s__c            = '4400';
        industryCode.Division__c                = 'Accommodation and Food Services';
        industryCode.Division_Code__c           =  'H';
        industryCode.External_ID__c             = '4400';
        industryCode.Group__c                   = 'Accommodation';
        industryCode.Group_Code_s__c            = '440';
        industryCode.Industry_Code_Adpoint__c   = 'Travel/Accom - Accommodation';
        industryCode.MI_Class_Adpoint__c        = 'Other Products & Services';
        industryCode.Subdivision__c             = 'Accommodation';
        industryCode.Subdivision_Code_s__c      = '44';
        
        return industryCode;

    }

    public static Feature__c createFeature()
    {
        Feature__c feature = new Feature__c();
        feature.Name = 'Test Feature';
        feature.Type__c = 'abc';
        feature.Feature_Date__c = Date.today();
        feature.Section_in_Product__c = 'Home';
        feature.System_Classification_Section__c = '123';
        feature.Category__c = 'Real Estate';
        feature.Contact_Email__c = 'test@test.com';
        feature.Contact_Name__c = 'Test Person';
        feature.Booking_Deadline__c = Date.today();
        feature.Audience__c = 'All People';
        feature.Target_Revenue__c = 100;
        feature.Product__c = 'The Daily Telegraph';
        insert feature;

        return feature;

    }

    public static void createFeatureProdState(){
        List<Feature_Product_State__c> prodStates = new List<Feature_Product_State__c>();

        Feature_Product_State__c fps = new Feature_Product_State__c();
        fps.Name = 'fps1';
        fps.State__c = 'NSW';
        fps.Product__c = 'The Daily Telegraph';
        fps.Type__c = 'Newspaper-Metro';

        Feature_Product_State__c fps2 = new Feature_Product_State__c();
        fps2.Name = 'fps2';
        fps2.State__c = 'NT';
        fps2.Product__c = 'Darwin Sun';
        fps2.Type__c = 'Newspaper-Local';

        prodStates.add(fps);
        prodStates.add(fps2);

        insert prodStates;
    }

    //Custom Setting
    public static void createFeatureCategoryColour(){

        List<Feature_Category_Colour__c> fccList = new List<Feature_Category_Colour__c>();

        Feature_Category_Colour__c fcc1 = new Feature_Category_Colour__c();
        fcc1.Name='fcc1';
        fcc1.Colour__c = '#FFFFFF';
        
        fccList.add(fcc1);

        insert fccList;
    }
    //Added for EMMA data --Hari Kundrapu 03/10/2018 for Jira NX-853
    public static List<EMMA_Readership_and_Circulation_Data__c> createEmmaRecords(Integer numOfEmmas)
    {
        List<EMMA_Readership_and_Circulation_Data__c> emmarecords = new List<EMMA_Readership_and_Circulation_Data__c>();

        for(Integer i = 0; i < numOfEmmas; i++)
        {

            EMMA_Readership_and_Circulation_Data__c emma1 = new EMMA_Readership_and_Circulation_Data__c();
            emma1.EMMA_Publication_Name__c = 'Test Adelaide Advertiser'+ String.valueOf(i);
            emma1.Genera_Publication_Name__c = 'Test The Advertiser'+ String.valueOf(i);
            emma1.Genera_Publication_Code__c = 'pubC'+ String.valueOf(i);
            emma1.Genera_Publication_Description__c = 'Test The Advertiser and Sunday Mail'+String.valueOf(i);
            emma1.Readership_Monday_Friday__c = 358000+i;
            emma1.Readership_Saturday_Sunday__c = 384000+i;
            emma1.Circulation__c = 434+i;

            emmarecords.add(emma1);
            
        }
        return emmarecords;
    }
}