public with sharing class InsertionOrder2ClickApproveController {
	//quick help, define product to Click Approve setting Name mapping
	private static final Map<String, String> productToCAsettingName = new Map<String, String>{
		'xtend'  => 'IO Email Approval Setting – News Xtend',
		'printLed' => 'IO Email Approval Setting – News Value Bundles',
		'others' => 'IO Email Approval Setting – News Multi Product Platform'
		
	};

	public InsertionOrder2ClickApproveController() {
	}

	public PageReference insertionOrder2ClickApprove() {
		Id ioId = ApexPages.currentPage().getParameters().get('Id');
		Id soId = ApexPages.currentPage().getParameters().get('soId');
		CSCAP__ClickApprove_Contact_Role__c role = null;

		csmso__Sales_Order__c so = [SELECT Id, csmso__Booking_Contact__c, Basket_Products__c,
									(SELECT Id FROM Attachments WHERE IsDeleted = false AND (NOT Name LIKE 'Retract%') )
									FROM csmso__Sales_Order__c WHERE Id = :soId];

		try {
			role = [SELECT CSCAP__Contact__c
					FROM CSCAP__ClickApprove_Contact_Role__c
					WHERE Upload_Approval__c = :ioId];
		} catch (Exception e) {
			// no records
		}

		Id clickApproveSettingId = getCAsettingIdForBasketProducts(so.Basket_Products__c);

		if (role == null) {
			role = new CSCAP__ClickApprove_Contact_Role__c(
				CSCAP__ClickApprove_Setting__c = clickApproveSettingId,
				Upload_Approval__c = ioId,
				CSCAP__IsPrimary__c = true,
				CSCAP__Role__c = 'Booking Contact');
		}

		role.CSCAP__Contact__c = so.csmso__Booking_Contact__c;
		upsert role;
		//gather all attached records, to be used once new url param is supported
		/*
		   String attachmentIds = '';
		   for (Attachment attachment : so.Attachments) {
		    attachmentIds +=  attachment.Id +',';
		   }
		   //remove last separator
		   attachmentIds = attachmentIds.removeEnd(';');
		 */
		//alternative approach: clone all attachemnts from SO to the upload approval record, make sure to delete all attachemtns (apart from Insertion Order ones)
		//delete all but InsertionOrder ones
		csmso__Upload_Approval__c ua = [SELECT Id, Name FROM csmso__Upload_Approval__c WHERE Id = :ioId];
		//due to NR-25 IO Attachment is no longer called InsertionOrder but it matches UA Name so we will use that
		List<Attachment> uploadApprovalAttachmentsForDeletion = [SELECT Id FROM Attachment WHERE ParentId = :ioId AND (NOT Name = :ua.Name)];
		if (!uploadApprovalAttachmentsForDeletion.isEmpty()) {
			delete uploadApprovalAttachmentsForDeletion;
		}
		//clone fresh ones, new query as binary fields can't be part of sub-select
		List<Attachment> soAttachmentsForClone = new List<Attachment>();
		for (Attachment att : [SELECT Name, Body, BodyLength, ParentId, ContentType, Description, OwnerId FROM Attachment WHERE Id IN :so.Attachments]) {
			Attachment attForInsert = att.clone(false, true, true, true);
			attForInsert.ParentId = ioId;
			soAttachmentsForClone.add(attForInsert);
		}
		if (!soAttachmentsForClone.isEmpty()) {
			insert soAttachmentsForClone;
		}

		PageReference pgRef = (new InsertionOrder2ClickApproveController()).callSendFormalEmailForApproval(ioId, role.CSCAP__Contact__c, clickApproveSettingId, '', '/' + (String) so.Id, true);

		return pgRef;

		//return new PageReference('/apex/CSCAP__SendFormalEmailForApproval_LE?Id=' + ioId);
	}

	public PageReference callSendFormalEmailForApproval(Id approvalObjectId, Id contactId, Id clickApproveSettingId, String attachmentIds, String retUrl, boolean isSelectAllAttachments){
		if (approvalObjectId == null) {
			return null;
		}

		String sendEmailForApprovalUrl = '/apex/CSCAP__SendFormalEmailForApproval_LE?id='+approvalObjectId;
		sendEmailForApprovalUrl += (clickApproveSettingId == null) ? '' : '&sId=' + clickApproveSettingId;
		sendEmailForApprovalUrl += (contactId == null) ? '' : '&cId=' + contactId;
		sendEmailForApprovalUrl += (String.isEmpty(attachmentIds)) ? '' : '&attIds=' + attachmentIds;
		sendEmailForApprovalUrl += (String.isEmpty(retUrl)) ? '' : '&retUrl=' + retUrl;
		sendEmailForApprovalUrl += (isSelectAllAttachments) ? '&selectAllAtts=true' : '';

		return new PageReference(sendEmailForApprovalUrl);
	}

	/**
	 * Rudimentary dynamic CA setting selection.
	 * If we have News Xtend product but no Led in the bundle then we will prefer CA settings for Xtend
	 * otherwise we default to bundle
	 * @return Id of Click Approve setting s to be used
	 */
	@TestVisible
	private Id getCAsettingIdForBasketProducts(String basketProducts) {
		//defaulting to old logic i.e. IO Email Approval Setting – News Corp Bundles
		String caSettingName = null;
		if (String.isNotBlank(basketProducts) && (basketProducts.containsIgnoreCase('[News Xtend]') || basketProducts.containsIgnoreCase('[Xtend Led]'))) {
			caSettingName = productToCAsettingName.get('xtend');
		}
		//additional revert back to default if we have bundle
		else if (String.isNotBlank(basketProducts) && basketProducts.containsIgnoreCase('[Print Led]')){
			caSettingName = productToCAsettingName.get('printLed');
		}else
			caSettingName = productToCASettingName.get('others');

		CSCAP__Click_Approve_Setting__c setting = [SELECT Id FROM CSCAP__Click_Approve_Setting__c WHERE Name = :caSettingName AND CSCAP__Status__c = 'Active'];
		return setting != null ? setting.Id : null;
	}
}