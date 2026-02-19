@isTest
private class DashboardComponentControllerTest {

	@TestSetup
	static void setup() {
		Rest_Settings__c rs = Rest_Settings__c.getOrgDefaults();
		if (rs == null) {
			rs = new Rest_Settings__c(Name = 'Default');
		}
		rs.Named_Credentials__c = 'TestCred';
		upsert rs;
	}

	@isTest
	static void testGetCrossOrgDataSuccess() {
		String reportJson = '{"factMap":{"T!T":{"rows":[],"aggregates":[{"value":0}]}}}';
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, reportJson));

		Test.startTest();
		Map<String, Object> result = DashboardComponentController.getCrossOrgData();
		Test.stopTest();

		Assert.areNotEqual(null, result, 'Result should not be null');
		Assert.isTrue(result.containsKey('factMap'), 'Should contain factMap');
	}

	@isTest
	static void testGetCrossOrgDataError() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, 'Not Found'));

		Test.startTest();
		try {
			DashboardComponentController.getCrossOrgData();
			System.assert(false, 'Should throw AuraHandledException');
		} catch (AuraHandledException e) {
			System.assert(String.isNotBlank(e.getMessage()), 'Should have error message');
		}
		Test.stopTest();
	}
}
