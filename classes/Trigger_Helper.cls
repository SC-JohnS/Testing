public with sharing class Trigger_Helper {

    // Global variables

    // class name, for debug output
    @TestVisible private static String className = 'Trigger_Helper';

    // flag to set different modes for testing
    @TestVisible private static Integer testMode = 0;

    // indicates if any errors have occurred
    @TestVisible private static Boolean hasErrors = false;

    // set debug prefix (for recursion)
    private static String debugPrefix = '';

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

    // Classes

    // Class to store an sObject and an index uniquely identifying its position in a list
    public class TriggerObject {

        public Integer index = null;
        public sObject obj = null;

        // set of API names of fields that changed in the current object vs. the previous version
        // WARNING: this set is overwritten by each call to checkRecords()
        public set<String> changedFields = new Set<String>();

        // constructor
        public TriggerObject(sObject obj, Integer index) {
            this.obj = obj;
            this.index = index;
        }

        public List<String> debug() {
            List<String> messages = New List<String>();
            messages.add('Index: ' + this.index);
            Id recordId = null;
            if (this.obj != null && this.obj.Id != null) {
                recordId = this.obj.Id;
            }
            messages.add('- Id: ' + recordId);
            messages.add('- changedFields: ' + this.changedFields);
            messages.add('- obj: ' + this.obj);
            return messages;
        }

    }

    // Static variables

    // map of ClassName to Count for tracking the # of times that class has recursed
    public static Map<String, Integer> recursionCountMap = New Map<String, Integer>();

    // return an incremented recursion count for the specified class
    public static Integer getRecursionCount(String callingClassName) {
        // if blank, initialize
        if (recursionCountMap.containsKey(callingClassName) == false) {
            recursionCountMap.put(callingClassName, 0);
        }

        // get value and increment it
        Integer count = recursionCountMap.get(callingClassName);
        count++;

        // store new value in map and return
        recursionCountMap.put(callingClassName, count);
        return count;
    }

    public static Integer recursionCounter = 0;

    // static map of ClassName.MethodName to Set<Id> of record ids that have already been processed by that method
    public static Map<String, Set<Id>> processedIdsMap = new Map<String, Set<Id>>();

    public static void addProcessedId(String identifier, Id recordId) {
        // get set of ids from map
        Set<Id> tempIds = processedIdsMap.get(identifier);

        // initialize
        if (tempIds == null) {
            tempIds = new Set<Id>();
        }

        // add to set
        tempIds.add(recordId);

        // add back to map
        processedIdsMap.put(identifier, tempIds);
    }

    public static Boolean isProcessedId(string identifier, Id recordId) {
        // get set of ids from map
        Set<Id> tempIds = processedIdsMap.get(identifier);

        // initialize
        if (tempIds == null) {
            tempIds = new Set<Id>();
        }

        // return whether the recordId is in the set of processed ids for this map
        return tempIds.contains(recordId);
    }

    // static map of Record Id to sObject that represents the fields that were changed
    // the last time the method ran, and what the values were
    public static Map<String, Map<Id, Map<String, String>>> changedCacheMap = New Map<String, Map<Id, Map<String, String>>>();

    // static map of Record Id to sObject that represents the fields that were nulled
    // the last time the method ran, and what the values were
    public static Map<String, Map<Id, Map<String, String>>> nulledCacheMap = New Map<String, Map<Id, Map<String, String>>>();

    // Instance variables

    public List<sObject> newObjects = null;
    public List<sObject> oldObjects = null;

    // Map of Index to sObject
    private Map<Integer, sObject> newObjectsIndexMap = null;
    private Map<Integer, sObject> oldObjectsIndexMap = null;

    // Map of Record Id to sObject
    private Map<Id, sObject> newObjectsIdMap = null;
    private Map<Id, sObject> oldObjectsIdMap = null;

    // initialize and return map of Index to New Trigger Object
    public Map<Integer, sObject> getNewObjectsIndexMap() {

        // if variable has not yet been set, initialize it then return it
        if (newObjectsIndexMap == null) {
            newObjectsIndexMap = new Map<Integer, sObject>();
            if (newObjects != null) {
                Integer size = newObjects.size();
                for (Integer i = 0; i < size; i++) {
                    sObject t = newObjects[i];
                    newObjectsIndexMap.put(i, t);
                }
            }
        }

        return newObjectsIndexMap;
    }

    // initialize and return map of Index to Old Trigger Object
    public Map<Integer, sObject> getOldObjectsIndexMap() {

        // if variable has not yet been set, initialize it then return it
        if (oldObjectsIndexMap == null) {
            oldObjectsIndexMap = new Map<Integer, sObject>();
            if (oldObjects != null) {
                Integer size = oldObjects.size();
                for (Integer i = 0; i < size; i++) {
                    sObject t = oldObjects[i];
                    oldObjectsIndexMap.put(i, t);
                }
            }
        }

        return oldObjectsIndexMap;
    }

    // initialize and return map of Id to New Trigger Object
    public Map<Id, sObject> getNewObjectsIdMap() {

        // if variable has not yet been set, initialize it then return it
        if (newObjectsIdMap == null) {
            newObjectsIdMap = new Map<Id, sObject>();
            if (newObjects != null) {
                Integer size = newObjects.size();
                for (Integer i = 0; i < size; i++) {
                    sObject t = newObjects[i];
                    Id recordId = t.Id;
                    if (recordId != null) {
                        newObjectsIdMap.put(recordId, t);
                    }
                }
            }
        }

        return newObjectsIdMap;
    }

    // initialize and return map of Id to Old Trigger Object
    public Map<Id, sObject> getOldObjectsIdMap() {

        // if variable has not yet been set, initialize it then return it
        if (oldObjectsIdMap == null) {
            oldObjectsIdMap = new Map<Id, sObject>();
            if (oldObjects != null) {
                Integer size = oldObjects.size();
                for (Integer i = 0; i < size; i++) {
                    sObject t = oldObjects[i];
                    Id recordId = t.Id;
                    if (recordId != null) {
                        oldObjectsIdMap.put(recordId, t);
                    }
                }
            }
        }

        return oldObjectsIdMap;
    }

    // set of ids of newObjects that have been changed and need an update
    public Set<Id> changedObjectIds;

    // stores the ids of the sObjects that have been cloned (when updating in an after context)
    // so that we don't clone more than once, wasting CPU time
    public Set<Id> clonedRecordIds = new Set<Id>();

    // prepare the sObject to be changed when running in an After context
    // by default records are read-only in After context, this creates a clone that is editable
    // also marks the record as changed so the trigger helper will perform an update on it when the trigger is done
    public sObject prepareForChange(TriggerObject o) {

        // if record has an id and is in After mode, it needs to be clone
        // before updates can be made to it
        if (o.obj.Id != null && triggerContext == 'After') {

            // clone the record if it hasn't been cloned already
            if (clonedRecordIds.contains(o.obj.Id) == false) {
                o.obj = o.obj.clone(true, true, true, true);
                clonedRecordIds.add(o.obj.Id);
            }

            // replace the record in the list and maps
            newObjects[o.index] = o.obj;

            // invalidate the maps
            newObjectsIdMap = null;
            newObjectsIndexMap = null;

            // mark the record as updated
            changedObjectIds.add(o.obj.Id);
        }

        return o.obj;

    }

    // same as above, but with the speified sObject obj at the specified index
    public sObject prepareForChange(sObject obj, Integer index) {

        // if record has an id and is in After mode, it needs to be clone
        // before updates can be made to it
        if (obj.Id != null && triggerContext == 'After') {

            // clone the record if it hasn't been cloned already
            if (clonedRecordIds.contains(obj.Id) == false) {
                obj = obj.clone(true, true, true, true);
                clonedRecordIds.add(obj.Id);
            }

            // replace the record in the list and maps
            newObjects[index] = obj;

            // invalidate the maps
            newObjectsIdMap = null;
            newObjectsIndexMap = null;

            // mark the record as updated
            changedObjectIds.add(obj.Id);
        }

        return obj;

    }

    Set<String> triggerModes = new Set<String>{'BeforeInsert',
                                               'BeforeUpdate',
                                               'AfterInsert',
                                               'AfterUpdate',
                                               'BeforeDelete',
                                               'AfterDelete',
                                               'AfterUndelete'
                                              };
    // Before or After
    public String triggerContext = null;

    // Insert, Update, Delete, Undelete
    public String triggerOperation = null;

    // constructor
    public Trigger_Helper(List<sObject> newObjects,
                                List<sObject> oldObjects,
                                String triggerContext,
                                String triggerOperation
                               ) {

        debugParams.methodName = 'constructor';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        // limit debugging
        Profiling methodProfiling;
        String limitDebug;

        if (debug || profile) {
            methodProfiling = New Profiling(debugParams, null);
            limitDebug = methodProfiling.getLimits('start ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        recursionCounter = getRecursionCount(className);

        this.triggerContext = triggerContext;
        this.triggerOperation = triggerOperation;

        if (debug) {

            //if (debug) Util_Debug.debugMessage('recursionCounter: ' + recursionCounter, debugParams);

            if (newObjects != null) {
                //if (debug) Util_Debug.debugMessage('newObjects: ' + newObjects.size(), debugParams);
            }
            if (oldObjects != null) {
                //if (debug) Util_Debug.debugMessage('oldObjects: ' + oldObjects.size(), debugParams);
            }

            //if (debug) Util_Debug.debugMessage('triggerContext: ' + triggerContext, debugParams);
            //if (debug) Util_Debug.debugMessage('triggerOperation: ' + triggerOperation, debugParams);
        }

        if (triggerModes.contains(triggerContext + triggerOperation) == false) {
            //if (debug) Util_Debug.debugMessage('Exiting early, unrecognized trigger mode: ' + triggerContext + triggerOperation, debugParams);
            return;
        }

        // set trigger variables
        Boolean isAfter = false;
        Boolean isDelete = false;

        if (triggerContext == 'After') {
            isAfter = true;
        }
        if (triggerOperation == 'Delete') {
            isDelete = true;
        }

        // initialize objects
        this.newObjects = new List<sObject>();
        this.oldObjects = new List<sObject>();

        //if (debug) Util_Debug.debugMessage('isAfter: ' + isAfter, debugParams);
        //if (debug) Util_Debug.debugMessage('isDelete: ' + isDelete, debugParams);

        // if running in delete mode, set swap newObjects and oldObjects
        if (isDelete) {
            //if (debug) Util_Debug.debugMessage('Running in delete mode, setting newObjects as oldObjects', debugParams);
            newObjects = oldObjects;
            oldObjects = null;
        }

        // if running in after trigger, make a clone of records and update the map so that updates can be made on the object
        if (isAfter == true) {

            //if (debug) Util_Debug.debugMessage('Running in after mode, cloning records', debugParams);

            // clone records so that it can be updated
            if (newObjects != null) {

                // perform a shallow copy of newObjects into this.newObjects, by creating a new collection we work around the 'collection is read only' error
                for (sObject o : newObjects) {
                    this.newObjects.add(o);
                }

            }

        // if running in before mode, just reference the records
        } else {
            //if (debug) Util_Debug.debugMessage('Running in before mode, using records as provided', debugParams);

            if (newObjects != null) {
                this.newObjects = newObjects;
            }
        }

        // old objects
        //if (debug) Util_Debug.debugMessage('Making references to old objects', debugParams);
        if (oldObjects != null) {
            this.oldObjects = oldObjects;
        }

        // initialize list of changed objects
        changedObjectIds = New Set<Id>();

        // limit debugging, adding to profile
        if (debug || profile) {
            limitDebug = methodProfiling.getLimits('end ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        //if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // Instance Methods

    // get the old version of a record based on the provided index
    public sObject getOldRecord(Integer index) {

        debugParams.methodName = 'getOldRecord';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        //if (debug) Util_Debug.debugMessage('index: ' + index, debugParams);

        sObject oldRecord = (sObject) getOldObjectsIndexMap().get(index);

        //if (debug) Util_Debug.debugMessage('end', debugParams);

        return oldRecord;

    }

    // get the old version of a record based on the provided index
    public sObject getOldRecord(Id id) {

        debugParams.methodName = 'getOldRecord';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        //if (debug) Util_Debug.debugMessage('id: ' + id, debugParams);

        sObject oldRecord = (sObject) getOldObjectsIdMap().get(id);

        //if (debug) Util_Debug.debugMessage('end', debugParams);

        return oldRecord;

    }

    // method to check either difference between old value and new value
    // checks the fields as specified by fieldNames
    // returns a list of changed records
    public List<TriggerObject> changedRecords(Set<String> fieldNames, String cacheIdentifier) {
        // set optional parameter caseSensitive=false
        return changedRecords(fieldNames, cacheIdentifier, false);
    }

    public List<TriggerObject> changedRecords(Set<String> fieldNames, String cacheIdentifier, Boolean caseSensitive) {

        debugParams.methodName = 'changedRecords';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        // limit debugging
        Profiling methodProfiling;
        String limitDebug;

        if (debug || profile) {
            methodProfiling = New Profiling(debugParams, null);
            limitDebug = methodProfiling.getLimits('start ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        //if (debug) Util_Debug.debugMessage('fieldNames: ' + fieldNames, debugParams);

        //if (debug) Util_Debug.debugMessage('Checking records for changes', debugParams);

        // force a re-check for field changes/nulls on newObjects
        List<TriggerObject> results = checkRecords(newObjects, oldObjects, fieldNames, cacheIdentifier, 'changed', caseSensitive);

        if (debug) debugObjects(results, 'results');

        // limit debugging, adding to profile
        if (debug || profile) {
            limitDebug = methodProfiling.getLimits('end ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        return results;
    }

    // method to check fieldnames for null values
    // checks the fields as specified by fieldNames
    // returns a list of changed records
    public List<TriggerObject> nulledRecords(Set<String> fieldNames, String cacheIdentifier) {

        debugParams.methodName = 'nulledRecords';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        // limit debugging
        Profiling methodProfiling;
        String limitDebug;

        if (debug || profile) {
            methodProfiling = New Profiling(debugParams, null);
            limitDebug = methodProfiling.getLimits('start ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        //if (debug) Util_Debug.debugMessage('fieldNames: ' + fieldNames, debugParams);

        //if (debug) Util_Debug.debugMessage('Checking records for nulls', debugParams);

        // force a re-check for field changes/nulls on newObjects
        List<TriggerObject> results = checkRecords(newObjects, oldObjects, fieldNames, cacheIdentifier, 'nulled', false);

        if (debug) debugObjects(results, 'results');

        // limit debugging, adding to profile
        if (debug || profile) {
            limitDebug = methodProfiling.getLimits('end ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        return results;
    }

    // method that checks each newObject and compared against the oldObject
    // fieldNames: API names of fields to check to see if they were changed/nulled
    // cacheIdentifier: String identifier that uniquely identifies which cache to check against for
    //   detecting a recursion after workflow field update
    // operationType: 'changed' or 'nulled' depending on what change we're looking for
    // caseSensitive: true the old vs. new comparison will be case sensitive, false means it won't be
    // populates the changedFields set with the API names of the fields that changed/nulled based on operationType
    //   (checking is limited to the fields within the provided fieldNames set)
    // updates the existing newObjects triggerobjects
    @TestVisible
    private List<TriggerObject> checkRecords(List<sObject> newObjects, List<sObject> oldObjects, Set<String> fieldNames, String cacheIdentifier, String operationType, Boolean caseSensitive) {

        debugParams.methodName = 'checkRecords';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        // limit debugging
        Profiling methodProfiling;
        String limitDebug;

        if (debug || profile) {
            methodProfiling = New Profiling(debugParams, null);
            limitDebug = methodProfiling.getLimits('start ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        // initialize the list of changed records to return
        List<TriggerObject> changedRecords = new List<TriggerObject>();

        //if (debug) Util_Debug.debugMessage('fieldNames: ' + fieldNames, debugParams);

        // error checking

        if (fieldNames == null || fieldNames.isEmpty() == true) {
            //if (debug) Util_Debug.debugMessage('Ending early, fieldNames is empty', debugParams);
            return changedRecords;
        }

        if (newObjects == null || newObjects.isEmpty() == true) {
            //if (debug) Util_Debug.debugMessage('Ending early, newObjects is empty', debugParams);
            return changedRecords;
        }

            // flag to indicate whether to use caching for this check
            Boolean useCache = false;

            // if a cache identifier is specified, enable caching
            if (cacheIdentifier != null) {
                useCache = true;
            }

            // static map of Record Id to Map<String, String> that represents the fields that were changed
            // the last time the method ran, and what the values were
            Map<Id, Map<String, String>> changedMap = New Map<Id, Map<String, String>>();

            // static map of Record Id to Map<String, String> that represents the fields that were nulled
            // the last time the method ran, and what the values were
            Map<Id, Map<String, String>> nulledMap = New Map<Id, Map<String, String>>();

            // initialize maps from cache
            if (useCache) {
                if (changedCacheMap.containsKey(cacheIdentifier)) {
                    changedMap = changedCacheMap.get(cacheIdentifier);
                }
                if (nulledCacheMap.containsKey(cacheIdentifier)) {
                    nulledMap = nulledCacheMap.get(cacheIdentifier);
                }
            }

            //if (debug) Util_Debug.debugMessage('changedMap: ' + changedMap, debugParams);
            //if (debug) Util_Debug.debugMessage('nulledMap: ' + nulledMap, debugParams);

            // proceed if no errors

            Integer count = newObjects.size();

            //if (debug) Util_Debug.debugMessage('count: ' + count, debugParams);

            for (Integer i = 0; i < count; i++) {

                // initialize newObject
                sObject newObject = newObjects[i];
                Integer newObjectIndex = i;

                //if (debug) Util_Debug.debugMessage('** Index:' + newObjectIndex + '**', debugParams);

                // initialize oldObject
                sObject oldObject = null;
                Integer oldObjectIndex = null;
                if (oldObjects != null && oldObjects.isEmpty() == false) {
                    oldObject = oldObjects[i];
                    oldObjectIndex = i;
                }

                // set of field names that were either changed or nulled for this record
                Set<String> changedFields = New Set<String>();

                // create an empty sObject for caching
                    //if (debug) Util_Debug.debugMessage('Creating empty maps for caching', debugParams);
                    Map<String, String> changedObject = new Map<String, String>();

                // Pull cached values from map
                    //if (debug) Util_Debug.debugMessage('Pulling cached values from map', debugParams);

                    // initialize cached map
                    Map<String, String> cachedChangedObject = new Map<String, String>();

                    if (useCache) {
                        if (operationType == 'changed' && newObject.Id != null && changedMap.containsKey(newObject.Id)) {
                            cachedChangedObject = changedMap.get(newObject.Id);
                        } else if (operationType == 'nulled' && newObject.Id != null && nulledMap.containsKey(newObject.Id)) {
                            cachedChangedObject = nulledMap.get(newObject.Id);
                        }
                    }

                    //if (debug) Util_Debug.debugMessage('cachedChangedObject: ' + cachedChangedObject, debugParams);

                // Step 1: Identify changes between old vs. new

                    //if (debug) Util_Debug.debugMessage('Identifying changes between old and new records', debugParams);

                    // loop through list of fields that we are checking against
                    for (String fieldName : fieldNames) {

                        //if (debug) Util_Debug.debugMessage('Checking field ' + fieldName, debugParams);

                        // flag to check to see if errors occurred while assigning values
                        Boolean methodError = false;

                        // initialize values from object, pulling based on the provided fieldName
                        Object newValue;
                        Object oldValue;

                        try {

                            newValue = newObject.get(fieldName);
                            oldValue = null;

                            if (oldObject != null) {
                                oldValue = oldObject.get(fieldName);
                            }

                        } catch (Exception e) {
                            methodError = true;
                            hasErrors = true;
                            processError(getNewObjectsIdMap().keySet(), 'An exception occurred while checking for field changes', e, new Debug(debugParams));
                        }

                        //if (debug) Util_Debug.debugMessage('Comparing new value: ' + newValue + ' against old value: ' + oldValue, debugParams);

                        // if there was no error in pulling the fieldname, and
                        // if value is different between old/new
                        // todo: treat '' and null the same?
                        if (methodError == false && operationType == 'changed') {

                            // flag to indicate a change was found
                            Boolean changeFound = false;

                            // if not performing a case-sensitive comparison
                            if (caseSensitive == false) {

                                // perform comparison and store result
                                changeFound = oldValue != newValue;

                            // if performing a case-sensitive comparison
                            } else {

                                // flag to indicate comparison should be done as strings
                                Boolean compareAsStrings = true;

                                // initialize the string versions of
                                String oldValueString = null;
                                String newValueString = null;

                                // if one value is null, don't compare as strings
                                if (oldValue == null || newValue == null) {
                                    compareAsStrings = false;
                                }

                                // try to convert the data to strings
                                try {

                                    if (testMode == 2) {
                                        insert new Contact();
                                    }

                                    oldValueString = String.valueOf(oldValue);
                                    newValueString = String.valueOf(newValue);

                                } catch (Exception e) {
                                    // if conversion failed, don't compare as strings
                                    compareAsStrings = false;
                                }

                                if (debug) Util_Debug.debugMessage('compareAsStrings: ' + compareAsStrings, debugParams);

                                // if comparing as strings, do a case-sensitive comparison
                                if (compareAsStrings == true && oldValueString.equals(newValueString) == false) {
                                    changeFound = true;

                                // if not comparing as strings, do an != comparison
                                } else if (compareAsStrings == false && oldValue != newValue) {
                                    changeFound = true;
                                }

                            }

                            if (debug) Util_Debug.debugMessage('changeFound: ' + changeFound, debugParams);

                            if (changeFound) {

                                //if (debug) Util_Debug.debugMessage('Field ' + fieldName + ' is changed on record index ' + newObjectIndex, debugParams);

                                // add the field to the list that matched
                                changedFields.add(fieldName);

                                // if the cache map contains this field
                                if (useCache) {

                                    //if (debug) Util_Debug.debugMessage('Checking to see if this change was already detected in the last check that was cached', debugParams);

                                    // initialize the value we'll be putting into the cache
                                    String valueForCache = null;

                                    // define the value to put into the cache
                                    if (triggerOperation == 'Delete') {
                                        valueForCache = null;
                                    } else {
                                        valueForCache = String.valueOf(newValue);
                                    }

                                    // if this field is present in the cache
                                    if (cachedChangedObject.containsKey(fieldName)) {

                                        // get the old cached value
                                        String oldCachedValue = cachedChangedObject.get(fieldName);

                                        //if (debug) Util_Debug.debugMessage('valueForCache: ' + valueForCache, debugParams);
                                        //if (debug) Util_Debug.debugMessage('oldCachedValue: ' + oldCachedValue, debugParams);

                                        // if value is the same between old/new
                                        if (oldCachedValue == valueForCache) {

                                            //if (debug) Util_Debug.debugMessage('Field ' + fieldName + ' is the same as cached value. Removing from changed fields.', debugParams);

                                            // remove field from list of changed fields
                                            changedFields.remove(fieldName);
                                        }
                                    }

                                    // store the new value into the cache object
                                    changedObject.put(fieldName, valueForCache);

                                }

                            }

                        // if there was no error in pulling the fieldname, and
                        // if the new value is null
                        } else if (methodError == false && operationType == 'nulled' && (triggerOperation == 'Delete' || newValue == null)) {

                            //if (debug) Util_Debug.debugMessage('Field ' + fieldName + ' is null on record index ' + newObjectIndex, debugParams);

                            // add the field to the list that matched
                            changedFields.add(fieldName);

                            // if the cache map contains this field
                            if (useCache) {

                                //if (debug) Util_Debug.debugMessage('Checking to see if this change was already detected in the last check that was cached', debugParams);

                                // initialize the value we'll be putting into the cache
                                String valueForCache = null;

                                // define the value to put into the cache
                                if (triggerOperation == 'Delete') {
                                    valueForCache = null;
                                } else {
                                    valueForCache = String.valueOf(newValue);
                                }

                                // if this field is present in the cache
                                if (cachedChangedObject.containsKey(fieldName)) {

                                    // get the old cached value
                                    String oldCachedValue = cachedChangedObject.get(fieldName);

                                    //if (debug) Util_Debug.debugMessage('valueForCache: ' + valueForCache, debugParams);
                                    //if (debug) Util_Debug.debugMessage('oldCachedValue: ' + oldCachedValue, debugParams);

                                    // if value is the same between old/new
                                    if (oldCachedValue == valueForCache && valueForCache == null) {

                                        //if (debug) Util_Debug.debugMessage('Field ' + fieldName + ' is the same as cached value. Removing from nulled fields.', debugParams);

                                        // remove field from list of changed fields
                                        changedFields.remove(fieldName);
                                    }
                                }

                                // store the new value into the cache object
                                changedObject.put(fieldName, valueForCache);

                            }
                        }

                    }

                //if (debug) Util_Debug.debugMessage('changedFields: ' + changedFields, debugParams);
                //if (debug) Util_Debug.debugMessage('changedObject: ' + changedObject, debugParams);

                // Step 3: Add values to cache

                    if (useCache) {
                        //if (debug) Util_Debug.debugMessage('Adding values to cache', debugParams);

                        // add record's changed fields to static map for the next pass
                        if (operationType == 'changed' && newObject.Id != null && changedObject.isEmpty() == false) {
                            changedMap.put(newObject.Id, changedObject);

                        // add record's changed fields to static map for the next pass
                        } else if (operationType == 'nulled' && newObject.Id != null && changedObject.isEmpty() == false) {
                            nulledMap.put(newObject.Id, changedObject);
                        }
                    }

                // Step 5: Update object with results

                    // update the trigger object with the results
                    if (changedFields.isEmpty() == false) {
                        // initialize trigger object
                        TriggerObject o = new TriggerObject(newObjects[i], i);

                        // set the fields that changed
                        o.changedFields = changedFields;

                        // add to results to return
                        changedRecords.add(o);
                    }

            }

            // update static maps
            if (useCache) {
                //if (debug) Util_Debug.debugMessage('changedMap: ' + changedMap, debugParams);
                //if (debug) Util_Debug.debugMessage('nulledMap: ' + changedMap, debugParams);

                updateChangedCacheMap(cacheIdentifier, changedMap);
                updateNulledCacheMap(cacheIdentifier, nulledMap);
            }

        // limit debugging, adding to profile
        if (debug || profile) {
            limitDebug = methodProfiling.getLimits('end ' + debugParams.methodName);
            Util_Debug.debugMessage(limitDebug, debugParams);
        }

        //if (debug) Util_Debug.debugMessage('end', debugParams);

        return changedRecords;
    }

    // method to perform update on changed records that have been
    // flagged as changed in changedObjectIds
    public void updateRecords() {

        debugParams.methodName = 'updateRecords';

        //if (debug) Util_Debug.debugMessage('start', debugParams);

        // initialize list of records to update
        List<sObject> recordsToUpdate = New List<sObject>();

        // if at least one account marked for update
        if (changedObjectIds.isEmpty() == false) {

            // loop through record ids to update and add to the update list
            for (Id id : changedObjectIds) {

                // get record to update by index
                sObject o = getNewObjectsIdMap().get(id);

                // if the record has an Id, add to list to update
                //if (debug) Util_Debug.debugMessage('Adding record to update:', debugParams);
                //if (debug) Util_Debug.debugMessage(o.debug(), debugParams);

                // add to list to update
                recordsToUpdate.add(o);
            }

            // reset changed object ids for the next recursion
            changedObjectIds = new Set<Id>();
        }

        // if at least one record to update
        if (recordsToUpdate.isEmpty() == false) {

            //if (debug) Util_Debug.debugMessage('Updating records', debugParams);

            try {

                // if test mode flag set, cause DML exception
                if (testMode == 1) {
                    insert New Contact();
                }

                update recordsToUpdate;

            } catch (Exception e) {
                hasErrors = true;
                processError(changedObjectIds, 'An error occurred while updating records', e, new Debug(debugParams));
            }

        // if no records to update
        } else {
            //if (debug) Util_Debug.debugMessage('No records to update', debugParams);
        }

        //if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // method for debugging a list of trigger objects
    public List<String> debugObjects(List<TriggerObject> objects, String label) {

        List<String> messages = New List<String>();

        Integer objectSize = null;

        if (objects != null) {
            objectSize = objects.size();
        }

        messages.add(label + ', size: ' + objectSize);

        if (objects != null && objects.isEmpty() == false) {

            Integer size = objects.size();
            for (Integer i = 0; i < size; i++) {
                TriggerObject o = objects[i];
                messages.addAll(o.debug());
            }
        }

        return messages;
    }

    // Static methods

    // public static method for processing errors that occur in trigger handlers that use this class
    // logs the error, and returns the error message
    public static String processError(Trigger_Helper triggerHelper, String message, Exception e, Debug debugParams) {
        return Error_Handler.processError(triggerHelper, message, e, new Debug(debugParams), true);
    }

    // public static method for processing errors that occur in trigger handlers that use this class
    // logs the error, and returns the error message
    public static String processError(Set<Id> idsAffected, String message, Exception e, Debug debugParams) {
        return Error_Handler.processError(idsAffected, message, e, new Debug(debugParams), true);
    }

    // reset cache map
    public static void resetCache() {
        changedCacheMap = New Map<String, Map<Id, Map<String, String>>>();
        nulledCacheMap = New Map<String, Map<Id, Map<String, String>>>();
    }

    // debug changed cache map
    public static List<String> debugChangedMap() {
        return debugCacheMap(changedCacheMap);
    }

    // debug nulled cache map
    public static List<String> debugNulledMap() {
        return debugCacheMap(nulledCacheMap);
    }

    // debug changed cache map
    public static Integer changedMapSize() {
        return cacheMapSize(changedCacheMap);
    }

    // debug nulled cache map
    public static Integer nulledMapSize() {
        return cacheMapSize(nulledCacheMap);
    }

    // count # of entries in cache map
    private static Integer cacheMapSize(Map<String, Map<Id, Map<String, String>>> cacheMap) {

        Integer count = 0;

        // if the cache exists
        if (cacheMap != null) {

            // loop through cache identifiers
            if (cacheMap.keySet().isEmpty() == false) {
                for (String cacheIdentifier : cacheMap.keySet()) {

                    // get records within the map for this cache identifier
                    Map<Id, Map<String, String>> recordMap = cacheMap.get(cacheIdentifier);

                    if (recordMap != null) {
                        count += recordMap.keySet().size();
                    }

                }
            }
        }

        return count;

    }

    // debug cache map
    private static List<String> debugCacheMap(Map<String, Map<Id, Map<String, String>>> cacheMap) {

        List<String> messages = New List<String>();

        // if the cache exists
        if (cacheMap != null) {

            messages.add('**cacheMap.keySet(): (' + cacheMap.keySet().size() + ') : ' + cacheMap.keySet());

            // loop through cache identifiers
            if (cacheMap.keySet().isEmpty() == false) {
                for (String cacheIdentifier : cacheMap.keySet()) {

                    // get records within the map for this cache identifier
                    Map<Id, Map<String, String>> recordMap = cacheMap.get(cacheIdentifier);

                    messages.add('**cacheMap.' + cacheIdentifier + ': (' + recordMap.keySet().size() + ')');

                    // loop through records
                    if (recordMap != null && recordMap.keySet().isEmpty() == false) {
                        for (Id recordId : recordMap.keySet()) {

                            // get the fields that are cached
                            Map<String, String> fieldMap = recordMap.get(recordId);

                            List<String> fieldOutput = new List<String>();

                            // loop through fields that are cached for the record
                            if (fieldMap != null && fieldMap.keySet().isEmpty() == false) {

                                for (String fieldName : fieldMap.keySet()) {
                                    // output field value
                                    String fieldValue = fieldMap.get(fieldName);
                                    fieldOutput.add(fieldName + '=' + fieldValue);
                                }
                            }

                            messages.add('**cacheMap.' + cacheIdentifier + '.' + recordId + ' => ' + Util_CSV.csvString(fieldOutput, false, false, ', '));

                        }
                    }
                }
            }
        }

        return messages;

    }

    // update cache map for the specified cacheIdentifier, adding the cache values for the specified record ids
    // within cacheMap without overwriting or conflicting with other record ids that another process may be attempting
    // to write to
    public static void updateChangedCacheMap(String cacheIdentifier, Map<Id, Map<String, String>> cacheMap) {
        debugParams.methodName = 'updateChangedCacheMap';

        //if (debug) Util_Debug.debugMessage('start', debugParams);
        //if (debug) Util_Debug.debugMessage('cacheIdentifier: ' + cacheIdentifier, debugParams);
        //if (debug) Util_Debug.debugMessage('cacheMap: ' + cacheMap, debugParams);

        if (cacheMap != null && cacheIdentifier != null) {

            // initialize map if empty
            if (changedCacheMap.containsKey(cacheIdentifier) == false) {
                changedCacheMap.put(cacheIdentifier, New Map<Id, Map<String, String>>());
            }

            // loop through map we're adding and add to the cache map
            for (Id recordId : cacheMap.keySet()) {
                Map<String, String> obj = cacheMap.get(recordId);
                //if (debug) Util_Debug.debugMessage('recordId: ' + recordId, debugParams);
                //if (debug) Util_Debug.debugMessage('obj: ' + obj, debugParams);
                changedCacheMap.get(cacheIdentifier).put(recordId, obj);
            }
        }

        //if (debug) Util_Debug.debugMessage('changedCacheMap: ' + changedCacheMap, debugParams);

        //if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // update cache map for the specified cacheIdentifier, adding the cache values for the specified record ids
    // within cacheMap without overwriting or conflicting with other record ids that another process may be attempting
    // to write to
    public static void updateNulledCacheMap(String cacheIdentifier, Map<Id, Map<String, String>> cacheMap) {
        debugParams.methodName = 'updateNulledCacheMap';

        //if (debug) Util_Debug.debugMessage('start', debugParams);
        //if (debug) Util_Debug.debugMessage('cacheIdentifier: ' + cacheIdentifier, debugParams);
        //if (debug) Util_Debug.debugMessage('cacheMap: ' + cacheMap, debugParams);

        if (cacheMap != null && cacheIdentifier != null) {

            // initialize map if empty
            if (nulledCacheMap.containsKey(cacheIdentifier) == false) {
                nulledCacheMap.put(cacheIdentifier, New Map<Id, Map<String, String>>());
            }

            // loop through map we're adding and add to the cache map
            for (Id recordId : cacheMap.keySet()) {
                Map<String, String> obj = cacheMap.get(recordId);
                //if (debug) Util_Debug.debugMessage('recordId: ' + recordId, debugParams);
                //if (debug) Util_Debug.debugMessage('obj: ' + obj, debugParams);
                nulledCacheMap.get(cacheIdentifier).put(recordId, obj);
            }
        }

        //if (debug) Util_Debug.debugMessage('nulledCacheMap: ' + nulledCacheMap, debugParams);

        //if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // take a set of trigger objects and field names and update the cache map with their latest values
    public void updateCacheLatestValues(List<Trigger_Helper.TriggerObject> changedRecords, String cacheIdentifier, Set<String> checkFields) {

        debugParams.methodName = 'updateCacheLatestValues';

        //if (debug) Util_Debug.debugMessage('start', debugParams);
        //if (debug) Util_Debug.debugMessage('cacheIdentifier: ' + cacheIdentifier, debugParams);
        //if (debug) Util_Debug.debugMessage('changedRecords: ' + changedRecords.size(), debugParams);
        //if (debug) Util_Debug.debugMessage('checkFields: ' + checkFields, debugParams);

        // update the cache map with the latest version of the checked fields, in case this method changed thos fields, to prevent recursion
        Map<Id, Map<String, String>> updateCacheMap = new Map<Id, Map<String, String>>();

        for (TriggerObject o : changedRecords) {

            // cast record
            sObject obj = (sObject) o.obj;

            if (obj.Id != null) {
                Map<String, String> cacheMapFields = new Map<String, String>();
                for (String checkField : checkFields) {
                    cacheMapFields.put(checkField, String.valueOf(obj.get(checkField)));
                }
                updateCacheMap.put(obj.Id, cacheMapFields);
            }

        }

        // update the global cache map for this method
        updateChangedCacheMap(cacheIdentifier, updateCacheMap);


        //if (debug) Util_Debug.debugMessage('end', debugParams);
    }

    // create a string to represent what context the trigger is running in
    public static String triggerContext(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete) {

        debugParams.methodName = 'triggerContext';

        if (debug) Util_Debug.debugMessage('start', debugParams);

        String triggerContext = '';

        if (isBefore && isInsert) {
            triggerContext = 'Before Insert';
        } else if (isBefore && isUpdate) {
            triggerContext = 'Before Update';
        } else if (isBefore && isDelete) {
            triggerContext = 'Before Delete';
        } else if (isAfter && isInsert) {
            triggerContext = 'After Insert';
        } else if (isAfter && isUpdate) {
            triggerContext = 'After Update';
        } else if (isAfter && isDelete) {
            triggerContext = 'After Delete';
        } else if (isAfter && isUndelete) {
            triggerContext = 'After Undelete';
        }

        if (debug) Util_Debug.debugMessage('triggerContext: ' + triggerContext, debugParams);
        if (debug) Util_Debug.debugMessage('end', debugParams);

        return triggerContext;
    }

}