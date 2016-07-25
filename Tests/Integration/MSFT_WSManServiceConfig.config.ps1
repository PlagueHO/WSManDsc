# These are the new values that the integration tests will set
$WSManServiceConfigNew = [PSObject] @{}

# Build the arrays using the ParameterList from the module itself
foreach ($parameter in $ParameterList)
{
    $WSManServiceConfigNew += [PSObject] @{ $($parameter.Name) = $($parameter.TestVal) }
} # foreach

Configuration MSFT_WSManServiceConfig_Config {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManServiceConfig Integration_Test {
            IsSingleInstance                 = 'Yes'
# Integration testing these values can result in difficult to reverse damage to the test server.
# So these tests are disabled. Only perform them on a disposable test server.
#            RootSDDL                         = $WSManServiceConfigNew.RootSDDL
#            AuthBasic                        = $WSManServiceConfigNew.AuthBasic
#            AuthKerberos                     = $WSManServiceConfigNew.AuthKerberos
#            AuthNegotiate                    = $WSManServiceConfigNew.AuthNegotiate
#            MaxConnections                   = $WSManServiceConfigNew.MaxConnections
#            MaxConcurrentOperationsPerUser   = $WSManServiceConfigNew.MaxConcurrentOperationsPerUser
#            EnumerationTimeoutms             = $WSManServiceConfigNew.EnumerationTimeoutms
#            MaxPacketRetrievalTimeSeconds    = $WSManServiceConfigNew.MaxPacketRetrievalTimeSeconds
#            AllowUnencrypted                 = $WSManServiceConfigNew.AllowUnencrypted
#            AuthCertificate                  = $WSManServiceConfigNew.AuthCertificate
#            AuthCredSSP                      = $WSManServiceConfigNew.AuthCredSSP
#            AuthCbtHardeningLevel            = $WSManServiceConfigNew.AuthCbtHardeningLevel
            EnableCompatibilityHttpListener  = $WSManServiceConfigNew.EnableCompatibilityHttpListener
            EnableCompatibilityHttpsListener = $WSManServiceConfigNew.EnableCompatibilityHttpsListener
        }
    }
}
