/**
* @company      existing code
* @author       Jonathan Hersh - jhersh@salesforce.com
* @date         2008-11-13
* @description  This class contains logic for Attachment trigger
* @mod 			201-06-28 Item-00323 louis.wang@bluewolf.com
*					- The existing code is now shifted to the helper class
*					- Updated the Attachment trigger such that when attachment is attached to a Booking record, 
*						a document record will also be created in user's "My Personal Documents" folder 
*/
trigger emailAttachmentReassigner on Attachment (before insert, after insert, after update) {

	if(Trigger.IsInsert && Trigger.isBefore)
	{
		// The existing code is now shifted to helper class
	    AttachmentTrigger_Helper.reparentAttachmentToCase(trigger.new);
	}
	else if((Trigger.IsInsert || Trigger.isUpdate) && Trigger.isAfter)
	{
		// 201-06-28 Item-00323 louis.wang@bluewolf.com
		//		- when attachment is attached to a CyberSell Booking record, 
		//			a document record will also be created in user's "My Personal Documents" folder 
		//		- Note - the existing trigger name could be misleading, but the best pracitce is 
		//					to put all the logic into the existing trigger, rather than creating a new one.
		AttachmentTrigger_Helper.createDocumentForCyberSell(trigger.new);
	}
}