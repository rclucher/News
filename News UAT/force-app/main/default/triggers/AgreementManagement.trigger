trigger AgreementManagement on Agreement__c (after update) {

if (Global_Helper.canTrigger( 'AgreementManagement' ) ){
	List<Id> agreementExpiryNotificationList = new List<Id>();
	List<Id> agreementQuartelyReviewNotificationList = new List<Id>();
	for(Agreement__c agree : Trigger.new)
	{
		if(agree.Trigger_Send_emails_to_account_owners__c &&
			agree.Trigger_Send_emails_to_account_owners__c != Trigger.oldMap.get(agree.id).Trigger_Send_emails_to_account_owners__c)
		{
			agreementExpiryNotificationList.add(agree.id);
		}

		if(agree.Trigger_Send_emails_for_QTR_Review_AMs__c &&
			agree.Trigger_Send_emails_for_QTR_Review_AMs__c != Trigger.oldMap.get(agree.id).Trigger_Send_emails_for_QTR_Review_AMs__c)
		{
			agreementQuartelyReviewNotificationList.add(agree.id);
		}


	}

	if(agreementExpiryNotificationList.size()>0)
	{
		Agreement_Helper.HandleAgreement(agreementExpiryNotificationList, Agreement_Helper.NotificationType.EXPIRY);
	}

	if(agreementQuartelyReviewNotificationList.size()>0)
	{
		Agreement_Helper.HandleAgreement(agreementQuartelyReviewNotificationList, Agreement_Helper.NotificationType.QUARTELYREVIEW);
	}
}

}