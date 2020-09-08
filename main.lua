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
					SetGear(Config.RealWeapons[i])
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
	local playerPed  = PlayerPedId()
	local playerData = ESX.GetPlayerData()

	local weaponHash = GetHashKey(weapon.name)
	ESX.Streaming.RequestWeaponAsset(weaponHash)
	
	local pickupObject = CreateWeaponObject(weaponHash, 50, x, y, z, true, 1.0, 0)
	SetWeaponObjectTintIndex(pickupObject, tintIndex)

	local playerLoadout = playerData.loadout
	local components = nil
	for k,v in ipairs(playerLoadout) do
		if v.name == weapon.name then
			components = v.components
			break
		end
	end

	if components ~= nil then
		for k,v in ipairs(components) do
			local component = ESX.GetWeaponComponent(weapon.name, v)
			GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
		end
	end

	local boneIndex = GetPedBoneIndex(playerPed, weapon.bone)
	local bonePos 	= GetWorldPositionOfEntityBone(playerPed, boneIndex)
	AttachEntityToEntity(pickupObject, playerPed, boneIndex, weapon.x, weapon.y, weapon.z, weapon.xRot, weapon.yRot, weapon.zRot, false, false, false, false, 2, true)
	Weapons[weapon.name] = pickupObject
	return false
end

function SetGears()
	local playerData = ESX.GetPlayerData()

	for k=1, #playerData.loadout, 1 do
		for i=1, #Config.RealWeapons, 1 do
			if playerData.loadout[k].name == Config.RealWeapons[i].name then
				local _wait = true

				while _wait do
					_wait = SetGear(Config.RealWeapons[i])
					Citizen.Wait(10)
				end
			end
		end
	end
end