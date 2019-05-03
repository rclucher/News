public with sharing class DNCUpdate_Controller {

    public PageReference runDncUpdate()
    {
        DNCPhoneUpdate_Batch dncUPdateBatch = new DNCPhoneUpdate_Batch(DNCPhone_Helper.updateQuery);
        ID idBatch = Database.executeBatch(dncUPdateBatch, DNCPhone_Helper.updateScopeSize);
        return null;
    }
    
    public PageReference checkJobStatus()
    {
        PageReference jobPage = new PageReference('/apexpages/setup/listAsyncApexJobs.apexp?retURL=%2Fui%2Fsetup%2FSetup%3Fsetupid%3DJobs&setupid=AsyncApexJobs');
        return jobPage;
    }
    
    public boolean showHeaderAndSidebar {
        get { return Global_Helper.showHeaderAndSidebar; }
        set;
    }

}