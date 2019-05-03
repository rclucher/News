@IsTest
public class CS_CacheTest {

	@isTest static void testBusinessHoursCache() {
		//initial run, consumes 1 SOQL
		List<BusinessHours> bHours = CS_Cache.defaultBusinessHours;
		//additional run should return cached result so no additional SOQLs
		Integer limitsBefore = Limits.getQueries();
		bHours = CS_Cache.defaultBusinessHours;
		Integer limitsAfter = Limits.getQueries();
		System.assertEquals(limitsBefore, limitsAfter, 'No additional SOQLs should be consumed');
	}

	@isTest static void testDefaultOrchUser() {
		//initial run, consumes 1 SOQL
		List<User> users = CS_Cache.defaultOrchestratorUser;
		//additional run should return cached result so no additional SOQLs
		Integer limitsBefore = Limits.getQueries();
		users = CS_Cache.defaultOrchestratorUser;
		Integer limitsAfter = Limits.getQueries();
		System.assertEquals(limitsBefore, limitsAfter, 'No additional SOQLs should be consumed');
	}

	@testSetup public static void dataSetup() {
		//not needed for now, placeholder
	}
}