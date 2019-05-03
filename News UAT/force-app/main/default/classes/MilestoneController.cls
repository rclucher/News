public with sharing class MilestoneController 
{    
    public Map<String, List<List<MilestoneStep>>> milestonesPerProcess {get; set;}
    public List<SelectOption> processOptions {get; private set;}
    public String selectedProcess {get; set;}
    public boolean hasProcesses {get; set;}
    
    public MilestoneController(ApexPages.StandardController stdController) 
    {
        String queryString = '';
        String objecttype = stdController.getRecord().getSObjectType().getDescribe().getName();
        String objectid = stdController.getId();
 
        queryString = 'select Id, Name, (select Id, CSPOFA__Step_Order__c, CSPOFA__Status__c, Name,CSPOFA__Orchestration_Process__c, CSPOFA__Milestone__c, CSPOFA__Milestone_Label__c, CSPOFA__Milestone_Description__c from CSPOFA__Orchestration_Steps__r order by CSPOFA__Step_Order__c ASC) from CSPOFA__Orchestration_Process__c where (' + objecttype + 
        ' = :objectid OR product_order__r.Order__c =: objectid)  order By createdDate';
        
        List<CSPOFA__Orchestration_Process__c> processes = Database.query(queryString);
        
        processOptions = new List<SelectOption>(); 
        processOptions.add(new SelectOption('All', 'All'));
        milestonesPerProcess = new Map<String, List<List<MilestoneStep>>>();
        milestonesPerProcess.put('All', new List<List<MilestoneStep>>());

        try {
            for (CSPOFA__Orchestration_Process__c p : processes)
            {
                List<MilestoneStep> processMilestones = new List<MilestoneStep>(); //collect milestones for the process
                for (CSPOFA__Orchestration_Step__c step : p.CSPOFA__Orchestration_Steps__r)
                {
                    if (step.CSPOFA__Milestone__c)
                    {
                        processMilestones.add(new MilestoneStep(step,getStatusCssClass(step.CSPOFA__Status__c)));
                    }
                }
                if(milestonesPerProcess.containsKey(p.Name))
                {
                    milestonesPerProcess.get(p.Name).add(processMilestones);
                }
                else 
                {
                    milestonesPerProcess.put(p.Name, new List<List<MilestoneStep>>{processMilestones});
                }
                milestonesPerProcess.get('All').add(processMilestones);
                processOptions.add(new SelectOption(p.Name, p.Name));
            } 
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', stdController.getRecord(), 'Milestones not showing.');
        }
        
        //default selection to 1st (most recently created Process)
        selectedProcess = (processes != null && processes.size() >0 ? processes[0].Name : null);
        hasProcesses = (processes != null && processes.size() >0);
//      system.debug('**** hasProcesses: ' + hasProcesses);
    }
    
    public PageReference processSelectionChanged() 
    {
        //Display the milestones of the selected Process
        return null;
    }
    
    public class MilestoneStep 
    {
        public CSPOFA__Orchestration_Step__c step {get; set;}
        public String cssClass {get; set;} 
        
        public MilestoneStep(CSPOFA__Orchestration_Step__c theStep, String theCssClass) 
        {
            step = theStep;
            cssClass = theCssClass;
        }
    }
    
    //
     public String getStatusCssClass(String status) 
     {
        if (status == 'In Progress') 
        {
            return 'in-progress';
        } 
        else if (status == 'Complete') 
        {
            return 'completed';
        }       
        return 'waiting';
     }
}