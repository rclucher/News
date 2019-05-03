public with sharing class CS_CreativeTriggerDelegate extends CS_TriggerHandler.DelegateBase 
{
    List<Creative__c> creativeRecords;
    CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();

    public override void prepareBefore() 
    {
    }

    public override void prepareAfter() 
    {
        creativeRecords = new List<Creative__c>();  
    }

    public override void beforeInsert(sObject o) 
    {
    }

    public override void beforeUpdate(sObject old, sObject o) 
    {
        Creative__c newCreative = (Creative__c)o; 
        Date dt = Date.today();
        if(newCreative.isNextBizDateRecal__c!=null && newCreative.isNextBizDateRecal__c==true)
        {
            newCreative.Next_Business_Date__c =  getNextBizDate(dt); 
            newCreative.isNextBizDateRecal__c = false;
        }
    }

    public override void beforeDelete(sObject o) 
    {
    }

    public override void afterInsert(sObject o) 
    {
        Creative__c creative = (Creative__c)o;
        creativeRecords.add(creative);

    }

    public override void afterUpdate(sObject old, sObject o)
    {
    }

    public override void afterDelete(sObject o) 
    {
    }

    public override void afterUndelete(sObject o) 
    {
    }

    public override void finish() 
    {
        if(trigger.isAfter) {
            if(!creativeRecords.isEmpty())
                CreateCreativeSetupOrchProcesses();
        }   
    }

    void CreateCreativeSetupOrchProcesses () 
    {
        CS_OrchestratorUtil orchestratorUtilNew = new CS_OrchestratorUtil();
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        for (Creative__c creative : creativeRecords) {
            try {
                String orchLabel = 'Creative Setup';

                Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel(orchLabel);

                for (String label : templateLabels) {
                    CSPOFA__Orchestration_Process_Template__c template = orchestratorUtilNew.GetProcessTemplateForLabel (label);
                
                    CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = orchLabel, 
                                                                                                        Creative__c = creative.Id);           
                    processesToInsert.add(process); 
                }
                
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }

        new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
    }
    Date getNextBizDate(Date givenDate)  
        {   
           Integer noOfDays = Integer.valueOf(System.Label.Creative_Days_NextBizDate); 
           if(noOfDays==null)
                noOfDays = 0;
           Date nextBizDt = givenDate; 
           List<Holiday> holList=[Select Name, ActivityDate From Holiday];  
           nextBizDt = nextBizDt.addDays(noOfDays);  
           while(!isWorkingDay(nextBizDt,holList)) 
           {
             nextBizDt = nextBizDt.addDays(1);
           }
           return nextBizDt;    
        }
    Boolean isWorkingDay(Date currentDate,List<Holiday> holidays)
        {   
            String strDay  = ((DateTime)currentDate).format('EEE');
            for(Holiday hDay:holidays)
            {      
                if(currentDate.isSameDay(hDay.ActivityDate)) 
                    return false; 
            }
            if(strDay.toUpperCase()=='SAT' || strDay.toUpperCase()=='SUN')
                return false;
            else 
                return true;
        }   
}