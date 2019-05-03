/*---------------------------------------------------------
 * Author: Logabalakrishnan (LBK) Muthukrishnan
 * Company: News
 * Description: 
 * 1. This test class is for Requirement: Item-01273.
 *              The purpose of this test class is to code cover the clsCreateOpportunityExtension. 
 * History:
 * 2018-03-17	LBK		Created (Code coverage achieved - ???%)
 ---------------------------------------------------------*/
@IsTest (SeeAllData=true)
public class testCreateOpportunityExtension {
    static testmethod void testCreateOpportunityExt() { 
        
        Test.startTest();
         Account objTestAccount = new Account();
         objTestAccount.Name = 'Test account 27';
         objTestAccount.No_Parent_Account__c = true;
         insert objTestAccount;
        
         //Account objTestAccount = [SELECT ID FROM Account LIMIT 1];
         ApexPages.StandardController sc = new ApexPages.StandardController(objTestAccount);
         clsCreateOpportunityExtension objCreateOpportunityExtension = new clsCreateOpportunityExtension(sc);
        
        PageReference pageRef = Page.qaCreateNewOpportunity;
        pageRef.getParameters().put('id', String.valueOf(objTestAccount.Id));
        Test.setCurrentPage(pageRef);
        
        List<SelectOption> lstRecordTypes = objCreateOpportunityExtension.getRecordTypes();
        RecordType objRecordType = [SELECT ID, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'Opportunity' LIMIT 1];
        objCreateOpportunityExtension.selectedRecordType = String.valueOf(objRecordType.Id);
        PageReference pageRef1 = objCreateOpportunityExtension.createOpportunity();
        Test.setCurrentPage(pageRef1);
        
        
        
        Test.stopTest();
    }
    
    static testmethod void testCreateOpportunityExt1() { 
        
        Test.startTest();
       
        
        // Create a unique UserName
        String uniqueUserName = 'KACUser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='KAC Sales'];
        User u = new User(Alias = 'standt', Email='kacuser@testorg.com',
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
						LocaleSidKey='en_US', ProfileId = p.Id,
						TimeZoneSidKey='America/Los_Angeles',
						 UserName=uniqueUserName);

        System.runAs(u) {
         //Account objTestAccount = [SELECT ID FROM Account LIMIT 1];
         Account objTestAccount = new Account();
         objTestAccount.Name = 'Test account 24';
         objTestAccount.No_Parent_Account__c = true;
         insert objTestAccount;
         ApexPages.StandardController sc = new ApexPages.StandardController(objTestAccount);
         //clsCreateOpportunityExtension objCreateOpportunityExtension = new clsCreateOpportunityExtension(sc);
            
            clsCreateOpportunityExtension objCreateOpportunityExtension1 = new clsCreateOpportunityExtension(sc);
            PageReference pageRef2 = Page.qaCreateNewOpportunity;
            pageRef2.getParameters().put('id', String.valueOf(objTestAccount.Id));
            Test.setCurrentPage(pageRef2);
            
            List<SelectOption> lstRecordTypes1 = objCreateOpportunityExtension1.getRecordTypes();
                
            PageReference pageRef3 = objCreateOpportunityExtension1.createOpportunity();
            Test.setCurrentPage(pageRef3);
            objCreateOpportunityExtension1.saveOpportunity();
            
            String sSelectedRecordType = String.valueOf(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('KAC').getRecordTypeId());
            objCreateOpportunityExtension1.setSelectedRecordType(sSelectedRecordType);
            //objCreateOpportunityExtension1.
            sSelectedRecordType = objCreateOpportunityExtension1.getSelectedRecordType();
            
            //PageReference pageRef4 = objCreateOpportunityExtension1.createOpportunity();
            objCreateOpportunityExtension1.objNewOpportunity.Name = 'QuickTest 0001';
            objCreateOpportunityExtension1.objNewOpportunity.CloseDate = system.today();
            objCreateOpportunityExtension1.objNewOpportunity.StageName = 'Discover Needs';
            objCreateOpportunityExtension1.objNewOpportunity.Amount = 1000;
            objCreateOpportunityExtension1.objNewOpportunity.Description = 'Description 0001';
            objCreateOpportunityExtension1.saveOpportunity();
            //objCreateOpportunityExtension1.saveOpportunity();
            
        }
        Test.stopTest();
    }
}