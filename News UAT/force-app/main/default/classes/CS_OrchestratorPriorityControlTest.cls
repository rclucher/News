@isTest
public class CS_OrchestratorPriorityControlTest {

    @isTest static void testPriorities() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;
        String PRIORITY = '2 - Normal';

        Creative__c creative = new Creative__c();

        insert creative;

        Product_Order__c pOrd = new Product_Order__c(
                Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
                Name = 'Campaign Setup',
                CSPOFA__OLA_Unit__c = 'day',
                CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
                Product_Order__c = pOrd.Id,
                CSPOFA__Orchestration_Process_Template__c = template.Id,
                CSPOFA__Priority__c = PRIORITY
        );

        insert process;

        CSPOFA__Orchestration_Process__c processCr = new CSPOFA__Orchestration_Process__c(
                Creative__c = creative.Id,
                CSPOFA__Orchestration_Process_Template__c = template.Id,
                CSPOFA__Priority__c = PRIORITY
        );
        insert processCr;

        CSPOFA__Orchestration_Process__c processOrd = new CSPOFA__Orchestration_Process__c(
                Order__c = order.Id,
                CSPOFA__Orchestration_Process_Template__c = template.Id,
                CSPOFA__Priority__c = PRIORITY
        );


        insert processOrd;



        Test.startTest();


        CS_OrchestratorPriorityControl orchPrCtrl = new CS_OrchestratorPriorityControl();

        CS_OrchestratorPriorityControl.setOrchestratorPriorityCampaign(order.Id, PRIORITY);
        CS_OrchestratorPriorityControl.setOrchestratorPriorityCreative (creative.Id, PRIORITY);
        CS_OrchestratorPriorityControl.setOrchestratorPriorityProduct(pOrd.Id, PRIORITY);

        Test.stopTest();
    }
}