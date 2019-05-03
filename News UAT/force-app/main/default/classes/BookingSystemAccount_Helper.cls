/*
 * @Author: Paul Kang
 * @Description: Booking System Account (External_Account__c) assign the worst Credit Status back the Account.Billing_Status__c
 * sequence of Credit_Status__c colours is:
 * 1. Green
 * 2. Amber
 * 3. Orange
 * 4. Red
 * Where Red is the worst followed by Orange and so forth 
 * History 
 * 2017-12-20: Paul Kang updated 
 * 2018-02-08: Paul Kang fixed an issue when creating a new External_Account__c record from UI related to Credit_Status__c null
 * 2018-09-20: Mohsin Ali - Adding another condition to exclude Contra condition in Query: AND (Account_Type__c != 'Contra'). Refer to Jira: NR-1398
*/ 
public without sharing class BookingSystemAccount_Helper {

    public static void resetNetDA(Map<Id, External_Account__c> externalAccounts, Map<Id, External_Account__c> oldMap) {
        for (External_Account__c extAccount : externalAccounts.values()) {
            if (extAccount.BSA__c != oldMap.get(extAccount.Id).BSA__c && extAccount.BSA_Net_DA__c == oldMap.get(extAccount.Id).BSA_Net_DA__c) {
                //clear netDA
                extAccount.BSA_Net_DA__c = null;
            }
        }
    }


    // Called from BookingSystemAccount.trigger
    public static void assignCreditStatus(List<External_Account__c> bookingSystemAcct) {

        Set<Id> parentAcctIds = new Set<Id>();
        for(External_Account__c ea : bookingSystemAcct)
        {
            if(ea.Customer_Account__c != null)
            parentAcctIds.add(ea.Customer_Account__c);
        }
        System.debug('parentAcctIds:' + parentAcctIds);
        
        //Map<External_Account__c, Integer> extAccMaxCreditStatus = new Map<External_Account__c, Integer>();

        Map<Id, Integer> accountCreditStatus = new Map<Id,Integer>();

        Map<String, Integer> creditStatusMap = new Map<String,Integer>{'green'=>1,'amber'=>2,'orange'=>3,'red'=>4};

        Map<Integer, String> creditStatusInvMap = new Map<Integer,String>{1=>'green',2=>'amber',3=>'orange',4=>'red'};

            // Only compare the credit statuses where External_Account__c 
            // Active, RecordType = Booking Account, has no parent account and is not of type Agency

            for(External_Account__c ea : [SELECT Customer_Account__c, Credit_Status__c 
                                                            FROM External_Account__c
                                                                WHERE Customer_Account__c in :parentAcctIds
                                                                AND RecordTypeName__c = 'Booking Account' 
                                                                AND Status__c = 'Active'
                                                                AND Parent_Account_Number__c = null 
                                                                AND (not Account_Type__c like '%Agency%')
                                         						AND (Account_Type__c != 'Contra')])
            {
                System.debug('ea:' + ea);

                if (ea.Credit_Status__c != null) {
                    
                    if(creditStatusMap.containsKey(ea.Credit_Status__c.toLowerCase()))
                    {
                        Integer crvalue = creditStatusMap.get(ea.Credit_Status__c.toLowerCase());

                        if(!accountCreditStatus.containsKey(ea.Customer_Account__c))
                        { 
                             accountCreditStatus.put(ea.Customer_Account__c, crvalue);   
                        }
                        else if(accountCreditStatus.get(ea.Customer_Account__c) < crvalue)
                        {
                            accountCreditStatus.put(ea.Customer_Account__c, crvalue);
                        }
                    }
                }
                System.debug('ea.Customer_Account__c:' + ea.Customer_Account__c);
                System.debug('ea.Credit_Status__c:' + ea.Credit_Status__c);

            }        

            System.debug('accountCreditStatus:' + accountCreditStatus);

            List<Account> accts = new List<Account>();
            for(id key : accountCreditStatus.keySet())
            {
                accts.add(new Account(id=key, Billing_Status__c=creditStatusInvMap.get(accountCreditStatus.get(key))));
            }

            
            System.debug('accts:' + accts);

            update accts;

    }

}