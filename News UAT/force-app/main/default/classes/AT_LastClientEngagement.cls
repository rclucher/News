public class AT_LastClientEngagement {
    public static void updateLCE() {
        /*Extracting the list of all events that had End Date Yesterday*/
        List < Event > eventsList = new List < Event > ([select id, EndDateTime, AccountId from Event where EndDateTime >= YESTERDAY and EndDateTime < TODAY order by AccountId, EndDateTime desc]);
        if (!eventsList.isEmpty()) {
            /*Creating a Map to Retain the Account ID & The Highest Event End Date*/
            Map < ID, DateTime > acc_dt = new Map < ID, DateTime > ();
            for (Event eL: eventsList) {
                if (acc_dt.get(eL.AccountId) == null) {
                    acc_dt.put(eL.AccountId, eL.EndDateTime);
                }
            }
            /*Extracting the list of Accounts that need to be updated along with the value in Last Client Engagement Date*/
            List < Account > acc = new List < Account > ([SELECT Id, Last_Client_Engagement__c FROM Account WHERE ID IN: acc_dt.keySet() FOR UPDATE]);
            for (Account acc_to_update: acc) {
            
            /*Checking that the Last Client Engagement is < End Date on Event or Blank*/
                if (acc_to_update.Last_Client_Engagement__c < acc_dt.get(acc_to_update.Id) || acc_to_update.Last_Client_Engagement__c == null) {
                    acc_to_update.Last_Client_Engagement__c = acc_dt.get(acc_to_update.Id);
                }
            }

            /*Updating the Last Client Engagement Date*/
            update acc;

            /*System.debug('This is the Event List:'+eventsList);
            System.debug('This is the Account List:'+acc);
            System.debug('This is the Account Date Time List:'+acc_dt);*/
        }
    }
    
}