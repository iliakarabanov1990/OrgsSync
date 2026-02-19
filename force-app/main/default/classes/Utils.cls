public with sharing class Utils {

	public static Set<String> getFieldSetFields(FieldSet fieldSet) {
		Set<String> fields = new Set<String>();
		for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
			String fieldPath = fieldSetMember.getFieldPath();
			if (fieldPath.contains('.')) { continue; }
			fields.add(fieldPath);
		}
		return fields;
	}

	public static Object valueForField(SObjectType sObjectType, String fieldName, Object value) {

		String valueStr = value == null ? null : String.valueOf(value);

		if (String.isBlank(valueStr)) { return null; }

		Schema.SObjectField fieldToken = sObjectType.getDescribe().fields.getMap().get(fieldName);
		if (fieldToken == null) { return value; }

		Schema.DescribeFieldResult df = fieldToken.getDescribe();
		Schema.DisplayType dt = df.getType();

		switch on dt {
			when STRING                    { return valueStr; }
			when DATE                      { return Date.valueOf(valueStr); }
			when DATETIME                  { return DateTime.valueOf(valueStr); }
			when INTEGER                   { return Integer.valueOf(valueStr); }
			when LONG                      { return Long.valueOf(valueStr); }
			when DOUBLE, CURRENCY, PERCENT { return Decimal.valueOf(valueStr); }
			when BOOLEAN                   { return Boolean.valueOf(valueStr); }
			when else                      { return value; }
		}
	}

	public static String typeForField(SObjectType sObjectType, String fieldName) {

		Schema.SObjectField fieldToken = sObjectType.getDescribe().fields.getMap().get(fieldName);

		if (fieldToken == null) { return 'string'; }

		Schema.DescribeFieldResult df = fieldToken.getDescribe();
		return df.getType().name().toLowerCase();
	}
}