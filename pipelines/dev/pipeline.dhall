  λ(workerCount : Natural)
→ let clusterEventResource = ../dhall-modules/resources/cluster-event.dhall
  
  let iksCreds =
        { account = "((ibmcloud-account))"
        , password = "((ibmcloud-password))"
        , user = "((ibmcloud-user))"
        }
  
  let inputs =
        { githubPrivateKey = "((github-private-key))"
        , eiriniCIBranch = "((ci-resources-branch))"
        , worldName = "((world-name))"
        , eiriniBranch = "((eirini-branch))"
        , eiriniReleaseBranch = "((eirini-release-branch))"
        , iksCreds = iksCreds
        , dockerhubUser = "((dockerhub-user))"
        , dockerhubPassword = "((dockerhub-password))"
        , gcsJSONKey = "((gcs-json-key))"
        , storageClass = "((storage_class))"
        , clusterAdminPassword = "((cluster_admin_password))"
        , uaaAdminClientSecret = "((uaa_admin_client_secret))"
        , natsPassword = "((nats_password))"
        , diegoCellCount = "((diego-cell-count))"
        }
  
  let Prelude = ../dhall-modules/deps/prelude.dhall
  
  let Concourse = ../dhall-modules/deps/concourse.dhall
  
  let clusterState =
        ../dhall-modules/resources/cluster-state.dhall inputs.githubPrivateKey
  
  let ciResources =
        ../dhall-modules/resources/ci-resources.dhall inputs.eiriniCIBranch
  
  let clusterReadyEvent =
        clusterEventResource inputs.worldName "ready" inputs.githubPrivateKey
  
  let uaaReadyEvent =
        clusterEventResource
          inputs.worldName
          "uaa-ready"
          inputs.githubPrivateKey
  
  let eiriniRepo = ../dhall-modules/resources/eirini.dhall inputs.eiriniBranch
  
  let eiriniReleaseRepo =
        ../dhall-modules/resources/eirini-release.dhall
          inputs.eiriniReleaseBranch
  
  let uaaResource =
        ../dhall-modules/resources/uaa.dhall inputs.eiriniReleaseBranch
  
  let smokeTestsResource = ../dhall-modules/resources/smoke-tests.dhall
  
  let sampleConfigs =
        ../dhall-modules/resources/sample-configs.dhall inputs.eiriniCIBranch
  
  let docker =
        ../dhall-modules/resources/all-dockers.dhall
          inputs.dockerhubUser
          inputs.dockerhubPassword
  
  let deploymentVersion =
        ../dhall-modules/resources/deployment-version.dhall
          inputs.worldName
          inputs.gcsJSONKey
  
  let downloadKubeconfigTask =
        ../dhall-modules/tasks/download-kubeconfig-iks.dhall
          iksCreds
          ciResources
          inputs.worldName
  
  let ImageLocation = ../dhall-modules/types/image-location.dhall
  
  let EiriniOrRepo = ../dhall-modules/types/eirini-or-repo.dhall
  
  let ClusterPrep = ../dhall-modules/types/cluster-prep.dhall
  
  let kubeClusterReqs =
        { ciResources = ciResources
        , clusterState = clusterState
        , clusterCreatedEvent =
            clusterEventResource
              inputs.worldName
              "created"
              inputs.githubPrivateKey
        , clusterReadyEvent = clusterReadyEvent
        , clusterName = inputs.worldName
        , enableOPIStaging = "true"
        , iksCreds = iksCreds
        , workerCount = workerCount
        , storageClass = inputs.storageClass
        , clusterPreparation =
            ClusterPrep.Required
              { clusterAdminPassword = inputs.clusterAdminPassword
              , uaaAdminClientSecret = inputs.uaaAdminClientSecret
              , natsPassword = inputs.natsPassword
              , diegoCellCount = inputs.diegoCellCount
              }
        }
  
  let runTestReqs =
        { ciResources = ciResources
        , eiriniRepo = eiriniRepo
        , secretSmugglerRepo = EiriniOrRepo.UseEirini
        , fluentdRepo = EiriniOrRepo.UseEirini
        , sampleConfigs = sampleConfigs
        , clusterName = inputs.worldName
        , dockerOPI = docker.opi
        , dockerBitsWaiter = docker.bitsWaiter
        , dockerRootfsPatcher = docker.rootfsPatcher
        , dockerSecretSmuggler = docker.secretSmuggler
        , dockerFluentd = docker.fluentd
        , iksCreds = iksCreds
        , upstream = { name = "prepare-cluster", event = clusterReadyEvent }
        }
  
  let tagImagesReqs =
        { dockerOPI = docker.opi
        , dockerBitsWaiter = docker.bitsWaiter
        , dockerRootfsPatcher = docker.rootfsPatcher
        , dockerSecretSmuggler = docker.secretSmuggler
        , dockerFluentd = docker.fluentd
        , worldName = inputs.worldName
        , eiriniRepo = eiriniRepo
        , deploymentVersion = deploymentVersion
        }
  
  let deploymentReqs =
        { clusterName = inputs.worldName
        , worldName = inputs.worldName
        , uaaResources = uaaResource
        , ciResources = ciResources
        , eiriniReleaseRepo = eiriniReleaseRepo
        , smokeTestsResource = smokeTestsResource
        , clusterReadyEvent = clusterReadyEvent
        , uaaReadyEvent = uaaReadyEvent
        , clusterState = clusterState
        , downloadKubeconfigTask = downloadKubeconfigTask
        , useCertManager = "false"
        , iksCreds = iksCreds
        , imageLocation =
            ImageLocation.FromTags
              { eiriniRepo = eiriniRepo, deploymentVersion = deploymentVersion }
        , skippedCats = None Text
        }
  
  let kubeClusterJobs = ../dhall-modules/kube-cluster.dhall kubeClusterReqs
  
  let runTestJobs =
        ../dhall-modules/test-and-build-docker-images.dhall runTestReqs
  
  let tagImages = ../dhall-modules/tag-images.dhall tagImagesReqs
  
  let deployEirini = ../dhall-modules/deploy-eirini.dhall deploymentReqs
  
  in  Prelude.List.concat
        Concourse.Types.Job
        [ kubeClusterJobs, runTestJobs, tagImages, deployEirini ]