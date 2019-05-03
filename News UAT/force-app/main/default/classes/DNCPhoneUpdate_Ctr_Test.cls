/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2016-01-14  Atul Gupta Updated
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - DNCUpdate_Controller 80%
    //  - DNCPhoneUpdate_Batch 75%
 */
@isTest
private class DNCPhoneUpdate_Ctr_Test 
{
    static testMethod void DNCPhoneUpdateCtrTest() 
    {
        //Create Custom Settings for Test
        DNC_Settings__c settings = new DNC_Settings__c(
            Name = 'DNC Defaults', 
            Delete_Scope_Size__c = 1000, 
            Delete_Window__c = 30, 
            Extract_Scope_Size__c = 50,
            Update_Scope_Size__c = 50,
            External_Id__c = '1234567'
        );

        insert settings;
        
        Test.startTest();
        PageReference dncPage = new PageReference('/apex/dncphoneupdate');
        Test.setCurrentPage(dncPage);
        
        DNCUpdate_Controller dncUpdateCtr = new DNCUpdate_Controller();
        dncUpdateCtr.runDncUpdate();
        dncUpdateCtr.checkJobStatus();
        Test.StopTest();
    }
}