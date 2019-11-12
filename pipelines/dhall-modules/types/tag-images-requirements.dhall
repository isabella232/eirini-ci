let Concourse = ../deps/concourse.dhall

in  { deploymentVersion : Concourse.Types.Resource
    , dockerOPI : Concourse.Types.Resource
    , dockerRootfsPatcher : Concourse.Types.Resource
    , dockerBitsWaiter : Concourse.Types.Resource
    , dockerSecretSmuggler : Concourse.Types.Resource
    , dockerFluentd : Concourse.Types.Resource
    , dockerRouteCollector : Concourse.Types.Resource
    , dockerRoutePodInformer : Concourse.Types.Resource
    , dockerRouteStatefulsetInformer : Concourse.Types.Resource
    , eiriniRepo : Concourse.Types.Resource
    , worldName : Text
    }
