public with sharing class CS_PaymentTriggerDelegate  extends CS_TriggerHandler.DelegateBase 
{
	Map<Id,Payment__c> mapOrderIdPayment;

	public override void prepareAfter() 
    {
		mapOrderIdPayment = new Map<Id,Payment__c>();
	}

	public override void afterInsert(sObject o) 
    {
		Payment__c newPayment = (Payment__c)o;
		{
			mapOrderIdPayment.put(newPayment.Order__c, newPayment);
		}
	}

	public override void afterUpdate(sObject old, sObject o)
    {
		Payment__c newPayment = (Payment__c)o;
        Payment__c oldPayment = (Payment__c)old;
		

		if ((newPayment.End_Date__c!=oldPayment.End_Date__c) || 
			(newPayment.Cancellation_Reason__c!=oldPayment.Cancellation_Reason__c) ||
			(newPayment.Cancellation_Reason_Notes__c!=oldPayment.Cancellation_Reason_Notes__c) ||
			(newPayment.Minimum_Evergreen_Cancellation_Date__c!=oldPayment.Minimum_Evergreen_Cancellation_Date__c) ||
			(newPayment.Cancelled_Date__c!=oldPayment.Cancelled_Date__c))
		{
			mapOrderIdPayment.put(newPayment.Order__c, newPayment);
		}
	}

	private void SyncCampaignOrder()
	{
		if (mapOrderIdPayment.size()>0)
		{
			List<Order__c> lstOrderSync = [select Id, End_Date__c,Cancellation_Reason__c,
				Cancellation_Reason_Notes__c , Minimum_Evergreen_Cancellation_Date__c, 
				Cancelled_Date__c
				from Order__c where Id in : mapOrderIdPayment.keySet()];

			for (Order__c tmpOrder : lstOrderSync)
			{
				Payment__c tmpPayment = mapOrderIdPayment.get(tmpOrder.Id);

				tmpOrder.Cancellation_Reason__c = tmpPayment.Cancellation_Reason__c;
				tmpOrder.Minimum_Evergreen_Cancellation_Date__c=tmpPayment.Minimum_Evergreen_Cancellation_Date__c;
				tmpOrder.Cancelled_Date__c=tmpPayment.Cancelled_Date__c;
				tmpOrder.Cancellation_Reason_Notes__c=tmpPayment.Cancellation_Reason_Notes__c;
				tmpOrder.Cancellation_Date__c = tmpPayment.End_Date__c; //Cancellation Date has been re-labelled to End Date
			}

			update lstOrderSync;
		}
	}

	public override void finish() 
    {
		if (Trigger.isAfter)
		{
			SyncCampaignOrder();
		}
	}
}