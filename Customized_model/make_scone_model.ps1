param(
    [string]$InputFile = "2D_gait_15Rloaded.osim",
    [string]$OutputFile = "2D_gait_15Rloaded_SCONE.osim",
    [string]$LockedLumbarOutputFile = "2D_gait_15Rloaded_SCONE_locked_lumbar.osim",
    [string]$OpenSimOutputFile = "2D_gait_15Rloaded_OpenSim.osim"
)

$inputPath = Join-Path $PSScriptRoot $InputFile
$outputPath = Join-Path $PSScriptRoot $OutputFile
$lockedLumbarOutputPath = Join-Path $PSScriptRoot $LockedLumbarOutputFile
$openSimOutputPath = Join-Path $PSScriptRoot $OpenSimOutputFile
$text = [System.IO.File]::ReadAllText($inputPath)

# In the source model pelvis_ty has no default value, so OpenSim displays the
# pelvis at ground height. In the neutral pose, pelvis_ty = 0.942 m places the
# heel and forefoot contact spheres at y = 0.
$pelvisTyPattern = '(?s)(<Coordinate name="pelvis_ty">.*?<range>[^<]+</range>)'
if (-not [regex]::IsMatch($text, $pelvisTyPattern)) {
    throw "Could not find the pelvis_ty coordinate in $inputPath"
}
$text = [regex]::Replace(
    $text,
    $pelvisTyPattern,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $match.Groups[1].Value + "`r`n`t`t`t`t`t`t`t<default_value>0.942</default_value>"
    },
    1
)

[System.IO.File]::WriteAllText($openSimOutputPath, $text, [System.Text.UTF8Encoding]::new($false))

$componentsPattern = '(?s)\s*<components>\s*(.*?)\s*</components>'
$componentsMatch = [regex]::Match($text, $componentsPattern)
if (-not $componentsMatch.Success) {
    throw "Could not find the model <components> section in $inputPath"
}

$forces = $componentsMatch.Groups[1].Value
$smoothContactPattern = '(?s)\s*<SmoothSphereHalfSpaceForce name="contact(?:Heel|Front)_[rl]">.*?</SmoothSphereHalfSpaceForce>'
$forces = [regex]::Replace($forces, $smoothContactPattern, '')

$footContactForces = @'
			<HuntCrossleyForce name="foot_r">
				<appliesForce>true</appliesForce>
				<HuntCrossleyForce::ContactParametersSet name="contact_parameters">
					<objects>
						<HuntCrossleyForce::ContactParameters>
							<geometry>floor heel_r front_r</geometry>
							<stiffness>3067776</stiffness>
							<dissipation>2</dissipation>
							<static_friction>0.9</static_friction>
							<dynamic_friction>0.8</dynamic_friction>
							<viscous_friction>0.2</viscous_friction>
						</HuntCrossleyForce::ContactParameters>
					</objects>
					<groups />
				</HuntCrossleyForce::ContactParametersSet>
				<transition_velocity>0.08</transition_velocity>
			</HuntCrossleyForce>
			<HuntCrossleyForce name="foot_l">
				<appliesForce>true</appliesForce>
				<HuntCrossleyForce::ContactParametersSet name="contact_parameters">
					<objects>
						<HuntCrossleyForce::ContactParameters>
							<geometry>floor heel_l front_l</geometry>
							<stiffness>3067776</stiffness>
							<dissipation>2</dissipation>
							<static_friction>0.9</static_friction>
							<dynamic_friction>0.8</dynamic_friction>
							<viscous_friction>0.2</viscous_friction>
						</HuntCrossleyForce::ContactParameters>
					</objects>
					<groups />
				</HuntCrossleyForce::ContactParametersSet>
				<transition_velocity>0.08</transition_velocity>
			</HuntCrossleyForce>
'@
$forces = "$footContactForces`r`n$forces"
$text = [regex]::Replace($text, $componentsPattern, "`r`n`t`t<components />", 1)

$forceSetPattern = '(?s)<ForceSet name="forceset">\s*<objects\s*/>\s*<groups\s*/>\s*</ForceSet>'
if (-not [regex]::IsMatch($text, $forceSetPattern)) {
    throw "Could not find the empty ForceSet in $inputPath"
}

$forceSet = "<ForceSet name=`"forceset`">`r`n`t`t`t<objects>`r`n$forces`r`n`t`t`t</objects>`r`n`t`t`t<groups />`r`n`t`t</ForceSet>"
$text = [regex]::Replace($text, $forceSetPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $forceSet }, 1)

# SCONE's OpenSim initial-load routine and the pretrained H0918 parameter file
# use the canonical /jointset/ground_pelvis/... state path.
$text = $text.Replace('<PlanarJoint name="groundPelvis">', '<PlanarJoint name="ground_pelvis">')

[System.IO.File]::WriteAllText($outputPath, $text, [System.Text.UTF8Encoding]::new($false))

# Baseline optimization model: lock the relative lumbar angle so the loaded
# torso behaves like the rigid upper body assumed by the H0918 controller.
$lumbarCoordinatePattern = '(?s)(<Coordinate name="lumbar">.*?<range>[^<]+</range>)'
if (-not [regex]::IsMatch($text, $lumbarCoordinatePattern)) {
    throw "Could not find the lumbar coordinate in $outputPath"
}
$lockedLumbarText = [regex]::Replace(
    $text,
    $lumbarCoordinatePattern,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $match.Groups[1].Value + "`r`n`t`t`t`t`t`t`t<locked>true</locked>"
    },
    1
)
[System.IO.File]::WriteAllText($lockedLumbarOutputPath, $lockedLumbarText, [System.Text.UTF8Encoding]::new($false))

Write-Host "Created $openSimOutputPath"
Write-Host "Created $outputPath"
Write-Host "Created $lockedLumbarOutputPath"
