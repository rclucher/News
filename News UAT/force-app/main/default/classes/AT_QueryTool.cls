public class AT_QueryTool {
	private static final Pattern rolePattern = Pattern.compile('\\$roles\\{(.+)\\}');

    public class QueryResult {
        @AuraEnabled
        public List<String> columns;
        
        @AuraEnabled
        public List<SObject> data;
    }
    
	@AuraEnabled
    public static QueryResult query(String soql) {
        String queryString = soql;
        
        QueryResult result = new QueryResult();
        
        Matcher roleMatcher = rolePattern.matcher(queryString);
        
        if (roleMatcher.find() && (roleMatcher.groupCount() > 0)) {
        	queryString = roleMatcher.replaceFirst(':roleIDs');
        }
        
        result.data = Database.query(queryString);
        
        if (!result.data.isEmpty()) {
            Map<String, Object> fieldMap = result.data[0].getPopulatedFieldsAsMap();
            
            result.columns = new List<String>(fieldMap.keySet());
        }
        
        return result;
    }
}