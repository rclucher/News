public class AT_Announcements {
    public class Announcement {
        @AuraEnabled
        public String id {get; set;}
        
        @AuraEnabled
        public Boolean first {get; set;}
        
        @AuraEnabled
        public Boolean last {get; set;}
        
        @AuraEnabled
        public Boolean odd {get; set;}
        
        @AuraEnabled
        public Boolean even {get; set;}
        
        @AuraEnabled
        public String title {get; set;}
        
        @AuraEnabled
        public String text {get; set;}
        
        public Announcement(String text) {
            this.text = text;
        }
    }
    
    @AuraEnabled
    public static List<Announcement> getPopups() {
        List<Announcement> announcements = new List<Announcement>();
        
        Boolean odd = true;
        
        for (Business_Announcement__c ann: [SELECT Id, Name, Content__c FROM Business_Announcement__c WHERE (Display__c INCLUDES ('Pop-up')) AND (Id NOT IN (SELECT Announcement__c FROM User_Announcement_Status__c WHERE (User__c = :UserInfo.getUserId()) AND (Status__c = 'Actioned'))) ORDER BY Order__c ASC]) {
            String text = ann.Content__c;
            
            if (text.startsWith('<p>')) text = text.substring(3);
            if (text.endsWith('</p>')) text = text.left(text.length() - 4);
            
            Announcement ancmnt = new Announcement(text);
            
            ancmnt.id = ann.Id;
            ancmnt.title = ann.Name;
            
            ancmnt.odd = odd;
            ancmnt.even = !odd;
            
            announcements.add(ancmnt);
            
            odd = !odd;
        }
        
        return announcements;
    }
    
    @AuraEnabled
    public static void displayPopup(String announcementID) {
        List<User_Announcement_Status__c> anns = [SELECT Display_Timestamp__c FROM User_Announcement_Status__c WHERE (User__c = :UserInfo.getUserId()) AND (Announcement__c = :announcementID) FOR UPDATE];

        if (anns.isEmpty()) {
            User_Announcement_Status__c ann = new User_Announcement_Status__c(
                                                    	User__c = UserInfo.getUserId(),
                										Announcement__c = announcementID,
                                                        Display_Timestamp__c = System.now(),
                										Status__c = 'Displayed'
                                                    );
            
            insert ann;
        } else {
            anns[0].Display_Timestamp__c = System.now();
        	anns[0].Status__c = 'Displayed';
        	update anns;
        }
        
		
    }
    
    @AuraEnabled
    public static void actionPopup(String announcementID) {
        List<User_Announcement_Status__c> anns = [SELECT Actioned_Timestamp__c FROM User_Announcement_Status__c WHERE (User__c = :UserInfo.getUserId()) AND (Announcement__c = :announcementID) FOR UPDATE];

		if (anns.isEmpty()) {
            User_Announcement_Status__c ann = new User_Announcement_Status__c(
                                                    	User__c = UserInfo.getUserId(),
                										Announcement__c = announcementID,
                										Display_Timestamp__c = System.now(),
                                                        Actioned_Timestamp__c = System.now(),
                										Status__c = 'Actioned'
                                                    );
            
            insert ann;
        } else {
            anns[0].Actioned_Timestamp__c = System.now();
            anns[0].Status__c = 'Actioned';
            update anns;
        }
    }
    
	@AuraEnabled
    public static List<Announcement> getAnnouncements() {
        List<Announcement> announcements = new List<Announcement>();
        
        Boolean odd = true;
        
        for (Business_Announcement__c ann: [SELECT Content__c FROM Business_Announcement__c WHERE (Display__c INCLUDES ('Ticker')) ORDER BY Order__c ASC]) {
            String text = ann.Content__c;
            
            if (text.startsWith('<p>')) text = text.substring(3);
            if (text.endsWith('</p>')) text = text.left(text.length() - 4);
            
            Announcement ancmnt = new Announcement(text);
            
            ancmnt.odd = odd;
            ancmnt.even = !odd;
            
            announcements.add(ancmnt);
            
            odd = !odd;
        }
        
        if (!announcements.isEmpty()) {
            announcements[0].first = true;
            
            announcements[announcements.size() - 1].last = true;
        }
        
        return announcements;
    }
}