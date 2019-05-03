/*---------------------------------------------------------
 * Author: John Moriarty
 * Company: Salesforce.com
 * Description: Implement smart templates, driven by division
 * Requirement 
 * 
 * History:
 * 12/03/2014  John Moriarty  Created
 ---------------------------------------------------------*/

global class SmartTemplateLoader implements Support.EmailTemplateSelector {
    // Empty constructor
    global SmartTemplateLoader() {    }
    // The main interface method
    global ID getDefaultEmailTemplateId(ID caseId) {
        // Select the case we're interested in, choosing any fields that are relevant to our decision
        Case c = [SELECT Sales_Order__r.Booking_Division__c FROM Case WHERE Id=:caseId];
        //Grab the record type
        String recordTypeName = '';
        
        //ID to return
        Id templateId = null;
        String divn = '';
        String templateName = 'Ad_Proofing_';
        
        //Now to grab the booking ID if it exists.
        if(c.Sales_Order__c != null)
        	divn = c.Sales_Order__r.Booking_Division__c;
        	
        if(divn.length() > 0) {
        	//We now have our division. Let's find the template.
        	templateName = templateName + divn;
        	
        	// get the template ID
	        List<EmailTemplate> ets = [SELECT id FROM EmailTemplate WHERE DeveloperName = :templateName];
	        //Return the ID of the template selected
	        if (!ets.isEmpty()) {
	            EmailTemplate et = ets[0];
	            templateId = et.Id;
	            System.Debug('Template Id ' + templateId + ' found');
	        }
       }
       
       return templateId;
    }    	
}