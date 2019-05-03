trigger CS_AllPaymentTriggers on Payment__c (before update, after update, before delete, after insert) {
    
    No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    if (!notriggers.Flag__c) {
        // Create new payment schedules if cancellation end date is greater than last payment schedule date
        // Changes status of cancelled or cancels payment schedules based on End Date
        if (trigger.isUpdate && trigger.isAfter) {
            List<Payment__c> paymentsThatNeedSchedules = new List<Payment__c>();
            List<Payment__c> paymentsThatNeedScheduleStatusChanges = new List<Payment__c>();
            for (Payment__c p : trigger.new) {
                if (p.End_Date__c != null && p.End_Date__c != Trigger.oldMap.get(p.Id).End_Date__c && p.End_Date__c > p.Last_End_Date__c) {
                    paymentsThatNeedSchedules.add(p);
                }
                if (p.End_Date__c != null && p.End_Date__c != Trigger.oldMap.get(p.Id).End_Date__c) {
                    paymentsThatNeedScheduleStatusChanges.add(p);
                }
            }
            if (!paymentsThatNeedSchedules.isEmpty()) {
                CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentsThatNeedSchedules);
            }
            if (!paymentsThatNeedScheduleStatusChanges.isEmpty()) {
                CS_PaymentCancellationHelper.activateAndcancelPaymentSchedules(paymentsThatNeedScheduleStatusChanges);
            }
        }

        if (Trigger.isUpdate && Trigger.isBefore)
        {
            for (Integer i=0;i<Trigger.new.size();i++)
            {
                if (Trigger.new[i].End_Date__c!= null && (Trigger.new[i].End_Date__c!=Trigger.old[i].End_Date__c))
                {
                    if (Trigger.new[i]==null)
                        Trigger.new[i].Cancelled_Date__c=null; //not needed
                    else
                        Trigger.new[i].Cancelled_Date__c=Date.today();
                }
            }
        }

        //NX-314 - do not allow deletion of Payments for certain statuses
        /*
		if ((Trigger.isDelete) && (Trigger.isBefore))
        {
            Set<Id> setCampaignOrderId = new Set<Id>();
            for (Integer i=0;i<Trigger.old.size();i++)
            {
                if (Trigger.old[i].Order__c!=null)
                    setCampaignOrderId.add(trigger.old[i].Order__c);
            }
            if (setCampaignOrderId.size()>0)
            {
                List<Order__c> lstCOrder = [select Id from Order__c 
                    where 
                    (Status__c='Paused' OR Status__c='Cancelled' OR 
                        Status__c='Pending For Pause' OR
                        Status__c='Pending For Cancel' OR
                        Status__c='Campaign Ended' OR Status__c='Campaign Live') AND Id in : setCampaignOrderId];

                if (lstCOrder.size()>0)
                    Trigger.old[0].addError('Campaign already started. Cannot reschedule payments');
            }
        }
        //NX-314 - do not allow deletion of Payments for certain statuses - END
		*/

		//NX-311 - too much logic let's introduce trigger handler class 
		//plan to move some of the logic above into it!
		CS_TriggerHandler.execute(new CS_PaymentTriggerDelegate());
    }

}