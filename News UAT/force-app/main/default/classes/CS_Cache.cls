/**
 * Helper class to implement "caching" for various queries or logic to help reduce SOQLs used
 */
public without sharing class CS_Cache {
	/**
	 * Business Hours caching.
	 * To be used where ever BusinessHours are queried.
	 */
	public static List<BusinessHours> defaultBusinessHours {
		get {
			if (defaultBusinessHours == null) {
				defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
			}
			return defaultBusinessHours;
		}
		private set;
	}

	/**
	 * "Default Orchestrator" User cache to help reduce SOQLs
	 * To be used where ever Default Orchestor user needs to be queried.
	 */
	public static List<User> defaultOrchestratorUser {
		get {
			if (defaultOrchestratorUser == null) {
				defaultOrchestratorUser = [SELECT Id FROM User WHERE Name = 'Default Orchestrator'];
			}
			return defaultOrchestratorUser;
		}
		private set;
	}
}