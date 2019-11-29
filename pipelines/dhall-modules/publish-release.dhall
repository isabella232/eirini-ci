let Concourse = ../dhall-modules/deps/concourse.dhall

let Prelude = ../dhall-modules/deps/prelude.dhall

let JSON = Prelude.JSON

let PublishReleaseRequirements =
      ../dhall-modules/types/publish-release-requirements.dhall

let publishReleaseJobs =
        λ(reqs : PublishReleaseRequirements)
      → let githubRelease =
              Concourse.schemas.Resource::{
              , name = "eirini-scf-release"
              , type = Concourse.Types.ResourceType.InBuilt "github-release"
              , icon = Some "rocket"
              , source =
                  Some
                    ( toMap
                        { owner = JSON.string "cloudfoundry-incubator"
                        , repository = JSON.string "eirini-release"
                        , access_token = JSON.string reqs.githubAccessToken
                        , drafts = JSON.bool True
                        }
                    )
              }

        let githubAccessTask =
                λ(name : Text)
              → Concourse.helpers.taskStep
                  Concourse.schemas.TaskStep::{
                  , task = name
                  , config = ./helpers/task-file.dhall reqs.ciResources name
                  , params =
                      Some (toMap { GITHUB_TOKEN = reqs.githubAccessToken })
                  }

        let boringTask
            : Text → Concourse.Types.Step
            =   λ(name : Text)
              → Concourse.helpers.taskStep
                  Concourse.schemas.TaskStep::{
                  , task = name
                  , config = ./helpers/task-file.dhall reqs.ciResources name
                  }

        let putScfRelease =
              Concourse.helpers.putStep
                Concourse.schemas.PutStep::{
                , resource = githubRelease
                , params =
                    Some
                      ( toMap
                          { name =
                              JSON.string "${reqs.versionResource.name}/version"
                          , tag =
                              JSON.string "${reqs.versionResource.name}/version"
                          , tag_prefix = JSON.string "v"
                          , globs =
                              ./helpers/text-list-to-json.dhall
                                [ "release-output/eirini*.tgz" ]
                          }
                      )
                }

        let putGhPagesPr =
              Concourse.helpers.putStep
                Concourse.schemas.PutStep::{
                , resource = reqs.ghPagesRepo
                , params =
                    Some (toMap { repository = JSON.string "gh-pages-updated" })
                }

        let tagSteps =
              ./jobs/steps/tag-repo.dhall reqs.ciResources reqs.versionResource

        let publishReleaseJob =
              Concourse.schemas.Job::{
              , name = "publish-release"
              , plan =
                    [ ./helpers/get.dhall reqs.ciResources
                    , ./helpers/get.dhall reqs.ghPagesRepo
                    , githubAccessTask "check-for-pending-release"
                    , ./helpers/get-named.dhall reqs.clusterState "state"
                    , ./helpers/get-passed.dhall
                        reqs.eiriniReleaseRepo
                        [ "run-smoke-tests-acceptance" ]
                    , ./helpers/get.dhall reqs.versionResource
                    , boringTask "create-release"
                    , boringTask "update-helm-repo"
                    , putScfRelease
                    , putGhPagesPr
                    , githubAccessTask "create-github-pr"
                    ]
                  # tagSteps reqs.writeableEiriniRepo "opi" "opi"
                  # tagSteps
                      reqs.writeableStagingRepo
                      "staging-downloader"
                      "recipe-downloader"
              }

        let AutoBumpVersion = ./types/auto-bump-version.dhall

        let bumpMajor =
              ./jobs/bump-version.dhall
                reqs.versionResource
                "major"
                AutoBumpVersion.NoAutoBump

        let bumpMinor =
              ./jobs/bump-version.dhall
                reqs.versionResource
                "minor"
                (AutoBumpVersion.AutoBumpOn publishReleaseJob.name)

        in  [ bumpMinor, bumpMajor, publishReleaseJob ]

in  publishReleaseJobs
