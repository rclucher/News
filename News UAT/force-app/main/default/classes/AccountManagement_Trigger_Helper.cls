/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is helper class for trigger AccountManagement
 * History:
 * 20/12/2013  Bohao Chen  Created
 * 21/08/2018  Pratyush Chalasani (Ativa) - Updated to include Segment+Spend mapping to customer Tier
 * 30/10/2018  Pratyush Chalasani (Ativa) - Updated to prevent owner chang
 * Making Print as Case Insensitive. Changing tier.Platform__c == 'Print' to tier.Platform__c.equalsIgnoreCase('Print'): Refer to Jira: NR-1201.
 */
public class AccountManagement_Trigger_Helper
{

    // AdSales-121 2016-08-04 darshan.gosar@bluewolfgroup.com
        // Added new bypass flag to bypass account trigger execute while updating person account in after trigger
    public static boolean byPassAccountTrigger = false;
    
    // this function takes list of account owner ids in order to retrieve mapping 
    // between salesforce owner and adpoint user id
    public static Map<Id, String> findAdPointUserIdByAccountOwner(Set<Id> ownerIds)
    {
        system.debug('@AccountManagement_Trigger_Helper ownerIds: ' + ownerIds);
        
        
        Map<Id, String> adPointUserIdByOwnerId = new Map<Id, String>();
        
        for(CyberAd_User_Credential__c cred : [Select c.User__c, c.AdPoint_User_Id__c 
                                                From CyberAd_User_Credential__c c 
                                                Where c.User__c IN: ownerIds
                                                And c.RecordType.DeveloperName = 'AdPoint'])
        {
            adPointUserIdByOwnerId.put(cred.User__c, cred.AdPoint_User_Id__c);
        }
        
        system.debug('@AccountManagement_Trigger_Test findAdPointUserIdByAccountOwner: ' + adPointUserIdByOwnerId);
        
        return adPointUserIdByOwnerId;
    }
    
    // AdSales-121 2016-08-04 darshan.gosar@bluewolfgroup.com
        // Added new method to populate Person Contact Id on Primary Account field
    public static void updatePersonAccountPrimaryContact(List<Account> newTriggerList){
        List<Account> updateAccountList = new List<Account>();
         
        for(Account a : newTriggerList){
            if(a.IsPersonAccount != null && a.IsPersonAccount && a.Primary_Contact__c == null){
                Account tempAccount = a.clone(true,true,true);
                tempAccount.Primary_Contact__c = tempAccount.PersonContactId;
                updateAccountList.add(tempAccount);
            }   
        }
        
        if(updateAccountList.size() > 0){
            byPassAccountTrigger = true;            
            update updateAccountList;
            byPassAccountTrigger = false;
        }       
    }
    
    //NR-1679: When a portfolio is attached to a account record the account owner should be locked
    public static void preventOwnerChangeWhenPortfolioAttached(List<Account> accounts, Map<Id, Account> oldMap) {
       	Set<Account> ownerChangedAccounts = new Set<Account>();
        
        System.debug('Checking for owner change');
        
        for (Account acc: accounts) {
            Account old = oldMap.get(acc.Id);
            
            if (old != null && (acc.OwnerId != old.OwnerId)) ownerChangedAccounts.add(acc);
        }
        
        System.debug('Accounts with changed owners: ' + ownerChangedAccounts);
        
        if (!ownerChangedAccounts.isEmpty()) {
            Set<String> nextgenProfileNames = new Set<String>();
            
            for (NextGen_User_Profile__mdt prof: [SELECT Label FROM NextGen_User_Profile__mdt]) nextgenProfileNames.add(prof.Label);
            
            System.debug('NextGen profiles: ' + nextgenProfileNames);
            
            nextgenProfileNames.remove('System Administrator');
            nextgenProfileNames.remove('~System Administrator');
            nextgenProfileNames.remove('News Sales Operations');
            
            String userProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
            
            if (nextgenProfileNames.contains(userProfileName)) {
                Set<Id> accountsWithPortfolios = new Set<Id>();
                
                for (Account_Portfolio_Relationship__c rel: [SELECT Account__c FROM Account_Portfolio_Relationship__c WHERE Account__c IN :ownerChangedAccounts]) {
                    accountsWithPortfolios.add(rel.Account__c);
                }
                
                for (Booking_System_Portfolio_Junction__c rel: [SELECT Booking_System_Account__r.Customer_Account__c FROM Booking_System_Portfolio_Junction__c WHERE Booking_System_Account__r.Customer_Account__c IN :ownerChangedAccounts]) {
                    accountsWithPortfolios.add(rel.Booking_System_Account__r.Customer_Account__c);
                }
                
                for (Account acc: ownerChangedAccounts) {
                    if (accountsWithPortfolios.contains(acc.Id)) {
                    	acc.addError('Cannot change owner for an Account with an attached Opportunity. Please speak to your Ops manager.');
                    }
                }
            }
        }
    }
    
    /* NR-390: Customer Tier for Print includes Segment variation
     * 
     * Use an account's segment and rolling 12 months spend to determine it's tier
     * Making it case insensitive NR-1201
     */
    public static void setCustomerTier(List<Account> accounts) {
        Map<String, List<Spend_Tier_Mapping__c>> segmentTiers = new Map<String, List<Spend_Tier_Mapping__c>>();
        
        for (Spend_Tier_Mapping__c tier: [SELECT Segment__c, Platform__c, Min_Spend__c, Max_Spend__c, Tier__c FROM Spend_Tier_Mapping__c ORDER BY Min_Spend__c ASC, Max_Spend__c ASC]) {
            //addToMap(segmentTiers, tier.Segment__c, tier);
            addToMap(segmentTiers, tier.Segment__c.toLowerCase(), tier);
        }
        
        for (Account acc: accounts) {
            if (acc.Customer_Segment__c != null) {
                List<Spend_Tier_Mapping__c> tiers = segmentTiers.get(acc.Customer_Segment__c.toLowerCase());
                
                if (tiers != null) {
                    Decimal printSpend = acc.Rolling_12_Months_Print__c != null ? acc.Rolling_12_Months_Print__c : 0 ;
                    
                    for (Spend_Tier_Mapping__c tier: tiers) {
                        if (tier.Platform__c.equalsIgnoreCase('Print') && (printSpend >= tier.Min_Spend__c) && (printSpend <= tier.Max_Spend__c)) {
                            acc.Print_Customer_Tier__c = tier.Tier__c;
                        }
                    }
                }
            }
        }
    }
    
   private static void addToMap(Map<String, List<Spend_Tier_Mapping__c>> mapList, String key, Spend_Tier_Mapping__c value) {
        List<Spend_Tier_Mapping__c> values = mapList.get(key);
        
        if (values == null) values = new List<Spend_Tier_Mapping__c>();
        
        values.add(value);
        
        mapList.put(key, values);
    }
}