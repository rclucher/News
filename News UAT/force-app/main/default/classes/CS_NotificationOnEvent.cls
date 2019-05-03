public class CS_NotificationOnEvent {
//whatever "event" happens at the end it has to be in a context of PO or CO


	public enum EventType {eMileStone,eObject,eButton}

	public enum ObjectType {ProductOrder,CampaignOrder,Opportunity}

	private class notificationEventWrapper 
	{
		public String Key {get;set;}	
		
		public EventType eventType {get;set;}		
		public ObjectType objectType {get;set;}
		
		public Id objectId {get;set;} 
		public string Message {get;set;}

		//potential recepients
		public Map<Id,UserDataFromSetting> mapUserDataFromContext {get;set;}

		//final recipients - if empty - don't send
		public Map<Id,UserDataFromSetting> mapUserDataForSending {get;set;}

		public emailTemplateData emailTemplateFields {get;set;}

		public notificationEventWrapper()
		{
			mapUserDataFromContext = new Map<Id,UserDataFromSetting>();
			mapUserDataForSending = new Map<Id,UserDataFromSetting>();
			emailTemplateFields = new emailTemplateData();
		}
	}

	private static List<notificationEventWrapper> lstnotificationEventWrapper;

	private static Map<String,Map<Id,UserDataFromSetting>> mapEventKeyUserDataFromSetting;

	private static Map<String,String> mapKeyCSEventId;

	private static Set<Id> setStepId;

	private Static Integer MileStoneEventCounter;
	private Static Integer ObjectEventCounter;
	private Static Integer ButtonEventCounter;

	private static EmailTemplate COEmailTemplate;
	private static EmailTemplate POEmailTemplate;



	static
	{
		if (lstnotificationEventWrapper==null) lstnotificationEventWrapper = new List<notificationEventWrapper>();
		
		if (mapEventKeyUserDataFromSetting==null) mapEventKeyUserDataFromSetting = new Map<String,Map<Id,UserDataFromSetting>>();

		if (mapKeyCSEventId==null) mapKeyCSEventId=new Map<String,String>();

		if (setStepId==null) setStepId=new Set<Id>();

		MileStoneEventCounter=0;
		ObjectEventCounter=0;
		ButtonEventCounter=0;
	}

	private class UserDataFromSetting
	{
		public Id UserId {get;set;}
		public String UserName {get;set;}
		public string Email {get;set;}
		public string FinalAudience {get;set;} 
		public Set<String> setAudienceType {get;set;}


		public UserDataFromSetting()
		{
			setAudienceType = new Set<String>();
		}
	}

	private class emailTemplateData 
	{
		public String accountName {get;set;}
		public String accountId {get;set;}
		public String opportunityName {get;set;}
		public String opportunityId {get;set;}
		public String campaignOrderName {get;set;}
		public String campaignOrderId {get;set;}
		public String productOrderRecordTypeId {get;set;}
		public String productOrderRecordTypeName {get;set;}
		public String productOrderName {get;set;}
		public String productOrderId {get;set;}
		public String productOrderProductNodeName {get;set;}
		public String productOrderProductNodeId {get;set;}
		public String eventInfo {get;set;}
		public String actionToDo {get;set;}
		public String salesOrderName {get;set;}
		public String salesOrderId {get;set;}
		public String opportunityOwnerId {get;set;}
		public String opportunityOwnerName {get;set;}
		public String opportunityOwnersManagerId {get;set;}
		public String opportunityOwnersManagerName {get;set;}
		public String assignedCampaignManagerId {get;set;}
		public String assignedCampaignManagerName {get;set;}
		public String assignedFullfilmentOwnerId {get;set;}
		public String assignedFullfilmentOwnerName {get;set;}

		public emailTemplateData()
		{
			accountName='';
			accountId='';
			opportunityName='';
			opportunityId='';
			campaignOrderName='';
			campaignOrderId='';
			productOrderRecordTypeId='';
			productOrderRecordTypeName='';
			productOrderName='';
			productOrderId='';
			productOrderProductNodeName='';
			productOrderProductNodeId='';
			eventInfo='';
			actionToDo='';
			salesOrderName='';
			salesOrderId='';
			opportunityOwnerId='';
			opportunityOwnerName='';
			opportunityOwnersManagerId='';
			opportunityOwnersManagerName='';
			assignedCampaignManagerId='';
			assignedCampaignManagerName='';
			assignedFullfilmentOwnerId='';
			assignedFullfilmentOwnerName='';
		}
	}


	public class notificationObjectChangeEventWrapper
	{
		public ObjectType objectType {get;set;}
		public String FieldName {get;set;}
		public String FromValue {get;set;}
		public string ToValue {get;set;}


		public Id objectId {get;set;} //original object Id
		public string Message {get;set;}

		public notificationObjectChangeEventWrapper()
		{
			Message='';
		}
	}

	public class notificationButtonEventWrapper
	{
		public ObjectType objectType {get;set;}
		public String ButtonName {get;set;}

		public Id objectId {get;set;} //original object Id
		public string Message {get;set;}

		public notificationButtonEventWrapper()
		{
			Message='';
		}
	}

	private static String CreateMileStoneKey(string ProcessName, string StepName)
	{
		string Key = 'Milestone' + '_' + ProcessName + '_' + StepName;

		return Key;
	}

	private static String CreateObjectKey(ObjectType pObjectType, string FieldName, string FromValue, string ToValue)
	{
		string ObjectName;
		
		ObjectName = TranslateObjectName(pObjectType,false);

		string Key = 'Object' + '_' + ObjectName + '_' + FieldName + '_' + FromValue + '_' + ToValue;

		return Key;
	} 


	private static string TranslateObjectName(ObjectType pObjectType, Boolean IsLabel)
	{
		string ObjectName='';

		if (IsLabel)
		{
			if (pObjectType==ObjectType.CampaignOrder)
				ObjectName='Campaign Order';
			else if (pObjectType==ObjectType.ProductOrder)
				ObjectName='Product Order';
			else if (pObjectType==ObjectType.Opportunity)
				ObjectName='Opportunity';
		}
		else
		{
			if (pObjectType==ObjectType.CampaignOrder)
				ObjectName='Order__c';
			else if (pObjectType==ObjectType.ProductOrder)
				ObjectName='Product_Order__c';
			else if (pObjectType==ObjectType.Opportunity)
				ObjectName='Opportunity';
	
		}

		return ObjectName;
	}

	private static String CreateButtonKey(ObjectType pObjectType, string ButtonName)
	{
		string ObjectName = TranslateObjectName(pObjectType,false);

		string Key = 'Button' + '_' + ObjectName + '_' + ButtonName;

		return Key;
	}

	public static void AddMileStoneEvent(Id stepId)
	{
		setStepId.add(stepId);
		MileStoneEventCounter++;
	}

	private static void ProcessMileStoneEvents()
	{
		//Map<Id,String> mapStepIdMessage = new Map<Id,String>();
		
		if (setStepId.size()>0)
		{
			List<CSPOFA__Orchestration_Step__c> lstStep =[select Id,CSPOFA__Milestone_Label__c,CSPOFA__Orchestration_Process__c, 
				CSPOFA__Orchestration_Process__r.Order__c, CSPOFA__Orchestration_Process__r.Product_Order__c,
				CSPOFA__Orchestration_Process__r.CSPOFA__Orchestration_Process_Template__r.Name,
				CSPOFA__Orchestration_Step_Template__r.Name, CSPOFA__Milestone__c
				from CSPOFA__Orchestration_Step__c 
				where Id in : setStepId];

			for (CSPOFA__Orchestration_Step__c tmpStep : lstStep)
			{
				if ((tmpStep.CSPOFA__Orchestration_Process__r.Product_Order__c!=null) || (tmpStep.CSPOFA__Orchestration_Process__r.Order__c!=null))
				{
					notificationEventWrapper tmpnotificationEventWrapper = new notificationEventWrapper();
					if (tmpStep.CSPOFA__Orchestration_Process__r.Product_Order__c!=null)
					{
						tmpnotificationEventWrapper.objectType=ObjectType.ProductOrder;
						tmpnotificationEventWrapper.objectId=tmpStep.CSPOFA__Orchestration_Process__r.Product_Order__c; 
					}
					else
					{
						tmpnotificationEventWrapper.objectType=ObjectType.CampaignOrder;
						tmpnotificationEventWrapper.objectId=tmpStep.CSPOFA__Orchestration_Process__r.Order__c;
					}

					tmpnotificationEventWrapper.EventType=EventType.eMileStone;

					tmpnotificationEventWrapper.Key=CreateMileStoneKey(tmpStep.CSPOFA__Orchestration_Process__r.CSPOFA__Orchestration_Process_Template__r.Name,tmpStep.CSPOFA__Orchestration_Step_Template__r.Name);
					tmpnotificationEventWrapper.Message= 'Step ' + tmpStep.CSPOFA__Orchestration_Process__r.CSPOFA__Orchestration_Process_Template__r.Name + '-' + tmpStep.CSPOFA__Orchestration_Step_Template__r.Name + ' has been completed';

					/*
					string tmpMessage = mapStepIdMessage.get(tmpStep.Id);

					if ((tmpMessage!=null) && (tmpMessage!=''))
						tmpnotificationEventWrapper.Message=tmpMessage;
					else
						tmpnotificationEventWrapper.Message= 'Step ' + tmpStep.CSPOFA__Orchestration_Process__r.CSPOFA__Orchestration_Process_Template__r.Name + '-' + tmpStep.CSPOFA__Orchestration_Step_Template__r.Name + ' has been completed';
					*/
					lstnotificationEventWrapper.add(tmpnotificationEventWrapper);
				}
			}
		}
	}


	private static notificationEventWrapper AddObjectChangeEventVariation(notificationObjectChangeEventWrapper tmpnotificationObjectChangeEventWrapper, String FromValue, string ToValue)
	{
		notificationEventWrapper tmpnotificationEventWrapper = new notificationEventWrapper();
		emailTemplateData emailTemplate = new emailTemplateData();
		tmpnotificationEventWrapper.emailTemplateFields = emailTemplate;
		tmpnotificationEventWrapper.eventType=EventType.eObject;
		tmpnotificationEventWrapper.objectType=tmpnotificationObjectChangeEventWrapper.objectType;
		
		tmpnotificationEventWrapper.Key=CreateObjectKey(tmpnotificationObjectChangeEventWrapper.objectType,
			tmpnotificationObjectChangeEventWrapper.FieldName,FromValue,ToValue);

		tmpnotificationEventWrapper.objectId=tmpnotificationObjectChangeEventWrapper.objectId;
		
		if (tmpnotificationObjectChangeEventWrapper.Message!='')
			tmpnotificationEventWrapper.Message=tmpnotificationObjectChangeEventWrapper.Message;
		else
			tmpnotificationEventWrapper.Message='Change of object ' + TranslateObjectName(tmpnotificationObjectChangeEventWrapper.objectType,true) 
				+ '.' + tmpnotificationObjectChangeEventWrapper.FieldName + ' from ' + tmpnotificationObjectChangeEventWrapper.FromValue +
				' to ' + tmpnotificationObjectChangeEventWrapper.ToValue;

		return tmpnotificationEventWrapper;
	}

	public static void AddObjectChangeEvent(notificationObjectChangeEventWrapper tmpnotificationObjectChangeEventWrapper)
	{
		notificationEventWrapper tmpnotificationEventWrapper;

		tmpnotificationEventWrapper=AddObjectChangeEventVariation(tmpnotificationObjectChangeEventWrapper,tmpnotificationObjectChangeEventWrapper.FromValue,tmpnotificationObjectChangeEventWrapper.ToValue);
		lstnotificationEventWrapper.add(tmpnotificationEventWrapper);

		tmpnotificationEventWrapper=AddObjectChangeEventVariation(tmpnotificationObjectChangeEventWrapper,tmpnotificationObjectChangeEventWrapper.FromValue,'*');
		lstnotificationEventWrapper.add(tmpnotificationEventWrapper);

		tmpnotificationEventWrapper=AddObjectChangeEventVariation(tmpnotificationObjectChangeEventWrapper,'*',tmpnotificationObjectChangeEventWrapper.ToValue);
		lstnotificationEventWrapper.add(tmpnotificationEventWrapper);

		tmpnotificationEventWrapper=AddObjectChangeEventVariation(tmpnotificationObjectChangeEventWrapper,'*','*');
		lstnotificationEventWrapper.add(tmpnotificationEventWrapper);

		ObjectEventCounter++;
	}

	public static Boolean HasEvents()
	{
		Boolean ret=false;

		if (MileStoneEventCounter+ObjectEventCounter+ButtonEventCounter>0)
			ret=true;

		System.debug('***MileStoneEventCounter=' + MileStoneEventCounter);
		System.debug('***ObjectEventCounter=' + ObjectEventCounter);
		System.debug('***ButtonEventCounter=' + ButtonEventCounter);



		return ret;
	}


	public static void AddButtonEvent(notificationButtonEventWrapper tmpnotificationButtonEventWrapper)
	{
		
		notificationEventWrapper tmpnotificationEventWrapper = new notificationEventWrapper();
		emailTemplateData emailTemplate = new emailTemplateData();
		tmpnotificationEventWrapper.emailTemplateFields = emailTemplate;
		tmpnotificationEventWrapper.eventType=EventType.eButton;
		
		if (tmpnotificationButtonEventWrapper.objectType==ObjectType.Opportunity)
		{
			List<Order__c> lstCO = [select Id, Opportunity__c from Order__c where Opportunity__c=:tmpnotificationButtonEventWrapper.objectId];

			tmpnotificationEventWrapper.objectType=ObjectType.CampaignOrder;
			tmpnotificationEventWrapper.objectId = lstCO[0].Id;
		}
		else
		{
			tmpnotificationEventWrapper.objectType=tmpnotificationButtonEventWrapper.objectType;
			tmpnotificationEventWrapper.objectId=tmpnotificationButtonEventWrapper.objectId;
		}
			
		tmpnotificationEventWrapper.Key = CreateButtonKey(tmpnotificationButtonEventWrapper.objectType,tmpnotificationButtonEventWrapper.ButtonName);

		if (tmpnotificationButtonEventWrapper.Message!='')
			tmpnotificationEventWrapper.Message=tmpnotificationButtonEventWrapper.Message;
		else
			tmpnotificationEventWrapper.Message='Button ' + TranslateObjectName(tmpnotificationButtonEventWrapper.objectType,true) + '.' + tmpnotificationButtonEventWrapper.ButtonName + ' has been clicked';
		

		lstnotificationEventWrapper.add(tmpnotificationEventWrapper);
		
		ButtonEventCounter++;
	}

	private static void AssignCOFieldContentToAudience(Order__c CO, Map<Id,UserDataFromSetting> pUserDataFromContext)
	{
		Id UserId;
		String AudienceType;
		
		if (CO.Opportunity__r.OwnerId!=null)
		{
			UserId = CO.Opportunity__r.OwnerId;
			System.debug('***CO.Opportunity__r.OwnerId=' + CO.Opportunity__r.OwnerId);
			AudienceType = 'Sales'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (CO.Sales_Representative__c!=null)
		{
			UserId = CO.Sales_Representative__c;
			System.debug('***CO.Sales_Representative__c=' + CO.Sales_Representative__c);
			AudienceType = 'Sales'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (CO.Assigned_Campaign_Manager__c!=null)
		{
			UserId = CO.Assigned_Campaign_Manager__c;
			System.debug('***CO.Assigned_Campaign_Manager__c=' + CO.Assigned_Campaign_Manager__c);
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (CO.Assigned_Campaign_Manager_For_QA__c!=null)
		{
			UserId = CO.Assigned_Campaign_Manager_For_QA__c;
			System.debug('***CO.Assigned_Campaign_Manager_For_QA__c=' + CO.Assigned_Campaign_Manager_For_QA__c);
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (CO.Assigned_Setup_Coordinator__c!=null)
		{
			UserId = CO.Assigned_Setup_Coordinator__c;
			System.debug('***CO.Assigned_Setup_Coordinator__c=' + CO.Assigned_Setup_Coordinator__c);
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		System.debug('***pUserDataFromContext=' + pUserDataFromContext);

	}

	private static void AssignPOFieldContentToAudience(Product_Order__c PO, Map<Id,UserDataFromSetting> pUserDataFromContext)
	{
		Id UserId;
		String AudienceType;
		
		if (PO.Order__r.Opportunity__r.OwnerId!=null)
		{
			UserId = PO.Order__r.Opportunity__r.OwnerId;
			AudienceType = 'Sales'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Order__r.Sales_Representative__c!=null)
		{
			UserId = PO.Order__r.Sales_Representative__c;
			AudienceType = 'Sales'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Assigned_Fulfilment_Owner__c!=null)
		{
			UserId = PO.Assigned_Fulfilment_Owner__c;
			AudienceType = 'PO Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Assigned_Fulfilment_Owner_For_QA__c!=null)
		{
			UserId = PO.Assigned_Fulfilment_Owner_For_QA__c;
			AudienceType = 'PO Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Assigned_Social_Owner__c!=null)
		{
			UserId = PO.Assigned_Social_Owner__c;
			AudienceType = 'Social Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Assigned_Social_Owner_For_QA__c!=null)
		{
			UserId = PO.Assigned_Social_Owner_For_QA__c;
			AudienceType = 'Social Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Order__r.Assigned_Campaign_Manager__c!=null)
		{
			UserId = PO.Order__r.Assigned_Campaign_Manager__c;
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Order__r.Assigned_Campaign_Manager_For_QA__c!=null)
		{
			UserId = PO.Order__r.Assigned_Campaign_Manager_For_QA__c;
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}

		if (PO.Order__r.Assigned_Setup_Coordinator__c!=null)
		{
			UserId = PO.Order__r.Assigned_Setup_Coordinator__c;
			AudienceType = 'Campaign Mgmt Team'; 
			AddUserDataFromContext(pUserDataFromContext,UserId,AudienceType);
		}
	}


	private static void GetNeededData()
	{
		List<Id> lstPOId = new List<Id>();
		List<Id> lstCOId = new List<Id>();
		map<Id,Order__c> mapCO;
		map<Id,Product_Order__c> mapPO;


		for (notificationEventWrapper tmpnotificationEventWrapper : lstnotificationEventWrapper)
		{
			if (tmpnotificationEventWrapper.objectType==ObjectType.CampaignOrder)
			{
				lstCOId.add(tmpnotificationEventWrapper.objectId);
			}
			else if (tmpnotificationEventWrapper.objectType==ObjectType.ProductOrder)
			{
				lstPOId.add(tmpnotificationEventWrapper.objectId);
			}
		}

		if (lstCOId.size()>0)
		{
			mapCO = new map<Id,Order__c>([SELECT Id, Name, Account__c, Account__r.Name, Opportunity__c, 
				Opportunity__r.Name, Sales_Order__c, Sales_Order__r.Name,
				CreatedById, LastModifiedById, OwnerId, Opportunity__r.OwnerId, Opportunity__r.Owner.Name, 
				Opportunity__r.Owner.ManagerId,Opportunity__r.Owner.Manager.Name,
				Opportunity__r.NLM_Opportunity_Team_Member_1__c, Opportunity__r.NLM_Opportunity_Team_Member_2__c, 
				Opportunity__r.NLM_Opportunity_Team_Member_3__c, Opportunity__r.Contact__c,
				Assigned_Campaign_Manager__c, Assigned_Campaign_Manager__r.Name, 
				Assigned_Campaign_Manager_For_QA__c, Assigned_Setup_Coordinator__c, Sales_Representative__c,
				Campaign_Customer_Contact__c,Customer_Contact__c
				FROM Order__c 
				WHERE Id in : lstCOId]);
		}

		if (lstPOId.size()>0)
		{
			mapPO = new map<Id,Product_Order__c >([SELECT Id, Name, Account__c, Account_Name__c, 
				Opportunity__c, RecordTypeId, RecordType.Name, Product_Node__c, 
				Product_Node__r.Name, Order__c, Order__r.Name, Order__r.Sales_Order__c, Order__r.Sales_Order__r.Name, 
				Order__r.Opportunity__r.Name, 
				CreatedById, LastModifiedById, Order__r.OwnerId, Order__r.CreatedById, Order__r.LastModifiedById,  
				Order__r.Opportunity__r.OwnerId, Order__r.Opportunity__r.Owner.Name,
				Order__r.Opportunity__r.Owner.ManagerId,Order__r.Opportunity__r.Owner.Manager.Name,
				Assigned_Fulfilment_Owner__c,Assigned_Fulfilment_Owner__r.Name, 
				Assigned_Fulfilment_Owner_For_QA__c,Assigned_Fulfilment_Owner_For_QA__r.Name, 
				Assigned_Social_Owner__c,Assigned_Social_Owner_For_QA__c,
				Order__r.Assigned_Campaign_Manager__c,Order__r.Assigned_Campaign_Manager__r.Name, 
				Order__r.Assigned_Campaign_Manager_For_QA__c,Order__r.Assigned_Setup_Coordinator__c,
				Order__r.Sales_Representative__c, Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__c,
				Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__c, Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__c,
				Order__r.Opportunity__r.Contact__c, Order__r.Campaign_Customer_Contact__c, Order__r.Customer_Contact__c
				FROM Product_Order__c 
				WHERE Id in : lstPOId]);
		}

		for (notificationEventWrapper tmpnotificationEventWrapper : lstnotificationEventWrapper)
		{
			if (tmpnotificationEventWrapper.objectType==ObjectType.CampaignOrder)
			{
				Order__c tmpCO = mapCO.get(tmpnotificationEventWrapper.objectId);

				if (tmpCO.Account__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.accountName = tmpCO.Account__r.Name;
				if (tmpCO.Account__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.accountId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Account__c;
				if (tmpCO.Opportunity__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityName = tmpCO.Opportunity__r.Name;
				if (tmpCO.Opportunity__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Opportunity__c;
				if (tmpCO.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.campaignOrderName = tmpCO.Name;
				if (tmpCO.Id != null)
					tmpnotificationEventWrapper.emailTemplateFields.campaignOrderId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Id;
					
				tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeId = '';
				tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeName = '';
				tmpnotificationEventWrapper.emailTemplateFields.productOrderName = '';
				tmpnotificationEventWrapper.emailTemplateFields.productOrderId = '';
				tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeName = '';
				tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeId = '';
				
				if (tmpnotificationEventWrapper.Message != null)
					tmpnotificationEventWrapper.emailTemplateFields.eventInfo = tmpnotificationEventWrapper.Message;
				tmpnotificationEventWrapper.emailTemplateFields.actionToDo = '';
				
				if (tmpCO.Sales_Order__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.salesOrderName = tmpCO.Sales_Order__r.Name;
				if (tmpCO.Sales_Order__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.salesOrderId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Sales_Order__c;
				if (tmpCO.Opportunity__r.OwnerId != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Opportunity__r.OwnerId;
				if (tmpCO.Opportunity__r.Owner.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerName =  tmpCO.Opportunity__r.Owner.Name;
				if (tmpCO.Opportunity__r.Owner.ManagerId != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Opportunity__r.Owner.ManagerId;
				if (tmpCO.Opportunity__r.Owner.Manager.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerName = tmpCO.Opportunity__r.Owner.Manager.Name;
				if (tmpCO.Assigned_Campaign_Manager__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpCO.Assigned_Campaign_Manager__c;
				if (tmpCO.Assigned_Campaign_Manager__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerName = tmpCO.Assigned_Campaign_Manager__r.Name;
				
					
				tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerId = '';

				AssignCOFieldContentToAudience(tmpCO,tmpnotificationEventWrapper.mapUserDataFromContext);

			}
			else if (tmpnotificationEventWrapper.objectType==ObjectType.ProductOrder)
			{

				Product_Order__c tmpPO = mapPO.get(tmpnotificationEventWrapper.objectId);
				if (tmpPO.Account_Name__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.accountName = tmpPO.Account_Name__c;
				if (tmpPO.Account__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.accountId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Account__c;
				if (tmpPO.Order__r.Opportunity__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityName = tmpPO.Order__r.Opportunity__r.Name;
				if (tmpPO.Opportunity__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Opportunity__c;
				if (tmpPO.Order__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.campaignOrderName = tmpPO.Order__r.Name;
				if (tmpPO.Order__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.campaignOrderId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__c;
				if (tmpPO.RecordTypeId != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.RecordTypeId;
				if (tmpPO.RecordType.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeName = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.RecordType.Name;
				if (tmpPO.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderName = tmpPO.Name;
				if (tmpPO.Id != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Id;
				if (tmpPO.Product_Node__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeName = tmpPO.Product_Node__r.Name;
				if (tmpPO.Product_Node__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Product_Node__c;
				if (tmpnotificationEventWrapper.Message != null)
					tmpnotificationEventWrapper.emailTemplateFields.eventInfo = tmpnotificationEventWrapper.Message;
				tmpnotificationEventWrapper.emailTemplateFields.actionToDo = '';
				if (tmpPO.Order__r.Sales_Order__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.salesOrderName = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__r.Sales_Order__r.Name;
				if (tmpPO.Order__r.Sales_Order__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.salesOrderId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__r.Sales_Order__c;
				if (tmpPO.Order__r.Opportunity__r.OwnerId != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__r.Opportunity__r.OwnerId;
				if (tmpPO.Order__r.Opportunity__r.Owner.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerName = tmpPO.Order__r.Opportunity__r.Owner.Name;
				if (tmpPO.Order__r.Opportunity__r.Owner.ManagerId != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__r.Opportunity__r.Owner.ManagerId;
				if (tmpPO.Order__r.Opportunity__r.Owner.Manager.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerName = tmpPO.Order__r.Opportunity__r.Owner.Manager.Name;	
				if (tmpPO.Order__r.Assigned_Campaign_Manager__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Order__r.Assigned_Campaign_Manager__c;
				if (tmpPO.Order__r.Assigned_Campaign_Manager__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerName = tmpPO.Order__r.Assigned_Campaign_Manager__r.Name;
				if (tmpPO.Assigned_Fulfilment_Owner__c != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerId = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tmpPO.Assigned_Fulfilment_Owner__c;
				if (tmpPO.Assigned_Fulfilment_Owner__r.Name != null)
					tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerName = tmpPO.Assigned_Fulfilment_Owner__r.Name;


				AssignPOFieldContentToAudience(tmpPO,tmpnotificationEventWrapper.mapUserDataFromContext);

			}
		}
	}

	private static void AddUserDataFromContext(Map<Id,UserDataFromSetting> mapUserDataFromContext,Id UserId,String AudienceType)
	{
		if (mapUserDataFromContext.containsKey(UserId))
		{
			UserDataFromSetting tmpUserDataFromSetting = mapUserDataFromContext.get(UserId);
			tmpUserDataFromSetting.setAudienceType.add(AudienceType);
		}
		else
		{
			UserDataFromSetting tmpUserDataFromSetting = new UserDataFromSetting();
			tmpUserDataFromSetting.UserId=UserId;
			tmpUserDataFromSetting.setAudienceType.add(AudienceType);

			mapUserDataFromContext.put(UserId,tmpUserDataFromSetting);
		}
	}

	private static void GetAudienceFromSetting()
	{
		map<String,notificationEventWrapper> mapKeynotificationEventWrapper = new map<String,notificationEventWrapper>();
		
		for (notificationEventWrapper tmpnotificationEventWrapper : lstnotificationEventWrapper)
		{
			mapKeynotificationEventWrapper.put(tmpnotificationEventWrapper.Key,tmpnotificationEventWrapper);
		}

		List<Notification_Event_Setting_User__c> lstNotificationEventUser = [SELECT Id,Name,Audience__c,User__c, 
			User__r.Email,User__r.Name,
			Notification_Event_Setting__c,Notification_Event_Setting__r.Key__c from Notification_Event_Setting_User__c
			where Active__c=true and Notification_Event_Setting__r.Key__c in : mapKeynotificationEventWrapper.keySet()];
		
		System.debug('***lstNotificationEventUser=' + lstNotificationEventUser);
		System.debug('***mapKeynotificationEventWrapper.keySet()=' + mapKeynotificationEventWrapper.keySet());



		for(Notification_Event_Setting_User__c tmpNotificationEventUser : lstNotificationEventUser)
		{
			
			string Key = tmpNotificationEventUser.Notification_Event_Setting__r.Key__c;
			Map<Id,UserDataFromSetting> mapIdUserDataFromSetting;
			UserDataFromSetting tmpUserDataFromSetting;

			mapKeyCSEventId.put(Key,tmpNotificationEventUser.Notification_Event_Setting__c);

			if (mapEventKeyUserDataFromSetting.containsKey(Key))
			{
				mapIdUserDataFromSetting = mapEventKeyUserDataFromSetting.get(Key);

				System.debug('****mapIdUserDataFromSetting=' + mapIdUserDataFromSetting);
				
				if (mapIdUserDataFromSetting.containsKey(tmpNotificationEventUser.User__c))
				{
					tmpUserDataFromSetting=mapIdUserDataFromSetting.get(tmpNotificationEventUser.User__c);
					List<String> lstAudience = tmpNotificationEventUser.Audience__c.split(';');
					for (string tmpAudience : lstAudience)
					{
						tmpUserDataFromSetting.setAudienceType.add(tmpAudience);
					}
				}
				else
				{
					tmpUserDataFromSetting = new UserDataFromSetting();
					tmpUserDataFromSetting.Email=tmpNotificationEventUser.User__r.Email;
					tmpUserDataFromSetting.UserId=tmpNotificationEventUser.User__c;
					tmpUserDataFromSetting.UserName=tmpNotificationEventUser.User__r.Name;
					
					List<String> lstAudience = tmpNotificationEventUser.Audience__c.split(';');
					for (string tmpAudience : lstAudience)
					{
						tmpUserDataFromSetting.setAudienceType.add(tmpAudience);
					}

					mapIdUserDataFromSetting.put(tmpUserDataFromSetting.UserId,tmpUserDataFromSetting);

					mapEventKeyUserDataFromSetting.put(Key,mapIdUserDataFromSetting);

				}
			}
			else
			{
				tmpUserDataFromSetting = new UserDataFromSetting();
				tmpUserDataFromSetting.Email=tmpNotificationEventUser.User__r.Email;
				tmpUserDataFromSetting.UserId=tmpNotificationEventUser.User__c;
				tmpUserDataFromSetting.UserName=tmpNotificationEventUser.User__r.Name;
				
				List<String> lstAudience = tmpNotificationEventUser.Audience__c.split(';');
				for (string tmpAudience : lstAudience)
				{
					tmpUserDataFromSetting.setAudienceType.add(tmpAudience);
				}

				mapIdUserDataFromSetting = new Map<Id,UserDataFromSetting>();
				mapIdUserDataFromSetting.put(tmpUserDataFromSetting.UserId,tmpUserDataFromSetting);

				mapEventKeyUserDataFromSetting.put(Key,mapIdUserDataFromSetting);

			}
		}

		System.debug('****mapEventKeyUserDataFromSetting=' + mapEventKeyUserDataFromSetting);
	}

	private static void GetAudienceToBeEmailed()
	{
		for(notificationEventWrapper tmpnotificationEventWrapper : lstnotificationEventWrapper)
		{
			string Key = tmpnotificationEventWrapper.Key;
			System.debug('***Key=' + Key);

			System.debug('***mapEventKeyUserDataFromSetting=' + mapEventKeyUserDataFromSetting);
			
			if (mapEventKeyUserDataFromSetting.containsKey(Key))
			{		
				Map<Id,UserDataFromSetting> mapUserIdUserDataSetting = mapEventKeyUserDataFromSetting.get(Key);
				Map<Id,UserDataFromSetting> mapUserIdUserDataFromContext = tmpnotificationEventWrapper.mapUserDataFromContext;

				System.debug('***mapUserIdUserDataSetting=' + mapUserIdUserDataSetting);
				System.debug('***mapUserIdUserDataFromContext=' + mapUserIdUserDataFromContext);


				for (Id UserId : mapUserIdUserDataFromContext.keySet())
				{
					
					System.debug('***UserId=' + UserId);
					
					if (mapUserIdUserDataSetting.containsKey(UserId))
					{
						Set<String> setAudienceFromDataSetting = mapUserIdUserDataSetting.get(UserId).setAudienceType;
						Set<String> setAudienceFromContext = mapUserIdUserDataFromContext.get(UserId).setAudienceType;

						System.debug('***setAudienceFromDataSetting' + setAudienceFromDataSetting);
						System.debug('***setAudienceFromContext' + setAudienceFromContext);


						for (String tmpAudience : setAudienceFromContext)
						{
							System.debug('***tmpAudience=' + tmpAudience);
							
							if (setAudienceFromDataSetting.contains(tmpAudience))
							{
								
								if (!tmpnotificationEventWrapper.mapUserDataForSending.containsKey(UserId))
								{
									UserDataFromSetting tmpUserDataFromSetting = new UserDataFromSetting();

									tmpUserDataFromSetting.Email=mapUserIdUserDataSetting.get(UserId).Email;
									tmpUserDataFromSetting.UserName=mapUserIdUserDataSetting.get(UserId).UserName;
									tmpUserDataFromSetting.FinalAudience=tmpAudience;
									tmpUserDataFromSetting.UserId=UserId;

									System.debug('***tmpUserDataFromSetting=' + tmpUserDataFromSetting);

									tmpnotificationEventWrapper.mapUserDataForSending.put(UserId,tmpUserDataFromSetting);
								}
							}
						}
					}
				}
			}
		}
	}

	private static string CreateUnsubscribeLink(String Key,String UserId, String Audience)
	{
		string CSNotificationEventId = mapKeyCSEventId.get(Key);

		string retURL=System.URL.getSalesforceBaseUrl().toExternalForm() + '/apex/' + 'CS_EventNotification?notificationEventSettingId='+CSNotificationEventId+'&userId=' + UserId + '&audience=' + Audience;

		return retURL;
	}

	private static EmailTemplate GetEmailTemplate(string TemplateName)
	{
		EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where Name=:TemplateName LIMIT 1];

		return emailTemplate;
	}

	private static string ParseEmailText(string Text,notificationEventWrapper tmpnotificationEventWrapper,UserDataFromSetting tmpUserDataFromSetting, Boolean isHTML)
	{
		string tmp;
		string UnsubscribeLink=CreateUnsubscribeLink(tmpnotificationEventWrapper.Key,tmpUserDataFromSetting.UserId,tmpUserDataFromSetting.FinalAudience);

		if (isHTML)
		{
			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.accountId + '">' +tmpnotificationEventWrapper.emailTemplateFields.accountName + '</a>';
			Text = Text.replace('{!Account.Link}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.opportunityId + '">' +tmpnotificationEventWrapper.emailTemplateFields.opportunityName + '</a>';
			Text = Text.replace('{!Opportunity.Link}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerId + '">' +tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerName +  '</a>';
			Text = Text.replace('{!Opportunity.OwnerLink}', tmp);
			
			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerId + '">' +tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerName +  '</a>';
			Text = Text.replace('{!Opportunity.OwnerManagerLink}', tmp);
			
			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.salesOrderId + '">' +tmpnotificationEventWrapper.emailTemplateFields.salesOrderName +  '</a>';
			Text = Text.replace('{!Sales_Order__c.Link}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.campaignOrderId + '">' +tmpnotificationEventWrapper.emailTemplateFields.campaignOrderName +  '</a>';				
			Text = Text.replace('{!Order__c.Link}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.productOrderId + '">' +tmpnotificationEventWrapper.emailTemplateFields.productOrderName +  '</a>';				
			Text = Text.replace('{!Product_Order__c.Link}', tmp);

			tmp=tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeName;								
			Text = Text.replace('{!Product_Order__c.RecordType}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeId + '">' +tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeName +  '</a>';
			Text = Text.replace('{!csmso__Product_Node__c.Link}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerId + '">' +tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerName +  '</a>';				
			Text = Text.replace('{!Order__c.Assigned_Campaign_Manager__c}', tmp);

			tmp='<a href="' + tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerId + '">' +tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerName +  '</a>';				
			Text = Text.replace('{!Product_Order__c.Assigned_Fulfilment_Owner__c}', tmp);

			tmp= tmpnotificationEventWrapper.emailTemplateFields.eventInfo;
			Text = Text.replace('{!EventInfo}', tmp);

			tmp='Key=' + tmpnotificationEventWrapper.Key + ' User Name=' + tmpUserDataFromSetting.UserName + ' Audience='  + tmpUserDataFromSetting.FinalAudience; 
			Text = Text.replace('{!UserEventInfo}', tmp);

			tmp='<a href="' + UnsubscribeLink + '">Unsubscribe</a>';
			Text = Text.replace('{!UnsubscribeLink}', tmp);		
		}
		else
		{
			Text = Text.replace('{!Account.Name}', tmpnotificationEventWrapper.emailTemplateFields.accountName);
			Text = Text.replace('{!Opportunity.Name}', tmpnotificationEventWrapper.emailTemplateFields.opportunityName);
			Text = Text.replace('{!Opportunity.OwnerFullName}', tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerName);
			Text = Text.replace('{!Opportunity.OwnerFullName}', tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnerName);
			Text = Text.replace('{!Opportunity.OwnerManager}', tmpnotificationEventWrapper.emailTemplateFields.opportunityOwnersManagerName);
			Text = Text.replace('{!Sales_Order__c.Name}', tmpnotificationEventWrapper.emailTemplateFields.salesOrderName);
			Text = Text.replace('{!Order__c.Name}', tmpnotificationEventWrapper.emailTemplateFields.campaignOrderName);
			Text = Text.replace('{!Product_Order__c.Name}', tmpnotificationEventWrapper.emailTemplateFields.productOrderName);
			Text = Text.replace('{!Product_Order__c.RecordType}', tmpnotificationEventWrapper.emailTemplateFields.productOrderRecordTypeName);
			Text = Text.replace('{!csmso__Product_Node__c.Name}', tmpnotificationEventWrapper.emailTemplateFields.productOrderProductNodeName);
			Text = Text.replace('{!Order__c.Assigned_Campaign_Manager__c}', tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerName);
			Text = Text.replace('{!Order__c.Assigned_Campaign_Manager__c}', tmpnotificationEventWrapper.emailTemplateFields.assignedCampaignManagerName);
			Text = Text.replace('{!Product_Order__c.Assigned_Fulfilment_Owner__c}', tmpnotificationEventWrapper.emailTemplateFields.assignedFullfilmentOwnerName);
			Text = Text.replace('{!EventInfo}', tmpnotificationEventWrapper.emailTemplateFields.eventInfo);
			
			tmp='Key=' + tmpnotificationEventWrapper.Key + ' User Name=' + tmpUserDataFromSetting.UserName + ' Audience='  + tmpUserDataFromSetting.FinalAudience + '<br>'; 
			Text = Text.replace('{!UserEventInfo}', tmp);

			Text = Text.replace('{!UnsubscribeLink}', UnsubscribeLink);

		}

		return Text;
	}


	private static void SendEmails()
	{
		string HTMLBody;
		string PlainTextBody;
		string Subject;
		
		COEmailTemplate=GetEmailTemplate('CO Event Notification');
		POEmailTemplate=GetEmailTemplate('PO Event Notification');


		Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();

		System.debug('***SendEmails');
		System.debug('***lstnotificationEventWrapper=' + lstnotificationEventWrapper);

		//string UnsubscribeLink;

		for(notificationEventWrapper tmpnotificationEventWrapper : lstnotificationEventWrapper)
		{
			
			if (tmpnotificationEventWrapper.objectType==ObjectType.CampaignOrder)
			{
				HTMLBody=COEmailTemplate.HtmlValue;
				PlainTextBody=COEmailTemplate.Body;
				Subject=COEmailTemplate.Subject;
			}
			else
			{
				HTMLBody=POEmailTemplate.HtmlValue;
				PlainTextBody=POEmailTemplate.Body;
				Subject=POEmailTemplate.Subject;
			}
			
			System.debug('***tmpnotificationEventWrapper=' + tmpnotificationEventWrapper);

			for(UserDataFromSetting tmpUserDataFromSetting : tmpnotificationEventWrapper.mapUserDataForSending.values())
			{
				HTMLBody=ParseEmailText(HTMLBody,tmpnotificationEventWrapper,tmpUserDataFromSetting,true);
				HTMLBody = HTMLBody.replace('<![CDATA[', '');
				HTMLBody = HTMLBody.replace(']]>', '');

				PlainTextBody=ParseEmailText(PlainTextBody,tmpnotificationEventWrapper,tmpUserDataFromSetting,false);
				Subject=ParseEmailText(Subject,tmpnotificationEventWrapper,tmpUserDataFromSetting,false);
				
				List<String> emailAddressArray = new List<String>();
				emailAddressArray.add(tmpUserDataFromSetting.Email);
				
				System.debug('***emailAddressArray=' + emailAddressArray);

				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.toAddresses =  emailAddressArray;

				message.subject=Subject;
				message.plainTextBody=PlainTextBody;
				message.htmlBody=HTMLBody;

								
				if (message.plainTextBody != '')
					messages.add(message);

			}
		}

		if (messages.size()>0)
		{
			System.debug('***messages=' + messages);

			Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
		
			if (results[0].success) 
			{
				System.debug('The email was sent successfully.');
			} 
			else 
			{
				System.debug('The email failed to send: ' + results[0].errors[0].message);
			}
		}
	}

	private static void CleanEvents()
	{
		lstnotificationEventWrapper.clear();
		mapEventKeyUserDataFromSetting.clear();
		setStepId.clear();
		mapKeyCSEventId.clear();

		MileStoneEventCounter=0;
		ObjectEventCounter=0;
		ButtonEventCounter=0;
	}

	public static void SendNotificationEmails()
	{
		
		if (HasEvents())
		{
			if (setStepId.size()>0) ProcessMileStoneEvents();

			GetNeededData();

			GetAudienceFromSetting();

			GetAudienceToBeEmailed();

			System.debug('***lstnotificationEventWrapper=' + lstnotificationEventWrapper);
			System.debug('***mapEventKeyUserDataFromSetting=' + mapEventKeyUserDataFromSetting);

			SendEmails();

			CleanEvents();
		}
	}
	
}