@isTest
public with sharing class DNCPhoneExtract_Test {
    //Class for unit testing the DNC Phone Extract Process

    
    public static void setupDNCSettingsTestData(){
        //Create Custom Settings for Test
        DNC_Settings__c settings = new DNC_Settings__c(
            Name = 'DNC Defaults', 
            Delete_Scope_Size__c = 1000, 
            Delete_Window__c = 30, 
            Extract_Scope_Size__c = 50,
            External_Id__c = '1234567'
        );

        insert settings;
    }
    
    public static void setupCampaignDNCTestData(){

        //Create an Active Campaign Test Record
        Campaign testCampaign_Active = new Campaign(Name = 'Unit Test Campaign - Active', Status = 'Launched', NEWS_Campaign_Type__c = 'Feature', Type = 'Feature', StartDate = System.Today(), EndDate = System.Today().addDays(7));
        insert testCampaign_Active;

        //Create an Inactive Campaign Test Record - negative test case
        Campaign testCampaign_Inactive = new Campaign(Name = 'Unit Test Campaign - Inactive', Status = 'Cancelled', NEWS_Campaign_Type__c = 'Feature', Type = 'Feature', StartDate = System.Today(), EndDate = System.Today().addDays(7));
        insert testCampaign_Inactive;

        //Create an account (so Contacts can be associated to it)
        Account acct = new Account(Name = 'Sample', Type = 'Account Managed', Account_Type__c = 'General', Phone = '123455678', Revenue_Group__c = 'House', Industry = 'Finance', No_Parent_Account__c = true);
        insert acct;
        
        //Create sample contacts
        List<Contact> cntList = new List<Contact>();

        for (Integer i = 0; i <10; i ++){
            Contact cnt = new Contact (FirstName = 'sampler', LastName = 'sampleContact' + i, No_Email__c = True);
            cnt.Phone = '+6141211111' + i;
            cnt.AssistantPhone = '+6141211122' + i;
            cnt.HomePhone = '+6141211133' + i;
            cnt.MobilePhone = '+6141211111' + i; //deliberately make this the same as Home Phone to check logic handles duplicate phone numbers
            cnt.OtherPhone = '+6141211144' + i;
            cntList.add(cnt);
        }

        insert cntList;

        //Create sample Leads

        List<Lead> ldList = new List<Lead>();


        for (Integer i = 0; i <10; i ++){
            Lead ld = new Lead (FirstName = 'sampler', LastName = 'sampleContact' + i);
            ld.Phone = '+6141211155' + i;

            ld.MobilePhone = '+6141211166' + i;
            ldList.add(ld);
        }
        insert ldList;

        //Add the first 5 contacts and leads to the active campaign as campaignmembers
        List<CampaignMember> cmList = new List<CampaignMember>();
        for (Integer i = 0; i <5; i ++){
            CampaignMember cm = new CampaignMember (ContactId = cntList[i].Id, CampaignId = testCampaign_Active.Id);
            cmList.add(cm);
        }

        for (Integer i = 0; i <5; i ++){
            CampaignMember cm = new CampaignMember (LeadId = ldList[i].Id, CampaignId = testCampaign_Active.Id);
            cmList.add(cm);

        }           

        insert cmList;
        
        List<CampaignMember> cmList2 = new List<CampaignMember>();
        //Add the 3 leads and contacts to the inactive campaign as campaignmembers
        for (Integer i = 5; i <8 ;i ++){
            CampaignMember cm = new CampaignMember (ContactId = cntList[i].Id, CampaignId = testCampaign_Inactive.Id);
            cmList2.add(cm);
        }

        for (Integer i = 5; i <8 ;i ++){
            CampaignMember cm = new CampaignMember (LeadId = ldList[i].Id, CampaignId = testCampaign_Inactive.Id);
            cmList2.add(cm);

        } 
        
        insert cmList2;
    }

    static testmethod void DNCExtractTest() {
        Test.startTest();

        setupDNCSettingsTestData();
        setupCampaignDNCTestData();

        //Start the Extract
        DNC_Settings__c settings = [Select Id, Name, Extract_Scope_Size__c From DNC_Settings__c WHERE Name = 'DNC Defaults'];
        Integer scopeSize = (Integer)settings.Extract_Scope_Size__c;

        String query = 'select Lead.id, Lead.Phone, Lead.MobilePhone,'
                    + 'Contact.id, Contact.Phone, Contact.MobilePhone, Contact.AssistantPhone, Contact.OtherPhone, Contact.HomePhone' 
                    + ' from CampaignMember'
                    + ' WHERE campaign.status NOT IN: CAMPAIGN_STATUS';
                    
        DNCPhoneExtract extractProcess = new DNCPhoneExtract(query);
        ID idBatch = Database.executeBatch(extractProcess, scopeSize);

        Test.stopTest();

        //set up expected result set
        List<String> phoneList = new List<String>();
        
        for (Integer i = 0; i <5; i ++){
            phoneList.add('+6141211111' + i);
            phoneList.add('+6141211122' + i);
            phoneList.add('+6141211133' + i);
            phoneList.add('+6141211144' + i);
            phoneList.add('+6141211155' + i);
            phoneList.add('+6141211166' + i);
        }
        
        //Evaluate results - check that the status is correct and the expected phone numbers are in DNC table
        List<DNC_Wash_Register__c> DNCNumbers = [SELECT Phone_Number__c, DNC_Status__c, Status_Date__c, Qualification_Date__c        
                                                 FROM DNC_Wash_Register__c
                                                 WHERE DNC_Status__c = 'Not Checked'
                                                     AND Phone_Number__c in :phoneList];


        //Are the total numbers correct?
        System.assertEquals(30, DNCNumbers.size()); //5 x 4 contact numbers + 5 x 2 lead numbers;
        
        //check that correct Qualification date is present
        DateTime Dt = System.today();
        Date D = Date.newInstance(Dt.year(),Dt.Month(),Dt.day());
        
        for (DNC_Wash_Register__c dnc : DNCNumbers){
            Date DNCdate = Date.newInstance(dnc.Qualification_Date__c.year(), dnc.Qualification_Date__c.Month(), dnc.Qualification_Date__c.day()); 
            System.assertEquals(D, DNCdate);
            
        }

        // test webservice call for method processCampaignMember
        String campaignId = [select Id from Campaign limit 1].Id;
        DNCPhone_Helper.processCampaignMember(campaignId);



    }


}