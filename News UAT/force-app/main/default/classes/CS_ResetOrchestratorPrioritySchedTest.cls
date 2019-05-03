@isTest
private class CS_ResetOrchestratorPrioritySchedTest {
	
	@isTest static void orchPriortyCleanup() {
		

		
		CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c();

		template.Name = 'Test Template';
		template.CSPOFA__Priority__c = '3 - High';
		template.CSPOFA__Processing_Mode__c = 'Background';
		insert template;

		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp1 = TestDataSetupClass.createOpportunity(acc, con);
		insert opp1;

		Order__c order = TestDataSetupClass.createOrder(opp1);
		insert order; 

		Product_Order__c po= TestDataSetupClass.createProductOrder(order);
		po.Status__c = 'Draft';
		insert po;

		CSPOFA__Orchestration_Process__c orchProcess1 = new CSPOFA__Orchestration_Process__c();
		orchProcess1.Name = 'Test Template';
		orchProcess1.CSPOFA__Priority__c = '3 - High';
		orchProcess1.CSPOFA__Processing_Mode__c = 'Background';
		orchProcess1.CSPOFA__Orchestration_Process_Template__c = template.Id;
		orchProcess1.Order__c = order.Id;
		insert orchProcess1;

		CSPOFA__Orchestration_Process__c orchProcess2 = new CSPOFA__Orchestration_Process__c();
		orchProcess2.Name = 'Test Template';
		orchProcess2.CSPOFA__Priority__c = '3 - High';
		orchProcess2.CSPOFA__Processing_Mode__c = 'Background';
		orchProcess2.CSPOFA__Orchestration_Process_Template__c = template.Id;
		orchProcess2.Product_Order__c = po.Id;
		insert orchProcess2;



		Test.startTest();
		CS_ResetOrchestratorPrioritySchedulable resetOrchPriority = new CS_ResetOrchestratorPrioritySchedulable();
		Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
		system.schedule('ResetOrchestratorPriority', CRON_EXP, resetOrchPriority); 

		Test.stopTest();

	}
	
	
	
}