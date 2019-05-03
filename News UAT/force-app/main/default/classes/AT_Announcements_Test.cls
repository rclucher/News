@isTest
public class AT_Announcements_Test {
	@isTest
    static void testTickerAnnouncements() {
        //SELECT Id, Name, Content__c FROM Business_Announcement__c WHERE (Display__c INCLUDES ('Pop-up')) AND (Id NOT IN (SELECT Announcement__c FROM User_Announcement_Status__c WHERE (User__c = :UserInfo.getUserId()) AND (Status__c = 'Actioned'))) ORDER BY Order__c ASC]
        
        Business_Announcement__c ann = new Business_Announcement__c(Content__c = 'test', Display__c = 'Ticker', Order__c = 0);
        
        insert ann;
        
        List<AT_Announcements.Announcement> anns = AT_Announcements.getAnnouncements();
        
        System.assertNotEquals(null, anns);
        System.assertEquals(1, anns.size());
        
        System.assertEquals('test', anns[0].text);
    }
    
    @isTest
    static void testPopupAnnouncements() {
        //SELECT Id, Name, Content__c FROM Business_Announcement__c WHERE (Display__c INCLUDES ('Pop-up')) AND (Id NOT IN (SELECT Announcement__c FROM User_Announcement_Status__c WHERE (User__c = :UserInfo.getUserId()) AND (Status__c = 'Actioned'))) ORDER BY Order__c ASC]
        
        Business_Announcement__c ann = new Business_Announcement__c(Content__c = 'test', Display__c = 'Pop-up', Order__c = 0);
        
        insert ann;
        
        List<AT_Announcements.Announcement> anns = AT_Announcements.getPopups();
        
        System.assertNotEquals(null, anns);
        System.assertEquals(1, anns.size());
        
        System.assertEquals('test', anns[0].text);
        
        AT_Announcements.displayPopup(anns[0].id);
        
        AT_Announcements.actionPopup(anns[0].id);
        
        anns = AT_Announcements.getPopups();
        
        System.assertEquals(0, anns.size());
    }
}