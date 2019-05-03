public without sharing class AT_AccessUtil {
    public static Set<Id> getCurrentUserRoleAndSubordinates() {
        return getRoleAndSubordinates(UserInfo.getUserRoleId());
    }
    
    public static Set<Id> getRoleAndSubordinates(Id userRoleID) {
        Set<Id> roles = new Set<Id>();
        
        Map<Id, Set<Id>> parentMap = new Map<Id, Set<Id>>();
        
        for (UserRole r: [SELECT Id, ParentRoleId FROM UserRole]) {
            Set<Id> ids = parentMap.get(r.ParentRoleId);
            
            if (ids == null) ids = new Set<Id>();
            
            ids.add(r.Id);
                
            parentMap.put(r.ParentRoleId, ids);
            
            roles.add(r.Id);
        }
        
        return findSubordinates(userRoleID, roles, parentMap);
    }

    public class RoleInfo {
        public String id;
        public String name;
        public Set<Id> roleIDs = new Set<Id>();
    }
    
    public static List<RoleInfo> getSubordinateRoleNamesAndIDs(Id userRoleID) {
        Set<Id> roles = new Set<Id>();
        
        // Map of a parent role to it's immediate children
        Map<Id, Set<Id>> parentMap = new Map<Id, Set<Id>>();
        
        Map<Id, String> roleNames = new Map<Id, String>();
        
        for (UserRole r: [SELECT Id, Name, ParentRoleId FROM UserRole]) {
            Set<Id> ids = parentMap.get(r.ParentRoleId);
            
            if (ids == null) ids = new Set<Id>();
            
            roleNames.put(r.Id, r.Name);
            
            ids.add(r.Id);
                
            parentMap.put(r.ParentRoleId, ids);
            
            roles.add(r.Id);
        }
        
		List<RoleInfo> roleInfos = new List<RoleInfo>();
        
        for (Id roleID: parentMap.get(userRoleID)) {
            RoleInfo ri = new RoleInfo();
            
            ri.id = roleID;
            
            ri.name = roleNames.get(roleID);
            
            ri.roleIDs = findSubordinates(roleID, roles, parentMap);
            
            ri.roleIDs.add(roleID);
            
            roleInfos.add(ri);
        }
        
        return roleInfos;
    }
    
    public static Set<Id> findSubordinates(Id userRoleID, Set<Id> roles, Map<Id, Set<Id>> parentMap) {
        Set<Id> subordinates = parentMap.get(userRoleID);
        
        if (subordinates == null) return new Set<Id>();
        
        for (Id rID: subordinates) {
            subordinates.addAll(findSubordinates(rID, roles, parentMap));
        }
        
        return subordinates;
    }
    
    public static Map<Id, User> getUsers(Id userRoleID) {
        Set<Id> roleIDs = AT_AccessUtil.getRoleAndSubordinates(userRoleID);
            
        return new Map<Id, User>([SELECT Id, Name FROM User WHERE UserRoleId IN :roleIDs]);
    }
}