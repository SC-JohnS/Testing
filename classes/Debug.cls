public without sharing class Debug {

    public String className;
    public String methodName;
    public String debugPrefix;

    public Boolean debug;
    public Boolean profile;

    public Debug(String className) {
        this.className = className;
        this.methodName = '';
        this.debugPrefix = '';

        this.debug = false;
        this.profile = false;
    }

    public Debug(String className, String methodName, String debugPrefix, Boolean debug, Boolean profile) {
        this.className = className;
        this.methodName = methodName;
        this.debugPrefix = debugPrefix;

        this.debug = debug;
        this.profile = profile;
    }

    public Debug(Debug debugParams) {
        this.className = debugParams.className;
        this.methodName = debugParams.methodName;
        this.debugPrefix = debugParams.debugPrefix;

        this.debug = debugParams.debug;
        this.profile = debugParams.profile;
    }

}