public class AT_Knowledge {
    public class KnowledgeResults {
        @AuraEnabled
        public List<Article> articles {get; set;}
        
        @AuraEnabled
        public List<String> contentTypes {get; set;}
    }
    
    public class Article {
        @AuraEnabled
        public Integer order {get; set;}
        
        @AuraEnabled
        public String title {get; set;}
        
        @AuraEnabled
        public String label {get; set;}
        
        @AuraEnabled
        public String summary {get; set;}
        
        @AuraEnabled
        public String url {get; set;}
        
        @AuraEnabled
        public String link {get; set;}
        
        @AuraEnabled
        public Boolean hasLink {get; set;}
        
        @AuraEnabled
        public String contentType {get; set;}
        
        @AuraEnabled
        public String icon {get; set;}
        
        @AuraEnabled
        public String iconColor {get; set;}
        
        @AuraEnabled
        public String iconClass {get; set;}
        
        public Article(Knowledge__kav knowl, Integer order) {
            this.order = order;
            this.title = knowl.Title;
            this.label = knowl.Title;
            this.summary = knowl.Summary;
            this.url = '/articles/Knowledge/' + knowl.UrlName;
            this.link = knowl.External_Link__c;
            this.contentType = knowl.Content_Type__c;
            
            if ((knowl.Icon__c == null) || (knowl.Icon__c == '')) {
                this.iconClass = 'knowledge-other';
            } else {
                this.iconClass = 'knowledge-' + knowl.Icon__c.toLowerCase();
            }
            
            if (knowl.Icon__c == 'Document') {
                this.icon = 'utility:copy'; this.iconColor = 'blue';
            } else if (knowl.Icon__c == 'Spreadsheet') {
                this.icon = 'utility:matrix'; this.iconColor = 'green';
            } else if (knowl.Icon__c == 'Presentation') {
                this.icon = 'utility:desktop'; this.iconColor = 'red';
            } else if (knowl.Icon__c == 'Image') {
                this.icon = 'utility:image'; this.iconColor = 'orange';
            } else if (knowl.Icon__c == 'Video') {
                this.icon = 'utility:video'; this.iconColor = 'purple';
            } else if (knowl.Icon__c == 'Other') {
                this.icon = 'utility:file'; this.iconColor = 'grey';
            } else {
                this.icon = 'utility:file'; this.iconColor = 'grey';
            }
            
            this.hasLink = ((knowl.External_Link__c != null) && (knowl.External_Link__c != ''));
        }
    }
    
	@AuraEnabled
    public static KnowledgeResults queryKnowledge(String pageName, String filterFieldName, String filterValue) {
        String page = String.valueOf(pageName);
        String filterField = String.valueOf(filterFieldName);
        String filterVal = String.valueOf(filterValue);
        
        System.debug('Querying knowledge');
        System.debug('Page: ' + page + ', filterField: ' + filterField + ', filterValue:' + filterVal);
        
        if (filterField == 'Opportunity_Stage__c') {
            Opportunity opp = [SELECT StageName FROM Opportunity WHERE Id = :filterValue];
            
            filterVal = opp.StageName;
        }
        
        
        KnowledgeResults results = new KnowledgeResults();
        
        List<Article> articles = new List<Article>(); 
		Set<String> contentTypes = new Set<String>();

        Integer count = 0;
        
        String query = 'SELECT Id, Title, UrlName, Summary, External_Link__c, Content_Type__c, Icon__c FROM Knowledge__kav WHERE (Page__c INCLUDES (\'' + page + '\'))';
        
        if (String.isNotBlank(filterField) && String.isNotBlank(filterVal)) {
            String value = (filterVal == null) ? '' : filterVal;
            
            if (filterField == 'Opportunity_Stage__c') {
                query += (' AND (' + filterField + ' INCLUDES (\'' + value + '\'))');
            } else {
            	query += (' AND (' + filterField + ' = \'' + value + '\')');
            }
        }
        
        System.debug(query);
        
        for (SObject sobj: Database.query(query)) {
            Knowledge__kav knowl = (Knowledge__kav)sobj;
            
            articles.add(new Article(knowl, count));
            count++;
            
            contentTypes.add(knowl.Content_Type__c);
        }
        
        System.debug(articles);
        
        results.articles = articles;
        results.contentTypes = new List<String>(contentTypes);
        
        return results;
    }
}