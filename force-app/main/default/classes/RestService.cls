@RestResource(urlMapping='/Objects/*')
global with sharing class RestService {

	@HttpGet
	global static List<sObject> getRecords() {
		try {
			RestRequest request = RestContext.request;
			Map<String, String> requestParams = request.params;

			String objectParam = requestParams.get('object');
			if (String.isBlank(objectParam)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: object');
			}
			objectParam = String.escapeSingleQuotes(objectParam);

			String fieldsParam = requestParams.get('fields');
			if (String.isBlank(fieldsParam)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: fields');
			}
			fieldsParam = fieldsParam.replaceAll('[^a-zA-Z0-9_,]', '');

			String limitStr   = requestParams.get('limit');
			String offsetStr  = requestParams.get('offset');
			String groupBy    = requestParams.get('groupBy');
			String searchString = requestParams.get('searchString');

			limitStr     = String.isNotBlank(limitStr)     ? String.escapeSingleQuotes(limitStr)   : '';
			offsetStr    = String.isNotBlank(offsetStr)    ? String.escapeSingleQuotes(offsetStr)  : '';
			groupBy      = String.isNotBlank(groupBy)      ? String.escapeSingleQuotes(groupBy)     : '';
			searchString = String.isNotBlank(searchString) ? String.escapeSingleQuotes(searchString) : '';

			if (String.isBlank(groupBy)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: groupBy');
			}

			Integer limitParam  = String.isBlank(limitStr) ? 50000 : Integer.valueOf(limitStr);
			Integer offsetParam = String.isBlank(offsetStr) ? null : Integer.valueOf(offsetStr);

			if (offsetParam == null || offsetParam > 2000) {
				offsetParam = 0;
			}

			if (String.isNotBlank(searchString)) {
				searchString += '*';

				String soslQuery =
				'FIND :searchString '      +
				'IN ALL FIELDS RETURNING ' +
				objectParam                + '(' + fieldsParam +
				' ORDER BY ' + groupBy     +
				' LIMIT :limitParam '      +
				'OFFSET :offsetParam)';

				List<List<sObject>> searchResults = Search.query(soslQuery, AccessLevel.USER_MODE);

				if (searchResults.size() == 0) { return new List<sObject>(); }

				return searchResults[0];
			}

			return Database.queryWithBinds (
				'SELECT '            + fieldsParam +
				' FROM '             + objectParam +
				' ORDER BY '         + groupBy     +
				' LIMIT :limitParam' +
				' OFFSET :offsetParam',
				new Map<String, Object>{ 'limitParam' => limitParam, 'offsetParam' => offsetParam },
				AccessLevel.USER_MODE
			);
		} catch(Exception e){
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpPost
	global static List<SObject> createRecords() {
		try {
			List<SObject> records = getRecordToUpsert();

			Database.insert(records, true, AccessLevel.USER_MODE);
			return records;
		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpPatch
	global static List<SObject> updateRecords() {
		try {
			List<SObject> records = getRecordToUpsert();
			Database.update(records, true, AccessLevel.USER_MODE);
			return records;
		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpDelete
	global static List<sObject> deleteRecord() {
		try {
			String recordId    = RestContext.request.params.get('Id');
			String objectParam = RestContext.request.params.get('object');

			if (String.isBlank(recordId) || String.isBlank(objectParam)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: Id or object');
			}

			recordId    = String.escapeSingleQuotes(recordId);
			objectParam = String.escapeSingleQuotes(objectParam);

			List<sObject> records = Database.queryWithBinds (
				'SELECT  Id' +
				' FROM '     + objectParam +
				' WHERE Id = :recordId',
				new Map<String, Object>{ 'recordId' => recordId },
				AccessLevel.USER_MODE
			);

			if(records.size() == 0) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Record with ID ' + recordId + ' is not exist!');
			}
			Database.delete(records[0], true, AccessLevel.USER_MODE);

			return records;

		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	global static List<SObject> getRecordToUpsert() {

		RestRequest request   = RestContext.request;
		Map<String, String> params = request.params;
		String objectTypeName = (params != null) ? params.get('object') : null;
		if (String.isBlank(objectTypeName)) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('Missing query parameter: object');
		}
		
		objectTypeName = String.escapeSingleQuotes(objectTypeName);

		SObjectType token = Schema.getGlobalDescribe().get(objectTypeName);
		if (token == null) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('Invalid object: ' + objectTypeName);
		}

		List<Object> rawList  = (List<Object>)JSON.deserializeUntyped(request.requestBody.toString());
		List<sObject> records = new List<sObject>();

		for (Object item : rawList) {
			Map<String, Object> itemMap = (Map<String, Object>)item;
			sObject record = token.newSObject();
			for (String key : itemMap.keySet()) {
				Object val = Utils.valueForField(token, key, itemMap.get(key));
				if (val != null) {
					record.put(key, val);
				}
			}
			records.add(record);
		}

		if (records.size() == 0) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('No records to operate');
		}

		return records;
	}

	private class RestServiceException extends Exception {}
}