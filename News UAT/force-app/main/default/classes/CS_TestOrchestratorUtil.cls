@isTest
private class CS_TestOrchestratorUtil
{
    @isTest static void test()
    {
   
        cspofa__orchestration_process_template__c newcampaignprocessTemplate = new cspofa__orchestration_process_template__c();
        newcampaignprocessTemplate.Name = 'Campaign Setup';
        insert newcampaignprocessTemplate;
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel('Campaign Setup');
        list<string> templist = new list<string> (templateLabels);
        string label = 'Campaign Setup';
        CS_OrchestratorUtil orchUtil = new CS_OrchestratorUtil();
        CSPOFA__Orchestration_Process_Template__c template = orchUtil.GetProcessTemplateForLabel (label);
        system.assert(template.Id == newcampaignprocessTemplate.Id);
        
        system.assert(orchUtil.GetProcessTemplateForLabel('Non Existing Template') == null);
    }
}