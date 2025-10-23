inTrunk = false;
carrying = false;
imCarried = false;
playerPed = PlayerPedId()
playerServerId = GetPlayerServerId(PlayerId())
cuffedType = nil;
dragData = {
	state = false,
	draggedBy = nil,
	thread = false
}
local cuffFix = false;
local handcuffThread = false;
local isDead = false;
local handcuffDisableThreadWorking = false;
local hardcuffDisableThreadWorking = false;
local handcuffing = false;
lib.onCache('ped', function(ped)
	playerPed = ped
end)
function checkCanHandcuff(entity)
	local targetState = Player(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))).state;
	if not exports['rev-inventory']:HasItemInInventoryOrContainer('handcuffs', 1) then
		return false
	end;
	if handcuffing then
		return false
	end;
	if DoesEntityExist(entity) and inTrunk == false and not targetState.Cuffed and not carrying and targetState.InTrunk == nil and not LocalPlayer.state.ImCarrying and not LocalPlayer.state.ImCarried then
		return true
	end;
	return false
end;
function checkCanCableTie(entity)
	local targetState = Player(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))).state;
	if not exports['rev-inventory']:HasItemInInventoryOrContainer('cable_tie', 1) then
		return false
	end;
	if handcuffing then
		return false
	end;
	if DoesEntityExist(entity) and inTrunk == false and not targetState.Cuffed and not carrying and targetState.InTrunk == nil and not LocalPlayer.state.ImCarrying and not LocalPlayer.state.ImCarried then
		return true
	end;
	return false
end;
function canTakeOutPed(vehicle, seat)
	local ped = GetPedInVehicleSeat(vehicle, seat)
	local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
	if Entity(ped).state.hostage then
		return DoesEntityExist(ped)
	end;
	return DoesEntityExist(ped) and IsPedAPlayer(ped) and (Player(serverId).state.Cuffed or Player(serverId).state.Dead) and not Player(serverId).state.seatbelt
end;
Citizen.CreateThread(function()
	exports.ox_target:addGlobalPlayer({
		{
			event = 'rev-police:handcuff',
			icon = 'fas fa-handcuffs',
			label = 'Zakuj od tyłu',
			cufftype = 'handcuffs_rear',
			canInteract = checkCanHandcuff,
			distance = 2.0
		},
		{
			event = 'rev-police:handcuff',
			icon = 'fas fa-handcuffs',
			label = 'Zakuj od przodu',
			cufftype = 'handcuffs_front',
			canInteract = checkCanHandcuff,
			distance = 2.0
		},
		{
			event = 'rev-police:handcuff',
			icon = 'fas fa-handcuffs',
			label = 'Zwiąż od tyłu',
			cufftype = 'cable_tie_rear',
			canInteract = checkCanCableTie,
			distance = 2.0
		},
		{
			event = 'NRmGdzG1PzkvHCOr',
			icon = 'fas fa-handcuffs',
			label = 'Zakuj nogi',
			cufftype = 'handcuffs_hard',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed and not carrying and state.Cuffed ~= 'handcuffs_hard' then
					return true
				end;
				return false
			end,
			items = 'handcuffs',
			distance = 2.0
		},
		{
			event = 'rev-police:unhardcuff',
			icon = 'fas fa-handcuffs',
			label = 'Odkuj nogi',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed == 'handcuffs_hard' and not carrying then
					local count = exports.ox_inventory:Search('count', 'handcuffs')
					if count > 0 then
						return true
					end;
					return false
				end;
				return false
			end,
			items = 'handcuffs',
			distance = 2.0
		},
		{
			event = 'rev-police:unhardcuff',
			icon = 'fas fa-handcuffs',
			label = 'Rozwiąż nogi',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed == 'cable_tie_hard' and not carrying then
					local count = exports.ox_inventory:Search('count', 'cable_tie')
					if count > 0 then
						return true
					end;
					return false
				end;
				return false
			end,
			items = 'cable_tie',
			distance = 2.0
		},
		{
			event = 'rev-police:dragPlayer',
			icon = 'fas fa-hand-holding',
			label = 'Przenieś',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and (state.Cuffed or state.Dead) and not carrying and (not LocalPlayer.state.Dragging or LocalPlayer.state.Dragging == serverId) and not LocalPlayer.state.DraggedBy and not LocalPlayer.state.ImCarrying and not LocalPlayer.state.ImCarried then
					return true
				end;
				return false
			end
		},
		{
			event = 'rev-police:putInVehicle',
			icon = 'fas fa-car',
			label = 'Włóż do pojazdu',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and not inTrunk and not state.inTrunk and (state.Cuffed or state.Dead) and lib.getClosestVehicle(GetEntityCoords(playerPed), 5.0) then
					return true
				end;
				return false
			end
		},
		{
			event = 'rev-police:unhandcuff',
			icon = 'fas fa-handcuffs',
			label = 'Odkuj',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed and not carrying then
					if state.Cuffed == 'handcuffs_rear' or state.Cuffed == 'handcuffs_front' or state.Cuffed == 'handcuffs_hard' then
						if Core.Utils.HasJob('police') or Core.Utils.HasJob('ems') then
							return true
						end
					elseif state.Cuffed == 'rope_rear' then
						return true
					end
				end;
				return false
			end,
			distance = 2.0
		},
		{
			event = 'rev-police:unhandcuff',
			icon = 'fas fa-handcuffs',
			label = 'Rozwiąż',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed and not carrying then
					if state.Cuffed == 'cable_tie_rear' then
						return true
					end
				end;
				return false
			end,
			distance = 2.0
		},
		{
			event = 'rev-police:unhandcuff',
			icon = 'fas fa-handcuffs',
			label = 'Rozwiąż',
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed and not carrying then
					if state.Cuffed == 'rope_rear' then
						return true
					end
				end;
				return false
			end,
			distance = 2.0
		},
		{
			event = 'rev-police:unhandcuff',
			icon = 'fas fa-handcuffs',
			label = 'Rozwal kajdanki',
			items = {
				'lockpick'
			},
			minigame = true,
			canInteract = function(entity)
				local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
				local state = Player(serverId).state;
				if DoesEntityExist(entity) and inTrunk == false and state.Cuffed and not carrying then
					return true
				end;
				return false
			end,
			distance = 2.0
		}
	})
	local vehicleOptions = {}
	for k, v in pairs(Config.SeatsNum) do
		table.insert(vehicleOptions, {
			event = "rev-police:takeOutPed",
			icon = "fas fa-car",
			label = locale("seat_put_out_vehicle", locale(v)),
			seat = k,
			canInteract = function(entity)
				return canTakeOutPed(entity, k) and not inTrunk
			end
		})
	end;
	exports.ox_target:addGlobalVehicle(vehicleOptions)
end)
AddEventHandler('rev-police:handcuff', function(data)
	local targetEntity = data.entity;
	if not DoesEntityExist(targetEntity) then
		return
	end;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetEntity))
	SetEntityHeading(playerPed, GetEntityHeading(targetEntity))
	handcuffing = true;
	lib.RequestAnimDict(Config.HandcuffsAnims[data.cufftype].cop.cuff.animDict)
	Core.Callbacks.Server.Async('rev-police:server:cuffAction', function(handcuffResult)
		if not handcuffResult then
			ClearPedTasks(playerPed)
			Citizen.Wait(500)
			FreezeEntityPosition(playerPed, false)
		end
	end, targetId, data.cufftype)
	Citizen.Wait(100)
	FreezeEntityPosition(playerPed, true)
	TaskPlayAnim(playerPed, Config.HandcuffsAnims[data.cufftype].cop.cuff.animDict, Config.HandcuffsAnims[data.cufftype].cop.cuff.anim, 8.0, 8.0, Config.HandcuffsAnims[data.cufftype].cop.cuff.duration, 0, 0.0, false, false, false)
	Citizen.Wait(Config.HandcuffsAnims[data.cufftype].cop.cuff.waitTime or 4000)
	FreezeEntityPosition(playerPed, false)
	handcuffing = false;
	RemoveAnimDict(Config.HandcuffsAnims[data.cufftype].cop.cuff.animDict)
end)
AddEventHandler('rev-police:unhandcuff', function(data)
	if data.minigame then
		local hasLockpick = Core.Callbacks.Server.Await('rev-police:server:hasLockpick')
		if hasLockpick then
			local lockpicking = true;
			Citizen.CreateThread(function()
				lib.RequestAnimDict('veh@break_in@0h@p_m_one@')
				while lockpicking do
					TaskPlayAnim(playerPed, "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 1.0, 1.0, 1.0, 16, 0.0, 0, 0, 0)
					Citizen.Wait(2000)
				end
			end)
			local result = exports['rev-hud']:startQte({
				speed = 15,
				dificulty = 6,
				rounds = 5,
				typeGame = 'circle',
				keys = {
					'e'
				}
			})
			lockpicking = false;
			StopAnimTask(playerPed, "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 1.0)
			RemoveAnimDict('veh@break_in@0h@p_m_one@')
			if not result then
				return
			end;
			Core.addNotification(locale('destroy_cuffs_success'), {
				type = 'success'
			})
		else
			return
		end
	end;
	local targetPed = data.entity;
	if not DoesEntityExist(targetPed) then
		return
	end;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
	local state = Player(targetId).state;
	lib.RequestAnimDict(Config.HandcuffsAnims[state.Cuffed].cop.uncuff.animDict)
	FreezeEntityPosition(playerPed, true)
	Citizen.CreateThread(function()
		Citizen.Wait(1000)
		FreezeEntityPosition(playerPed, false)
	end)
	TaskPlayAnim(playerPed, Config.HandcuffsAnims[state.Cuffed].cop.uncuff.animDict, Config.HandcuffsAnims[state.Cuffed].cop.uncuff.anim, 8.0, 8.0, Config.HandcuffsAnims[state.Cuffed].cop.uncuff.duration, 48, 0.0, false, false, false)
	RemoveAnimDict(Config.HandcuffsAnims[state.Cuffed].cop.uncuff.animDict)
	TriggerServerEvent('wiYlb3GxanHa', targetId)
end)
AddEventHandler('rev-police:dragPlayer', function(data)
	local targetPed = data.entity;
	if not DoesEntityExist(targetPed) then
		return
	end;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
	TriggerServerEvent('BGWFcrjdVPv', targetId)
end)
AddEventHandler('rev-police:putInVehicle', function(data)
	local vehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 5.0)
	if not vehicle then
		return
	end;
	if GetVehicleDoorLockStatus(vehicle) == 2 then
		Core.addNotification(locale('vehicle_locked'), {
			type = 'error'
		})
		return
	end;
	local targetPed = data.entity;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
	local success = lib.progressBar({
		duration = 5000,
		label = locale('vehicle_putin_progress'),
		canCancel = true,
		disable = {
			combat = true
		},
		anim = {
			dict = "mini@repair",
			clip = 'fixing_a_player',
			flag = 49
		}
	})
	if success then
		TriggerServerEvent('Q0041v5vYCYZKN', targetId, NetworkGetNetworkIdFromEntity(vehicle))
	end
end)
AddEventHandler('rev-police:takeOutPed', function(data)
	local vehicle = data.entity;
	if GetVehicleDoorLockStatus(vehicle) == 2 then
		Core.addNotification(locale('vehicle_locked'), {
			type = 'error'
		})
		return
	end;
	local success = lib.progressBar({
		duration = 5000,
		label = locale('vehicle_takeout_progress'),
		canCancel = true,
		disable = {
			combat = true
		},
		anim = {
			dict = "mini@repair",
			clip = 'fixing_a_player',
			flag = 49
		}
	})
	if success then
		if Entity(GetPedInVehicleSeat(vehicle, data.seat)).state.hostage then
			TriggerServerEvent('kUUNAOwyoXrnx9', NetworkGetNetworkIdFromEntity(GetPedInVehicleSeat(vehicle, data.seat)))
		else
			TriggerServerEvent('6n5uqH3XrzK6', GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(vehicle, data.seat))), NetworkGetNetworkIdFromEntity(vehicle), data.seat, GetOffsetFromEntityInWorldCoords(playerPed, -0.5, 0.3, 0.0), GetEntityHeading(playerPed))
		end
	end
end)
AddEventHandler('NRmGdzG1PzkvHCOr', function(data)
	local targetEntity = data.entity;
	if not DoesEntityExist(targetEntity) then
		return
	end;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetEntity))
	local animCoords = (GetEntityCoords(targetEntity) - (GetEntityForwardVector(targetPed) * 1.1)) - vector3(0.0, 0.0, 1.0)
	SetEntityHeading(playerPed, GetEntityHeading(targetEntity))
	lib.RequestAnimDict(Config.HandcuffsAnims[data.cufftype].cop.cuff.animDict)
	TaskPlayAnim(playerPed, Config.HandcuffsAnims[data.cufftype].cop.cuff.animDict, Config.HandcuffsAnims[data.cufftype].cop.cuff.anim, 8.0, 8.0, Config.HandcuffsAnims[data.cufftype].cop.cuff.duration, 0, 0.0, false, false, false)
	TriggerServerEvent('NRmGdzG1PzkvHCOr', targetId, data.cufftype)
end)
AddEventHandler('rev-police:unhardcuff', function(data)
	local targetPed = data.entity;
	if not DoesEntityExist(targetPed) then
		return
	end;
	local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
	local state = Player(targetId).state;
	SetEntityHeading(playerPed, GetEntityHeading(targetPed))