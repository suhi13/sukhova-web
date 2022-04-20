jenkins:
    systemMessage: "Amazon Fargate"
    numExecutors: 0
    remotingSecurity:
      enabled: true
    agentProtocols:
        - "JNLP4-connect"
    securityRealm:
        local:
            allowsSignup: false
            users:
                - id: ecsuser
                  password: \$${ADMIN_PWD}
    authorizationStrategy:
        globalMatrix:
            grantedPermissions:
                - "Overall/Read:authenticated"
                - "Job/Read:authenticated"
                - "View/Read:authenticated"
                - "Overall/Administer:authenticated"
    crumbIssuer: "standard"
    slaveAgentPort: 50000
    clouds:
        - ecs:
              allowedOverrides: "inheritFrom,label,memory,cpu,image"
              credentialsId: ""
              cluster: ${ecs_cluster_fargate_spot}
              name: "fargate-cloud-spot"
              regionName: ${cluster_region}
              retentionTimeout: 10
              jenkinsUrl: "http://${jenkins_cloud_map_name}:${jenkins_controller_port}"
              templates:
                  - cpu: "512"
                    image: "jenkins/inbound-agent"
                    label: "build-example-spot"
                    executionRole: ${execution_role_arn}
                    launchType: "FARGATE"
                    memory: 0
                    memoryReservation: 1024
                    networkMode: "awsvpc"
                    privileged: false
                    remoteFSRoot: "/home/jenkins"
                    securityGroups: ${agent_security_groups}
                    sharedMemorySize: 0
                    subnets: ${subnets}
                    templateName: "build-example"
                    uniqueRemoteFSRoot: false
        - ecs:
              allowedOverrides: "inheritFrom,label,memory,cpu,image"
              credentialsId: ""
              cluster: ${ecs_cluster_fargate}
              name: "fargate-cloud"
              regionName: ${cluster_region}
              retentionTimeout: 10
              jenkinsUrl: "http://${jenkins_cloud_map_name}:${jenkins_controller_port}"
              templates:
                  - cpu: "512"
                    image: "jenkins/inbound-agent"
                    label: "build-example"
                    executionRole: ${execution_role_arn}
                    launchType: "FARGATE"
                    memory: 0
                    memoryReservation: 1024
                    networkMode: "awsvpc"
                    privileged: false
                    remoteFSRoot: "/home/jenkins"
                    securityGroups: ${agent_security_groups}
                    sharedMemorySize: 0
                    subnets: ${subnets}
                    templateName: "build-example"
                    uniqueRemoteFSRoot: false
        - ecs:
            allowedOverrides: "inheritFrom,label,memory,cpu,image"
            credentialsId: ""
            cluster: ${ecs_cluster_fargate}
            jenkinsUrl: "http://${jenkins_cloud_map_name}:${jenkins_controller_port}"
            name: "ecs-cloud"
            regionName: ${cluster_region}
            retentionTimeout: 10
            templates:
              - assignPublicIp: false
                capacityProviderStrategies:
                  - base: 0
                    provider: ${ec2_capacity_provider}
                    weight: 0
                containerUser: "root"
                cpu: 0
                defaultCapacityProvider: false
                executionRole: ${execution_role_arn}
                image: ${ec2builder_image}
                label: "ec2-builder"
                launchType: "EC2"
                memory: 0
                memoryReservation: 1000
                mountPoints:
                  - containerPath: "/var/run/docker.sock"
                    name: "Docker"
                    readOnly: false
                    sourcePath: "/var/run/docker.sock"
                  - containerPath: "/home/jenkins"
                    name: "Jenkins"
                    readOnly: false
                    sourcePath: "/tmp"
                networkMode: "awsvpc"
                platformVersion: "LATEST"
                privileged: true
                remoteFSRoot: "/home/jenkins"
                securityGroups: ${agent_security_groups}
                sharedMemorySize: 0
                subnets: ${subnets}
                templateName: "ec2-builder"
                uniqueRemoteFSRoot: false
security:
  sSHD:
    port: -1
jobs:
  - script: >
      pipelineJob('sukhova-shopizer') {
        definition {
          cpsScm {
            scm {
              git {
                remote { url('https://github.com/suhi13/sukhova-web.git') }
                branches('development')
                scriptPath('jobs/shopizer/Jenkinsfile')
                extensions { }
              }
            }
          }
        }
      }
