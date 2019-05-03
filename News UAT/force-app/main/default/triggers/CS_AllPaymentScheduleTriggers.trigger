trigger CS_AllPaymentScheduleTriggers on Payment_Schedule__c (before update, before insert, after insert, after update, before delete) {
    
    No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    if (!notriggers.Flag__c) {
        
        CS_AllPaymentScheduleTriggers_Helper.processPaymentScheduleTrigger(Trigger.oldMap, Trigger.newMap);
        /**
         * Sets billing date to last day of the schedule month
         */
       /* if (trigger.isBefore && (trigger.isUpdate || trigger.isInsert)) {
            for (Payment_Schedule__c ps : trigger.new) {
                if (ps.Schedule_Start_Date__c != null) {
                    ps.Billing_Date__c = ps.Schedule_Start_Date__c.addMonths(1).toStartofMonth().addDays(-1);
                }
            }
        }*/
        
        /**
         * prevents updates to credit approved if status is not in progress or pending
         */ 
         /*if (trigger.isUpdate && trigger.isBefore) {
            for (Payment_Schedule__c ps : trigger.new) {
                if (ps.Status__c != 'In Progress' && ps.Status__c != 'Pending' && ps.Credit_Approved__c == true && trigger.oldMap.get(ps.Id).Credit_Approved__c == false) {
                    ps.addError('Cannot approve as the payment schedule is already processed.');
                }
            }
         }*/
         /**
         * Updates Payment End date to last payment schedule end date
         */
        /*if (trigger.isAfter && (trigger.isUpdate || trigger.isInsert)) {
            Map<Id, List<Payment_Schedule__c>> psMap = new Map<Id, List<Payment_Schedule__c>>();
            Set<Id> paymentId = new Set<Id>();
            for (Payment_Schedule__c ps : trigger.new) {
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
        }*/
    }

}