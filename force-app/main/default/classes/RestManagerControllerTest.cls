@isTest
private class RestManagerControllerTest {

	@TestSetup
	static void setup() {
		Rest_Settings__c rs = Rest_Settings__c.getOrgDefaults();
		if (rs == null) {
			rs = new Rest_Settings__c(Name = 'Default');
		}
		rs.Named_Credentials__c = 'TestCred';
		rs.Objects__c = 'Account';
		upsert rs;
	}

	@isTest
	static void testGetInitialData() {
		Test.startTest();
		try {
			Map<String, Object> result = RestManagerController.getInitialData();
			Assert.areNotEqual(null, result, 'Result should not be null');
			Assert.isTrue(result.containsKey('fieldsInfo'), 'Should contain fieldsInfo');
			Assert.isTrue(result.containsKey('namedCred'), 'Should contain namedCred');
			Assert.isTrue(result.containsKey('objectsList'), 'Should contain objectsList');
		} catch (IllegalArgumentException e) {
			System.assert(e.getMessage().contains('FieldSet') || e.getMessage().contains('Object'), 'Expected field set or object error in org without required setup');
		}
		Test.stopTest();
	}

	@isTest
	static void testSendRequastGet() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '[{"Name":"Test","Id":"001xx000001"}]'));

		Map<String, String> paramsMap = new Map<String, String>{
			'object'  => 'Account',
			'fields'  => 'Name,Id',
			'limit'   => '10',
			'offset'  => '0',
			'groupBy' => 'Name'
		};

		Test.startTest();
		Map<String, Object> result = RestManagerController.sendRequast('GET', paramsMap, '', 'TestCred');
		Test.stopTest();

		Assert.areEqual('200', result.get('status'), 'Status should be 200');
		Assert.areNotEqual(null, result.get('body'), 'Body should not be null');
	}

	@isTest
	static void testSendRequastInvalidObject() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '[{"Name":"X"}]'));

		Map<String, String> paramsMap = new Map<String, String>{ 'object' => 'InvalidObjectXYZ' };

		Test.startTest();
		Map<String, Object> result = RestManagerController.sendRequast('GET', paramsMap, null, 'TestCred');
		Test.stopTest();

		Assert.areNotEqual(null, result.get('body'), 'Should return error body for invalid object');
		Assert.isTrue(String.valueOf(result.get('body')).contains('Invalid object'), 'Body should mention invalid object');
	}
}
