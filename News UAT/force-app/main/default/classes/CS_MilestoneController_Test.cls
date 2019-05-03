@isTest
private class CS_MilestoneController_Test 
{   
    @isTest static void test_method_one() 
    {
    
        //Create Order
        Order__c o = new Order__c();
        insert o;

        //Create Orchestratation Process Template
        CSPOFA__Orchestration_Process_Template__c opt = new CSPOFA__Orchestration_Process_Template__c(name='MilestoneUnitTest OP Template');
        insert opt;
        
        //Create Orchestratation Process Template Steps
        List<RecordType> rtypeids = [select Id from RecordType where sObjectType='CSPOFA__Orchestration_Step_Template__c' and Name = 'Create Task' and isActive=true LIMIT 1];

        //Create Orchestratation Process 
        CSPOFA__Orchestration_Process__c op = new CSPOFA__Orchestration_Process__c(Name='MilestoneUnitTest OP', CSPOFA__Orchestration_Process_Template__c=opt.id, Order__c=o.id);
        insert op;

        //Create Orchestratation Process Steps
        CSPOFA__Orchestration_Step__c ops01= new CSPOFA__Orchestration_Step__c(Name='MilestoneUnitTest OP Step #01', CSPOFA__Milestone__c = true, CSPOFA__Milestone_Label__c = 'Milestone 01', CSPOFA__Orchestration_Process__c=op.id);
        insert ops01;
        CSPOFA__Orchestration_Step__c ops02= new CSPOFA__Orchestration_Step__c(Name='MilestoneUnitTest OP Step #02', CSPOFA__Milestone__c = true, CSPOFA__Milestone_Label__c = 'Milestone 02', CSPOFA__Orchestration_Process__c=op.id);
        insert ops02;
        CSPOFA__Orchestration_Step__c ops03= new CSPOFA__Orchestration_Step__c(Name='MilestoneUnitTest OP Step #03', CSPOFA__Milestone__c = true, CSPOFA__Milestone_Label__c = 'Milestone 03', CSPOFA__Orchestration_Process__c=op.id);
        insert ops03;
        CSPOFA__Orchestration_Step__c ops04= new CSPOFA__Orchestration_Step__c(Name='MilestoneUnitTest OP Step #04', CSPOFA__Milestone__c = true, CSPOFA__Milestone_Label__c = 'Milestone 04', CSPOFA__Orchestration_Process__c=op.id);
        insert ops04;
        CSPOFA__Orchestration_Step__c ops05= new CSPOFA__Orchestration_Step__c(Name='MilestoneUnitTest OP Step #05', CSPOFA__Milestone__c = true, CSPOFA__Milestone_Label__c = 'Milestone 05', CSPOFA__Orchestration_Process__c=op.id);
        insert ops05;

        List<CSPOFA__Orchestration_Step__c> steps = [select id, name, CSPOFA__Orchestration_Process__c from CSPOFA__Orchestration_Step__c where CSPOFA__Orchestration_Process__c = :op.id];
        System.assertEquals(steps.size(), 5);

        // Getting Test Data 
        //Order__c orderObject = [select id, name from Order__c where id = 'a4YO0000000Pf5fMAC' LIMIT 1];

        // Test execution
        Test.startTest();
        Test.setCurrentPage(Page.OrderMilestonePage);

        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        MilestoneController mc = new MilestoneController(sc);
        
        System.assertEquals(null, mc.processSelectionChanged());

        Test.stopTest();


    }

}