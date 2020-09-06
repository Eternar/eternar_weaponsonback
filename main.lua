ESX = nil
local Weapons = {}
local Loaded = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while not Loaded do
		Citizen.Wait(500)
	end

	while true do
		Citizen.Wait(500)
		local playerPed = PlayerPedId()

		for i=1, #Config.RealWeapons, 1 do
			local weaponHash = GetHashKey(Config.RealWeapons[i].name)

			if HasPedGotWeapon(playerPed, weaponHash, false) then
				local onPlayer = false

				for weaponName, entity in pairs(Weapons) do
					if weaponName == Config.RealWeapons[i].name then
						onPlayer = true
						break
					end
				end

				if not onPlayer and weaponHash ~= GetSelectedPedWeapon(playerPed) then
					SetGear(Config.RealWeapons[i].name)
				elseif onPlayer and weaponHash == GetSelectedPedWeapon(playerPed) then
					RemoveGear(Config.RealWeapons[i].name)
				end
			end
		end
	end
end)

AddEventHandler('skinchanger:modelLoaded', function()
	SetGears()
	Loaded = true
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName)
	RemoveGear(weaponName)
end)

function RemoveGear(weapon)
	local _Weapons = {}

	for weaponName, entity in pairs(Weapons) do
		if weaponName ~= weapon then
			_Weapons[weaponName] = entity
		else
			ESX.Game.DeleteObject(entity)
		end
	end

	Weapons = _Weapons
end

function SetGear(weapon)
	local bone       = nil
	local boneX      = 0.0
	local boneY      = 0.0
	local boneZ      = 0.0
	local boneXRot   = 0.0
	local boneYRot   = 0.0
	local boneZRot   = 0.0
	local playerPed  = PlayerPedId()
	local playerData = ESX.GetPlayerData()

	for i=1, #Config.RealWeapons, 1 do
		if Config.RealWeapons[i].name == weapon then
			bone     = Config.RealWeapons[i].bone
			boneX    = Config.RealWeapons[i].x
			boneY    = Config.RealWeapons[i].y
			boneZ    = Config.RealWeapons[i].z
			boneXRot = Config.RealWeapons[i].xRot
			boneYRot = Config.RealWeapons[i].yRot
			boneZRot = Config.RealWeapons[i].zRot
			break
		end
	end

	local weaponHash = GetHashKey(weapon)
	ESX.Streaming.RequestWeaponAsset(weaponHash)
	
	local pickupObject = CreateWeaponObject(weaponHash, 50, x, y, z, true, 1.0, 0)
	SetWeaponObjectTintIndex(pickupObject, tintIndex)

	local playerLoadout = playerData.loadout
	local components = nil
	for k,v in ipairs(playerLoadout) do
		if v.name == weapon then
			components = v.components
			break
		end
	end

	if components ~= nil then
		for k,v in ipairs(components) do
			local component = ESX.GetWeaponComponent(weapon, v)
			GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
		end
	end

	local boneIndex = GetPedBoneIndex(playerPed, bone)
	local bonePos 	= GetWorldPositionOfEntityBone(playerPed, boneIndex)
	AttachEntityToEntity(pickupObject, playerPed, boneIndex, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot, false, false, false, false, 2, true)
	Weapons[weapon] = pickupObject
	return false
end

function SetGears()
	local playerData = ESX.GetPlayerData()

	for i=1, #playerData.loadout, 1 do
		local _wait = true
		_wait = SetGear(playerData.loadout[i].name)

		while _wait do
			Citizen.Wait(10)
		end
	end
end