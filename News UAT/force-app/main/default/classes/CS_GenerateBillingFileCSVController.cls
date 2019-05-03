/**
 * Generates billing file CSV and attaches it to billing file
 * Old CSV file is deleted
 */
global class CS_GenerateBillingFileCSVController {
	
    @TestVisible
	private ApexPages.StandardController controller;
	
	/**
	 * Generates CSV file - used only for testing in classic
	 * @param Id billingFileId
	 * @return String
	 */
	webservice static String generateCSV(Id billingFileId) {
		try {
			Billing_File__c bf = [
				select id, name, Billing_Date__c
				from Billing_File__c
				where id = :billingFileId
			];
            System.debug('bf-->'+bf);
			List<Attachment> oldAttachments = [
				select id
				from Attachment
				where ParentId = :bf.Id
				and name = :bf.Name
			];
            System.debug('oldAttachments-->'+oldAttachments);
			if (!oldAttachments.isEmpty()) {
				delete oldAttachments;
			}
			Attachment att = new Attachment(
				name = bf.Name + '.csv',
				ParentId = bf.Id,
				Body = Blob.valueOf(CS_BillingFileCSVGenerator.generateCSV(bf))
			);
			insert att;
			return 'CSV file generated.';
		} catch (Exception e) {
			return 'Error - ' + e.getMessage();
		}
	}
	
	public CS_GenerateBillingFileCSVController(ApexPages.StandardController sc) {
		this.controller = sc;
	}
	
	/**
	 * For lightning - custom action to execute code
	 * @return PageReference
	 */
	public PageReference generateCSV() {
		Billing_File__c bf = [
			select id, name, Billing_Date__c
			from Billing_File__c
			where id = :controller.getRecord().Id
		];
		List<Attachment> oldAttachments = [
			select id
			from Attachment
			where ParentId = :bf.Id
		];
		if (!oldAttachments.isEmpty()) {
			delete oldAttachments;
		}
		Attachment att = new Attachment(
			name = bf.Name + '.csv',
			ParentId = bf.Id,
			Body = Blob.valueOf(CS_BillingFileCSVGenerator.generateCSV(bf))
		);
		insert att;
		return controller.view();
	}

}