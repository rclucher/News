@isTest
public with sharing class CS_TestBatchTierCalculation {
    @testSetup static void setup() {
        insert new Customer_Tier_Ranges__c(Lowerbound__c = 0,Upperbound__c = 5000, Name = 'TestTierRange');
		Account acc = new Account(Name='testTier1', No_Parent_Account__c=true);
        Account testAcc = new Account(Name='Test2', No_Parent_Account__c=true);
        insert new List<Account>{acc,testAcc};
            
		Contact ctct = TestDataSetupClass.createContact(acc);
		Opportunity opp = TestDataSetupClass.createOpportunity(acc,ctct);
        
        Contact testCtct = TestDataSetupClass.createContact(acc);
		Opportunity testOpp = TestDataSetupClass.createOpportunity(testAcc,testCtct);
        
        insert new List<Opportunity>{opp,testOpp};
            
		createPayment (acc.Id, 100, opp);
		createPayment (testAcc.Id, 0, testOpp);
    }
    
    
	static testMethod void testTierCalculation() {

		Account testAcc = [SELECT Id, No_Parent_Account__c FROM Account Where Name = 'Test2'];
        
		Test.startTest();

		CS_BatchTierCalculation job = new CS_BatchTierCalculation();
		job.query = 'select payment__r.order__r.account__c, Amount__c, Payment__r.order__r.Opportunity__r.accountid from payment_schedule__c where schedule_start_date__c = THIS_MONTH and status__c != ' + '\'Cancelled\' Limit 200';
		ID batchprocessid = Database.executeBatch(job);

		job = new CS_BatchTierCalculation(testAcc.Id);
		job.query = 'select payment__r.order__r.account__c, Amount__c, Payment__r.order__r.Opportunity__r.accountid from payment_schedule__c where schedule_start_date__c = THIS_MONTH and status__c != ' + '\'Cancelled\' Limit 200';
		batchprocessid = Database.executeBatch(job);

	/*	job = new CS_BatchTierCalculation(new List<Account>({testAcc}));
		job.query = 'select payment__r.order__r.account__c, Amount__c, Payment__r.order__r.Opportunity__r.accountid from payment_schedule__c where schedule_start_date__c = THIS_MONTH and status__c != ' + '\'Cancelled\' Limit 200';
		batchprocessid = Database.executeBatch(job);*/

		Test.stopTest();
		List<account> accounts = [select id, tier__c, name from account];
		/*for (Account accountTemp : accounts) {
			if (accountTemp.Name == 'testTier1')
				system.assertEquals(accountTemp.tier__c,'Tier 1','Tier level has not been set.');
			else
				system.assertEquals(accountTemp.tier__c,'Tier 2','Tier level has not been set.');
		}*/
	}

	private static void createPayment(Id accId, Decimal boost, Opportunity opp) {
		Date todayDate = Date.today();

        Date dateEndTemp = Date.newInstance(todayDate.year(),todayDate.month(),todayDate.day());
        String campEndDate =dateEndTemp.format();
        Order__c order = new Order__c(Account__c = accId, Opportunity__c = opp.Id);
        insert order;

		Payment__c payment = new Payment__c (
			Start_Date__c = todayDate,
			Order__c = order.Id);
		insert payment;
		/* this is throwing too many SOQl queries

		//List<Payment_Schedule__c> paySchedules = new List<Payment_Schedule__c>();

		/*for (Integer i=0; i<4; i++) {
			List<Payment_Line_Item__c> payLineItems = new List<Payment_Line_Item__c>();
			Payment_Schedule__c payRecSch = new Payment_Schedule__c(
				Name = 'Payment Schedule',
	            Schedule_Start_Date__c = todayDate.addMonths(i),
	            
	            Schedule_End_Date__c = date.parse(campEndDate).addMonths(i+1),
	            Status__c = 'Pending',
	            Payment__c = payment.id);
				insert payRecSch;

			for (Integer j=0; j<2; j++) {
				Payment_Line_Item__c pli = new Payment_Line_Item__c (
					Payment_Schedule__c = payRecSch.id,
		            Name ='test',                
		            Type__c = 'Normal',
		            Basic_Price__c = 50+i,
		            Quantity__c = j+1,
		            Price__c = 60 + boost
	            );
	            payLineItems.add(pli);
			}
			insert payLineItems;
		}*/
	List<Payment_Schedule__c> payResearchList = new List<Payment_Schedule__c>();
    List<Payment_Line_Item__c> paylineresearchlist =  new List<Payment_Line_Item__c>();
            List<Payment_Line_Item__c> payLineItems = new List<Payment_Line_Item__c>();        

		 for (Integer i=0; i<100; i++) {

            Payment_Schedule__c payRecSch = new Payment_Schedule__c(
                Name = 'Payment Schedule',
                Schedule_Start_Date__c = todayDate.addMonths(i),
                
                Schedule_End_Date__c = date.parse(campEndDate).addMonths(i+1),
                Status__c = 'Pending',
                Payment__c = payment.id);
            payResearchList.add(payRecSch);
            
        }
        upsert  payResearchList;
       if(payResearchList.size()>0){
            for( Payment_Schedule__c pr : payResearchList){
                Payment_Line_Item__c pli = new Payment_Line_Item__c (
                    Payment_Schedule__c = pr.id,
                    Name ='test',                
                    Type__c = 'Normal',
                    Basic_Price__c = 50+Math.random(),
                    Quantity__c = 1,
                    Price__c = 60 + boost);
                paylineresearchlist.add(pli);
            }
        }
        upsert paylineresearchlist;
    } 
}