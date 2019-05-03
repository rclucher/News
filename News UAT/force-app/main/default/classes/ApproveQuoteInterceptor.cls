global class ApproveQuoteInterceptor implements Messaging.InboundEmailHandler {

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

		try {
			List<String> subjectTokens = email.subject.split(':');
			String customerApprovalKey = subjectTokens.get(1);

			List<CSCAP__Customer_Approval__c> customerApproval = [Select Id, Name, CSCAP__Approved_By_Customer__c, CSCAP__Opportunity__c,
																  CSCAP__Opportunity__r.Approved_Sales_Order_Number__c, Upload_Approval__r.csmso__Sales_Order__c,
																  Upload_Approval__r.csmso__Sales_Order__r.Name,
																  Upload_Approval__r.csmso__Sales_Order__r.csmso__Booking_Contact__c,
																  CSCAP__Click_Approve_Setting__r.Acknowl_Template_Approval_Exists__c
																  FROM CSCAP__Customer_Approval__c
																  WHERE CSCAP__Key__c = :customerApprovalKey];
			//Get all approved SO for current Opportunity, not relying on CSCAP__Opportunity__r.Approved_Sales_Order_Number__c as it includes Internally Approved SOs
			Id opportunityId = customerApproval[0].CSCAP__Opportunity__c;
			Id currentSO     = customerApproval[0].Upload_Approval__r.csmso__Sales_Order__c;
			Map<Id, csmso__Sales_Order__c> approvedOrdersMap = new Map<Id, csmso__Sales_Order__c>([SELECT Id, csmso__Status__c
																								   FROM csmso__Sales_Order__c
																								   WHERE csmso__Opportunity__c = : opportunityId
																									 AND csmso__Status__c IN:SalesOrder_Helper.APPROVED_STATUS_SET]);
			//if current approval is already approved then no need to do anything
			//redundant check that package doesn't need but we do as we would create additional document
			if (customerApproval[0].CSCAP__Approved_By_Customer__c) {
				//Optionally we could notify approver that this SO was already approved
				sendEmail(
						email.fromAddress,
						customerApproval[0].Upload_Approval__r.csmso__Sales_Order__r.csmso__Booking_Contact__c,
						customerApproval[0].Id,
						customerApproval[0].CSCAP__Click_Approve_Setting__r.Acknowl_Template_Approval_Exists__c);
			} else if (approvedOrdersMap.isEmpty()) {
				//approval is allowed if Opportunity doesn't have already approved SO
				//NR-608 Save approval notification email body as pdf
				Attachment att = new Attachment(
					Name = customerApproval[0].Upload_Approval__r.csmso__Sales_Order__r.Name + ' approval by: ' + email.fromAddress + '.pdf',
					Body = Blob.toPdf(email.htmlBody),
					ContentType = 'application/pdf',
					ParentId = customerApproval[0].CSCAP__Opportunity__c);//Requested to save it on Opp level

				insert att;
				//handover control to package logic as we have nothing else to do
				CSCAP.ApproveQuote approveQuote = new CSCAP.ApproveQuote();
				approveQuote.handleInboundEmail(email, env);
			} else {
				//Opp has approved SOs so inform approver that this approval isn't possible
				sendEmail(
					email.fromAddress,
					customerApproval[0].Upload_Approval__r.csmso__Sales_Order__r.csmso__Booking_Contact__c,
					customerApproval[0].Id,
					customerApproval[0].CSCAP__Click_Approve_Setting__r.Acknowl_Template_Approval_Exists__c);
			}
		} catch (Exception ex) {
			System.debug('ApproveQuoteInterceptor > handleInboundEmail: ' + ex);
			//TODO send email to admin to be aware that approval silently failed?
		}

		result.success = true;
		return result;
	}

	/**
	 * Helper method for constructing and sending email.
	 * Email will be sent to the toEmail and logged as in activity history of whatId object.
	 * Email uses template defined by templateName.
	 * If any of the params is not provided method assumes that email is not needed and finishes.
	 */
	private void sendEmail(String toEmail, Id targetObjectId, Id whatId, String templateName) {
		//get template by using name
		Id templateId;
		if (String.isBlank(templateName) || String.isBlank(toEmail) || targetObjectId == null || whatId == null) {
			//we need all info so aborting as email shouldn't be send
			return;
		} else {
			List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName];
			if (emailTemplates.isEmpty()) {
				//incorrect setup, unknown template name
				System.debug('ApproveQuoteInterceptor > sendEmail: Unknown email template name: ' + templateName);
				return;
			} else {
				templateId = emailTemplates[0].Id;
			}
		}
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new List<String>{toEmail});
		mail.setTemplateID(templateId);
		mail.setTargetObjectId(targetObjectId);
		mail.setTreatTargetObjectAsRecipient(false);
		mail.setWhatId(whatId);
		mail.setSaveAsActivity(true);
		List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail}, false);
		//System.debug('Email results: '+ emailResults);
	}
}