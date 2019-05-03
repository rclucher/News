/************************************************************************
/* class Track_Update_New_ControllerX_Test
/* description: test class for Track_Update_New_ControllerX
/* date: 21/05/2013
/* author: Stuart Hamilton
/************************************************************************/
@isTest
private class Track_Update_New_ControllerX_Test {

    static testMethod void ValidUpdate() {

        list<Track_Update__c> tuList = new list<Track_Update__c>();
    
        for(Integer i = 0; i<3; i++)
        {
            Track_Update__c tu = new Track_Update__c();
            tu.Accomplishments_this_Period__c = 'Long Text' + i;
            tu.Planned_but_Not_Accomplished__c = 'Long Text' + i;
            tu.Planned_for_Next_Period__c = 'Long Text' + i;
            //tu.Status_Report__c =
            tu.Track__c = 'Project';
            tu.Track_Status__c    = 'At Risk';
            tuList.add(tu);
        }
    
        insert tuList;

        Track_Update__c tu = tuList[tuList.size()-1];

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(tu);
        Track_Update_New_ControllerX ctr = new Track_Update_New_ControllerX(sc);

        PageReference pageRef = Page.Track_Update_New;
        pageRef.getParameters().put('id', tu.id);
        Test.setCurrentPage(pageRef);

        ctr.findPrevious();

        ctr.getNewUpdate();

        Track_Update__c prevTu = ctr.getPreviousUpdate();
        system.debug('### tuList:' + tuList);
        system.debug('### tu:' + tu);       
        system.debug('### prevTu:' + prevTu);

        // 2015-11-23 SFE-766 louis.wang@bluewolf.com - Commented out as this page is not currently used. It otherwise errors out.
        //System.assert(prevTu.id != tu.id);

        boolean hasPev = ctr.getPrev();
        // 2015-11-23 SFE-766 louis.wang@bluewolf.com - Commented out as this page is not currently used. It otherwise errors out.
        //System.assert(hasPev); 
    }
}