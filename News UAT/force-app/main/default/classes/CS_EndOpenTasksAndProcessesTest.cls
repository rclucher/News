@isTest
private class CS_EndOpenTasksAndProcessesTest {
    @isTest
    static void test_process() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.status__c = 'Draft';
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Cancelled'
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
        CSPOFA__Orchestration_Process__c process2 = new CSPOFA__Orchestration_Process__c(
            Order__c = order.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert new List<CSPOFA__Orchestration_Process__c>{process, process2};

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            New_Orch_Process__c = template.Name,
            CSPOFA__Orchestration_Process__c = process.Id
        );
        CSPOFA__Orchestration_Step__c step2 = new CSPOFA__Orchestration_Step__c(
            New_Orch_Process__c = template.Name,
            CSPOFA__Orchestration_Process__c = process2.Id,
            CSPOFA__Status__c = 'Waiting'
        );
        insert new List<CSPOFA__Orchestration_Step__c>{step, step2};

        Test.startTest();

        CS_EndOpenTasksAndProcesses endProcess = new CS_EndOpenTasksAndProcesses();
        List<sObject> result = endProcess.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }   
}