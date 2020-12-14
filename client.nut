// ----------------------------------------------------------------------------

setErrorMode(RESOURCEERRORMODE_STRICT);

// ----------------------------------------------------------------------------

local raceSphere = null;
local raceBlip = null;
local nextRaceBlip = null;

// ----------------------------------------------------------------------------

addEvent("OnRaceCarEnterSphere", 0);

// ----------------------------------------------------------------------------

local returnToRaceVehicleMessage = false;
local kickedFromRaceMessage = false;
local returnToRaceVehicleTime = false;

// ----------------------------------------------------------------------------

addNetworkHandler("pos", function(x, y, z, heading) {
  local position = Vec3(x, y, z);
  localPlayer.position = position;
  localPlayer.heading = heading;
});

// ----------------------------------------------------------------------------

addNetworkHandler("engine", function(vehicle, engineState) {
  if(vehicle != null) {
    vehicle.engine = engineState;
  }
});

// ----------------------------------------------------------------------------

addNetworkHandler("makepoint", function(x, y, z, colour, sphereRadius, nextX = 0.0, nextY = 0.0, nextZ = 0.0) {
  local position = Vec3(x, y, z);
  raceSphere = gta.createSphere(position, sphereRadius);
  raceSphere.colour = colour;

  raceBlip = gta.createBlip(position, 0, 3, toColour(255, 255, 0, 255));

  local nextPosition = Vec3(nextX, nextY, nextZ);
  nextRaceBlip = gta.createBlip(nextPosition, 0, 2, toColour(160, 160, 0, 255));
  
  print("Added sphere and blip");
});

// ----------------------------------------------------------------------------

addNetworkHandler("movepoint", function(x, y, z, colour, sphereRadius, nextX = 0.0, nextY = 0.0, nextZ = 0.0) {
  local position = Vec3(x, y, z);

  raceSphere = gta.createSphere(position, sphereRadius);
  raceSphere.colour = colour;

  if(nextX == 0.0 && nextY == 0.0 && nextZ == 0.0) {
    destroyElement(nextRaceBlip);
  } else {
    nextRaceBlip.position = Vec3(nextX, nextY, nextZ);
  }

  raceBlip.position = position;

  print("Moved sphere and blip");
});

// ----------------------------------------------------------------------------

addNetworkHandler("removepoint", function() {
  if(raceSphere != null) {
    destroyElement(raceSphere);
  }

  if(raceBlip != null) {
    destroyElement(raceBlip);
  }

  if(nextRaceBlip != null) {
    destroyElement(nextRaceBlip);
  }  

  print("Removed sphere and blip");
});

// ----------------------------------------------------------------------------

function checkRaceSphereEnterExit() {
  if(!raceSphere) {
    return false;
  }

  if(!localPlayer.vehicle) {
    return false;
  }

  if(raceSphere.position.distance(localPlayer.vehicle.position) <= raceSphere.radius) {
    destroyElement(raceSphere);
    raceSphere = null;
    triggerNetworkEvent("enterpoint");
  }
}

// ----------------------------------------------------------------------------

addEventHandler("OnProcess", function(event, deltaTime) {
  checkRaceSphereEnterExit()
});

// ----------------------------------------------------------------------------

addNetworkHandler("giveweapons", function(weaponData) {
  if(localPlayer != null) {
    foreach(i, v in weaponData) {
     if(v > 0) {
       localPlayer.giveWeapon(i, v, false);
     }
   }
  }
});

// ----------------------------------------------------------------------------

addNetworkHandler("clearweapons", function() {
  localPlayer.clearWeapons();
});

// ----------------------------------------------------------------------------