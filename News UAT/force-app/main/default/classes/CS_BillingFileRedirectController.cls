/**
 * Creates payment schedules for specific billing file and redirects to billing file page
 */
global class CS_BillingFileRedirectController {
	@TestVisible
	private ApexPages.StandardController controller;
	
	public CS_BillingFileRedirectController(ApexPages.StandardController stdController) {
		this.controller = stdController;
	}
	
	webservice static String generatePayments(Id billingFileId) {
		try {
			Billing_File__c bf = [
				select id, Billing_Date__c
				from Billing_File__c
				where id = :billingFileId
			];
			Date d = bf.Billing_Date__c;
			CS_BillingFileHelper.associatePaymentSchedulesToBillingFile(datetime.newInstance(d.year(), d.month(),d.day()));
			return 'Success';
		} catch(Exception e) {
			return 'Error - ' + e.getMessage();
		}
	}
	
	public PageReference generatePayments() {
		try {
			Id recordId = controller.getRecord().Id;
			Billing_File__c bf = [
				select id, Billing_Date__c
				from Billing_File__c
				where id = :recordId
			];
            system.debug('recordId-->'+recordId);
            system.debug('bf-->'+bf);
			Date d = bf.Billing_Date__c;
			CS_BillingFileHelper.associatePaymentSchedulesToBillingFile(datetime.newInstance(d.year(), d.month(),d.day()));
			return controller.view();
		} catch(Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
			return null;
		}
	}

}