/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className	NXX2_CreateDisplayProofAdFromStaging
* @description  This class will be used to create display proof ads records for staging dsiplay prood ads.  
*/
global class NXX2_CreateDisplayProofAdFromStaging implements Database.Batchable<sObject>,Database.Stateful{
    private string displayProofAdRecordTypeId;private Map<String,String> stagingToActualProofStatusMap;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Default constructor
    */
    public NXX2_CreateDisplayProofAdFromStaging(){
        displayProofAdRecordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName().get('Display Ad').getRecordTypeId();
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the staging task Recods which are related to product order.
        return Database.getQueryLocator([SELECT Link__c,Related_Proof__c,
                                         Related_Proof__r.Status__c,
                                         Error_Message_For_Display__c,Error_Details_For_Display__c,
                                         Processing_Status_For_Display__c 
                                         FROM NXX2_Task_Staging__c 
                                         WHERE Related_Proof__c != null 
                                         AND Type__c = 'DISPLAY_PROOF'
                                         AND Processed_To_Create_Display_Ad__c = false
                                        ]);
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  execute method implementation of Batch interface
    * @param        Database.BatchableContext BC, List<sObject> scope
    * @return       void
    */
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        processTaskRecords((List<NXX2_Task_Staging__c>)scope);
        try{
            processTaskRecords((List<NXX2_Task_Staging__c>)scope);
            for(NXX2_Task_Staging__c task : (List<NXX2_Task_Staging__c>)scope){
            	task.Processed_To_Create_Display_Ad__c = true;
                task.Processing_Status_For_Display__c = 'Success';
            }
            update scope;
        }catch(Exception e){
            for(NXX2_Task_Staging__c task : (List<NXX2_Task_Staging__c>)scope){
                task.Processing_Status_For_Display__c = 'Error';
                task.Error_Message_For_Display__c = 'Exception Occured!';
                task.Error_Details_For_Display__c = e.getMessage();
            }
            update scope;
        }
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_Task_Staging__c> stagingTasks
    * @return       void
    */
    public void processTaskRecords(List<NXX2_Task_Staging__c> stagingTasks){
        List<SocialAd__c> displayAds = new List<SocialAd__c>();
        for(NXX2_Task_Staging__c task : stagingTasks){
            displayAds.add(new SocialAd__c(
                Display_Ad_Link__c = task.Link__c,
                Social_Campaign__c = task.Related_Proof__c,
                RecordTypeId = displayProofAdRecordTypeId,
                Status__c = task.Related_Proof__r.Status__c,
                Created_From_Staging__c = true
            ));
        }
        system.debug('******Display Proof Ad******'+displayAds);
        insert displayAds;
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateProofAdContentFromStaging b = new NXX2_CreateProofAdContentFromStaging();
        database.executebatch(b,1);
    }
}