public class AccountPortfolioManagement {
    public static void addPortfoliosToAccounts(Map<Id, Id> accountPortfolioMap) {
        Id unassigned, vacant;
        
        for (User u: [SELECT Id, FirstName, LastName FROM User WHERE (LastName = 'NextG') AND (FirstName IN ('Unassigned', 'Vacant'))]) {
            if (u.FirstName == 'Unassigned') unassigned = u.Id;
            if (u.FirstName == 'Vacant')     vacant = u.Id;
        }
        
        Map<Id, List<Id>> portfolioOwners = new Map<Id, List<Id>>();
        
        for (Id pId: accountPortfolioMap.values()) {
            portfolioOwners.put(pId, null);
        }
        
        for (Portfolio_Owners__c po: [SELECT Portfolio2__c, Portfolio_Owner__c FROM Portfolio_Owners__c WHERE Portfolio2__c IN :accountPortfolioMap.values()]) {
            List<Id> owners = portfolioOwners.get(po.Portfolio2__c);
            
            if (owners == null) owners = new List<Id>();
            
            owners.add(po.Portfolio_Owner__c);
            
            portfolioOwners.put(po.Portfolio2__c, owners);
        }
        
        List<Account> accounts = [SELECT Id, Type, OwnerId FROM Account WHERE (Id IN :accountPortfolioMap.keySet()) AND (Type NOT IN ('Multi Managed', 'Locally Activated')) FOR UPDATE];
        
        for (Account acc: accounts) {
            Id portfolioID = accountPortfolioMap.get(acc.Id);
            
            if (portfolioID != null) {
            	List<Id> owners = portfolioOwners.get(portfolioID);
                
                if ((owners == null) || owners.isEmpty()) {
                    acc.Type = 'Account Managed';
                    acc.OwnerId = vacant;
                } else if (owners.size() == 1) {
                    if (owners[0] == unassigned) {
                        acc.Type = 'Non Account Managed';
                    } else {
                        acc.Type = 'Account Managed';
                    }
                    
                    acc.OwnerId = owners[0];
                } else {
                    acc.Type = 'Account Managed';
                }
			}
        }
        
        update accounts;
    }
    
    public static void removePortfoliosFromAccounts(Map<Id, Id> accountPortfolioMap) {
        Id unassigned, vacant;
        
        for (User u: [SELECT Id, FirstName, LastName FROM User WHERE (LastName = 'NextG') AND (FirstName IN ('Unassigned', 'Vacant'))]) {
            if (u.FirstName == 'Unassigned') unassigned = u.Id;
            if (u.FirstName == 'Vacant')     vacant = u.Id;
        }
        
        List<Account> accounts = [SELECT Id, Type, OwnerId FROM Account WHERE (Id IN :accountPortfolioMap.keySet()) AND (Type NOT IN ('Multi Managed', 'Locally Activated')) FOR UPDATE];
        
        for (Account acc: accounts) {
            acc.Type = 'Non Account Managed';
            acc.OwnerId = unassigned;
        }
        
        update accounts;
    }
}