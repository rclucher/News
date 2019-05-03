@isTest
private class NXX2_AccountListController_Test {
	
	@isTest static void test_method_one() {
        NXX2_TestUtility.disableAllTriggerDuringTesting();
		User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
		System.runAs(currentUser){
			//Create portal account owner
			UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
			Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
			User portalAccountOwner1 = new User(
				UserRoleId = portalRole.Id,
				ProfileId = profile1.Id,
				Username = System.now().millisecond() + 'test2@test.com',
				Alias = 'batman',
				Email='bruce.wayne@wayneenterprises.com',
				EmailEncodingKey='UTF-8',
				Firstname='Bruce',
				Lastname='Wayne',
				LanguageLocaleKey='en_US',
				LocaleSidKey='en_US',
				TimeZoneSidKey='America/Chicago'
			);
			Database.insert(portalAccountOwner1);

			//Create account
			Account portalAccount1 = new Account(
				Name = 'TestAccount',
				OwnerId = portalAccountOwner1.Id,
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
					
			//Create user
			Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%NewsXtend My Account Community Read Only%' Limit 1];
			User user1 = new User(
				Username = System.now().millisecond() + 'test12345@test.com',
				ContactId = contact1.Id,
				ProfileId = portalProfile.Id,
				Alias = 'test123',
				Email = 'test12345@test.com',
				EmailEncodingKey = 'UTF-8',
				LastName = 'McTesty',
				CommunityNickname = 'test12345',
				TimeZoneSidKey = 'America/Los_Angeles',
				LocaleSidKey = 'en_US',
				LanguageLocaleKey = 'en_US'
			);
			insert(user1);

         system.debug('insert user1' +user1);
        
		AccountShare accountShare = new AccountShare();
		accountShare.AccountId = portalAccount1.Id;
		accountShare.UserOrGroupId=user1.Id;
		accountShare.OpportunityAccessLevel='Edit';
		accountShare.AccountAccessLevel='Edit';
		accountShare.CaseAccessLevel='Edit';
		insert accountShare;
		system.debug('insert accountShare' +accountShare);

		Test.startTest();
        NXX2_AccountListController.getAllAccessibleAccount(contact1.Id); 
		NXX2_AccountListController.getLoggedInUserContact();
		NXX2_AccountListController.getIconName('Account');
		NXX2_AccountListController.getAccountsListAccessibleToCustomer();
        Test.stopTest();
		}
	}
	
	
	
}