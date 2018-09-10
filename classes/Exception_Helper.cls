public class Exception_Helper {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Exception_Helper';

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

    // recursion prefix for debug
    private static String debugPrefix = '';

    // flag for tracking if any errors occurred
    @TestVisible private static Boolean hasErrors = false;

    // flag to indicate if this class or the Trigger_Handler class it extends have errors across the execution context
    @TestVisible private static Boolean hasErrors() {
        return (hasErrors);
    }

    // flag on whether to show debug statements for this class
    @TestVisible private static Boolean debug;
    static{
        debug = Util_Class_Settings.getBoolean(className, 'debug', false);
    }

    // flag on whether to log profiling information
    @TestVisible private static Boolean profile;
    static{
        profile = Util_Class_Settings.getBoolean(className, 'profile', false);
    }

    // initialize variable for debugging
    @TestVisible private static Debug debugParams = new Debug(className, '', debugPrefix, debug, profile);

    // identifier to uniquely identify all exceptions within execution context
    public static String identifier = null;

    // return the identifier
    public static String getIdentifier() {

        // initialize identifier if null
        if (identifier == null) {
            identifier = Datetime.now().format('yyyy-MM-dd HH:mm:ss z', 'America/New_York') + '__' + generateRandomString(10);
        }

        return identifier;
    }

    // Instance variables

    private static List<ExceptionHelper> exceptions = new List<ExceptionHelper>();

    // Classes

    // custom exception for testing
    public class MyException extends Exception{}

    // add exception to the list, with exception object
    public static ExceptionHelper addException (String message, Exception e, Debug debugParams) {
        return addExceptionSupport('Exception', debugParams.className, debugParams.methodName, message, e, null);
    }

    // add exception to the list, with exception object and triggerHelper
    public static ExceptionHelper addException (Trigger_Helper triggerHelper, String message, Exception e, Debug debugParams) {
        Set<Id> idsAffected = new Set<Id>();
        if (triggerHelper != null) {
            idsAffected = triggerHelper.getNewObjectsIdMap().keySet();
        }
        return addExceptionSupport('Exception', debugParams.className, debugParams.methodName, message, e, idsAffected);
    }

    // add exception to the list, with exception object and idsAffected
    public static ExceptionHelper addException (Set<Id> idsAffected, String message, Exception e, Debug debugParams) {
        return addExceptionSupport('Exception', debugParams.className, debugParams.methodName, message, e, idsAffected);
    }

    // add exception to the list, with exception object and idsAffected
    public static ExceptionHelper addException (Map<Id, sObject> idsMap, String message, Exception e, Debug debugParams) {
        Set<Id> idsAffected = new Set<Id>();
        if (idsMap != null) {
            idsAffected = idsMap.keySet();
        }
        return addExceptionSupport('Exception', debugParams.className, debugParams.methodName, message, e, idsAffected);
    }

    // add exception to the list, with provided exception object
    public static ExceptionHelper addExceptionSupport (String paramType, String paramClass, String paramMethod, String paramMessage, Exception e, Set<Id> idsAffected) {

        debugParams.methodName = 'addExceptionSupport';

        if (debug) Util_Debug.debugMessage('start', debugParams);
        if (debug) Util_Debug.debugMessage('paramClass: ' + paramClass, debugParams);
        if (debug) Util_Debug.debugMessage('paramMethod: ' + paramMethod, debugParams);
        if (debug) Util_Debug.debugMessage('paramMessage: ' + paramMessage, debugParams);
        if (debug) Util_Debug.debugMessage('idsAffected: ' + idsAffected, debugParams);

        ExceptionHelper ex;

        // initialize exception helper
        ex = New ExceptionHelper(paramType, paramClass, paramMethod, paramMessage, e, idsAffected);

        // write to debug log
        ex.debug();

        // add to exception list
        exceptions.add(ex);

        if (debug) Util_Debug.debugMessage('end', debugParams);
        return ex;
    }

    // get list of exeptions
    public static List<ExceptionHelper> getExceptions() {
        return exceptions;
    }

    // get list of exeptions based on the specified type
    public static List<ExceptionHelper> getExceptions(String type) {

        List<ExceptionHelper> helpers = New List<ExceptionHelper>();

        if (exceptions.size() > 0) {
            for (ExceptionHelper h : exceptions) {
                if (h.theType == type) {
                    helpers.add(h);
                }
            }
        }

        return helpers;
    }

    // clear the exception list
    public static void clearExceptions() {

        debugParams.methodName = 'clearExceptions';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        exceptions = new List<ExceptionHelper>();

        if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // write exceptions to the custom object and clear the list
    public static void writeExceptions() {

        debugParams.methodName = 'writeExceptions';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // check for errors
        if (exceptions == null || exceptions.size() == 0) {
            if (debug) Util_Debug.debugMessage('Exiting early, no exceptions to write', debugParams);
            return;
        }

        // create a local copy of the exceptions
        List<ExceptionHelper> tempExceptions = exceptions.clone();

        // clear the exception list
        clearExceptions();

        // build list of records to insert
        List<Exception_Log__c> recordsToInsert = New List<Exception_Log__c>();

        if (tempExceptions.size() > 0) {
            for (ExceptionHelper ex : tempExceptions) {
                recordsToInsert.add(ex.getExceptionRecord());
            }
        }

        if (recordsToInsert.size() > 0) {

            // message to store batch-wide exception error
            String exceptionMessage;

            // store the database result
            List<Database.SaveResult> result = null;

            if (debug) Util_Debug.debugMessage('Inserting exception records', debugParams);

            // cause record-level validation error due to missing field
            if (testMode == 2) {
                // cause first record to fail
                recordsToInsert[0].Class__c = null;
            }

            Boolean batchHasErrors = false;

            // insert records
            try {

                // throw error if testing
                if (testMode == 1) {
                    if (debug) Util_Debug.debugMessage('Throwing Error', debugParams);
                    Contact c = New Contact();
                    insert c;
                }

                // execute the insert
                result = Database.Insert(recordsToInsert, false);

                if (debug) Util_Debug.debugMessage('Batch processed successfully', debugParams);

            } catch (Exception e) {

                // store exception message
                exceptionMessage = e.getMessage();

                String message = 'Exception insert failed. Exception: ' + exceptionMessage;
                if (debug) Util_Debug.debugMessage(message, debugParams);

                // indicate some error has occurred
                hasErrors = true;

                // flag the batch as having errors
                batchHasErrors = true;

                // add exception to list
                Exception_Helper.addException(message, e, new Debug(debugParams));
            }

            if (debug) Util_Debug.debugMessage('Checking inserted exception records', debugParams);

            // loop through records to insert
            Integer j=0;
            for (Exception_Log__c c : recordsToInsert) {

                String message = '';

                // if no batch-wide exception occurred
                if (batchHasErrors == false) {

                    // get database result
                    Database.SaveResult sr = result[j];

                    // if some error occurred with this database operation
                    if (sr.isSuccess() == false) {

                        // indicate some error has occurred
                        hasErrors = true;

                        message = '';

                        // Operation failed, so get all errors
                        for(Database.Error err : sr.getErrors()) {
                            if (message != '') message = message + '\n';
                            message = message + err.getStatusCode() + ': ' + err.getMessage();
                        }

                        if (debug) Util_Debug.debugMessage('Exception on record: ' + message, debugParams);

                    } else {
                        if (debug) Util_Debug.debugMessage('Exception inserted successfully' + message, debugParams);
                    }

                }

                j++;
            }

        }

        if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // class to hold each exception
    public class ExceptionHelper {

        // Instance variables

        private String theType;
        private String theIdentifier;
        private String theClass;
        private String theMethod;
        private String theMessage;
        private String theMessageSummary;
        private String theMessageDisplay;
        private Datetime theDate;
        private Id theUser;
        private String theIdsAffected;

        // Constructor

        // with trigger helper
        public ExceptionHelper (String paramType, String paramClass, String paramMethod, String paramFriendlyMessage, Exception e, Trigger_Helper triggerHelper) {
            Set<Id> idsAffected = new Set<Id>();
            if (triggerHelper != null && triggerHelper.newObjects != null && triggerHelper.newObjects.isEmpty() == false) {
                for (sObject o : triggerHelper.newObjects) {
                    if (o.Id != null) {
                        idsAffected.add(o.Id);
                    }
                }
            }
            constructor(paramType, paramClass, paramMethod, paramFriendlyMessage, e, idsAffected);
        }

        // with idsaffected
        public ExceptionHelper (String paramType, String paramClass, String paramMethod, String paramFriendlyMessage, Exception e, Set<Id> paramIdsAffected) {
            constructor(paramType, paramClass, paramMethod, paramFriendlyMessage, e, paramIdsAffected);
        }

        // called by the real constructors
        public void constructor(String paramType, String paramClass, String paramMethod, String paramFriendlyMessage, Exception e, Set<Id> paramIdsAffected) {

            String exceptionDetails = null;

            // if exception provided, build string for output
            if (e != null) {

                // initialize
                exceptionDetails = '';

                // get details of the exception
                Integer getLineNumber = e.getLineNumber();
                String getMessage = e.getMessage();
                String getStackTraceString = e.getStackTraceString();
                String getTypeName = e.getTypeName();

                // build exception details
                exceptionDetails += 'Exception details:\n\n';
                exceptionDetails += 'Type Name: ' + getTypeName + '\n';
                exceptionDetails += 'Line Number: ' + String.valueOf(getLineNumber) + '\n';
                exceptionDetails += 'Message: ' + getMessage + '\n\n';
                exceptionDetails += 'Stack Trace:\n' + getStackTraceString;
            }

            // if ids affected provided, build string for output
            String idsAffected = null;

            if (paramIdsAffected != null && paramIdsAffected.isEmpty() == false) {
                idsAffected = 'Ids affected: ' + Util_CSV.csvString(paramIdsAffected, false, false, ', ');
            }

            // build the message for the log
            theMessage = paramFriendlyMessage;
            if (exceptionDetails != null) {
                theMessage += '\n\n' + exceptionDetails;
            }
            if (idsAffected != null) {
                theMessage += '\n\n' + idsAffected;
            }

            // build the message for display
            theMessageDisplay = paramFriendlyMessage + '...';
            if (exceptionDetails != null) {
                theMessageDisplay += '\n\n' + exceptionDetails;
            }
            if (idsAffected != null) {
                theMessageDisplay += '\n\n' + idsAffected;
            }
            theMessageDisplay = theMessageDisplay.replaceAll('\\n', '|');

            // set private variables
            theType = paramType;
            theIdentifier = getIdentifier();
            theClass = paramClass;
            theMethod = paramMethod;
            theMessageSummary = trimString(theMessageDisplay, 250);
            theDate = System.now();
            theUser = UserInfo.getUserId();
            theIdsAffected = idsAffected;
        }

        // returns the provided variables in an Exception_Log__c record
        public Exception_Log__c getExceptionRecord() {
            Exception_Log__c record = new Exception_Log__c(Type__c = theType, Class__c=theClass, Method__c=theMethod, Message__c=theMessage, Message_Summary__c=theMessageSummary, Date__c=theDate, User__c=theUser, Identifier__c=theIdentifier);
            return record;
        }

        // writes the details of the exception to the debug log
        public void debug() {
            debugParams.methodName = 'ExceptionHelper.debug';
            if (debug) Util_Debug.debugMessage('Exception helper: identifier: ' + theIdentifier + ', type: ' + theType + ', class: ' + theClass + ', method: ' + theMethod + ', date: ' + theDate + ', user: ' + theUser + ', message: ' + theMessage + ', messageSummary: ' + theMessageSummary + ', Ids affected: ' + theIdsAffected, debugParams);
        }

        public String getMessageDisplay() {
            return theMessageDisplay;
        }

    }

    // generate random string method
    // note: do not call if (debug) debugMessage() from this method or it will create recursion
    public static String generateRandomString(Integer len) {

        // error checking
        if (len == null) {
            return null;
        }

        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';

        String randStr = '';

        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), 62);
           randStr += chars.substring(idx, idx+1);
        }

        return randStr;
    }

    // trims a provided string down to the first "length" characters
    // if it trims the string, adds ... to the end
    public static String trimString (string inText, Integer length) {
        if (inText != null && length != null && inText.length() > length) {
            return inText.substring(0, length - 3) + '...';
        } else {
            return inText;
        }
    }

    // returns the count of the # of exceptions in the database
    public static Integer getCount() {
        List<AggregateResult> results = [SELECT COUNT(Id)cnt FROM Exception_Log__c];
        return Integer.valueOf(results[0].get('cnt'));
    }

}