/************************************************************************
/* class Track_Update_New_ControllerX
/* description: extension controller to support Track_Update_New page
/* date: 21/05/2013
/* author: Stuart Hamilton
/************************************************************************/

public with sharing class Track_Update_New_ControllerX {

    private Boolean hasPrev;
    private Track_Update__c newUpdate;
    private Track_Update__c prevUpdate;
    private Id projOverviewId;
    
    public Track_Update_New_ControllerX(ApexPages.StandardController controller) {
    if(!test.isRunningTest())
    {     
        controller.addFields(new String[]{'Status_Report__c'});
    }

        newUpdate = (Track_Update__c)controller.GetRecord();
        // get the project Id 
        List<Status_Report__c> sr = [SELECT Project_Overview__c FROM Status_Report__c WHERE Id = :newUpdate.Status_Report__c];
        if (sr.size() == 1)  projOverviewId = sr[0].Project_Overview__c;
    }
    
    public Track_Update__c getNewUpdate() {
    
        return this.newUpdate;
    }
    
    public Track_Update__c getPreviousUpdate() {
               
        return this.prevUpdate; 
    }
    
    public Boolean getPrev() {
        return this.hasPrev;
    }

    public PageReference findPrevious() {
    
        this.hasPrev = false;
        
        system.debug('Track: ' + newUpdate.Track__c);
        system.debug('Project Overview: ' + projOverviewId);
        
        List<Track_Update__c> prevUpdates = [SELECT Accomplishments_this_Period__c, Planned_but_Not_Accomplished__c, Planned_for_Next_Period__c, 
                                             Status_Report__c, Track__c, Track_Status__c, Track_Status_Icon__c, Owner.Name, Status_Report__r.Project_Overview__c
                                             FROM Track_Update__c
                                             WHERE Track__c = :newUpdate.Track__c 
                                             AND Status_Report__r.Project_Overview__c = :projOverviewId
                                             ORDER BY CreatedDate DESC
                                             LIMIT 1];  
        
        if (prevUpdates.size() == 1) {
            this.hasPrev = true;
            this.prevUpdate = prevUpdates[0];
        }

        return null;
    }
    
}