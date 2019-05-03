public with sharing class EmailTemplate_Controller 
{
	public String baseUrl {get;set;}
	public String divisionName {get;set;}
    private map<String, Division_Info__c> divisionInfoByDivisionName= new map<String, Division_Info__c>();

	public EmailTemplate_Controller()
	{
		baseUrl = system.Url.getSalesforceBaseUrl().getHost();

        for(Division_Info__c di : [Select Name, ABN__c, Address__c, Disclaimer__c, SwitchBoard__c from Division_Info__c])
        {
            divisionInfoByDivisionName.put(di.Name, di);
        }
	}
	
	public String getLogoId()
	{
		Id adProofDocumentId;
		
		if(divisionName != null)
		{
			String documentName = divisionName + ' Logo';
			
	        adProofDocumentId = [Select d.Id
	                                   From Document d 
	                                   Where d.Folder.Name = 'Logos & Identity' 
	                                   And d.Name =: documentName
	                                   order By d.LastModifiedDate DESC limit 1].Id;
		} 
        return adProofDocumentId;
	}
	
    public String getOrgId()
    {
    	return UserInfo.getOrganizationId();
    }
    
    public String getDivisionAddress()
    {
    	try
    	{
            return divisionInfoByDivisionName.get(this.divisionName).Address__c;
    	}
    	catch(Exception e)
    	{
            return null;
    	}
    }
    
    public String getSwitchboard()
    {
        try
        {
            return divisionInfoByDivisionName.get(this.divisionName).SwitchBoard__c;
        }
        catch(Exception e)
        {
            return null;
        }
    }
    
    public String getAbn()
    {
        try
        {
            return divisionInfoByDivisionName.get(this.divisionName).ABN__c;
        }
        catch(Exception e)
        {
            return null;
        }
    }

    public String getDisclaimer()
    {
        try
        {
            return divisionInfoByDivisionName.get(this.divisionName).Disclaimer__c;
        }
        catch(Exception e)
        {
            return null;
        }
    }


}