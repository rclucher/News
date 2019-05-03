@isTest
public class CS_CustomLookupFactoryTest {
	
	@isTest public static void insertPriceItems() {
		List<cspmb__Price_Item__c> priceItems = new List<cspmb__Price_Item__c>{
													new cspmb__Price_Item__c(Name = 'Price Item 1', 
																			Segment__c = 'SME',
																			State__c = 'NSW',
																			Client_Outcome__c = 'Sales',
																			Media_Type__c = 'Print',
																			Bundle_Name__c = 'Plus',
																			Impact__c = 'Pro',
																			Duration__c = '13',
																			cspmb__Effective_Start_Date__c = Date.valueOf('2018-01-01'), 
									   										cspmb__Effective_End_Date__c = null),
													new cspmb__Price_Item__c(Name = 'Price Item 2', 
																			Segment__c = 'SME',
																			State__c = 'NSW',
																			Client_Outcome__c = 'Sales',
																			Media_Type__c = 'Print',
																			Bundle_Name__c = 'Plus',
																			Impact__c = 'Pro',
																			Duration__c = '26',
																			cspmb__Effective_Start_Date__c = Date.valueOf('2018-01-01'), 
									    									cspmb__Effective_End_Date__c = Date.valueOf('2018-03-01'))};

		// Note there is a Workflow rule that changes the Name of the record to be 
		// "Media_Type__c | Segment__c | State__c | Client_Outcome__c | Bundle_Name__c | Impact__c | Duration__c"
		insert priceItems;
	}
}