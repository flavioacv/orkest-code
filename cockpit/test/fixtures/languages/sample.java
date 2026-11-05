// Java sample fixture
package com.orkest.sample;

public class TaskRunner {
    private final String taskId;

    public TaskRunner(String taskId) {
        this.taskId = taskId;
    }

    public void execute() {
        System.out.println("Executing " + taskId);
    }
}
