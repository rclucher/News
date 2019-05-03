global with sharing class CS_IssuePickerPluginImplementation implements csmso.SalesOrderAPI.IssuePickerPlugin {
    
    global String getIssuesJSON(String productNodeCode) {
        
        // this will be filled in with the NAAs to list in the Issue Picker
        String jsonNAAs = '';

        if (!String.isEmpty(productNodeCode)) {
            // get Parent_Node_List__c from selected Product Node object
            csmso__Product_Node__c productNode = [SELECT csmso__Parent_Node_List__c 
                                                  FROM csmso__Product_Node__c 
                                                  WHERE csmso__Code__c  = :productNodeCode];

            // build the query string. Include product parent nodes in query, if any
            String query =  'SELECT Id, Name FROM csmso__Node_Advert_Assignment__c ' +
                            'WHERE csmso__Title_Product_Node__r.csmso__Code__c  = :productNodeCode ';

            if (!String.isEmpty(productNode.csmso__Parent_Node_List__c)) {
                List<String> PNIDs = productNode.csmso__Parent_Node_List__c.split(',');
                
                query += 'OR csmso__Title_Product_Node__c IN :PNIDs ';
            }

            query += 'ORDER BY Name ASC';

            // query NAA IDs and put them into json
            List<csmso__Node_Advert_Assignment__c> NAAs = Database.query(query);

            if (NAAs != null) {
                List<String> NAAsJsonList = new List<String>();
                
                for (csmso__Node_Advert_Assignment__c NAA : NAAs) {
                    NAAsJsonList.add('{"Id": "' + NAA.Id + '", "label": "' + NAA.Name + '"}');
                }
                
                jsonNAAs = String.join(NAAsJsonList, ',');
            }
        }

        // make sure you update the test class if the return values change!
        return '{"colDefinition": [{"label": "Ad Size", "key": "label", "width": "160px"}],' +
               '"listItems": [' + jsonNAAs + '],' +
               '"attributeMap": {"Id": "Node_Advert_Assignments_0"}}';
    }
}