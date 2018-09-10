// Settings for reading values from the Class Settings custom setting
public without sharing class Util_Class_Settings {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Util_Class_Settings';

    // set debug prefix (for recursion)
    private static String debugPrefix = '';

    // flag to indicate whether an error/exception occurred in the class
    @TestVisible private static Boolean hasErrors = false;

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

    // flag on whether to show debug statements for this class
    @TestVisible private static Boolean debug = false;

    // flag on whether to log profiling information
    @TestVisible private static Boolean profile = false;

    // initialize variable for debugging
    @TestVisible private static Debug debugParams = new Debug(className, '', debugPrefix, debug, profile);

    // cached copy of class settings
    @TestVisible public static Map<String, Class_Setting__c> classSettings = null;

    // populate the map of class settings
    public static void initialize() {

        debugParams.methodName = 'initialize';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        if (classSettings == null) {
            if (debug) Util_Debug.debugMessage('Map is null, initializing', debugParams);

            // populate static variable with custom setting contents
            // note: don't use .getAll() to populate the map because it makes the collection read-only
            List<Class_Setting__c> allSettings = Class_Setting__c.getAll().values();

            // initialize map
            classSettings = new Map<String, Class_Setting__c>();

            // populate map
            for (Class_Setting__c c : allSettings) {
                classSettings.put(c.Name, c);
            }
        }

        if (debug) Util_Debug.debugMessage('classSettings: ' + classSettings, debugParams);

        if (debug) Util_Debug.debugMessage('end', debugParams);

    }

    // upserts the classes specified by name in the set
    public static void upsertSettings(Set<String> classNames) {

        debugParams.methodName = 'upsertSettings';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // initialize class settings (if null)
        if (classSettings == null) { initialize(); }

        // initialize list of settings to upsert
        List<Class_Setting__c> settingsToUpsert = new List<Class_Setting__c>();

        if (debug) Util_Debug.debugMessage('Looking up settings to add to list to upsert', debugParams);

        // loop through each provided setting and pull from map
        for (String className : classNames) {

            if (debug) Util_Debug.debugMessage('className: ' + className, debugParams);

            // get from map
            Class_Setting__c setting = classSettings.get(className);
            if (debug) Util_Debug.debugMessage('setting: ' + setting, debugParams);

            // if the setting has been initialized, add it to the list to upsert
            if (setting != null) {
                if (debug) Util_Debug.debugMessage('Setting exists, adding to list to upsert', debugParams);
                settingsToUpsert.add(setting);
            }
        }

        // if there are settings to upsert perform upsert
        if (settingsToUpsert.isEmpty() == false) {
            if (debug) Util_Debug.debugMessage('Updating settings', debugParams);
            upsert settingsToUpsert;
        }

        if (debug) Util_Debug.debugMessage('end', debugParams);

    }

    // return the value from the Class_Setting__c specified by className.settingName, returning as Boolean
    // if value not yet set in custom setting, returns defaultValue
    public static Boolean getBoolean(String paramClassName, String paramSettingName, Boolean defaultValue) {

        debugParams.methodName = 'getBoolean';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        if (debug) Util_Debug.debugMessage('paramClassName: ' + paramClassName, debugParams);
        if (debug) Util_Debug.debugMessage('paramSettingName: ' + paramSettingName, debugParams);
        if (debug) Util_Debug.debugMessage('defaultValue: ' + defaultValue, debugParams);

        // set the setting name for lookup
        String settingName = paramClassName + '.' + paramSettingName;

        if (debug) Util_Debug.debugMessage('settingName: ' + settingName, debugParams);

        // initialize class settings (if null)
        if (classSettings == null) { initialize(); }

        // define return variable
        Boolean result;

        // get the setting specified by name
        Class_Setting__c cs = classSettings.get(settingName);

        // if value not found in the map
        if (cs == null) {

            if (debug) Util_Debug.debugMessage('setting not found, setting default: ' + defaultValue, debugParams);

            // create setting with default value
            cs = new Class_Setting__c(Name=settingName, Value__c = String.valueOf(defaultValue));

            // put in map
            classSettings.put(settingName, cs);
        }

        // get value from custom setting
        String settingValue = cs.Value__c;

        if (debug) Util_Debug.debugMessage('settingValue: ' + settingValue, debugParams);

        // parse setting into boolean result
        if (settingValue == 'true' || settingValue == '1' || settingValue == 'on') {
            result = true;
        } else {
            result = false;
        }

        if (debug) Util_Debug.debugMessage('result: ' + result, debugParams);

        if (debug) Util_Debug.debugMessage('end', debugParams);

        return result;
    }

    // custom exception that accepts a set of ids as a parameter
    public class ClassSettingException extends Exception {}

    // sets the value for a Class Setting value in the cached map
    public static void setBoolean(String paramClassName, String paramSettingName, Boolean value) {

        debugParams.methodName = 'setBoolean';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        if (debug) Util_Debug.debugMessage('paramClassName: ' + paramClassName, debugParams);
        if (debug) Util_Debug.debugMessage('paramSettingName: ' + paramSettingName, debugParams);
        if (debug) Util_Debug.debugMessage('value: ' + value, debugParams);

        // set the setting name for lookup
        String settingName = paramClassName + '.' + paramSettingName;

        if (debug) Util_Debug.debugMessage('settingName: ' + settingName, debugParams);

        // if the setting is longer than the maximum allowed by the custom setting, throw an exception
        if (settingName.length() > 40) {
            throw new ClassSettingException('The setting ' + settingName + ' exceeds the maximum allowed 40 character length');
        }

        // initialize class settings (if null)
        if (classSettings == null) { initialize(); }

        // get the setting specified by name
        Class_Setting__c cs = classSettings.get(settingName);

        // if value not found in the map
        if (cs == null) {

            if (debug) Util_Debug.debugMessage('setting not found, creating', debugParams);

            // create setting record
            cs = new Class_Setting__c(Name=settingName);
        }

        // set value
        cs.Value__c = String.valueOf(value);

        // put in map
        classSettings.put(settingName, cs);

        if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // checks to see if the method specified by className + methodName is disabled
    // returns true if disabled, false if not
    // writes to the debug log on behalf of the calling class/method if that class has debug on
    public static Boolean disabledCheck (Debug debugParams) {
        // initialize default value
        Boolean result = false;

        // check if the specified className+methodName is disabled
        if (getBoolean(debugParams.className, debugParams.methodName, true) == false) {
            if (debugParams.debug) Util_Debug.debugMessage('Exiting early, ' + debugParams.methodName + ' is disabled', debugParams);
            result = true;
        }

        return result;
    }

}