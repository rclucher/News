/**
 * Clones last payment schedule with payment line items for payments
 */
public class CS_EvergreenPaymentRenewalHelper {

	/**
	 * Clones last payment schedule with payment line items for payments
	 * @param paymentIds
	 */
	public static void clonePaymentScheduleWithLineItems(Set<Id> paymentIds) {
		String paymentQuery = 'select ' + CS_Utils.getSobjectFields('Payment_Schedule__c');
		paymentQuery += ' from Payment_Schedule__c where Payment__c in :paymentIds';
		List<Payment_Schedule__c> paymentSchedules = Database.query(paymentQuery);
		Map<Id, List<Payment_Schedule__c>> psMap = new Map<Id, List<Payment_Schedule__c>>();
		for (Payment_Schedule__c ps : paymentSchedules) {
			if (psMap.get(ps.Payment__c) == null) {
				psMap.put(ps.Payment__c, new List<Payment_Schedule__c>());
			}
			psMap.get(ps.Payment__c).add(ps);
		}
		List<Payment_Schedule__c> lastPayments = new List<Payment_Schedule__c>();
		Set<Id> psIds = new Set<Id>();
		for (Id p : psMap.keySet()) {
			Payment_Schedule__c lastPS;
			for (Payment_Schedule__c ps : psMap.get(p)) {
				if (lastPS == null) {
					lastPS = ps;
				} else {
					if (lastPS != null && lastPS.Schedule_End_Date__c != null && lastPS.Schedule_End_Date__c < ps.Schedule_End_Date__c) {
						lastPS = ps;
					}
				}
			}
			if (lastPS != null) {
				psIds.add(lastPs.Id);
				lastPayments.add(lastPS);
			}
		}
		String paymentScheduleItemsQuery = 'select ' + CS_Utils.getSobjectFields('Payment_Schedule__c');
		paymentScheduleItemsQuery += ', (select ' + CS_Utils.getSobjectFields('Payment_Line_Item__c') + ' from payment_line_items__r)';
		paymentScheduleItemsQuery += ' from Payment_Schedule__c where id in :psIds';
		List<Payment_Schedule__c> psList = Database.query(paymentScheduleItemsQuery);
		system.debug(JSON.serializePretty(psList));
		
		List<Payment_Schedule__c> newPS = new List<Payment_Schedule__c>();
		Map<Id, List<Payment_Line_Item__c>> plis = new Map<Id, List<Payment_Line_Item__c>>();
		for (Payment_Schedule__c ps : psList) {
			Payment_Schedule__c nps = ps.clone(false, true, false, false);
			plis.put(ps.Id, ps.Payment_Line_Items__r);
			if (nps.Schedule_End_Date__c.month() == 2) {
				nps.Schedule_End_Date__c = nps.Schedule_Start_Date__c.addMonths(2);
				nps.Schedule_Start_Date__c = nps.Schedule_Start_Date__c.addMonths(1);
			} else if (nps.Schedule_Start_Date__c.month() == 2) {
				nps.Schedule_Start_Date__c = nps.Schedule_End_Date__c;
				nps.Schedule_End_Date__c = nps.Schedule_End_Date__c.addMonths(1);
			} else {
				nps.Schedule_End_Date__c = nps.Schedule_Start_Date__c.addMonths(2);
				nps.Schedule_Start_Date__c = nps.Schedule_Start_Date__c.addMonths(1);
			}
			nps.Name = 'Payment Schedule - ' + nps.Schedule_Start_Date__c.format() + ' - ' + nps.Schedule_End_Date__c.format();
			nps.Credit_Adjusted__c = false;
			newPS.add(nps);
		}
		
		if (!newPS.isEmpty()) {
			insert newPs;
			system.debug(newPs[0].id + ' - ' + newPs[0].getCloneSourceId());
			List<Payment_Line_Item__c> newPLis = new List<Payment_Line_Item__c>();
			for (Payment_Schedule__c p : newPs) {
				for (Payment_Line_Item__c pli : plis.get(p.getCloneSourceId())) {
					if (pli.Type__c == 'Normal' && pli.Recurring__c) {
						Payment_Line_Item__c pl = pli.clone(false, false);
						pl.Payment_Schedule__c = p.Id;
						pl.Price__c = pl.List_Price__c;
						newPLis.add(pl);
					}
				}
			}
			if (!newPLis.isEmpty()) {
				insert newPLis;
			}
		}
		
	}

}