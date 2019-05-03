/** 
 *
 * @author      Paul Kang 
 * @description Portfolio Picker for Opportunity Page 
 * @description Modified 2018-01-29 Paul Kang changed the Portfolio2__c fields to text to minimise lookups
 *              
 **/

public with sharing class OpportunityPortfolioPicker_Controller {

    public static Set<Id> idsOfPortfolio {get; set;}


    // 1. Load Portfolios from BSA Junction
    private static void populateBSAs(Set<Id> bsaIDs) {

        for(Booking_System_Portfolio_Junction__c portFolioId: [Select Portfolio__r.Portfolio_Code__c from Booking_System_Portfolio_Junction__c where Booking_System_Account__c IN :bsaIDs]) {

            idsOfPortfolio.add(portfolioId.Portfolio__r.Id);
        }
        System.debug('@idsOfPortfolio BSA Junction: ' + idsOfPortfolio);

    }


    // 2. Populate from Account Junction to Portfolio
    private static void populateAccounts(Id asscAcctId) {
        for(Account_Portfolio_Relationship__c actPortId: [Select Portfolio__r.Portfolio_Code__c from Account_Portfolio_Relationship__c 
                                                            where Account__c =:asscAcctId]) {
            idsOfPortfolio.add(actPortId.Portfolio__r.Id);
        }
        System.debug('@idsOfPortfolio Account Junction: ' + idsOfPortfolio);
    }

    /*
    * 1. Portfolios assigned to the booking account which has a relationship to the Salesforce account
    * 2. Portfolios assigned to the Salesforce Account
    * 3. Portfolios assigned to the owner of the opportunity
    */
    @AuraEnabled
    public static List<SelectItems> getPortfolios(String opportunityId) {
        
        idsOfPortfolio = new Set<Id>();
        List<SelectItems> portfolios = new List<SelectItems> ();
    

        // get opportunity owner id
        Id opptyOwnerId = [Select OwnerId From Opportunity Where Id =: opportunityId Limit 1].OwnerId;

        // Load the Booking System Account - Portfolio Junction object
        // based on Opportunity
        Id asscAcctId = [Select Account.Id from Opportunity where Id=: opportunityId Limit 1].Account.Id;

        System.debug('@opportunitys AccountId: ' + asscAcctId);

        if (asscAcctId != null) {
                // Check to see if the Account has associated Booking System Accounts
            Set<Id> bsaIDs = new Set<Id>();


            Map<Id,External_Account__c> bsaMap = new Map<Id,External_Account__c>([select Id from External_Account__c where Customer_Account__c =: asscAcctId]);

            System.debug('@bsaMap ' + bsaMap);
            bsaIDs = bsaMap.keySet();
            System.debug('@bsaIDs ' + bsaIDs);
    
            // 1. populate BSAs
            populateBSAs(bsaIDs);

            // 2. populate Accounts
            populateAccounts(asscAcctId);

            // 3. Populate from the owner's portfolio
            if (idsOfPortfolio.size() == 0) {
                idsOfPortfolio = getPortfoliosByOwner(opptyOwnerId);
            }

            // Load the Portfolio Junction to the Portfolio list
            List<Portfolio2__c> portfolioList = [select Portfolio_Code__c, Name From Portfolio2__c where Id IN:idsOfPortfolio order by Name];
            for (Portfolio2__c pt : portfolioList) {
                portfolios.add(new SelectItems(pt.Portfolio_Code__c, pt.Name));
            }


            System.debug('@portfolios size returned ' + portfolios.size());

            if (portfolios.size() == 0) {
                
                // Get the default Portfolio for opportunity
                PortfolioResponse resId = getOpptyPortfolio(opportunityId);

                if (resId != null) System.debug('@resId ' + resId);

                if (resId.defaultPortfolio == null) {
                    System.debug('@SetUnspecifiedPortfolio');
                    SetUnspecifiedPortfolio(opportunityId, portfolios);
                }
                else {
                    //set the default if it already exists for the opportunity 
                    Portfolio2__c pt = [select Portfolio_Code__c, Name FROM Portfolio2__c where Portfolio_Code__c= : resId.defaultPortfolio];
                    System.debug('@get defaultPortfolio ' + pt);

                    portfolios.add(new SelectItems(pt.Portfolio_Code__c, pt.Name));                 
                }
            }
            else if (portfolios.size() == 1) {
                //set the default 

                System.debug('@portfolios[0].value ' + portfolios[0].value);
                String label = (String)portfolios[0].label;
                assignPortfolioToOppty(opportunityId, portfolios[0].value);
            }                           
        }

        System.debug('@portfolios returned: ' + portfolios);
        return portfolios;
    }


    private static void SetUnspecifiedPortfolio(Id opptyId, List<SelectItems> portfolios) {
        System.debug('@setUnspecified called');
        string unspecified = 'unspecified';
        portfolios.add(new SelectItems(unspecified,unspecified));       
    }

    
    public static Set<Id> getPortfoliosByOwner(Id ownerId) {
        System.debug('@ownerId passed ' + ownerId);
        Set<Id> idSet = new Set<Id>();
        for (Portfolio_Owners__c portOwner :[select Portfolio2__c from Portfolio_Owners__c where Portfolio_Owner__c =:ownerId])
        {
            System.debug('added portfolio ' + portOwner.Portfolio2__c);
            idSet.add(portOwner.Portfolio2__c);
        }
        return idSet;
    }


    @AuraEnabled
    public static void assignPortfolioToOppty(String opportunityId, String portfolioCode) {
        Opportunity oppty = [SELECT Id, Portfolio_Code__c FROM Opportunity WHERE Id= :opportunityId FOR UPDATE];
        
        // 2018-05-25 - Pratyush Chalasani (Ativa): Added a check to make sure that a portfolio is selected
        // and that the new portfolio is not already assigned to the opportunity before updating.
        if (oppty.Portfolio_Code__c != portfolioCode) {
            oppty.Portfolio_Code__c = portfolioCode;
            update oppty;
    
            System.debug('@assigned Portfolio Code ' + portfolioCode + ' to opportunityId ' + opportunityId);
        }
    }


    @AuraEnabled
    public static String getDefaultPortfolio(String opportunityId) {
        PortfolioResponse res = getOpptyPortfolio(opportunityId);

        return JSON.serialize(res);
    }


    public static PortfolioResponse getOpptyPortfolio(String opportunityId) {
        System.debug('@OpportunityId ' + opportunityId);
        PortfolioResponse res = new PortfolioResponse();
        Opportunity oppty = [Select Portfolio_Code__c, OwnerId From Opportunity Where Id =: opportunityId Limit 1];

        System.debug('@oppty returned ' + oppty);

        if (oppty != null) {
            res.defaultPortfolio = oppty.Portfolio_Code__c;
            res.opportunityOwner = oppty.OwnerId;
        }

        System.debug('@defaultPortfolio: ' + oppty);
        System.debug('@PortfolioResponse: ' + res);
        return res;
    }


   
    public class PortfolioResponse {
        public String defaultPortfolio;
        public String opportunityOwner;
    }

}