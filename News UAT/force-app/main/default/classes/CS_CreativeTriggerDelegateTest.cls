@isTest
private class CS_CreativeTriggerDelegateTest {
    @isTest static void test_insert() {
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Creative Setup'
        );
        insert template;

        Test.startTest();

        Creative__c creative = new Creative__c();
        insert creative;

        Test.stopTest();
    }

    @isTest static void test_update() {
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Creative Setup'
        );
        insert template;

        Creative__c creative = new Creative__c();
        insert creative;

        Test.startTest();

        update creative;

        Test.stopTest();
    }

    @isTest static void test_delete() {
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Creative Setup'
        );
        insert template;

        Creative__c creative = new Creative__c();
        insert creative;

        Test.startTest();

        delete creative;

        Test.stopTest();
    }

    @isTest static void test_undelete() {
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Creative Setup'
        );
        insert template;

        Creative__c creative = new Creative__c();
        insert creative;
        delete creative;

        Test.startTest();

        undelete creative;

        Test.stopTest();
    }
}