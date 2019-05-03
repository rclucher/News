/*---------------------------------------------------------
	Author: Bohao Chen
	Company: Salesforce.com
	Description: this trigger relates to requirement R-0822.
	             this trigger is used to maintain the field PublicationList__c on product
	             where publication/product mapping records
	             being inserted or updated or deleted
	History:
	2/09/2013   Bohao Chen  Created
---------------------------------------------------------*/
trigger PublicationProductManagement on Publication_Product__c (after delete, after insert, after update) 
{
    if (Global_Helper.canTrigger( 'PublicationProductManagement' ) ){
	Map<String, List<String>> deletePublicationsByProductId = new Map<String, List<String>>();
	Map<String, List<String>> insertPublicationsByProductId = new Map<String, List<String>>();
	
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isDelete))
    {
    	if(trigger.isDelete)
    	{
    		for(Publication_Product__c p : trigger.old)
    		{
    			system.debug('====== delete p======= ' + p);
    			
                if(p.Product__c != null)
                {
                	if(!deletePublicationsByProductId.containsKey(p.Product__c))
                    {
                    	deletePublicationsByProductId.put(p.Product__c, new List<String>());
                    }
                    
                    deletePublicationsByProductId.get(p.Product__c).add(p.Publication__c);
                }
    		}
    	}
    	
    	if(trigger.isInsert)
    	{
    		for(Publication_Product__c p : trigger.new)
            {
                system.debug('======= insert p======= ' + p);
                
                if(p.Product__c != null && p.Active__c)
                {
                    if(!insertPublicationsByProductId.containsKey(p.Product__c))
                    {
                        insertPublicationsByProductId.put(p.Product__c, new List<String>());
                    }
                    
                    insertPublicationsByProductId.get(p.Product__c).add(p.Publication__c);
                }
            }
    	}
    	
    	if(trigger.isUpdate)
    	{
            for(Publication_Product__c p : trigger.new)
            {
    			String oldProductId = trigger.oldMap.get(p.Id).Product__c;
    			String newProductId = trigger.newMap.get(p.Id).Product__c;
    			String oldPublication = trigger.oldMap.get(p.Id).Publication__c;
    			String newPublication = trigger.newMap.get(p.Id).Publication__c;
    			
    			if(oldProductId != newProductId || oldPublication != newPublication)
    			{
	    			// delete old publications on old products
	    			if(!deletePublicationsByProductId.containsKey(oldProductId))
	                {
	                    deletePublicationsByProductId.put(oldProductId, new List<String>());
	                }
	                
	                deletePublicationsByProductId.get(oldProductId).add(oldPublication);
	                
	                // insert new publications on new products
	                if(p.Active__c)
	                {
		                if(!insertPublicationsByProductId.containsKey(newProductId))
		                {
		                    insertPublicationsByProductId.put(newProductId, new List<String>());
		                }
		                
		                insertPublicationsByProductId.get(newProductId).add(newPublication);
	                }
    			}
            }
    	}
    	
    	system.debug('==== BC: deletePublicationsByProductId=== ' + deletePublicationsByProductId);
        system.debug('==== BC: insertPublicationsByProductId=== ' + insertPublicationsByProductId);
    	
    	if(deletePublicationsByProductId.size() > 0 || insertPublicationsByProductId.size() > 0)
    	{
    	   PublicationProductManagement_Helper.updatePublications(deletePublicationsByProductId, insertPublicationsByProductId);
    	}
    }
}
}