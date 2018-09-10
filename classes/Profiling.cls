// class for displaying limit information
public class Profiling {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Profiling';

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

    // recursion counter
    public static Integer recursionCounter = 0;

    // recursion prefix for debug
    private static String debugPrefix = '';

    // flag for tracking if any errors occurred
    @TestVisible private static Boolean hasErrors = false;

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

    // initalize parameters for debugging
    public static Debug debugParams = new Debug(className, '', debugPrefix, debug, profile);

    // identifier to uniquely identify all limits within execution context
    public static String identifier;
    static {
        identifier = Datetime.now().format('yyyy-MM-dd HH:mm:ss z', 'America/New_York') + '__' + generateRandomString(10);
    }

    // Instance variables

    // limit names that are profiled
    // documentation:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_limits.htm
    public static Set<String> limitNames;
    static{
        limitNames = New Set<String>();
        // Returns the CPU time (in milliseconds) accumulated on the Salesforce servers in the current transaction.
        limitNames.add('CpuTime');
        // Returns the approximate amount of memory (in bytes) that has been used for the heap.
        limitNames.add('HeapSize');
        // Returns the number of SOQL queries that have been issued.
        limitNames.add('Queries');
        // Returns the number of records that have been returned by issuing SOQL queries.
        limitNames.add('QueryRows');
        // Returns the number of DML statements (such as insert, update or the database.EmptyRecycleBin method) that have been called.
        limitNames.add('DmlStatements');
        // Returns the number of DML rows returned
        limitNames.add('DmlRows');
        // Returns the number of aggregate queries that have been processed with any SOQL query statement.
        limitNames.add('AggregateQueries');
    }

    // limit names to debug
    public Set<String> selectedLimitNames = New Set<String>();

    // map that identifies the number of times a class+method has been called
    public static Map<String, Integer> iterationMap = New Map<String, Integer>();

    // limit object for tracking the limits for this context
    private Profiling_Object limitObject;

    // list of limit objects for profiling, cached to be written to the database
    public static List<Profiling_Object> profiles = New List<Profiling_Object>();

    // constructor with parameters
    public Profiling(Debug debugParams, Set<String> selectedLimitNames) {
        initialize(debugParams.className, debugParams.methodName, selectedLimitNames);
    }

    // constructor without parameters
    public Profiling() {
        initialize(null, null, null);
    }

    // initialize from constructor
    public void initialize(String callingClassName, String callingMethodName, Set<String> selectedLimitNames) {

        debugParams.methodName = 'initialize';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        // create limit object for profiling
        this.limitObject = new Profiling_Object(callingClassName, callingMethodName);

        // initialize selected limit names for debugging
        if (selectedLimitNames != null) {
            // set limits
            this.selectedLimitNames = selectedLimitNames;
        } else {
            this.selectedLimitNames = limitNames;
        }

        // initialize original limits
        limitObject.originalLimits = limitObject.calculateLimits();

        if (debug) Util_Debug.debugMessage('start', debugParams);

    }

    // return limit information in a string for debugging
    public String getLimits(String label) {

        debugParams.methodName = 'getLimits';

        if (debug) Util_Debug.debugMessage('start', debugParams);
        if (debug) Util_Debug.debugMessage('label: ' + label, debugParams);

        String output = 'LIMITS: ';

        // set current limits
        limitObject.currentLimits = limitObject.calculateLimits();

        List<String> outputLines = New List<String>();

        for (String limitName : limitNames) {

            String mapName = 'get' + limitName;
            Integer currentValue = limitObject.currentLimits.get(mapName);
            Integer originalValue = limitObject.originalLimits.get(mapName);
            Integer diffValue = currentValue - originalValue;

            String mapLimitName = 'getLimit' + limitName;
            Integer limitValue = limitObject.currentLimits.get(mapLimitName);

            String temp1 = currentValue.format().rightPad(8);
            String temp2 = limitValue.format().rightPad(8);
            String temp3 = '(' + diffValue.format() + ')';
                   temp3 = temp3.rightPad(10);

            outputLines.add(mapName + ': ' + temp1 + ' / ' +  temp2 + ' ' + temp3);

            // add diff to calculated limit map
            limitObject.calculatedLimits.put('get' + limitName, diffValue);
            limitObject.calculatedLimits.put('getLimit' + limitName, limitValue);

        }

        // add the output lines to the final output
        output += String.join(outputLines, ', ');

        output += ' [' + label + ']';

        // set original limits for the next call
        limitObject.originalLimits = limitObject.currentLimits;

        if (debug) Util_Debug.debugMessage('end', debugParams);

        return output;
    }

    // object to hold the current calculated limits
    public class Profiling_Object {

        // parameters for object for tracking the context
        public String callingClassName;
        public String callingMethodName;
        public Integer iteration;

        // original limits from the last call
        private Map<String, Integer> originalLimits = New Map<String, Integer>();

        // current limits from the current call
        private Map<String, Integer> currentLimits = New Map<String, Integer>();

        // calculated limits from the current call
        private Map<String, Integer> calculatedLimits = New Map<String, Integer>();

        // constructor
        public Profiling_Object(String callingClassName, String callingMethodName) {

            debugParams.methodName = 'constructor';
            if (debug) Util_Debug.debugMessage('start', debugParams);

            if (debug) Util_Debug.debugMessage('callingClassName: ' + callingClassName, debugParams);
            if (debug) Util_Debug.debugMessage('callingMethodName: ' + callingMethodName, debugParams);

            this.callingClassName = callingClassName;
            this.callingMethodName = callingMethodName;

            if (debug) Util_Debug.debugMessage('end', debugParams);
        }

        // update limits map
        private Map<String, Integer> calculateLimits() {

            Map<String, Integer> limitsMap = New Map<String, Integer>();

            if (limitNames.contains('Queries')) {
                limitsMap.put('getQueries', Limits.getQueries());
                limitsMap.put('getLimitQueries', Limits.getLimitQueries());
            }
            if (limitNames.contains('QueryRows')) {
                limitsMap.put('getQueryRows', Limits.getQueryRows());
                limitsMap.put('getLimitQueryRows', Limits.getLimitQueryRows());
            }
            if (limitNames.contains('DmlStatements')) {
                limitsMap.put('getDmlStatements', Limits.getDmlStatements());
                limitsMap.put('getLimitDmlStatements', Limits.getLimitDmlStatements());
            }
            if (limitNames.contains('DmlRows')) {
                limitsMap.put('getDmlRows', Limits.getDmlRows());
                limitsMap.put('getLimitDmlRows', Limits.getLimitDmlRows());
            }
            if (limitNames.contains('HeapSize')) {
                limitsMap.put('getHeapSize', Limits.getHeapSize());
                limitsMap.put('getLimitHeapSize', Limits.getLimitHeapSize());
            }
            if (limitNames.contains('CpuTime')) {
                limitsMap.put('getCpuTime', Limits.getCpuTime());
                limitsMap.put('getLimitCpuTime', Limits.getLimitCpuTime());
            }
            if (limitNames.contains('AggregateQueries')) {
                limitsMap.put('getAggregateQueries', Limits.getAggregateQueries());
                limitsMap.put('getLimitAggregateQueries', Limits.getLimitAggregateQueries());
            }

            return limitsMap;

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

}