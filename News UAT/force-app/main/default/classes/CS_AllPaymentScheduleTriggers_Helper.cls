public with sharing class CS_AllPaymentScheduleTriggers_Helper {
    
    public static void processPaymentScheduleTrigger(Map<Id, Payment_Schedule__c> psOldMap, Map<Id, Payment_Schedule__c> psNewMap) {
        if (trigger.isBefore && trigger.isInsert && psNewMap != null && !psNewMap.isEmpty()) {
            handleBeforeInsert(psNewMap.values());
        }
        
        if (trigger.isBefore && trigger.isUpdate && psNewMap != null && !psNewMap.isEmpty()) {
            handleBeforUpdate(psOldMap, psNewMap.values());
        }

        if (trigger.isBefore && trigger.isDelete) {
            handleBeforDelete(psOldMap.values());
        }

            
        if (trigger.isAfter && (trigger.isUpdate || trigger.isInsert) && psNewMap != null && !psNewMap.isEmpty()) {
            handleAfterInsertAndUpdate(psNewMap.values());
        }
    }
    
    /**
    * Sets billing date to last day of the schedule month
    */
    private static void handleBeforeInsert(List<Payment_Schedule__c> psNew){
        for (Payment_Schedule__c ps : psNew) {
            if (ps.Schedule_Start_Date__c != null) {
                ps.Billing_Date__c = ps.Schedule_Start_Date__c.addMonths(1).toStartofMonth().addDays(-1);
            }
        }
    }
    
    /**
    * prevents updates to credit approved if status is not in progress or pending
    */
    private static void handleBeforUpdate(Map<Id, Payment_Schedule__c> psOldMap, List<Payment_Schedule__c> psNew) {
        for (Payment_Schedule__c ps : psNew) {
            if (ps.Schedule_Start_Date__c != null) {
                ps.Billing_Date__c = ps.Schedule_Start_Date__c.addMonths(1).toStartofMonth().addDays(-1);
            }
            if (ps.Status__c != 'In Progress' && ps.Status__c != 'Pending' && ps.Credit_Approved__c == true && psOldMap.get(ps.Id).Credit_Approved__c == false) {
                ps.addError('Cannot approve as the payment schedule is already processed.');
            }
        }
    }

    private static void handleBeforDelete(List<Payment_Schedule__c> lstPSOld)
    {
        for (Payment_Schedule__c tmpPS : lstPSOld)
        {
            //NXIII-314
			//if ((tmpPS.Status__c == 'Pending') || (tmpPS.Status__c == 'Cancelled') || (tmpPS.Status__c == 'Invoiced'))
			//if ((tmpPS.Status__c == 'Cancelled') || (tmpPS.Status__c == 'Invoiced'))
			/*
			if ((tmpPS.Status__c != 'Pending'))
            {
                tmpPS.addError('It is not allowed to delete Payment Schedule that is not in Status: Pending');
            }
			*/
        }
    }
    
    /**
    * Updates Payment End date to last payment schedule end date
    */
    private static void handleAfterInsertAndUpdate(List<Payment_Schedule__c> psNew){
        Map<Id, List<Payment_Schedule__c>> psMap = new Map<Id, List<Payment_Schedule__c>>();
            Set<Id> paymentId = new Set<Id>();
            for (Payment_Schedule__c ps : psNew) {
                paymentId.add(ps.Payment__c);
                
            }
            Map<Id, Payment__c> paymentMap = new Map<Id, Payment__c>(
                [
                    select id, Last_End_Date__c from Payment__c 
                    where id in :paymentId
                ]
            );
            List<Payment_Schedule__c> psList = [
                select id, Payment__c, Schedule_End_Date__c
                from Payment_Schedule__c
                where Payment__c in :paymentId
                and Status__c != 'Cancelled'
            ];
            for (Payment_Schedule__c ps : psList) {
                if (psMap.get(ps.Payment__c) == null) {
                    psMap.put(ps.Payment__c, new List<Payment_Schedule__c>());
                }
                psMap.get(ps.Payment__c).add(ps);
            }
            List<Payment__c> paymentsForUpdate = new List<Payment__c>();
            for (Payment__c p : paymentMap.values()) {
                Date endDate = null;
                for (Payment_Schedule__c ps : psMap.get(p.Id)) {
                    if (endDate == null) {
                        endDate = ps.Schedule_End_Date__c;
                    } else {
                        if (ps.Schedule_End_Date__c != null && ps.Schedule_End_Date__c > endDate) {
                            endDate = ps.Schedule_End_Date__c;
                        }
                    }
                }
                if (p.Last_End_Date__c != endDate) {
                    p.Last_End_Date__c = endDate;
                    paymentsForUpdate.add(p);
                }
                
            }
            if (!paymentsForUpdate.isEmpty()) {
                update paymentsForUpdate;
            }
    }
}