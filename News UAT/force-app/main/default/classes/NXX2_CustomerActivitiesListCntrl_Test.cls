@isTest
private class NXX2_CustomerActivitiesListCntrl_Test {
	
	static testMethod void testcCustomerActivitiesList(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
		User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
		System.runAs(currentUser){
			UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
			Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
			User portalAccountOwner1 = new User(
				UserRoleId = portalRole.Id,
				ProfileId = profile1.Id,
				Username = System.now().millisecond() + 'test2@test.com',
				Alias = 'batman',
				Email='test@testSalesforce.com',
				EmailEncodingKey='UTF-8',
				Firstname='Bruce',
				Lastname='Wayne',
				LanguageLocaleKey='en_US',
				LocaleSidKey='en_US',
				TimeZoneSidKey='America/Chicago'
			);
			Database.insert(portalAccountOwner1);
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
			Account portalAccount2 = new Account(
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
			Database.insert(portalAccount2);
			Contact contact1 = new Contact(
				FirstName = 'Test',
				Lastname = 'McTesty',
				AccountId = portalAccount1.Id,
				Email = System.now().millisecond() + 'test@test.com',
                Title = 'Test title',
                Contact_Status__c = 'Active',
				NewsXtend_My_Account_Access__c=true
			);
			Database.insert(contact1);
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
			AccountShare accountShare = new AccountShare();
			accountShare.AccountId = portalAccount1.Id;
			accountShare.UserOrGroupId=user1.Id;
			accountShare.OpportunityAccessLevel='Edit';
			accountShare.AccountAccessLevel='Edit';
			accountShare.CaseAccessLevel='Edit';
			insert accountShare;
			List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),portalAccount1,contact1);
            opportunities.get(0).Payer_Account__c = portalAccount2.Id;
			insert opportunities;
			Order__c campaignOrder = new Order__c();
			campaignOrder.Opportunity__c = opportunities[0].Id;
			campaignOrder.Campaign_Customer_Contact__c = contact1.id; 
			campaignOrder.Account__c = portalAccount1.id; 
			insert campaignOrder;
			Product_Order__c productOrder;
			List<Product_Order__c> orders = new List<Product_Order__c>();
			for(Integer i = 0; i < 2; i++){
				productOrder = new Product_Order__c();
				productOrder.Order__c = campaignOrder.id;
				productOrder.Status__c = 'In Progress';
				orders.add(productOrder);
			}
			insert orders;
            SocialCampaign__c socialCampaignForApproved = NXX2_TestUtility.createProof(orders[0].Id);
            SocialCampaign__c socialCampaignForRequestChange = NXX2_TestUtility.createProof(orders[1].Id); 
			SocialCampaign__c socialCampaignForWithCustomer = NXX2_TestUtility.createProof(orders[1].Id); 
            List<SocialCampaign__c> proofsForSocial = new List<SocialCampaign__c>();
            proofsForSocial.add(socialCampaignForApproved);
            proofsForSocial.add(socialCampaignForRequestChange);
            proofsForSocial.add(socialCampaignForWithCustomer);
            List<Customer_Task__c> customerActivity = NXX2_TestUtility.createCustomerActivity(proofsForSocial);
			List<Order__c> campaignOrderList= new List<Order__c>();
			campaignOrderList.add(campaignOrder);
            Test.startTest();
            NXX2_CustomerActivitiesListController.fetchCustomerTask(proofsForSocial.get(0).Id,'SocialCampaign__c',true);
			NXX2_CustomerActivitiesListController.fetchCustomerTask(orders.get(0).Id,'Product_Order__c',true);
			NXX2_CustomerActivitiesListController.fetchCustomerTask(campaignOrderList.get(0).Id,'Order__c',true);
			NXX2_CustomerActivitiesListController.updateCustomerTaskStatus(customerActivity.get(0).Id);
			NXX2_CustomerActivitiesListController.getIconName('Customer_Task__c');
			NXX2_CustomerActivitiesListController.fetchLoggedInUsersDetails();
			NXX2_CustomerActivitiesListController.getCustomerActivityRecordTypeForProof();
			NXX2_CustomerActivitiesListController.getAllCommentsLinkedToType();
			NXX2_CustomerActivitiesListController.getAllAccessibleAccountCustomerTask(contact1.id);
            
            Test.stopTest();  
		}
	}
}