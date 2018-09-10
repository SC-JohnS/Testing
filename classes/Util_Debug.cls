// Class for printing debug messages to the log at the ERROR severity level
// Outputs a prefix before the message that includes the class name, method name, and a debug prefix
// Debug prefix indicates what level of recursion the statement is at
// The prefix+class+name is outputted with a fixed width
public without sharing class Util_Debug {

    // fixed width to apply to the prefix+class+method part of the debug message
    private static Integer fixedWidth = 45;

    // public method for printing one debug message
    public static void debugMessage(String message, Debug params) {
        String left = params.debugPrefix + params.className + '.' + params.methodName;
        system.debug(LoggingLevel.ERROR, left.rightPad(fixedWidth) + ': ' + message);
    }

    // public method for printing many debug messages
    public static void debugMessage(List<String> messages, Debug params) {
        if (messages.isEmpty() == false) {
            for (String message : messages) {
                String left = params.debugPrefix + params.className + '.' + params.methodName;
                system.debug(LoggingLevel.ERROR, left.rightPad(fixedWidth) + ': ' + message);
            }
        }
    }
}