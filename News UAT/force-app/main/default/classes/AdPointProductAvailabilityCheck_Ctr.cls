public without sharing class AdPointProductAvailabilityCheck_Ctr 
{
	public String adPointUrl
	{
        get
        {
            String adPointUrl;
                
			if(SystemParameters__c.getAll().get('AdPoint_Url')!=null)
			{
			    adPointUrl = SystemParameters__c.getAll().get('AdPoint_Url').value__c;
			}
			return adPointUrl;
        }
	   
        private set;
	}
	
    public boolean showHeaderAndSidebar {
        get { return Global_Helper.showHeaderAndSidebar; }
        set;
    }
}