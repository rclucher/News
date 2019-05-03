trigger BookingSystemAccount on External_Account__c (before insert, before update, after insert, after update) {
	if (trigger.isBefore && (trigger.isUpdate)) {

        BookingSystemAccount_Helper.resetNetDA(Trigger.newMap, Trigger.oldMap);

    } else if (trigger.isAfter) {
    	//BookingSystemAccount_Helper.assignCreditStatus(ids);

		BookingSystemAccount_Helper.assignCreditStatus(trigger.new);


    }
}