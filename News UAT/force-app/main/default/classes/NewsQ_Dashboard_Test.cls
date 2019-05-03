@isTest(SeeAllData = true)
public class NewsQ_Dashboard_Test {
    public static User GM = [SELECT Id, Username, UserRoleId FROM User WHERE Username = 'michael.wilbow@news.com.au'];
    public static User GSD = [SELECT Id, Username, UserRoleId FROM User WHERE Username = 'toni.jones@news.com.au'];
    
    @isTest(SeeAllData = true)
    public static void testDashboardInfo() {
        testDashboardInfo(GSD);
        
        Test.startTest();
        	
        testDashboardInfo(GM);
        
        Test.stopTest();
    }
    
    public static void testDashboardInfo(User u) {
         System.runAs(u) {
            NewsQ_Dashboard.DashboardInfo info = NewsQ_Dashboard.getDashboardInfo(u.Username);
            NewsQ_Dashboard.currentOrSpecifiedUserRole(u.UserRoleID);
            NewsQ_Dashboard.getUsersOrRoles(u.UserRoleID);
        	NewsQ_Dashboard.getTopicScores(info.pillars[0].Name, info.topics.size(), u.UserRoleID); 
            NewsQ_Dashboard.getPillarScores(u.UserRoleID); 
        }
    }
    
   
    @isTest(SeeAllData = true)
    public static void testFinancials() {
        testFinancials(GSD);
        
		Test.startTest();
        
        testFinancials(GM);
        
        Test.stopTest();
    }
    
    public static void testFinancials(User u) {
        System.runAs(u) {
            NewsQ_Dashboard.getFinancials(new List<String>{u.Id}, new List<String>());
        }
    }
}