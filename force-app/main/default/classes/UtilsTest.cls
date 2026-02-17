@isTest
private class UtilsTest {

    @isTest
    static void testValueForFieldNull() {
        Test.startTest();
        Object result = Utils.valueForField(Account.SObjectType, 'Name', null);
        Test.stopTest();
        System.assertEquals(null, result, 'Null value should return null');
    }

    @isTest
    static void testValueForFieldStringName() {
        Test.startTest();
        Object result = Utils.valueForField(Account.SObjectType, 'Name', 'Test Account');
        Test.stopTest();
        System.assertEquals('Test Account', result, 'String for Name field should return as-is');
    }

    @isTest
    static void testValueForFieldUnknownField() {
        Test.startTest();
        Object result = Utils.valueForField(Account.SObjectType, 'UnknownFieldXYZ__c', 'value');
        Test.stopTest();
        System.assertEquals('value', result, 'Unknown field should return value unchanged');
    }

    @isTest
    static void testValueForFieldBlankString() {
        Test.startTest();
        Object result = Utils.valueForField(Account.SObjectType, 'Name', '   ');
        Test.stopTest();
        System.assertEquals(null, result, 'Blank string should return null');
    }

    @isTest
    static void testGetFieldSetFields() {
        Schema.DescribeSObjectResult accountDescribe = SObjectType.Account;
        Map<String, Schema.FieldSet> fsMap = accountDescribe.fieldSets.getMap();
        if (fsMap.isEmpty()) {
            System.assert(true, 'Account has no field sets in this org - skipping getFieldSetFields assertion');
            return;
        }
        Schema.FieldSet fs = fsMap.values()[0];

        Test.startTest();
        Set<String> fields = Utils.getFieldSetFields(fs);
        Test.stopTest();

        System.assertNotEquals(null, fields, 'Fields set should not be null');
    }
}
