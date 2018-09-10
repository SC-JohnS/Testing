public class Error_Handler {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Error_Handler';

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

    // recursion prefix for debug
    private static String debugPrefix = '';

    // flag for tracking if any errors occurred
    @TestVisible private static Boolean hasErrors = false;

    // flag to indicate if this class or any classes it depends on have triggered any caught exceptions
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

    // public static method for processing errors that occur in trigger handlers that use this class
    // logs the error, and returns the error message
    public static String processError(Trigger_Helper triggerHelper, String message, Exception e, Debug debugParams, Boolean writeException) {

        // set local variables based on debugging parameters
        Boolean debug = debugParams.debug;
        Boolean profile = debugParams.profile;

        if (debug) Util_Debug.debugMessage('Starting', debugParams);

        Exception_Helper.ExceptionHelper exceptionHelper;

        if (debug) Util_Debug.debugMessage('Checking to write exception', debugParams);
        if (writeException) {
            // build an exception handler object and add it to the writeable exceptions
            exceptionHelper = Exception_Helper.addException(triggerHelper, message, e, new Debug(debugParams));
        } else {
            // build an exception hander object without adding it to the writeable exceptions
            exceptionHelper = New Exception_Helper.ExceptionHelper('Exception', debugParams.className, debugParams.methodName, message, e, triggerHelper);
        }

        // get the exception message for display/debug
        String exceptionMessage = exceptionHelper.getMessageDisplay();

        // debug the exception
        if (debug) Util_Debug.debugMessage(exceptionMessage, debugParams);

        // add error message to trigger records
        if (debug) Util_Debug.debugMessage('Adding error message to trigger records', debugParams);
        if (triggerHelper != null && triggerHelper.newObjects != null && triggerHelper.newObjects.isEmpty() == false) {
            Integer i = 0;
            for (sObject o : triggerHelper.newObjects) {

                // prepare record to be updated by replacing it with a clone and mark its id for later update
                o = triggerHelper.prepareForChange(o, i);

                // add error to record
                o.addError(exceptionMessage);

                i++;
            }
        }

        // return the exception error message
        if (debug) Util_Debug.debugMessage('Complete', debugParams);
        return exceptionMessage;
    }

    // public static method for processing errors that occur in trigger handlers that use this class
    // logs the error, and returns the error message
    public static String processError(Set<Id> idsAffected, String message, Exception e, Debug debugParams, Boolean writeException) {

        // set local variables based on debugging parameters
        Boolean debug = debugParams.debug;
        Boolean profile = debugParams.profile;

        Exception_Helper.ExceptionHelper exceptionHelper;

        if (writeException) {
            // build an exception handler object and add it to the writeable exceptions
            exceptionHelper = Exception_Helper.addException(idsAffected, message, e, new Debug(debugParams));
        } else {
            // build an exception hander object without adding it to the writeable exceptions
            exceptionHelper = New Exception_Helper.ExceptionHelper('Exception', debugParams.className, debugParams.methodName, message, e, idsAffected);
        }

        // get the exception message for display/debug
        String exceptionMessage = exceptionHelper.getMessageDisplay();

        // debug the exception
        if (debug) Util_Debug.debugMessage(exceptionMessage, debugParams);

        // return the exception error message
        return exceptionMessage;
    }

}