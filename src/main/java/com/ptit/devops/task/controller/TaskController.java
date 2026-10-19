package com.ptit.devops.task.controller;

import com.ptit.devops.task.entity.Task;
import com.ptit.devops.task.repository.TaskRepository;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class TaskController {

    private final TaskRepository repository;

    public TaskController(TaskRepository repository) {
        this.repository = repository;
    }

    /** GET /api/tasks - danh sách công việc */
    @GetMapping("/tasks")
    public List<Task> findAll() {
        return repository.findAll(Sort.by("id"));
    }
}
