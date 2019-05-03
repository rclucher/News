@isTest
public with sharing class DNCPhoneDelete_Test {
    //Class for unit testing the DNC Phone Delete Process

    public static void setupRegisterDNCTestData(){
        //Set up sample date in the DNC Register object for deletion
        
        List<DNC_Wash_Register__c> dncList = new List<DNC_Wash_Register__c>();
        
        //set up some data under a month old - sync with test data in extract so this data can be used for updates
        for (Integer i = 0; i < 5; i++){
            DNC_Wash_Register__c dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211111' +i);
            dnc.Qualification_Date__c = System.today();
            dnc.DNC_Status__c = 'Do Not Call';
            dnc.Status_Date__c = System.today();
            dncList.add(dnc);
            
            dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211122' +i);
            dnc.Qualification_Date__c = System.today();
            dnc.DNC_Status__c = 'Unregistered';
            dnc.Status_Date__c = System.today();
            dncList.add(dnc);
            
            dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211133' +i);
            dnc.Qualification_Date__c = System.today();
            //leave dnc status as default
            dncList.add(dnc);
            
        }
        
        //set up some more data over a month old
        for (Integer i = 0; i < 5; i++){
            DNC_Wash_Register__c dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211144' +i);
            dnc.Qualification_Date__c = System.today().addDays(-45);//45 days before today
            dnc.DNC_Status__c = 'Do Not Call';
            dnc.Status_Date__c = System.today();
            dncList.add(dnc);
                        
            dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211155' +i);
            dnc.Qualification_Date__c = System.today().addDays(-45);
            //leave dnc status as default
            dncList.add(dnc);
            
            dnc = new DNC_Wash_Register__c(Phone_Number__c = '+6141211166' +i);
            dnc.Qualification_Date__c = System.today().addDays(-45); //45 days before today
            dnc.DNC_Status__c = 'Unregistered';
            dnc.Status_Date__c = System.today();
            dncList.add(dnc);
        }
        
        insert dncList;
    }
    
    
    static testmethod void DNCPhoneDeleteTest() {
        Test.startTest();

        //set up Custom settings data
        DNCPhoneExtract_Test.setupDNCSettingsTestData();
        
        //set up data in DNC object
        setupRegisterDNCTestData();
        
        //Execute the delete job (get custom settings for scope size first) 
        //Get the scope size from custom settings
        DNC_Settings__c settings = [Select Id, Name, Delete_Scope_Size__c From DNC_Settings__c WHERE Name = 'DNC Defaults'];
        Integer scopeSize = (Integer)settings.Delete_Scope_Size__c;

        System.debug(Logginglevel.DEBUG, 'Delete Scope Size: ' + scopeSize);
        
        String query = 'Select Id, Name, Qualification_Date__c From DNC_Wash_Register__c';
           
        DNCPhoneDelete del = new DNCPhoneDelete(query);
        ID batchprocessid = Database.executeBatch(del, scopeSize);
        
        Test.stopTest();
        
        //set up expected result set
        List<String> phoneList = new List<String>();
        
        for (Integer i = 0; i <5; i ++){
            phoneList.add('+6141211111' + i);
            phoneList.add('+6141211122' + i);
            phoneList.add('+6141211133' + i);
        }
        
        //Evaluate results - check that the status is correct and the expected phone numbers are in DNC table
        List<DNC_Wash_Register__c> DNCNumbers = [SELECT Phone_Number__c, DNC_Status__c, Status_Date__c, Qualification_Date__c        
                                                 FROM DNC_Wash_Register__c
                                                 WHERE Phone_Number__c in :phoneList];


        //Are the total numbers correct?
        System.assertEquals(15, DNCNumbers.size()); //15 numbers are under 30 days old


    }

}