/**
 * Creates billing file and payment schedule associations
 */
global class CS_ScheduleBillingFileCreation implements Schedulable {
	
	global void execute(SchedulableContext SC) {
		CS_BillingFileHelper.createBillingFile(System.now());
		CS_BillingFileHelper.associatePaymentSchedulesToBillingFile(System.now());
	}

}