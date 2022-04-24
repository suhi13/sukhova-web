[
    {
      "name": "${name}",
      "image": "${container_image}",
      "cpu": ${cpu},
      "memory": ${memory},
      "memoryReservation": ${memory},
      "environment": [
        { "name" : "JAVA_OPTS", "value" : "-Dsonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false" }
      ],
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${sonar_port}
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${log_group}",
            "awslogs-region": "${region}",
            "awslogs-stream-prefix": "sonar"
        }
      },
      "secrets": [
        {
          "name": "ADMIN_PWD",
          "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/jenkins-pwd"
        }
      ]
    }
]
  