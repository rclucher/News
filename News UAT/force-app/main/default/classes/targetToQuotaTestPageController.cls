public without sharing class targetToQuotaTestPageController 
{
	public Boolean isVisible {get; set;}
	
	public targetToQuotaTestPageController()
	{
		Id runningUserId = userInfo.getUserId();
		
		isVisible = true;
		
		try
		{
			PermissionSet ps = [Select p.Id From PermissionSet p Where p.Name = 'Managers_Divisional_Ops' limit 1];
			Integer permissionSetNumber = [Select count() From PermissionSetAssignment p Where p.AssigneeId =: runningUserId and p.PermissionSetId =: ps.Id];
			
			if(permissionSetNumber == 0)
			{
				isVisible = false;
			}
		}
		catch(Exception e){
            isVisible = false;
		}
	}	
	
    public PageReference loadTarget() 
    {
        TargetToQuota_Batch targetToQuota = new TargetToQuota_Batch(TargetToQuota_Helper.targetToQuotaQuery);
        ID batchProcessId = Database.executeBatch(targetToQuota);
        return null;
    }

    
}