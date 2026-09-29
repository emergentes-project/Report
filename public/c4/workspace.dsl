workspace "Lifeline" "Arquitectura C4 de Lifeline (RescueBridge): orientacion de primeros auxilios offline-first con IA on-device, RAG local y sincronizacion hacia un backend modular." {

    model {
        ciudadano = person "Ciudadano" "Persona afectada por un sismo que necesita orientacion inmediata de primeros auxilios, incluso sin conexion a internet."
        personalMedico = person "Personal medico" "Medico, paramedico u otro profesional autorizado que visualiza, asigna, atiende y cierra casos sincronizados."

        cloudinary = softwareSystem "Cloudinary" "Servicio externo de almacenamiento, transformacion y entrega de evidencias fotograficas de las consultas." {
            tags "External"
        }

        lifeline = softwareSystem "Lifeline" "Plataforma movil offline-first que brinda orientacion de primeros auxilios mediante IA on-device y RAG, y sincroniza los casos con un backend modular cuando existe conectividad." {

            mobileApp = container "Mobile App" "Aplicacion movil multimodal y offline-first para consultas de emergencia, orientacion paso a paso, gestion de casos, Hoja Consultativa y Medical Bases." "Flutter/Dart" {
                tags "Mobile"

                emergencyUi = component "Emergency Consultation UI" "Permite registrar una emergencia mediante texto, voz o fotografia y presenta las indicaciones en pasos simples y comprensibles." "Flutter Widget" {
                    tags "Ui"
                }
                consultationService = component "Consultation Service" "Orquesta el flujo de consulta, solicita conocimiento medico, coordina la inferencia local y controla la generacion de la orientacion." "Dart Application Service" {
                    tags "Service"
                }
                localPersistence = component "Local Persistence and Sync" "Gestiona la persistencia local, Transactional Outbox, estados pending/synced y reintentos de sincronizacion cuando retorna la conectividad." "Drift/SQLite + Transactional Outbox" {
                    tags "Infra"
                }
                onDeviceAi = component "On-Device AI Engine" "Ejecuta localmente el modelo de IA utilizando la consulta y el contexto medico recuperado mediante RAG, sin depender de internet." "On-device LLM Runtime" {
                    tags "Infra"
                }
                consultationDomain = component "Consultation Domain" "Modela la consulta, evidencias, severidad y orientacion. Aplica reglas de seguridad y validacion antes de presentar una respuesta." "Dart Domain Model" {
                    tags "Domain"
                }
                medicalKnowledgeApi = component "Medical Knowledge API" "Open Host Service local que expone a Consultation la capacidad de recuperar conocimiento medico relevante." "OHS / Published Language" {
                    tags "PublishedLanguage"
                }
                medicalKnowledgeService = component "Medical Knowledge Service" "Coordina la recuperacion de conocimiento y prioriza el uso de fuentes medicas previamente validadas." "Dart Application Service" {
                    tags "Service"
                }
                semanticRetriever = component "Semantic Retriever" "Realiza busqueda semantica y selecciona los fragmentos medicos relevantes utilizados en el proceso RAG." "On-device Embedding Engine" {
                    tags "Domain"
                }
                knowledgeRepository = component "Knowledge Repository" "Accede al indice medico precargado y lo consume localmente en el dispositivo." "Local Vector Store Adapter" {
                    tags "Infra"
                }
            }

            localDb = container "Local Database" "Persistencia offline de consultas, evidencias, estados y registros Outbox pendientes de sincronizacion." "SQLite" {
                tags "Database"
            }

            medicalStore = container "Medical Knowledge Store" "Indice medico local compuesto por fuentes previamente validadas y utilizado por RAG para sustentar la orientacion." "Local Vector / ONNX Runtime" {
                tags "KnowledgeStore"
            }

            loadBalancer = container "Load Balancer" "Punto de entrada HTTPS que realiza health checks y distribuye solicitudes entre instancias saludables del Backend Modular API." "HAProxy" {
                tags "LoadBalancer"
            }

            backend = container "Backend Modular API" "Monolito modular que aloja IAM y Case Management y orquesta la sincronizacion de consultas provenientes del dispositivo movil." "Spring Boot" {
                tags "Backend"

                caseManagementApi = component "Case Management API" "Expone las operaciones necesarias para sincronizar, visualizar, autoasignar, atender y cerrar casos." "Spring REST Controller" {
                    tags "Api"
                }
                caseManagementService = component "Case Management Service" "Coordina el ciclo de vida de los casos, la sincronizacion idempotente y la autorizacion de las operaciones realizadas por el personal medico." "Spring Service" {
                    tags "Service"
                }
                asyncPublisher = component "Async Event Publisher" "Publica tareas secundarias en el Message Broker sin bloquear la solicitud HTTP principal." "RabbitMQ Adapter" {
                    tags "Infra"
                }
                caseRepository = component "Case Repository" "Implementa la persistencia y recuperacion de casos y su historial de cambios." "Spring Data JPA" {
                    tags "Infra"
                }
                caseDomain = component "Case Domain" "Modela los estados disponible, asignado, en atencion y cerrado, incluyendo reglas de transicion y prevencion de doble asignacion." "Java Domain Model" {
                    tags "Domain"
                }
                iamInterface = component "IAM Interface" "Expone autenticacion, consulta de identidad, perfiles y roles mediante endpoints REST y contratos internos." "Spring REST Controller" {
                    tags "Api"
                }
                iamService = component "IAM Service" "Coordina autenticacion, sesiones, recuperacion de perfiles y autorizacion de ciudadanos y personal medico." "Spring Service" {
                    tags "Service"
                }
                iamRepository = component "IAM Repository" "Implementa persistencia y recuperacion de usuarios, perfiles y roles." "Spring Data JPA" {
                    tags "Infra"
                }
                identityDomain = component "Identity and Access Domain" "Modela usuarios, perfiles, roles y las reglas de autorizacion." "Java Domain Model" {
                    tags "Domain"
                }
            }

            messageBroker = container "Message Broker" "Descarga tareas secundarias y absorbe picos de sincronizacion mediante procesamiento asincrono." "RabbitMQ" {
                tags "Broker"
            }

            asyncWorkers = container "Async Workers" "Procesan tareas asincronas consumiendo desde RabbitMQ sin mantener ocupados los recursos HTTP del backend." "Spring Boot / RabbitMQ" {
                tags "Worker"
            }

            cloudDb = container "Cloud Database" "Fuente de verdad cloud para identidades, roles, casos, estados e historial." "PostgreSQL" {
                tags "Database"
            }
        }

        ciudadano -> lifeline "Solicita orientacion de primeros auxilios y consulta el estado de sus casos"
        personalMedico -> lifeline "Gestiona y atiende casos sincronizados"
        lifeline -> cloudinary "Almacena y entrega evidencias fotograficas de consultas y casos" "HTTPS/REST"

        ciudadano -> mobileApp "Registra emergencia y recibe orientacion paso a paso"
        personalMedico -> mobileApp "Visualiza, asigna, atiende y cierra casos cuando hay conectividad"
        mobileApp -> loadBalancer "Sincroniza consultas, casos y estado" "HTTPS/JSON"
        mobileApp -> localDb "Persiste consultas, evidencias, estado local y Outbox" "SQL"
        mobileApp -> medicalStore "Recupera conocimiento medico local para RAG"
        loadBalancer -> backend "Distribuye solicitudes hacia instancias saludables" "HTTPS"
        backend -> messageBroker "Publica trabajos secundarios" "AMQP"
        backend -> cloudDb "Lee y actualiza identidades, casos y estados" "SQL/TLS"
        backend -> cloudinary "Almacena y entrega evidencias fotograficas sincronizadas" "HTTPS/REST"
        messageBroker -> asyncWorkers "Entrega trabajos secundarios" "AMQP"
        asyncWorkers -> cloudDb "Persiste resultados del procesamiento asincrono" "SQL/TLS"

        ciudadano -> emergencyUi "Describe la emergencia mediante texto, voz o fotografia"
        emergencyUi -> consultationService "Envia la consulta multimodal"
        consultationService -> onDeviceAi "Solicita orientacion utilizando consulta y contexto medico"
        consultationService -> localPersistence "Persiste la consulta y registra la sincronizacion pendiente"
        consultationService -> medicalKnowledgeApi "Solicita contexto medico relevante" "OHS/Published Language"
        consultationService -> consultationDomain "Ejecuta reglas del flujo de consulta"
        onDeviceAi -> consultationDomain "Entrega el borrador para validacion de seguridad y grounding"
        localPersistence -> localDb "Lee y escribe consultas, evidencias y Outbox" "SQL"
        localPersistence -> loadBalancer "Sincroniza operaciones pendientes al recuperar conectividad" "HTTPS/JSON"

        medicalKnowledgeApi -> medicalKnowledgeService "Solicita recuperacion de conocimiento"
        medicalKnowledgeService -> semanticRetriever "Inyecta la consulta, metadatos y/o fuentes validadas"
        semanticRetriever -> knowledgeRepository "Extrae fragmentos medicos relevantes"
        knowledgeRepository -> medicalStore "Consulta el indice medico local"

        loadBalancer -> caseManagementApi "Enruta sincronizacion y operaciones sobre casos" "HTTPS"
        loadBalancer -> iamInterface "Enruta autenticacion y operaciones de identidad" "HTTPS"
        caseManagementApi -> caseManagementService "Ejecuta comandos y consultas de Case Management"
        caseManagementService -> asyncPublisher "Delega procesamiento secundario"
        caseManagementService -> caseRepository "Persiste o consulta casos"
        caseManagementService -> caseDomain "Aplica reglas y transiciones del ciclo de vida"
        caseManagementService -> iamInterface "Consulta identidad y rol del profesional" "Internal Contract"
        caseManagementService -> cloudinary "Almacena y obtiene evidencias fotograficas del caso" "HTTPS/REST"
        asyncPublisher -> messageBroker "Publica trabajo sin bloquear la solicitud principal" "AMQP"
        caseRepository -> cloudDb "Lee y escribe casos e historial" "SQL/TLS"

        iamInterface -> iamService "Solicita autenticacion, perfil o validacion de rol"
        iamService -> iamRepository "Consulta o actualiza usuarios y perfiles"
        iamService -> identityDomain "Aplica reglas de identidad y autorizacion"
        iamRepository -> cloudDb "Persiste identidades, perfiles y roles" "SQL/TLS"

        live = deploymentEnvironment "Produccion" {
            deploymentNode "Smartphone" "Dispositivo movil del ciudadano o del personal medico" "Android/iOS" {
                containerInstance mobileApp
                containerInstance localDb
                containerInstance medicalStore
            }

            deploymentNode "Microsoft Azure" "Nube de despliegue del backend modular" "Azure" {
                deploymentNode "Ingress / Load Balancing" "Punto de entrada HTTPS y health checks" "Azure Load Balancer / HAProxy" {
                    containerInstance loadBalancer
                }

                deploymentNode "Backend Pool" "Pool de instancias saludables del monolito modular" "Azure App Service" {
                    deploymentNode "Backend Instance A" "Instancia Spring Boot" "Spring Boot" {
                        containerInstance backend
                    }
                    deploymentNode "Backend Instance B" "Instancia Spring Boot" "Spring Boot" {
                        containerInstance backend
                    }
                }

                deploymentNode "Messaging" "Cola de trabajos secundarios y picos de sincronizacion" "Azure / RabbitMQ" {
                    containerInstance messageBroker
                }

                deploymentNode "Worker Compute" "Procesamiento asincrono desacoplado del HTTP" "Azure App Service" {
                    containerInstance asyncWorkers
                }

                deploymentNode "Relational Database" "Fuente de verdad cloud" "Azure Database for PostgreSQL" {
                    containerInstance cloudDb
                }
            }

            deploymentNode "Cloudinary Cloud" "SaaS externo de media" "Cloudinary" {
                softwareSystemInstance cloudinary
            }
        }
    }

    views {
        systemLandscape landscape {
            title "Lifeline - C1 System Landscape"
            include *
            autoLayout lr
        }

        systemContext lifeline c1 {
            title "Lifeline - C1 System Context"
            include *
            autoLayout lr
        }

        container lifeline c2 {
            title "Lifeline - C2 Container Diagram"
            include *
            autoLayout lr
        }

        component mobileApp C3-Consultation {
            title "Lifeline - C3 Consultation Bounded Context"
            description "Consulta multimodal, reglas de asistencia, inferencia on-device, persistencia offline y sincronizacion."
            include emergencyUi consultationService localPersistence onDeviceAi consultationDomain medicalKnowledgeApi
            include ciudadano localDb loadBalancer
            autoLayout lr
        }

        component mobileApp C3-MedicalBases {
            title "Lifeline - C3 Medical Bases Bounded Context"
            description "Recuperacion semantica mediante RAG sobre una base de conocimiento medico local validada."
            include consultationService medicalKnowledgeApi medicalKnowledgeService semanticRetriever knowledgeRepository
            include medicalStore
            autoLayout lr
        }

        component backend C3-CaseManagement {
            title "Lifeline - C3 Case Management Bounded Context"
            description "Sincronizacion, ciclo de vida del caso, autorizacion, persistencia y procesamiento asincrono."
            include caseManagementApi caseManagementService asyncPublisher caseRepository caseDomain iamInterface
            include loadBalancer messageBroker cloudDb cloudinary
            autoLayout lr
        }

        component backend C3-IAM {
            title "Lifeline - C3 IAM Bounded Context"
            description "Autenticacion, identidad, perfiles, roles y persistencia."
            include caseManagementService iamInterface iamService iamRepository identityDomain
            include loadBalancer cloudDb
            autoLayout lr
        }

        deployment lifeline live deployment {
            title "Lifeline - Deployment Diagram"
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #1168BD
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Mobile" {
                background #1B4F72
                color #ffffff
            }
            element "Backend" {
                background #1E8449
                color #ffffff
            }
            element "LoadBalancer" {
                background #1E8449
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #7F8C8D
                color #ffffff
            }
            element "KnowledgeStore" {
                shape Cylinder
                background #8E44AD
                color #ffffff
            }
            element "Broker" {
                background #E67E22
                color #ffffff
            }
            element "Worker" {
                background #D35400
                color #ffffff
            }
            element "Ui" {
                background #5B6ABF
                color #ffffff
            }
            element "Api" {
                background #4A5DBD
                color #ffffff
            }
            element "Service" {
                background #2E86C1
                color #ffffff
            }
            element "Domain" {
                background #1ABC9C
                color #ffffff
            }
            element "Infra" {
                background #6E4C1E
                color #ffffff
            }
            element "PublishedLanguage" {
                background #1F4E79
                color #ffffff
            }
        }
    }
}
