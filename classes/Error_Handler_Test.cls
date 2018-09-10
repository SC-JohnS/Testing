@isTest
public without sharing class Error_Handler_Test {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Error_Handler_Test';

    // recursion prefix for debug
    private static String debugPrefix = '';

    // flag on whether to show debug output
    @TestVisible private static Boolean debug = true;

    // flag on whether to log profiling information
    @TestVisible private static Boolean profile = false;

    // initialize variable for debugging
    @TestVisible private static Debug debugParams = new Debug(className, '', debugPrefix, debug, profile);

    // method that creates test data immediately before running
    // individual unit tests
    @TestSetup private static void createTestDataSetup() {
        createTestData();
    }

    // method for creating test data
    @TestVisible private static void createTestData() {

        debugParams.methodName = 'createTestData';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // set whitelist to skip processing all async queues
        Async_Queue_Process.processWhitelist = new Set<String>{};

        // limit debugging
        Profiling methodProfiling;
        String limitDebug;

        if (debug) {
            methodProfiling = New Profiling();
            limitDebug = methodProfiling.getLimits('start ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        // initialize error
        String error;

        // ACCOUNT

            Factory_Account accountFactory = New Factory_Account();
            accountFactory.add(5, new Set<String>{'canada'});
            error = accountFactory.insertRecords();
            system.assertEquals(null, error);


        // limit debugging, adding to profile
        if (debug) {
            limitDebug = methodProfiling.getLimits('end ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        // output stats about async queues
        Test_Support.asyncStats(debugParams, 'Async Stats: ');

        if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // processError with triggerHelper
    @isTest
    private static void triggerHelper() {

        debugParams.methodName = 'triggerHelper';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // turn on debug logging
        Util_Class_Settings.setBoolean('Error_Handler', 'debug', true);

        // set whitelist to only process the methods described in the set
        // leave the set empty to skip ALL methods
        Async_Queue_Process.processWhitelist = new Set<String>{};

        // pull test records created before method was called
            List<Account> accounts = [SELECT Id, Name FROM Account];

        // create test data after method was called

            // initialize error
            String error;

            // disable method
            //Util_Class_Settings.setBoolean(Error_Handler.className, 'METHODNAME', false);

            // method-specific test data changes


            // enable method
            //Util_Class_Settings.setBoolean(Error_Handler.className, 'METHODNAME', true);

            // query newly created test data

        // final changes before test begins

        String result;
        Integer exceptionCount;

        // initialize trigger handler
        List<sObject> newObjects = accounts.deepClone(true, true, true);
        List<sObject> oldObjects = accounts.deepClone(true, true, true);

        Trigger_Helper triggerHelper = New Trigger_Helper(newObjects, oldObjects, 'Before', 'Update');

        // reset static variables for testing
        Test_Support.resetStatics();

        if (debug) Util_Debug.debugMessage('Starting Test', debugParams);
        Test.startTest();

        // test using triggerHelper and writeExceptions: false

            // get current count of exceptions
            exceptionCount = Exception_Helper.getCount();

            // process error
            result = Error_Handler.processError(triggerHelper, 'test', null, new Debug(debugParams), false);

            // write any exceptions to the database
            Exception_Helper.writeExceptions();

            // validate that
            system.assertEquals(exceptionCount, Exception_Helper.getCount());

        // test using triggerHelper and writeExceptions: true

            // get current count of exceptions
            exceptionCount = Exception_Helper.getCount();

            // process error
            result = Error_Handler.processError(triggerHelper, 'test', null, new Debug(debugParams), true);

            // write any exceptions to the database
            Exception_Helper.writeExceptions();

            // validate that there are more records created than what were there originally
            system.assertEquals(true, Exception_Helper.getCount() > exceptionCount);

        if (debug) Util_Debug.debugMessage('Stopping test', debugParams);
        Test.stopTest();

        // validate if any errors occurred
        system.assertEquals(false, Error_Handler.hasErrors());

        // output stats about async queues that were processed
        Test_Support.asyncStats(debugParams, 'Async Stats: ');

        if (debug) Util_Debug.debugMessage('end', debugParams);

    }

    // processError with idsAffected
    @isTest
    private static void idsAffected() {

        debugParams.methodName = 'idsAffected';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // turn on debug logging
        Util_Class_Settings.setBoolean('Error_Handler', 'debug', true);
        Util_Class_Settings.setBoolean('Exception_Helper', 'debug', true);

        // set whitelist to only process the methods described in the set
        // leave the set empty to skip ALL methods
        Async_Queue_Process.processWhitelist = new Set<String>{};

        // pull test records created before method was called
            List<Account> accounts = [SELECT Id, Name FROM Account];

        // create test data after method was called

            // initialize error
            String error;

            // disable method
            //Util_Class_Settings.setBoolean(Error_Handler.className, 'METHODNAME', false);

            // method-specific test data changes


            // enable method
            //Util_Class_Settings.setBoolean(Error_Handler.className, 'METHODNAME', true);

            // query newly created test data

        // final changes before test begins

        String result;
        Integer exceptionCount;

        // reset static variables for testing
        Test_Support.resetStatics();

        if (debug) Util_Debug.debugMessage('Starting Test', debugParams);
        Test.startTest();

        // test using idsAffected and writeExceptions: false

            // get current count of exceptions
            exceptionCount = Exception_Helper.getCount();

            // process error
            result = Error_Handler.processError(new Set<Id>{UserInfo.getUserId()}, 'test', null, new Debug(debugParams), false);

            // write any exceptions to the database
            Exception_Helper.writeExceptions();

            // validate that
            system.assertEquals(exceptionCount, Exception_Helper.getCount());

        // test using idsAffected and writeExceptions: true

            // get current count of exceptions
            exceptionCount = Exception_Helper.getCount();

            // process error
            result = Error_Handler.processError(new Set<Id>{UserInfo.getUserId()}, 'test', null, new Debug(debugParams), true);

            // write any exceptions to the database
            Exception_Helper.writeExceptions();

            // validate that there are more records created than what were there originally
            system.assertEquals(true, Exception_Helper.getCount() > exceptionCount);

        if (debug) Util_Debug.debugMessage('Stopping test', debugParams);
        Test.stopTest();

        // validate if any errors occurred
        system.assertEquals(false, Error_Handler.hasErrors());

        // output stats about async queues that were processed
        Test_Support.asyncStats(debugParams, 'Async Stats: ');

        if (debug) Util_Debug.debugMessage('end', debugParams);

    }

}