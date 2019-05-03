public class NewsQ_Dashboard {
    public class Topic implements Comparable {
        @AuraEnabled
        public String id {get; set;}
        
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public String status {get; set;}
        
        public Topic(String id, String name, String status) {
            this.id = id;
            this.name = name;
            this.status = status;
        }
        
        public Integer compareTo(Object compareTo) {
    		Topic that = (Topic)compareTo;
            
            return (this.name < that.name) ? -1 : (this.name == that.name) ? 0 : 1;
		}
    }
    
    public class TopicScore implements Comparable {
        @AuraEnabled
        public String id {get; set;}
        
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public Decimal score {get; set;}
        
        @AuraEnabled
        public Decimal pillarMax {get; set;}
        
        @AuraEnabled
        public Integer userCount {get; set;}
        
        @AuraEnabled
        public List<Topic> topics {get; set;}
        
        public Map<String, Topic> topicMap {get; set;}
        
        public TopicScore(String id, String name, Decimal score, Decimal pillarMax) {
            this.id = id;
            this.name = name;
            this.score = score;
            this.pillarMax = pillarMax;
            topics = new List<Topic>();
            topicMap = new Map<String, Topic>();
            
            this.userCount = 1;
        }
        
        public Integer compareTo(Object compareTo) {
    		TopicScore that = (TopicScore)compareTo;
            
            return (this.name < that.name) ? -1 : (this.name == that.name) ? 0 : 1;
		}
    }
    
    public class Pillar {
        @AuraEnabled
        public String id {get; set;}
        
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public Decimal score {get; set;}
        
        @AuraEnabled
        public String status {get; set;}
        
        public Pillar(String id, String name, Decimal score, String status) {
            this.id = id;
            this.name = name;
            this.score = score;
            this.status = status;
        }
    }
    
    public class PillarScore {
        @AuraEnabled
        public String id {get; set;}
        
        @AuraEnabled
        public String name {get; set;}
        
        @AuraEnabled
        public Decimal score {get; set;}
        
        @AuraEnabled
        public Decimal percent {get; set;}
        
        
        @AuraEnabled
        public Decimal pillarMax {get; set;}
        
        //@AuraEnabled
        //public String status {get; set;}
        
        @AuraEnabled
        public Integer userCount {get; set;}
        
        @AuraEnabled
        public List<Pillar> pillars {get; set;}
        
        public Map<String, Pillar> pillarMap {get; set;}
        
        public PillarScore(String id, String name, Decimal score, Decimal percent, Decimal pillarMax) {
            this.id = id;
            this.name = name;
            //this.status = status;
            this.score = score;
            this.pillarMax = pillarMax;
            this.percent = percent;
            pillars = new List<Pillar>();
            pillarMap = new Map<String, Pillar>();
            
            this.userCount = 1;
        }
    }
    
    class UserRoles {
        // If true, the IDs are for users, or else for user roles
        public Boolean users;
        
        public List<Id> ids;
    }
    
    public class DashboardInfo {
        @AuraEnabled
        public String roleID {get; set;}
        
        @AuraEnabled
        public String type {get; set;}
        
        @AuraEnabled
        public List<Topic__c> topics {get; set;}
        
        @AuraEnabled
        public List<Pillar__c> pillars {get; set;}
        
        public DashboardInfo() {
            topics = new List<Topic__c>();
            pillars = new List<Pillar__c>();
        }
    }
    
    @AuraEnabled
    public static DashboardInfo getDashboardInfo(String username) {
        DashboardInfo info = new DashboardInfo();
        
        List<User> users;
        
        if (String.isNotBlank(username)) users = [SELECT UserRoleId, UserRole.Name FROM User WHERE Username = :username];
        
        if (users != null && !users.isEmpty()) {
            info.roleID = users[0].UserRoleId;
            info.type = users[0].UserRole.Name.contains('GSD') ? 'users' : 'roles';
        } else {
            User u = [SELECT UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
            
            info.roleID = UserInfo.getUserRoleId();
            info.type = u.UserRole.Name.contains('GSD') ? 'users' : 'roles';
        }
        
        info.topics = [SELECT Pillar_Name__c, Topic_ID__c, Name, Max_Score__c FROM Topic__c ORDER BY Topic_ID__c ASC];
        
        info.pillars = [SELECT Pillar_ID__c, Name FROM Pillar__c WHERE Name IN ('Digital', 'Marketing', 'Sales', 'Product') ORDER BY Pillar_ID__c ASC];
        
        return info;
    }
    
    public static String currentOrSpecifiedUserRole(Id userRoleID) {
        return String.isNotBlank(userRoleID) ? userRoleID : USerInfo.getUserRoleId();
    }
    
    // True is we need to display User names, or False if we need to display Role names.
    // If the current logged in user has GSD in their role name then we need to show all users below them, or else we show roles.
    @AuraEnabled
    public static Boolean getUsersOrRoles(Id userRoleID) {
        UserRole role = [SELECT Name FROM UserRole WHERE Id = :currentOrSpecifiedUserRole(userRoleID)];
        
        return role.Name.contains('GSD');
    }
    
    /*@AuraEnabled
    public static List<TopicScore> getTopicScores(String pillarName) {
        return getTopicScores(pillarName, UserInfo.getUserRoleId());
    }*/
    
    class Percs {
        public Decimal score = 0;
        public Integer count = 0;
        public Decimal percent = 0;
        public Decimal max = 0;
    }
    
	@AuraEnabled
    public static List<TopicScore> getTopicScores(String pillarName, Integer topicCount, String userRoleID) {
        String userRole = currentOrSpecifiedUserRole(userRoleID);
        
        //System.debug('Topic scores for ' + userRoleID + ' (' + pillarName + ')');
        
        Map<String, TopicScore> scoreMap = new Map<String, TopicScore>();
        
        Boolean isGSD = getUsersOrRoles(userRole);
        
        if (isGSD) {
            Map<Id, User> userMap = AT_AccessUtil.getUsers(userRole);
            
            for (Topic_Data__c td: [SELECT User__c, User__r.Name, Score__c, Score_Percent__c, Max_Score__c, Topic_ID__r.Topic_ID__c, Topic_Name__c, Completion_Status__c, Pillar_ID__r.Max_Score__c FROM Topic_Data__c WHERE (Pillar_Name__c = :pillarName) AND (User__c IN :userMap.values()) ORDER BY User__r.Name, Topic_ID__r.Topic_ID__c ASC]) {
                TopicScore score = scoreMap.get(td.User__r.Name);
                
                if (score == null) {
                    score = new TopicScore(td.User__c, td.User__r.Name, td.Score__c, td.Pillar_ID__r.Max_Score__c);
                } else {
                    score.score += td.Score__c;
                    //score.pillarMax += td.Max_Score__c;
                }
                
                String topicID = String.valueOf(td.Topic_ID__r.Topic_ID__c);
                
                score.topicMap.put(topicID, new Topic(topicID, td.Topic_Name__c, td.Completion_Status__c));
                
                scoreMap.put(td.User__r.Name, score);
        	}
        } else {
            List<AT_AccessUtil.RoleInfo> roles = AT_AccessUtil.getSubordinateRoleNamesAndIDs(userRole);
            
            Set<Id> allRoleIDs = new Set<Id>();
            
            Map<Id, Id> parentRoleMap = new Map<Id, Id>();
            Map<Id, String> roleNameMap = new Map<Id, String>();
            Map<Id, Set<Id>> roleUserSetMap = new Map<Id, Set<Id>>();
            
            Map<String, Percs> debugs = new Map<String, Percs>();
            
            for (AT_AccessUtil.RoleInfo role: roles) {
                roleNameMap.put(role.id, role.name);
                
                allRoleIDs.addAll(role.roleIDs);
                
                for (Id roleID: role.roleIDs) parentRoleMap.put(roleID, role.id);
                
                roleUserSetMap.put(role.id, new Set<Id>());
            }
            
            //System.debug('Pillar Name: ' + pillarName);
            //System.debug('Role Map: ' + parentRoleMap);
            
            //for (AT_AccessUtil.RoleInfo role: roles) {
                //Set<Id> userIDs = new Set<Id>();
                
                //TopicScore score;
                
                for (Topic_Data__c td: [SELECT User__c, User__r.Name, User__r.UserRoleId, User__r.UserRole.Name, Score__c, Score_Percent__c, Max_Score__c, Topic_ID__r.Topic_ID__c, Topic_Name__c, Completion_Status__c, Pillar_ID__r.Max_Score__c FROM Topic_Data__c WHERE (Pillar_Name__c = :pillarName) AND (User__r.UserRoleId IN :allRoleIDs) ORDER BY User__r.UserRole.Name, Topic_ID__r.Topic_ID__c ASC]) {
                    Id      parentRoleID   = parentRoleMap.get(td.User__r.UserRoleId);
                    String  parentRoleName = roleNameMap.get(parentRoleID);
                    Set<Id> userIDs        = roleUserSetMap.get(parentRoleID);
                    
                    userIDs.add(td.User__c);
                    
                    TopicScore score = scoreMap.get(parentRoleID);
                    
                    /*if (pillarName == 'Digital' && (parentRoleName == 'IMA GSD NSW 3')) {
                        System.debug(td.User__r.Name + ' -> ' + td.Topic_Name__c + ': ' + td.Score_Percent__c + '(' + td.Score__c + ' / ' + td.Pillar_ID__r.Max_Score__c + '|' + td.Max_Score__c + ')');
                        
                        Percs perc = debugs.get(td.User__r.Name);
                        
                        if (perc == null) perc = new Percs();
                        
                        perc.percent += td.Score_Percent__c;
                        perc.score += td.Score__c;
                        perc.max += td.Max_Score__c;
                        perc.count++;
                        
                        debugs.put(td.User__r.Name, perc);
                    }*/
                    
                    if (score == null) {
                        score = new TopicScore(parentRoleID, parentRoleName, td.Score__c, td.Pillar_ID__r.Max_Score__c);
                    } else {
                        score.score += td.Score__c;
                        //score.pillarMax += td.Max_Score__c;
                    }
                    
                    String topicID = String.valueOf(td.Topic_ID__r.Topic_ID__c);
                    
                    Topic topic = score.topicMap.get(topicID);
                    
                    if (topic == null) {
                    	topic = new Topic(topicID, td.Topic_Name__c, td.Completion_Status__c);
                    } else {
                        //topic.score += td.Score_Percent__c;
                        
                        if (td.Completion_Status__c == 'pass') topic.status = 'pass';
                    }
                    
                    score.topicMap.put(topicID, topic);
                    
                    scoreMap.put(parentRoleID, score);
                    
                    /*Boolean exists = false;
                    
                    for (Topic t: score.topics) {
                        if (t.id == td.Topic_ID__r.Topic_ID__c) {
                            if (td.Completion_Status__c != 'pass') t.status = td.Completion_Status__c;
                            exists = true;
                            break;
                        }
                    }
                    
                    if (!exists) score.topics.add(new Topic(td.Topic_ID__r.Topic_ID__c, td.Topic_Name__c, td.Completion_Status__c));                    
                    
                    scoreMap.put(parentRoleID, score);*/
                }
                
                /*if (score != null) {
                    score.userCount = userIDs.size();
                	scoreMap.put(role.name, score);
                }*/
            //}
            
             /*for (String u: debugs.keySet()) {
                 Percs perc = debugs.get(u);
                System.debug(u + ': ' + (perc.score / perc.max) + ' [' + (perc.percent / perc.count) + ']');
             }*/
            
            for (TopicScore score: scoreMap.values()) {
                Set<Id> userIDs = roleUserSetMap.get(score.id);
                
                score.userCount = userIDs.size();
            }
        }
  
        for (Integer i = 0; i < 10; i++) System.debug('');
        
        List<TopicScore> scores = scoreMap.values();
        
        Integer topicNumber = Integer.valueOf(topicCount);
        
        for (TopicScore score: scores) {
            if (score.score == null) score.score = 0;
            
            if (isGSD) {
            	score.score = (score.score / score.pillarMax) * 100.0; // / score.userCount;
            } else {                
                score.score = (score.score / (score.pillarMax * score.userCount)) * 100.0; // / ;
            }
            
            score.topics = score.topicMap.values();
        }
        
        scores.sort();
        
        //System.debug(debugs.keySet());
        
       
        
        /*for (TopicScore score: scores) {
            Decimal total = 0;
            
            for (Topic p: score.topics) total += p.score;
            
            //if (score.score == null) score.percent = 0;
            
            if (isGSD) {
                score.percent = (total / 4.0);
            } else {
                score.percent = (total / 4.0); // / score.userCount;
            }
        }*/
        
        return scores;
    }
    
    @AuraEnabled
    public static List<PillarScore> getPillarScores() {
		return getPillarScores(UserInfo.getUserRoleId());
    }
    
    @AuraEnabled
    public static List<String> getUserIDs(String userRoleID) {
        String userRole = currentOrSpecifiedUserRole(userRoleID);
        
        List<String> userIDs = new List<String>();
        
        if (getUsersOrRoles(userRole)) {
            for (User u: AT_AccessUtil.getUsers(userRoleID).values()) userIDs.add(u.Name);
        } else {
            List<AT_AccessUtil.RoleInfo> roles = AT_AccessUtil.getSubordinateRoleNamesAndIDs(userRoleID);
        }
        
        return userIDs;
    }
    
    @AuraEnabled
    public static List<PillarScore> getPillarScores(String userRoleID) {
        String userRole = currentOrSpecifiedUserRole(userRoleID);
        
		Map<String, PillarScore> scoreMap = new Map<String, PillarScore>();
        
        Boolean isGSD = getUsersOrRoles(userRole);
        
        if (isGSD) {
            Map<Id, User> userMap = AT_AccessUtil.getUsers(userRole);
            
            for (Pillar_Data__c pd: [SELECT User__c, User__r.Name, Score__c, Score_Percent__c, Pillar_ID__r.Pillar_ID__c, Pillar_Name__c, Completion_Status__c, Pillar_ID__r.Max_Score__c FROM Pillar_Data__c WHERE (User__c IN :userMap.values()) ORDER BY User__r.Name ASC, Pillar_ID__r.Pillar_ID__c ASC]) {
                PillarScore score = scoreMap.get(pd.User__r.Name);
                
                if (score == null) {
                    score = new PillarScore(pd.User__c, pd.User__r.Name, pd.Score__c, pd.Score_Percent__c, pd.Pillar_ID__r.Max_Score__c); //, pd.Score__c
                } else {
                    score.score += pd.Score_Percent__c;
                }
                
                score.pillars.add(new Pillar(String.valueOf(pd.Pillar_ID__r.Pillar_ID__c), pd.Pillar_Name__c, pd.Score_Percent__c, pd.Completion_Status__c));
                
                scoreMap.put(pd.User__r.Name, score);
            }
        } else {
            List<AT_AccessUtil.RoleInfo> roles = AT_AccessUtil.getSubordinateRoleNamesAndIDs(userRole);
            
            Set<Id> allRoleIDs = new Set<Id>();
            
            Map<Id, Id> parentRoleMap = new Map<Id, Id>();
            Map<Id, String> roleNameMap = new Map<Id, String>();
            Map<Id, Set<Id>> roleUserSetMap = new Map<Id, Set<Id>>();
            
            for (AT_AccessUtil.RoleInfo role: roles) {
                roleNameMap.put(role.id, role.name);
                
                allRoleIDs.addAll(role.roleIDs);
                
                for (Id roleID: role.roleIDs) parentRoleMap.put(roleID, role.id);
                
                roleUserSetMap.put(role.id, new Set<Id>());
            }
            
            //System.debug('All role IDs: '  + allRoleIDs);
                //System.debug(role.name + ' (' + role.id + ')');
                //System.debug('Subroles: ' + role.roleIDs);
            
            //for (Id roleID: allRoleIDs) {
                //Set<Id> userIDs = new Set<Id>();
                
                //PillarScore score;
                
                //-List<User> users = [SELECT Id, Name, Username FROM User WHERE (UserRoleId IN :role.roleIDs)];

				//System.debug('Role: ' + role);
                
                //System.debug('GM Users:');
                //System.debug(users);
                
                for (Pillar_Data__c pd: [SELECT User__c, User__r.UserRoleId, User__r.UserRole.Name, Score__c, Score_Percent__c, Pillar_ID__r.Pillar_ID__c, Pillar_Name__c, Completion_Status__c, Max_Score__c, Pillar_ID__r.Max_Score__c FROM Pillar_Data__c WHERE (User__r.UserRoleId IN :allRoleIDs) ORDER BY User__r.UserRole.Name ASC, Pillar_ID__r.Pillar_ID__c ASC]) {
                    Id      parentRoleID   = parentRoleMap.get(pd.User__r.UserRoleId);
                    String  parentRoleName = roleNameMap.get(parentRoleID);
                    Set<Id> userIDs        = roleUserSetMap.get(parentRoleID);
                    
                    userIDs.add(pd.User__c);
                    
                    PillarScore score = scoreMap.get(parentRoleID); //
                    
                    /*if (parentRoleName == 'IMA GSD NSW 3') {
                        System.debug('Parent: ' + parentRoleName);
                        System.debug(score);
                    }*/
                    
                    if (score == null) {
                        score = new PillarScore(parentRoleID, parentRoleName, pd.Score__c, pd.Score_Percent__c, pd.Max_Score__c /*pd.Pillar_ID__r.Max_Score__c*/); //, pd.Score__c
                    } else {
                        score.score += pd.Score__c;
                    }
                    
                    String pillarID = String.valueOf(pd.Pillar_ID__r.Pillar_ID__c);
                    
                    Pillar pillar = score.pillarMap.get(pillarID);
                    
                    if (pillar == null) {
                    	pillar = new Pillar(pillarID, pd.Pillar_Name__c, pd.Score_Percent__c, pd.Completion_Status__c);
                    } else {
                        pillar.score += pd.Score_Percent__c;
                    }
                    
                    score.pillarMap.put(pillarID, pillar);
                    
                    scoreMap.put(parentRoleID, score); //pd.User__r.UserRole.Name
                }
                
            for (String roleID: scoreMap.keySet()) {
                PillarScore score = scoreMap.get(roleID);
                
                Integer userCount = roleUserSetMap.get(roleID).size();
                
                score.userCount = userCount;
                
                score.pillars = score.pillarMap.values();
                
                for (Pillar p: score.pillars) p.score = p.score / userCount;
            }
                //if (score != null) {
                //	score.userCount = userIDs.size();
                	//score.userCount = users.size();
                //	scoreMap.put(role.name, score);
                //}
            //}
        }
        
        List<PillarScore> scores = scoreMap.values();
        
        for (PillarScore score: scores) {
            Decimal total = 0;
            
            for (Pillar p: score.pillars) total += p.score;
            
            //if (score.score == null) score.percent = 0;
            
            if (isGSD) {
                score.percent = (total / 4.0);
            } else {
                score.percent = (total / 4.0); // / score.userCount;
            }
        }
        
        return scores;
    }
    
    class FinancialInfo {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public Decimal combinedTarget {get; set;}
        @AuraEnabled
        public Decimal combinedRevenue {get; set;}
        @AuraEnabled
        public Decimal digitalTarget {get; set;}
        @AuraEnabled
        public Decimal digitalRevenue {get; set;}
        
        public FinancialInfo() {
            this.combinedTarget = 0;
            this.combinedRevenue = 0;
            this.digitalTarget = 0;
            this.digitalRevenue = 0;
        }
    }
    
    @AuraEnabled
    public static List<FinancialInfo> getFinancials(List<String> userIDs, List<String> roleIDs) {
        List<FinancialInfo> financials = new List<FinancialInfo>();
        
        Set<Id> blank = new Set<Id>();
        
        if ((userIDs != null) && !userIDs.isEmpty()) {
            System.debug('User IDs: ' + userIDs);
            
            for (String id: userIDs){
                FinancialInfo info = new FinancialInfo();
                
                info.id = id;
                
                SalesTargetController.SalesTargetResponse targets = SalesTargetController.getRevenueForecast(id, blank, -3);
                
                for (SalesTargetController.SalesTarget target: targets.targets) {
                    if (target != null) {
                        info.combinedTarget += target.combined;
                        info.digitalTarget += target.digital;
                    }
                }
                
                List<Id> periodIDs = SalesTargetController.getMonthPeriods(-3);
                
                List<AT_SalesPerformance.Sales> sales = AT_SalesPerformance.getSalesActualsForPeriods(periodIDs, id, blank);
                
                System.debug('Sales: ' + sales);
                
                for (AT_SalesPerformance.Sales actuals: sales) {
                    System.debug('Actuals: ' + actuals);
                    
                    if (actuals != null) {
                        info.combinedRevenue += actuals.combined;
                        info.digitalRevenue += actuals.digital;
                    }
                }
                
                info.combinedTarget  = info.combinedTarget / 3;
                info.digitalTarget   = info.digitalTarget / 3;
                info.combinedRevenue = info.combinedRevenue / 3;
                info.digitalRevenue  = info.digitalRevenue / 3;
                
                financials.add(info);
            }
        } else if (roleIDs != null) {
            for (String id: roleIDs){
                Set<Id> subordinates = AT_AccessUtil.getRoleAndSubordinates(id);
                
                FinancialInfo info = new FinancialInfo();
                
                info.id = id;
                
                SalesTargetController.SalesTargetResponse targets = SalesTargetController.getRevenueForecast(null, subordinates, -3);
                
                System.debug('Targets: ' + targets);
                
                for (SalesTargetController.SalesTarget target: targets.targets) {
                    if (target != null) {
                        info.combinedTarget += target.combined;
                        info.digitalTarget += target.digital;
                    }
                }
                
                List<Id> periodIDs = SalesTargetController.getMonthPeriods(-3);
                
                List<AT_SalesPerformance.Sales> sales = AT_SalesPerformance.getSalesActualsForPeriods(periodIDs, null, subordinates);
                
                System.debug('Sales: ' + sales);
                
                for (AT_SalesPerformance.Sales actuals: sales) {
                    if (actuals != null) {
                        info.combinedRevenue += actuals.combined;
                        info.digitalRevenue += actuals.digital;
                    }
                }
                
                info.combinedTarget  = info.combinedTarget / 3;
                info.digitalTarget   = info.digitalTarget / 3;
                info.combinedRevenue = info.combinedRevenue / 3;
                info.digitalRevenue  = info.digitalRevenue / 3;
                
                financials.add(info);
            }
        }
        
        return financials;
    }
}