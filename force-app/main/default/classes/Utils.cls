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

    public static Object valueForField(SObjectType sobjectType, String fieldName, Object value) {
        if (value == null) { return null; }
        Schema.SObjectField fieldToken = sobjectType.getDescribe().fields.getMap().get(fieldName);
        if (fieldToken == null) { return value; }
        Schema.DescribeFieldResult df = fieldToken.getDescribe();
        Schema.DisplayType dt = df.getType();
        if (value instanceof String) {
            String s = (String) value;
            if (String.isBlank(s)) { return null; }
            if (dt == Schema.DisplayType.DATE) {
                return Date.valueOf(s);
            }
            if (dt == Schema.DisplayType.DATETIME) {
                return DateTime.valueOf(s);
            }
            if (dt == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(s);
            }
            if (dt == Schema.DisplayType.LONG) {
                return Long.valueOf(s);
            }
            if (dt == Schema.DisplayType.DOUBLE || dt == Schema.DisplayType.CURRENCY || dt == Schema.DisplayType.PERCENT) {
                return Decimal.valueOf(s);
            }
            if (dt == Schema.DisplayType.BOOLEAN) {
                return Boolean.valueOf(s);
            }
        }
        return value;
    }
}