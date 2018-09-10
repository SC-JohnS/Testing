// Takes a list/set of values and outputs as a CSV (or other delimiter) seperated string
public without sharing class Util_CSV {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Util_CSV';

    // set debug prefix (for recursion)
    private static String debugPrefix = '';

    // flag to indicate whether an error/exception occurred in the class
    @TestVisible private static Boolean hasErrors = false;

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

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

    // values: a set or list of values to output
    // addQuotes: true=add single quotes around each value, false=do nothing
    // addSlashes: true=adds slashes before any quotes present in value, false=do nothing
    // delimieter: the character to use as the delimiter between each value
    public static String csvString (List<String> values, Boolean addQuotes, Boolean addSlashes, String delimiter) {

        String result = null;

        if (values.isEmpty() == false) {

            // split to CSV
            result = String.join(values, delimiter);

            // add quotes to any single quotes
            if (addSlashes) {
                result = String.escapeSingleQuotes(result);
            }

            // put single quotes around each value
            if (addQuotes) {

                // put single quotes around the delimiter
                result = result.replaceAll(delimiter, '\'' + delimiter + '\'');

                // put single quotes at beginning and end
                result = '\'' + result + '\'';
            }

        }

        return result;
    }

    // version that accepts a Set of Strings
    public static String csvString (Set<String> values, Boolean addQuotes, Boolean addSlashes, String delimiter) {
        List<String> valuesList = new List<String>();
        valuesList.addAll(values);
        return csvString(valuesList, addQuotes, addSlashes, delimiter);
    }

    // version that accepts a Set of Ids
    public static String csvString (Set<Id> values, Boolean addQuotes, Boolean addSlashes, String delimiter) {
        List<String> valuesList = new List<String>();
        for (Id value : values) {
            valuesList.add(String.valueOf(value));
        }
        return csvString(valuesList, addQuotes, addSlashes, delimiter);
    }

    // version that accepts a List of IDs
    public static String csvString (List<Id> values, Boolean addQuotes, Boolean addSlashes, String delimiter) {
        List<String> valuesList = new List<String>();
        for (Id value : values) {
            valuesList.add(String.valueOf(value));
        }
        return csvString(valuesList, addQuotes, addSlashes, delimiter);
    }
}