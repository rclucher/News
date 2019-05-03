public with sharing class TempSOQLTesterController {

  public TempSOQLTesterController() {

  }

  public String theQuery {get;set;}

  public pageReference doQuery(){

      try{
          soqlResult = Database.query(theQuery);
      } catch (Exception e){
          Apexpages.addMessage(New Apexpages.Message(ApexPages.severity.ERROR,e.getMessage()));
          return null;
      }
      system.debug(soqlResult);

      if(!soqlResult.isEmpty()){
          Map<String, Object> queriedFieldValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(soqlResult[0]));
          System.debug(queriedFieldValues);   
          fields = new List<String>();
          dumpFields('', queriedFieldValues);
          system.debug(fields);
      }

      return null;
  }

  public List<String> fields {get;set;}

  public List<sObject> soqlResult {get;set;}

  public void dumpFields(String relatedField, Map<String, Object> queriedFieldValues)
  {
      for(String queriedFieldName : queriedFieldValues.keySet())
      {
          system.debug(queriedFieldName);
          // Skip this information, its not a field
          if(queriedFieldName.equals('attributes'))
              continue;
          // Check if the queried value represents a related field reference?
          Object queriedFieldValue = queriedFieldValues.get(queriedFieldName);
          if(queriedFieldValue instanceof Map<String,Object>){
              system.debug((Map<String, Object>) queriedFieldValue);
              dumpFields(relatedField+queriedFieldName + '.', (Map<String, Object>) queriedFieldValue);
          } else{
              System.debug(relatedField + queriedFieldName + ' = ' + queriedFieldValue);
              fields.add(relatedField + '' + queriedFieldName);
          }
      }
  }
}