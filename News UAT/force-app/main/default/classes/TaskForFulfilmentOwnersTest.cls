@isTest
private class TaskForFulfilmentOwnersTest {
    @isTest
    static void test_process() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Order__c = order.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            New_Orch_Process__c = template.Name,
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        TaskForFulfilmentOwners taskCreate = new TaskForFulfilmentOwners();
        List<sObject> result = taskCreate.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }
}