@isTest
private class NXX2_Batch_Send_Email_Outstanding_Test {
	

	 static public void setupTestData(){
		User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
		System.runAs(currentUser){
			NXX2_TestUtility.disableAllTriggerDuringTesting();

			//Create portal account owner
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

			//Create account
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
					
			//Create contact
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

			

			

			List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),portalAccount1,contact1);
            opportunities.get(0).Payer_Account__c = portalAccount2.Id;
			insert opportunities;

			System.debug('opportunities' + opportunities);

			// campaign Order

			Order__c campaignOrder = new Order__c();
			campaignOrder.Opportunity__c = opportunities[0].Id;
			campaignOrder.Campaign_Customer_Contact__c = contact1.id; 
			campaignOrder.Account__c = portalAccount1.id; 
			insert campaignOrder;

			System.debug('campaignOrder' + campaignOrder);
			Product_Order__c productOrder;

			List<Product_Order__c> orders = new List<Product_Order__c>();
			for(Integer i = 0; i < 2; i++){
				productOrder = new Product_Order__c();
				productOrder.Order__c = campaignOrder.id;
				productOrder.Status__c = 'In Progress';
				orders.add(productOrder);
			}
			insert orders;

			System.debug('orders' + orders);
   
            SocialCampaign__c socialCampaignForApproved = NXX2_TestUtility.createProof(orders[0].Id);
            SocialCampaign__c socialCampaignForRequestChange = NXX2_TestUtility.createProof(orders[1].Id); 
			SocialCampaign__c socialCampaignForWithCustomer = NXX2_TestUtility.createProof(orders[1].Id); 


            List<SocialCampaign__c> proofsForSocial = new List<SocialCampaign__c>();
            proofsForSocial.add(socialCampaignForApproved);
            proofsForSocial.add(socialCampaignForRequestChange);
            proofsForSocial.add(socialCampaignForWithCustomer);

			System.debug('proofsForSocial' + proofsForSocial);

            List<Customer_Task__c> customerActivity = NXX2_TestUtility.createCustomerActivity(proofsForSocial);
			System.debug('customerActivity' + customerActivity);
			for(Customer_Task__c customerTask : customerActivity){
				customerTask.Status__c ='With Client';
			}
			update customerActivity;

            List<String> roles = new List<String>();
            Schema.DescribeFieldResult fieldResult = Contact_Role__c.Role__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple){
                roles.add(f.getValue());
            } 
			List<Customer_Role_Access__c> customerRoleAccessList = NXX2_TestUtility.createCustomerRoleAccess(roles);
            System.debug('customerRoleAccessList' + customerRoleAccessList);
            Contact_Role__c Contact_Role = new Contact_Role__c();
			Contact_Role.Account__c = portalAccount1.id;
			Contact_Role.Contact__c = contact1.id;
			Contact_Role.HasOptedInOfEmail__c=true;
			Contact_Role.Role__c  = 'NewsXtend Agency';
			insert Contact_Role;
			System.debug('Contact_Role' + Contact_Role);

			Customer_Task__Share customerTaskShare = new Customer_Task__Share();
			customerTaskShare.ParentId = customerActivity[0].Id;
			customerTaskShare.UserOrGroupId=user1.Id;
			customerTaskShare.RowCause=Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c;
			customerTaskShare.AccessLevel='Edit';
			insert customerTaskShare;
			system.debug('insert accountShare' +customerTaskShare);


		}
		
	}

	static testMethod void sendEmailForOutstandingTask(){
        setupTestData();  
        Test.startTest();

            NXX2_Batch_Send_Email_Outstanding_Tasks obj = new NXX2_Batch_Send_Email_Outstanding_Tasks();
            DataBase.executeBatch(obj); 
            
        Test.stopTest();               
    }

	
}