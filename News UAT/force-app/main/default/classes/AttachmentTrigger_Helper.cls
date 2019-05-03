/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2017-06-29
* @description  This class contains methods that are used for Attachment trigger (emailAttachmentReassigner.trigger)
*/
public with sharing class AttachmentTrigger_Helper 
{
    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2017-06-29
    * @description  This method is an existing code, copied from emailAttachmentReassigner.trigger
    */    
    public static void reparentAttachmentToCase(List<Attachment> attList)
    {
		// This existing code will save attachment from EmailMessage to Case record
	    for( Attachment a : attList ) 
	    {
	        // Check the parent ID - if it's 02s, this is for an email message
	        if( a.parentid == null )
	            continue;
	        
	        String s = string.valueof( a.parentid );
	        
	        if( s.substring( 0, 3 ) == '02s' )
	            a.parentid = [select parentID from EmailMessage where id = :a.parentid].parentID;            
	    }
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2017-06-29
    * @description  Item-00323
	*					- when attachment is attached to a CyberSell Booking record, 
	*						a document record will also be created in user's "My Personal Documents" folder 
	*					- Note - the existing trigger name could be misleading, but the best pracitce is 
	*						to put all the logic into the existing trigger, rather than creating a new one.
    */    
    public static void createDocumentForCyberSell(List<Attachment> attList)
    {


    	System.debug('@@AttachmentTrigger_Helper : createDocumentForCyberSell : attList.Count ' + attList.size());
		// Determine if Attachment relates to a CyberSell booking
		Map<Id, String> cyberSellBookingName_byBookingId_map = new Map<Id, String>();
		List<Id> bookingIdList = new List<Id>();
	    for( Attachment a : attList ) 
	    {
	    	Id parentId = a.ParentId;
    		if(parentId!=null && parentId.getSobjectType()==Schema.Booking__c.SObjectType)
    		{
    			bookingIdList.add(parentId);
    		}
	    }
	    for(Booking__c b : [SELECT Id, Name, Source_System__c FROM Booking__c
							WHERE Id IN: bookingIdList])
	    {
	    	if(b.Source_System__c=='Cyber$ell')
	    	{
	    		cyberSellBookingName_byBookingId_map.put(b.Id, b.Name);
	    	}
	    }

	    // if Attachment relates to CyberSell Booking, then create a Document record
	    for( Attachment a : attList ) 
	    {
	    	if(cyberSellBookingName_byBookingId_map.containsKey(a.ParentId))
	    	{
				Document document = new Document();
			    document.AuthorId = UserInfo.getUserId();
			    //20170719 NK item-00329
			    //query document folders to find "CyberSell Proofs" 
			    //document.FolderId = UserInfo.getUserId(); // put it in running user's folder
				Folder folder = [select id from Folder where name='CyberSell Proofs' LIMIT 1];
				document.FolderId = folder.Id;
			    document.Body = a.body;
			    // the name of the document is made up of Booking Name and Attachment Name
			    document.Name = cyberSellBookingName_byBookingId_map.get(a.ParentId) + ' - ' + a.Name;        
				insert document;
    		}
	    }
	}
}