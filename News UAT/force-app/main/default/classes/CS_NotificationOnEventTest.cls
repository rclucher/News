@isTest
public class CS_NotificationOnEventTest {

	@isTest static void test_method_one() {

	EmailTemplate eTemplate;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			eTemplate = new EmailTemplate(
				isActive = true,
				Name = 'CO Event Notification',
				DeveloperName = 'unique_TestTemplate',
				TemplateType = 'text',
				FolderId = UserInfo.getUserId()
			);
			insert eTemplate;
		}

	EmailTemplate eTemplate2;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			eTemplate2 = new EmailTemplate(
				isActive = true,
				Name = 'PO Event Notification',
				DeveloperName = 'unique_TestTemplate2',
				TemplateType = 'text',
				FolderId = UserInfo.getUserId()
			);
			insert eTemplate2;
		}

		User currentUser = [SELECT Id, Name, LastName, AccountId, Account.Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		Contact newContact = new Contact(
									FirstName = currentUser.Name,
									LastName = currentUser.LastName,
									AccountId = currentUser.AccountId,
									Title = 'Test title',
									Contact_Status__c = 'Active',
									Email = currentUser.Email
								);
		insert newContact;



System.debug('+++ newContact.AccountId = ' + newContact.AccountId);
		Opportunity opportunity = new Opportunity(
											Name = 'Test Opportunity ',
											CloseDate = date.today().addDays(10),
											StageName = 'Qualify Opportunity',
											Classification__c = 'New Business',
											Description = 'Test Opportunity',
											Revenue_Group__c = 'House',
											Is_Test__c = true,
											Campaign_Start_Date__c = date.today(),
											NLM_Opportunity_Team_Member_1__c = UserInfo.getUserId(),
											NLM_Opportunity_Team_Member_2__c = UserInfo.getUserId(),
											NLM_Opportunity_Team_Member_3__c = UserInfo.getUserId(),
											Contact__c = newContact.Id
										);
		insert opportunity;

		Order__c order = new Order__c(
								Account__c = currentUser.AccountId,
								Opportunity__c = opportunity.Id,
								Assigned_Campaign_Manager__c = UserInfo.getUserId(),
								Assigned_Campaign_Manager_For_QA__c = UserInfo.getUserId(),
								Assigned_Setup_Coordinator__c = UserInfo.getUserId(),
								Sales_Representative__c = UserInfo.getUserId(),
								Campaign_Customer_Contact__c = newContact.Id,
								Customer_Contact__c = newContact.Id
							);
		insert order;

		//RecordType recordTyp = [SELECT Id, Name FROM RecordType LIMIT 1];


		Product_Order__c productOrder = new Product_Order__c(
															Account_Name__c = currentUser.Account.Name,
															//RecordTypeId = recordTyp.Id,
															Order__c = order.Id,
															Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
															Assigned_Fulfilment_Owner_For_QA__c = UserInfo.getUserId(),
															Assigned_Social_Owner__c = UserInfo.getUserId(),
															Assigned_Social_Owner_For_QA__c = UserInfo.getUserId()
														);
		insert productOrder;

		CSPOFA__Orchestration_Process_Template__c orchProcessTemplate = new CSPOFA__Orchestration_Process_Template__c(
															Name = 'Campaign Setup Test'
														);
		insert orchProcessTemplate;

		CSPOFA__Orchestration_Process__c orchProcess = new CSPOFA__Orchestration_Process__c (
															Name = 'Live Chat Setup',
															CSPOFA__Orchestration_Process_Template__c = orchProcessTemplate.Id,
															Order__c = order.Id,
															Product_Order__c = productOrder.Id
														);
		insert orchProcess;

		CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
															Name = 'Do task',
															CSPOFA__Orchestration_Process_Template__c = orchProcessTemplate.Id
														);
		insert stepTemplate;

		CSPOFA__Orchestration_Step__c orchStep1 = new CSPOFA__Orchestration_Step__c(
															Name = 'Orchestration Step Test1', 
															CSPOFA__Milestone_Label__c = 'FAQ sent to client',
															CSPOFA__Orchestration_Process__c = orchProcess.Id,
															CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
															CSPOFA__Milestone__c = true
														);
		insert orchStep1;

		CSPOFA__Orchestration_Step__c orchStep2 = new CSPOFA__Orchestration_Step__c(
															Name = 'Orchestration Step Test2', 
															CSPOFA__Milestone_Label__c = 'FAQ sent to client',
															CSPOFA__Orchestration_Process__c = orchProcess.Id,
															CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
															CSPOFA__Milestone__c = true
														);
		insert orchStep2;

		CSPOFA__Orchestration_Step__c orchStep3 = new CSPOFA__Orchestration_Step__c(
															Name = 'Orchestration Step Test3', 
															CSPOFA__Milestone_Label__c = 'FAQ sent to client',
															CSPOFA__Orchestration_Process__c = orchProcess.Id,
															CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
															CSPOFA__Milestone__c = true
														);
		insert orchStep3;

		RecordType milestoneRecType = [select Id, Name from RecordType where Name = 'Milestone' LIMIT 1];


		Notification_Event_Setting__c eventSetting = new Notification_Event_Setting__c (
															Process_Name__c = 'Campaign Setup Test',
															Step_Name__c = 'Do task'
														);
		if (milestoneRecType != null)
			eventSetting.RecordTypeId = milestoneRecType.Id;

		insert eventSetting;

		Notification_Event_Setting__c eventSettingQuery = [SELECT Id, Name, Key__c, Process_Name__c, Step_Name__c FROM Notification_Event_Setting__c WHERE Id = :eventSetting.Id];

		eventSetting = eventSettingQuery;

		update eventSetting;

		Notification_Event_Setting_User__c  eventSettingUser = new Notification_Event_Setting_User__c (
															User__c = UserInfo.getUserId(),
															Audience__c = 'Campaign Mgmt Team;PO Mgmt Team;Social Team;Sales',
															Notification_Event_Setting__c = eventSetting.Id,
															Active__c = true
														);
		insert eventSettingUser;

		Notification_Event_Setting_User__c eventSettingUserQuery = [SELECT Id,Name,User__c,Audience__c,Notification_Event_Setting__c,Notification_Event_Setting__r.Key__c,Active__c from Notification_Event_Setting_User__c where Id = :eventSettingUser.Id];

		eventSettingUser = eventSettingUserQuery;
		update eventSettingUser;


		CS_NotificationOnEvent noe = new CS_NotificationOnEvent();

		CS_NotificationOnEvent.notificationObjectChangeEventWrapper lstnotificationObjectChangeEventWrapper1 = new CS_NotificationOnEvent.notificationObjectChangeEventWrapper();
		lstnotificationObjectChangeEventWrapper1.objectType = CS_NotificationOnEvent.ObjectType.ProductOrder;
		lstnotificationObjectChangeEventWrapper1.FieldName = 'Name';
		lstnotificationObjectChangeEventWrapper1.objectId = productOrder.Id;
		lstnotificationObjectChangeEventWrapper1.Message = 'My message for product order';

		CS_NotificationOnEvent.notificationObjectChangeEventWrapper lstnotificationObjectChangeEventWrapper2 = new CS_NotificationOnEvent.notificationObjectChangeEventWrapper();
		lstnotificationObjectChangeEventWrapper2.objectType = CS_NotificationOnEvent.ObjectType.CampaignOrder;
		lstnotificationObjectChangeEventWrapper2.FieldName = 'Name';
		lstnotificationObjectChangeEventWrapper2.objectId = order.Id;
		lstnotificationObjectChangeEventWrapper2.Message = 'My message for order';

		CS_NotificationOnEvent.notificationButtonEventWrapper buttonWrapper1 = new CS_NotificationOnEvent.notificationButtonEventWrapper();
		buttonWrapper1.objectType = CS_NotificationOnEvent.ObjectType.ProductOrder;
		buttonWrapper1.ButtonName = 'save';
		buttonWrapper1.objectId = productOrder.Id;
		buttonWrapper1.Message = 'Message for notificationButtonEventWrapper';

		CS_NotificationOnEvent.notificationButtonEventWrapper buttonWrapper2 = new CS_NotificationOnEvent.notificationButtonEventWrapper();
		buttonWrapper2.objectType = CS_NotificationOnEvent.ObjectType.CampaignOrder;
		buttonWrapper2.ButtonName = 'save';
		buttonWrapper2.objectId = order.Id;
		buttonWrapper2.Message = 'Message for notificationButtonEventWrapper';

		Test.startTest();

		CS_NotificationOnEvent.AddMileStoneEvent(orchStep3.Id);
		CS_NotificationOnEvent.AddObjectChangeEvent(lstnotificationObjectChangeEventWrapper1);
		CS_NotificationOnEvent.AddObjectChangeEvent(lstnotificationObjectChangeEventWrapper2);

		CS_NotificationOnEvent.AddButtonEvent(buttonWrapper1);
		CS_NotificationOnEvent.AddButtonEvent(buttonWrapper2);

		CS_NotificationOnEvent.SendNotificationEmails();

		System.debug('+++ eventSettingUser = ' + eventSettingUser.Notification_Event_Setting__r.Key__c);
		Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}