/**
 * Logic for payment cancellation
 */
public class CS_PaymentCancellationHelper {
	
	/**
	 * Returns number of payment schedules required for Payments
	 * @param pList
	 * @return Map<Id, Integer>
	 */
	public static Map<Id, Integer> calculateNumberOfPaymentSchedulesRequired(List<Payment__c> pList, List<Payment_Schedule__c> paymentSchedules) {
		Map<Id, Integer> numberOfPSRequired = new Map<Id, Integer>();
		Map<Id, List<Payment_Schedule__c>> psMap = new Map<Id, List<Payment_Schedule__c>>();
		for (Payment_Schedule__c ps : paymentSchedules) {
			if (psMap.get(ps.Payment__c) == null) {
				psMap.put(ps.Payment__c, new List<Payment_Schedule__c>());
			}
			psMap.get(ps.Payment__c).add(ps);
		}
		for (Payment__c p : pList) {
			if (p.End_Date__c != null) {
				Integer monthsBetween = p.Last_End_Date__c.monthsBetween(p.End_Date__c);
				if (p.End_Date__c.day() > p.Last_End_Date__c.day())  {
					monthsBetween++;
				}
				
				for (Payment_Schedule__c ps : psMap.get(p.Id)) {
					if (ps.Schedule_End_Date__c > p.Last_End_Date__c) {
						monthsBetween--;
					}
				}
				numberOfPSRequired.put(p.Id, monthsBetween);
			}
		}
		
		
		return numberOfPSRequired;
	}
	
	/**
	 * Returns last Payment Schedule for a payment
	 * @param pList
	 * @return Map<Id,Payment_Schedule__c>
	 */
	public static Map<Id,Payment_Schedule__c> getLastPaymentSchedule(List<Payment__c> pList, List<Payment_Schedule__c> paymentSchedules) {
		Map<Id, List<Payment_Schedule__c>> psMap = new Map<Id, List<Payment_Schedule__c>>();
		Map<Id, Payment__c> pMap = new Map<Id, Payment__c>();
		for (Payment__c p : pList) {
			pMap.put(p.Id, p);
		}
		for (Payment_Schedule__c ps : paymentSchedules) {
			if (psMap.get(ps.Payment__c) == null) {
				psMap.put(ps.Payment__c, new List<Payment_Schedule__c>());
			}
			psMap.get(ps.Payment__c).add(ps);
		}
		Map<Id, Payment_Schedule__c> lastPayments = new Map<Id, Payment_Schedule__c>();
		for (Id p : psMap.keySet()) {
			Payment_Schedule__c lastPS;
			for (Payment_Schedule__c ps : psMap.get(p)) {
				if (lastPS == null && ps.Schedule_End_Date__c < pMap.get(p).End_Date__c) {
					lastPS = ps;
				} else if (lastPs != null && lastPs.Schedule_End_Date__c != null && lastPS.Schedule_End_Date__c < ps.Schedule_End_Date__c && ps.Schedule_End_Date__c < pMap.get(p).End_Date__c) {
					lastPS = ps;
				}
			}
			if (lastPS != null) {
				lastPayments.put(p, lastPS);
			}
		}
		
		return lastPayments;
	}
	
	/**
	 * Creates required number of Payment Schedules for Payment cancellation
	 * @param pList
	 */
	public static void createPaymentSchedulesForPaymentCancellation(List<Payment__c> pList) {
		List<Payment_Schedule__c> paymentSchedules = getPaymentScheduleForPayments(pList);
		Map<Id, Integer> requiredNumberOfPayments = calculateNumberOfPaymentSchedulesRequired(pList, paymentSchedules);
		Map<Id,Payment_Schedule__c> lastPayments = getLastPaymentSchedule(pList, paymentSchedules);
		
		List<Payment_Schedule__c> newPS = new List<Payment_Schedule__c>();
		Map<Id, List<Payment_Line_Item__c>> plis = new Map<Id, List<Payment_Line_Item__c>>();
		for (Id pId : lastPayments.keySet()) {
			plis.put(lastPayments.get(pId).Id, lastPayments.get(pId).Payment_Line_Items__r);
            System.debug('requiredNumberOfPayments-->'+ requiredNumberOfPayments);
			for (Integer i = 1; i <= requiredNumberOfPayments.get(pId); i++) {
				Payment_Schedule__c nps = lastPayments.get(pId).clone(false, true, false, false);
				if (nps.Schedule_End_Date__c.month() == 2) {
					nps.Schedule_End_Date__c = nps.Schedule_Start_Date__c.addMonths(i+1);
					nps.Schedule_Start_Date__c = nps.Schedule_Start_Date__c.addMonths(i);
				} else if (nps.Schedule_Start_Date__c.month() == 2) {
					nps.Schedule_Start_Date__c = nps.Schedule_End_Date__c.addMonths(i-1);
					nps.Schedule_End_Date__c = nps.Schedule_End_Date__c.addMonths(i);
				} else {
					nps.Schedule_End_Date__c = nps.Schedule_Start_Date__c.addMonths(i+1);
					nps.Schedule_Start_Date__c = nps.Schedule_Start_Date__c.addMonths(i);
				}
				nps.Credit_Adjusted__c = false;
				nps.Name = 'Payment Schedule - ' + nps.Schedule_Start_Date__c.format() + ' - ' + nps.Schedule_End_Date__c.format();
				nps.Status__c = 'Pending';
				newPS.add(nps);
			}
		}
		
		if (!newPS.isEmpty()) {
			insert newPs;
			List<Payment_Line_Item__c> newPLis = new List<Payment_Line_Item__c>();
			for (Payment_Schedule__c p : newPs) {
				system.debug(p.getCloneSourceId());
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
	
	/**
	 * Returns list of Payment Schedules with Payment Line Items
	 * @param pList
	 * @return List<Payment_Schedule__c>
	 */
	public static List<Payment_Schedule__c> getPaymentScheduleForPayments(List<Payment__c> pList) {
		Set<Id> paymentIds = new Set<Id>();
		for (Payment__c p : pList) {
			paymentIds.add(p.Id);
		}
		String paymentQuery = 'select ' + CS_Utils.getSobjectFields('Payment_Schedule__c');
		paymentQuery += ',(select ' + CS_Utils.getSobjectFields('Payment_Line_Item__c') + ' from Payment_Line_Items__r)';
		paymentQuery += ' from Payment_Schedule__c where Payment__c in :paymentIds';
		List<Payment_Schedule__c> paymentSchedules = Database.query(paymentQuery);
		return paymentSchedules;
	}
	
	/**
	 * Cancels payments after end date or activates if end date is in future
	 * Calculates pro rated values for last month
	 * @param pList
	 */
	public static void activateAndCancelPaymentSchedules(List<Payment__c> pList) {
		List<Payment_Schedule__c> paymentSchedules = getPaymentScheduleForPayments(pList);
		Map<Id, Date> paymentEndDates = new Map<Id, Date>();
		for (Payment__c p : pList) {
			paymentEndDates.put(p.Id, p.End_Date__c);
		}
		for (Payment_Schedule__c ps : paymentSchedules) {
			// reset prices
			for (Payment_Line_Item__c pli : ps.Payment_Line_Items__r) {
				if (pli.Type__c == 'Normal') {
					pli.Price__c = pli.List_Price__c;
				}
			}
			if (ps.Schedule_Start_Date__c >= paymentEndDates.get(ps.Payment__c)) {
				ps.Status__c = 'Cancelled';
			} else if (ps.Status__c == 'Cancelled' && ps.Schedule_Start_Date__c < paymentEndDates.get(ps.Payment__c)) {
				ps.Status__c = 'Pending';
			}
		}
		paymentSchedules = proRatePaymentSchedules(pList, paymentSchedules, paymentEndDates);
		List<Payment_Line_Item__c> pliToUPdate = new List<Payment_Line_Item__c>();
		for (Payment_Schedule__c ps : paymentSchedules) {
			pliToUPdate.addAll(ps.Payment_Line_Items__r);
		}
		update paymentSchedules;
		update pliToUPdate;
	}
	
	/**
	 * Pro rates last payment schedule. Creates new payment schedule if needed
	 * @param pList
	 * @param paymentSchedules
	 * @param Map<Id, Date> paymentEndDates
	 * @return List<Payment_Schedule__c>
	 */
	public static List<Payment_Schedule__c> proRatePaymentSchedules(List<Payment__c> pList, List<Payment_Schedule__c> paymentSchedules, Map<Id, Date> paymentEndDates) {
		Map<Id, List<Payment_Schedule__c>> paymentPSMap = new Map<Id, List<Payment_Schedule__c>>();
		List<Payment_Schedule__c> psToCreate = new List<Payment_Schedule__c>();
		List<Payment_Line_Item__c> pliToCreate = new List<Payment_Line_Item__c>();
		Map<Id, List<Payment_Line_Item__c>> plis = new Map<Id, List<Payment_Line_Item__c>>();
		Map<Id, Payment__c> paymentMap = new Map<Id, Payment__c>();
		for (Payment_Schedule__c ps : paymentSchedules) {
			if (paymentPSMap.get(ps.Payment__c) == null) {
				paymentPSMap.put(ps.Payment__c, new List<Payment_Schedule__c>());
			}
			paymentPSMap.get(ps.Payment__c).add(ps);
		}
		// if End date is before last end date create new PS and pro rate it negatively
		// if End date is after last end date find last active PS (start date < end date) and pro rate it positively 
		for (Payment__c p : pList) {
			paymentMap.put(p.Id, p);
			// create new ps if one does not exist. else scenario is when positive pro rating is needed
			if (p.End_Date__c != null && p.Last_Scheduled_End_Date__c != null && p.End_Date__c < p.Last_Scheduled_End_Date__c) {
				Boolean lastPsFound = false;
				for (Payment_Schedule__c ps : paymentPSMap.get(p.Id)) {
					if (ps.Schedule_Start_Date__c > p.End_Date__c && ps.Schedule_Start_Date__c < p.Last_Scheduled_End_Date__c.addMonths(1)) {
						lastPsFound = true;
						ps.Status__c = 'Pending';
						for (Payment_Line_Item__c pli : ps.Payment_Line_Items__r) {
							if (pli.Type__c == 'Normal' && pli.Recurring__c) {
								pli.Price__c = (pli.List_Price__c / 30) * (p.Last_Scheduled_End_Date__c.daysBetween(p.End_Date__c));
							}
						}
					}
				}
				if (!lastPsFound) {
					Payment_Schedule__c ps = paymentPSMap.get(p.Id).get(0);
					system.debug(ps.Payment_Line_Items__r);
					plis.put(ps.Id, ps.Payment_Line_Items__r);
					Payment_Schedule__c nps = ps.clone(false, true, false, false);
					if (p.Last_Scheduled_End_Date__c.month() == 2) {
						nps.Schedule_End_Date__c = p.Last_Scheduled_Start_Date__c.addMonths(2);
						nps.Schedule_Start_Date__c = p.Last_Scheduled_End_Date__c;
					} else if (p.Last_Scheduled_Start_Date__c.month() == 2) {
						nps.Schedule_Start_Date__c = p.Last_Scheduled_End_Date__c;
						nps.Schedule_End_Date__c = p.Last_Scheduled_End_Date__c.addMonths(1);
					} else {
						nps.Schedule_Start_Date__c = p.Last_Scheduled_End_Date__c;
						nps.Schedule_End_Date__c = p.Last_Scheduled_End_Date__c.addMonths(1);
					}
					nps.Credit_Adjusted__c = false;
					nps.Name = 'Payment Schedule - ' + nps.Schedule_Start_Date__c.format() + ' - ' + nps.Schedule_End_Date__c.format();
					nps.Status__c = 'Pending';
					psToCreate.add(nps);
				}
			} else if (p.End_Date__c != null) {
				for (Payment_Schedule__c ps : paymentPSMap.get(p.Id)) {
					if (ps.Schedule_Start_Date__c < p.End_Date__c && ps.Schedule_End_Date__c > p.End_Date__c && (ps.Status__c == 'Pending' || ps.Status__c == 'In Progress')) {
						for (Payment_Line_Item__c pli : ps.Payment_Line_Items__r) {
							if (pli.Type__c == 'Normal' && pli.Recurring__c) {
								pli.Price__c = (pli.List_Price__c / 30) * (ps.Schedule_End_Date__c.addMonths(-1).daysBetween(p.End_Date__c));
							}
						}
					}
				}
			}
		}
		if (!psToCreate.isEmpty()) {
			insert psToCreate;
			List<Payment_Line_Item__c> newPLis = new List<Payment_Line_Item__c>();
			for (Payment_Schedule__c ps : psToCreate) {
				Payment__c p = paymentMap.get(ps.Payment__c);
				for (Payment_Line_Item__c pli : plis.get(ps.getCloneSourceId())) {
					if (pli.Type__c == 'Normal') {
						Payment_Line_Item__c pl = pli.clone(false, false);
						pl.Payment_Schedule__c = ps.Id;
						pl.Price__c = (pl.List_Price__c / 30) * (p.Last_Scheduled_End_Date__c.daysBetween(p.End_Date__c));
						newPLis.add(pl);
					}
				}
			}
			if (!newPLis.isEmpty()) {
				insert newPLis;
			}
		}
		return paymentSchedules;
	}


}