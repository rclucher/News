public without sharing class Global_Helper 
{
    /***** retrieve record type id by sOjbect type and record type name *****/
    private static Map<String, Map<String, RecordType>> bySobjectAndRecordTypeName
    {
        get{ return bySobjectAndRecordTypeName = bySobjectAndRecordTypeName == null ? new Map<String, Map<String, RecordType>>() : bySobjectAndRecordTypeName; }
        set;
    }

    public static String getRecordTypeIdByName(String recordTypeName, String sObjectType)
    {
        String recordTypeId;
        
        recordTypeName = recordTypeName.trim();
        
        if(recordTypeName != null && sObjectType != null && (!bySobjectAndRecordTypeName.containsKey(sObjectType) || !bySobjectAndRecordTypeName.get(sObjectType).containsKey(recordTypeName)))
        {
            getRecordObjectMap (sObjectType);
        }

        if(bySobjectAndRecordTypeName.get(sObjectType).containsKey(recordTypeName))
        {   
            return bySobjectAndRecordTypeName.get(sObjectType).get(recordTypeName).Id;
        }

        return null;
    }

    private static void getRecordObjectMap (String s)
    {
        Map<String,RecordType> rtObj = new Map<String,RecordType>();      

        for(RecordType rt : [Select r.Id, r.Name From RecordType r where r.SobjectType =: s])
        {
            rtObj.put(rt.name, rt);
        }

        if(rtObj.size()>0)
        {
            bySobjectAndRecordTypeName.put(s, rtObj);
        }

    }
    
    public static void sendMessageToUsers(String subject, String msg, List<String> toAddresses, String bodyType)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        
        if(bodyType == 'html')
        {
            mail.setHtmlBody(msg);
        }
        else
        {
            mail.setPlainTextBody(msg);        	
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public static void sendMessageToUsers(String subject, Map<String, String> messagesByEmail)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        for(String email : messagesByEmail.keySet())
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{email});
            mail.setSubject(subject);
            mail.setHtmlBody('<html><body>' + messagesByEmail.get(email) + '</body></html>');
            mails.add(mail);
        }
        
        Messaging.sendEmail(mails);
    }
    
    public static void notifySysAdminException (List<String> failedIds, String subject, String toAddress)
    {
        String msg = 'Failure records id are ' + failedIds;
                
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{toAddress});
        mail.setSubject(subject);
        mail.setPlainTextBody(msg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public static String convertIdToFifteenDigits(String recId)
    {
        // change 18 digits id to 15 digits id
        if(String.isNotBlank(recId) && recId.length() == 18)
        {
            recId = recId.subString(0, 15);
        }
        
        return recId;
    }
    
    public static Map<Id, Id> parentRoleIdByRoleId
    {
    	get{
    		if(parentRoleIdByRoleId == null)
    		{
		    	parentRoleIdByRoleId = new Map<Id, Id>(); 
		    
		    	if(parentRoleIdByRoleId.size() == 0)
		    	{
			        for(UserRole ur : [Select u.Id, u.ParentRoleId From UserRole u])
			        {
			           parentRoleIdByRoleId.put(ur.Id, ur.ParentRoleId);
			        }
		    	}
    		}
    		
    		return parentRoleIdByRoleId;
    	}
    	private set;
    }
    
    public static boolean isBelowRoleHierarchy(Id userRoleId1, Id userRoleId2)
    {
    	if(userRoleId1 == userRoleId2)
    	   return false;
    	else
    	{
	    	Id parentRoleId = parentRoleIdByRoleId.get(userRoleId2);
	    	
	    	if(parentRoleId == null)
	    		return false;
	    	else if(parentRoleId == userRoleId1)
	    		return true;
	    	else
	    		return isBelowRoleHierarchy(userRoleId1, parentRoleId);
    	}
    }

    // this function determines whether to show header or sidebar in visualforce page
    public static boolean showHeaderAndSidebar {
        get
        {
            showHeaderAndSidebar = false;
            if(ApexPages.currentPage().getParameters().get('s')!=null)
            {
                showHeaderAndSidebar = Boolean.valueOf(ApexPages.currentPage().getParameters().get('s'));
            }
            return showHeaderAndSidebar;
        }
        set;
    }
    
    /*------------------------------------------------------------
    Author:        Stuart Hamilton
    Company:       Salesforce.com
    Description:   Function to retrieve the list of triggers from the User object
                   that have been selected to be bypassed.  This allows triggers to be muted
                   for specified users
    Inputs:        None
    Returns:       A semi colon delimited list of trigger names
    History
    2014-02-21     Stuart Hamilton     Fixed initiation every class creation  
    ------------------------------------------------------------*/
    private static String bypassTrigger {
        get {
            if (bypassTrigger == null) {
                User triggerList = [ Select Bypass_Triggers__c from User where Id =: UserInfo.getUserId() ];
                bypassTrigger = ';' + triggerList.Bypass_Triggers__c + ';'; 
            }
            return bypassTrigger;
        }
    }

        
    /*------------------------------------------------------------
    Author:        Stuart Hamilton
    Company:       Salesforce.com
    Description:   Function to return whether or not a trigger should be fired
                   based on the trigger name passed in
    Inputs:        The apex trigger name as defined in 'Apex Triggers'
    Returns:       true - the trigger should fire
                   false - the trigger should not fire
    History
    <Date>      <Authors Name>     <Brief Description of Change> 
    ------------------------------------------------------------*/       
    public static boolean canTrigger(string apexTriggerName) {   
        if (bypassTrigger != null && bypassTrigger.indexOf(';'+apexTriggerName+';') > -1){
            return false;
         }
        return true;
    }





    /*------------------------------------------------------------
    Author:        Celso de Souza
    Company:       Salesforce.com
    Description:   Function to return whether or not a the current user is an Integration User, based on it's profile
    Inputs:        nill
    Returns:       true - user has profile = Integration
                   false - user does not have profile = Integration
    History
    <Date>      <Authors Name>     <Brief Description of Change> 
    ------------------------------------------------------------*/       
    public static boolean amIIntegrationUser() {
        boolean isIntegrationUser = false;
        try
        {               
            User u = [ Select profile.Name from User where Id =: UserInfo.getUserId()];
            System.debug('@ amIIntegrationUser u.profile.Name:' + u.profile.Name);
            isIntegrationUser = u.profile.Name.contains('Integration');                
        } catch(exception e){
                //Handle exception 
        }

        return isIntegrationUser;
    }


    /*------------------------------------------------------------
    Author:        Celso de Souza
    Company:       Salesforce.com
    Description:   Validate email address
    Inputs:        String email address (eg. 'myemail@gmail.com')
    Returns:       true - if the email address format validates
                   false - if the email address format DOES NOT validates
    History
    <Date>      <Authors Name>     <Brief Description of Change> 
    ------------------------------------------------------------*/  
    public static boolean isEmailAddressValid(String emailAddress)
    {
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(emailAddress);

        return MyMatcher.matches();
    }


    public static map<String, DescribeSObjectResult> sObjectNameBySObjectPrefixMap;
    public static map<String, DescribeSObjectResult> getSObjectDescribeBySObjectPrefixMap()
    {
        if(Global_Helper.sObjectNameBySObjectPrefixMap==null)
        {
            Global_Helper.sObjectNameBySObjectPrefixMap = new map<String, DescribeSObjectResult>();
            // Search every object in the getGlobalDescribe() map to check key prefixes
            for( Schema.SObjectType t : Schema.getGlobalDescribe().values() )
            {
                Schema.DescribeSObjectResult d = t.getDescribe();
                Global_Helper.sObjectNameBySObjectPrefixMap.put(d.getKeyPrefix(), d);
            }
        }
        return Global_Helper.sObjectNameBySObjectPrefixMap;

    }

    public static DescribeSObjectResult getSObjecDescribetBySObjectPrefix(String sObjectPrefix)
    {
        DescribeSObjectResult d = null;

        if(Global_Helper.getSObjectDescribeBySObjectPrefixMap().containsKey(sObjectPrefix))
        {
            d = Global_Helper.getSObjectDescribeBySObjectPrefixMap().get(sObjectPrefix);
        }

        return d;
    }

    /*------------------------------------------------------------
    Author:        Bohao Chen
    Company:       Bluewolf PTY LTD
    Description:   Validate fax number format
    Inputs:        String fax number (eg. '612999999992')
    Returns:       true - if the fax number format validates
                   false - if the fax number format DOES NOT validates
    ------------------------------------------------------------*/  
    public static boolean isValidFax(String fax)
    {
        String faxFormatRegex = '^(61)([2|3|7|8]{1})([0-9]{8})$';
        Pattern MyPattern = Pattern.compile(faxFormatRegex);
        Matcher MyMatcher = MyPattern.matcher(fax);
        return MyMatcher.matches();
    }
}