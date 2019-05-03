/**
 * Sends billing file to ESB
 */
global class CS_SendBillingFileController {
	
	@TestVisible
	private ApexPages.StandardController controller;
	
	/**
	 * sends CSV file to ESB - used only for testing in classic
	 * @param Id billingFileId
	 * @return String
	 */
	webservice static String sendBillingFile(Id billingFileId) {
		Billing_File__c bf = [
			select id, name, Billing_Date__c, Status__c, Error_Message__c
			from Billing_File__c
			where id = :billingFileId
		];
		try {
			if (bf.Status__c == 'Sent to Billing') {
				return 'File already sent to Billing';
			}
			String res = FileExporter.pushFileToOut(bf.Id);
			if (res.contains('FAIL') || res.contains('Error')) {
				bf.Status__c = 'Error';
				bf.Error_Message__c = res;
				update bf;
				return 'Cannot send file to ESB.' + ' ' + res;
			}
			bf.Status__c = 'Sent to Billing';
			bf.Error_Message__c = '';
			update bf;
			List<Payment_Schedule__c> psToUpdate = [
				select id, status__c
				from Payment_Schedule__c
				where id in (
					select Payment_Schedule__c
					from PS_Billing_File_Association__c
					where Billing_File__c = :billingFileId
				)
			];
			if (!psToUpdate.isEmpty()) {
				for (Payment_Schedule__c ps : psToUpdate) {
					ps.Status__c = 'Invoiced';
				}
				update psToUpdate;
			}
			return 'File sent to ESB';
		} catch (Exception e) {
			bf.Status__c = 'Error';
			bf.Error_Message__c = e.getMessage();
			update bf;
			return 'Error - ' + e.getMessage();
		}
	}
	
	public CS_SendBillingFileController(ApexPages.StandardController sc) {
		this.controller = sc;
	}
	
	/**
	 * For lightning - custom action to execute code
	 * @return PageReference
	 */
	public PageReference sendBillingFile() {
		Billing_File__c bf = [
			select id, name, Billing_Date__c, Status__c, Error_Message__c
			from Billing_File__c
			where id = :controller.getRecord().Id
		];
		if (bf.Status__c == 'Sent to Billing') {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'File already sent to Billing'));
			return null;
		}
		String res = FileExporter.pushFileToOut(bf.Id);
		if (res.contains('FAIL') || res.contains('Error')) {
			bf.Status__c = 'Error';
			bf.Error_Message__c = res;
			update bf;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'Cannot send file to ESB.' + ' ' + res));
			return null;
		}
		bf.Status__c = 'Sent to Billing';
		bf.Error_Message__c = '';
		update bf;
		List<Payment_Schedule__c> psToUpdate = [
			select id, Status__c
			from Payment_Schedule__c
			where id in (
				select Payment_Schedule__c
				from PS_Billing_File_Association__c
				where Billing_File__c = :controller.getRecord().Id
			)
		];
		if (!psToUpdate.isEmpty()) {
			for (Payment_Schedule__c ps : psToUpdate) {
				ps.Status__c = 'Invoiced';
			}
			update psToUpdate;
		}
		return controller.view();
	}

}