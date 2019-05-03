@isTest
private class NXX2_ContactListPageController_Test {
	
	@isTest static void test_method_one() {
		NXX2_TestUtility.disableAllTriggerDuringTesting();
        User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
		System.runAs(currentUser){
		Account portalAccount1 = new Account(
			Name = 'TestAccount',
			//OwnerId = portalAccountOwner1.Id,
			BillingPostalCode='2000',
			BillingCountry = 'Australia',
			BillingState = 'NSW',
			BillingCity = 'Sydney',
			BillingStreet = 'George Street',
			DPID_Primary_Address__c = '555',
			AccountNumber = '12345678901',
			Phone = '61021234567',
			Revenue_Group__c = 'Classified - Marketplace',
			No_Parent_Account__c = true,
			Total_Customer_Spend__c = 0,
			Total_Agency_Spend__c = 0,
			Total_Group_Spend__c = 0            
		);
		Database.insert(portalAccount1);
				
		//Create contact
		Contact contact1 = new Contact(
		FirstName = 'Test',
		Lastname = 'McTesty',
		AccountId = portalAccount1.Id,
		Email = System.now().millisecond() + 'test@test.com',
		Title = 'Test title',
		Contact_Status__c = 'Active'
		);
		Database.insert(contact1);
		Test.startTest();
		NXX2_ContactListPageController.getTotalCount(contact1.Email);
		Integer limits = 0;
		Integer offsets = 10;
		String searchKeyword = contact1.Email;
		NXX2_ContactListPageController.getContacts(limits,offsets,searchKeyword);
        Test.stopTest();
		}
	}
	
	
}