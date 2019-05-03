/**
 * Created by petar.mikic on 26/09/2017.
 */

global class CS_UpgradeBasketSessionBatch implements Database.Batchable<sObject>{

    // prepare eligible Product Baskets with an SO and a missing User Session
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(' SELECT Id, ' +
                                        '        csmso__Sales_Order__c, ' +
                                        '        csmso__Sales_Order__r.Name, ' +
                                        '        LastModifiedDate ' +
                                        ' FROM cscfga__Product_Basket__c ' +
                                        ' WHERE csmso__Sales_Order__c != null ' +
                                        ' AND cscfga__User_Session__c = null ' );
    }
    /*
    * For each basket found, create a user session record and insert the lot
    * Update all the baskets with the related user session
     */
    global void execute(Database.BatchableContext BC, List<cscfga__Product_Basket__c> scope)
    {

        if ( !scope.isEmpty() ) {

            System.debug('* * Updating ' + scope.size() + ' product baskets');

            String namePrefix = 'Session for Sales Order \'';
            String namePostfix = '\'';

            List<cscfga__User_Session__c> newUserSessions = new List<cscfga__User_Session__c>();
            cscfga__User_Session__c user_session = null;
            String                  usName       = null;

            for (cscfga__Product_Basket__c productBasket: scope) {

                user_session = new cscfga__User_Session__c();
                usname       = namePrefix + productBasket.csmso__Sales_Order__r.Name + namePostfix;

                user_session.Name                           = usName;
                user_session.cscfga__Last_Accessed_Date__c  = productBasket.LastModifiedDate;
                user_session.cscfga__PC_Return_URL__c       = '/';
                user_session.cscfga__Session_Id__c          = productBasket.csmso__Sales_Order__c;

                newUserSessions.add(user_session);
                System.debug('* * Adding ' + usName);
            }

            insert newUserSessions;

            //gather user sesssion Ids to update lookup on basket
            Map<String,String> soToUserSessionMap = new Map<String, String>();

            for (cscfga__User_Session__c userSession: newUserSessions) {
                soToUserSessionMap.put(userSession.cscfga__Session_Id__c, userSession.Id);
            }

            //populate the session lookup on the baskets
            for (cscfga__Product_Basket__c product_basket: scope) {
                product_basket.cscfga__User_Session__c = soToUserSessionMap.get(product_basket.csmso__Sales_Order__c);
            }

            update scope;
        }
    }

    global void finish(Database.BatchableContext BC)
    {

    }

}