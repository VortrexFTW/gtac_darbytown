// ----------------------------------------------------------------------------

setErrorMode(RESOURCEERRORMODE_STRICT);

// ----------------------------------------------------------------------------

/* 
To-Do:
  - Add race timer and display the score.
  - Store high scores in a array untime the server closes
  - Display time and a scoreboard of times
  - Autostart a random race for the player to do.
  - Add mission failed with a handler to reset everything.
  - Add random DM (police station roof as MTA did)
*/

// ----------------------------------------------------------------------------

// This will be removed on next update for the new property server.maxPlayers
const MAX_PLAYERS = 35;

// ----------------------------------------------------------------------------

// Colors
local white = toColour(255, 255, 255, 255);
local red = toColour(255, 0, 0, 255);
local yellow = toColour(255, 255, 0, 255);
local green = toColour(0, 255, 0, 255);
local blue = toColour(0, 0, 255, 255);
local orange = toColour(0, 180, 255, 255);
local grey = toColour(180, 180, 180, 255);

// ----------------------------------------------------------------------------

// Spawns
local hospital = [
[1143,-591,14], // portland
[182,-18,16], // staunton
[-1253,-144, 58] // shoreside
];

// ----------------------------------------------------------------------------

local serverEvent = null;

// ----------------------------------------------------------------------------

// Arrays
local kills = array(MAX_PLAYERS, 0);
local deaths = array(MAX_PLAYERS, 0);
local timesKilled = array(MAX_PLAYERS, 0);
local healthCap = array(MAX_PLAYERS, 0);
local status = array(MAX_PLAYERS, 0);
local raceCP = array(MAX_PLAYERS, 0);
local lastRaceCP = array(MAX_PLAYERS, [false, 0.0]);
local returnToRaceVehicle = array(MAX_PLAYERS, [false, 0]);
local raceVehicle = array(MAX_PLAYERS, false);
local preEventPosition = array(MAX_PLAYERS, false);

// ----------------------------------------------------------------------------

// Commands
local commandList = [
  "race", 
  "stats",
  "die", 
  "spawncar", 
  "veh", 
  "car", 
  "pos", 
  "angle"
];

// ----------------------------------------------------------------------------

// Spawn Weapons
local spawnWeapons = [
  0,    // Fist (always 0)
  1,    // Bat
  30,   // Colt 45
  30,   // Uzi
  10,   // Shotgun
  60,   // AK-47
  0,    // M16
  0,    // Sniper Rifle
  0,    // Rocket Launcher
  0,    // Flamethrower
  0,    // Molotov
  1     // Grenade
];

// ----------------------------------------------------------------------------

// Health Caps
local healthLevel = [
  25,   // Default spawn level
  50,   // 50 kills
  75,   // 75 kills
  100   // 100 kills
];

// ----------------------------------------------------------------------------

// Misc Config
local returnToRaceVehicleTimeLimit = 30;

// ----------------------------------------------------------------------------

enum playerStatus {
  idle,
  event,
};

// ----------------------------------------------------------------------------

enum eventTypes {
  none,
  race,
  dm,
  tdm,
};

// ----------------------------------------------------------------------------

class raceData {
  eventType = eventTypes.race;

  name = "";
  vehicleModel = 0;

  spawns = [];
  checkpoints = [];
  objects = [];

  participants = [];

  countdownTick = 3;
  countdownTimer = null;

  constructor(fileContents) {
    foreach(i, v in split(fileContents, "\r\n")) {
      if(v.len() > 0) {
        local splitLine = split(v, " ");
        if(splitLine.len() > 0) {
          switch(splitLine[0]) {
            case "V":
              vehicleModel = splitLine[1].tointeger();
              break;

            case "N":
              name = v.slice(2);
              break;

            case "S":
              spawns.push([Vec3(splitLine[1].tofloat(), splitLine[2].tofloat(), splitLine[3].tofloat()), splitLine[4].tofloat()]);
              break;

            case "O":
              objects.push([Vec3(splitLine[1].tofloat(), splitLine[2].tofloat(), splitLine[3].tofloat()), Vec3(splitLine[4].tofloat(), splitLine[5].tofloat(), splitLine[6].tofloat())]);
              break;

            case "C":
              checkpoints.push([Vec3(splitLine[1].tofloat(), splitLine[2].tofloat(), splitLine[3].tofloat()), splitLine[4].tofloat()]);
              break; 

            default:
              break;          
          }
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------

class dmData {
  eventType = eventTypes.dm;

  name = "";

  spawns = [];
  weapons = [];
  objects = [];

  participants = [];

  countdownTick = 3;
  countdownTimer = null;

  constructor(fileContents) {
    foreach(i, v in split(fileContents, "\r\n")) {
      if(v.len() > 0) {
        local splitLine = split(v, " ");
        if(splitLine.len() > 0) {
          switch(splitLine[0]) {
            case "N":
              name = v.slice(2);
              break;

            case "S":
              spawns.push([Vec3(splitLine[1].tofloat(), splitLine[2].tofloat(), splitLine[3].tofloat()), splitLine[4].tofloat()]);
              break;

            case "O":
              objects.push([splitLine[1].tointeger(), Vec3(splitLine[2].tofloat(), splitLine[3].tofloat(), splitLine[4].tofloat()), Vec3(splitLine[5].tofloat(), splitLine[6].tofloat(), splitLine[7].tofloat())]);
              break;

            case "W":
              weapons.push([splitLine[1].tointeger(), splitLine[2].tointeger(), Vec3(splitLine[3].tofloat(), splitLine[4].tofloat(), splitLine[5].tofloat())]);
              break; 

            default:
              break;          
          }
        }
      }
    }
  }  
}

// ----------------------------------------------------------------------------

class tdmData {
  eventType = eventTypes.tdm;

  name = "";

  spawns = [];
  weapons = [];
  objects = [];

  participants = [];

  teams = [];

  countdownTick = 3;
  countdownTimer = null;

  constructor(fileContents) {
    foreach(i, v in split(fileContents, "\r\n")) {
      if(v.len() > 0) {
        local splitLine = split(v, " ");
        if(splitLine.len() > 0) {
          switch(splitLine[0]) {
            case "N":
              name = v.slice(2);
              break;

            case "S":
              spawns.push([Vec3(splitLine[1].tofloat(), splitLine[2].tofloat(), splitLine[3].tofloat()), splitLine[4].tofloat()]);
              break;

            case "O":
              objects.push([splitLine[1].tointeger(), Vec3(splitLine[2].tofloat(), splitLine[3].tofloat(), splitLine[4].tofloat()), Vec3(splitLine[5].tofloat(), splitLine[6].tofloat(), splitLine[7].tofloat())]);
              break;

            case "W":
              weapons.push([splitLine[1].tointeger(), splitLine[2].tointeger(), Vec3(splitLine[3].tofloat(), splitLine[4].tofloat(), splitLine[5].tofloat())]);
              break; 

            default:
              break;          
          }
        }
      }
    }
  }  
}

// ----------------------------------------------------------------------------

function onScriptLoad(event, resource) {
  print("Script is starting");

  foreach(command in commandList) {
    addCommandHandler(command, onPlayerCommand);
  }
}
bindEventHandler("onResourceStart", thisResource, onScriptLoad);

// ----------------------------------------------------------------------------

function onScriptUnload(event, resource) {
  saveAllPlayerStats();
  saveRaceHighScores();

  foreach(command in commandList) {
    removeCommandHandler(command);
  }

  print("The script has terminated");
}
bindEventHandler("onResourceStop", thisResource, onScriptUnload);

// ----------------------------------------------------------------------------

addEventHandler("onPlayerJoined", function(event, client) {

  local select = random(0, 2);

  
  spawnPlayer(client, Vec3(hospital[select][0], hospital[select][1], hospital[select][2]), 0.0, 0, 0, 0)    
  fadeCamera(client,true);
  
  for(local i = 0; i <= 50; i++) {
    messageClient("", client, white);
  }

  messageClient("⭐⭐⭐⭐ DARBYTOWN ⭐⭐⭐⭐", client);
  messageClient("〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️", client);
  messageClient("📈 To see in game stats type /stats", client);
  messageClient("🚘 Need a car guy? Type /car number", client);
  messageClient("☠️ If you wish to die at this point feel free to type /die", client);
  messageClient("⚠️ This is a demo so chill my guy", client, white);

  kills[client.index] = 0;
  timesKilled[client.index] = 0;
  deaths[client.index] = 0;
  healthCap[client.index] = 25;

  // For testing
  client.administrator = true;
});

// ----------------------------------------------------------------------------

addEventHandler("onPedSpawn", function(event, ped) {
  if(ped.isType(ELEMENT_PLAYER)) {
    local client = getClientFromPlayerElement(ped);
    message("> " + ped.name + " has entered Darbytown.", white);

    giveClientWeapons(client);
  }
});

// ----------------------------------------------------------------------------

addEventHandler("onPedWasted", function(event, wastedPed, killerPed, weaponID, pedPiece) {
  if(!wastedPed.isType(ELEMENT_PLAYER)) {
    return false;
  }

  local wastedClient = getClientFromPlayerElement(wastedPed);

  local outputMessage = "☠️ " + wastedClient.name + " has died";
  if(killerPed == null) {
    deaths[wastedClient.index]++;
  }
  
  if(killerPed != null) {
    if(killerPed.isType(ELEMENT_PLAYER)) {
      local killerClient = getClientFromPlayerElement(killerPed);
      kills[killerClient.index]++;
      timesKilled[wastedClient.index]++;

      if(kills[killerClient.index] > healthCap[killerClient.index]) {
        foreach(i, v in healthLevel) {
          if(v == kills[killerClient.index]) {
            healthCap[killerClient.index] = healthLevel[i];
            killerPed.health = healthCap[killerClient.index];
          }
        }
      }     

      outputMessage = "🤺 " + killerClient.name + " killed " + wastedClient.name;
    }
  }

  local select = random(0, 2);

  
  message(outputMessage, white);
  spawnPlayer(wastedClient, Vec3(hospital[select][0], hospital[select][1], hospital[select][2]), 0.0, 0, 0, 0)  
});

// ----------------------------------------------------------------------------

addEventHandler("onPlayerQuit", function(event, client, reason) {
  message("> " + client.name + " has left Darbytown.", white);
  collectAllGarbage();
});

// ----------------------------------------------------------------------------

addEventHandler("onPedExitVehicle", function(event, ped, vehicle) {
  if(ped.isType(ELEMENT_PLAYER)) {
    local client = getClientFromPlayerElement(ped);
    if(status[client.index] == playerStatus.event) {
      if(returnToRaceVehicle[client.index][0]) {
        clearInterval(returnToRaceVehicle[client.index][0]);
        returnToRaceVehicle[client.index][0] = false;
        returnToRaceVehicle[client.index][1] = 0;        
      }
      returnToRaceVehicle[client.index][0] = setInterval(returnToRaceVehicleCounter, 1000, client);
      returnToRaceVehicle[client.index][1] = time();
    }
  }
});

// ----------------------------------------------------------------------------

addEventHandler("onPedEnterVehicle", function(event, ped, vehicle, seat) {
  if(ped.isType(ELEMENT_PLAYER)) {
    local client = getClientFromPlayerElement(ped);
    if(status[client.index] == playerStatus.event) {
      if(raceVehicle[client.index] == vehicle) {
        if(returnToRaceVehicle[client.index][0]) {
          clearInterval(returnToRaceVehicle[client.index][0]);
          returnToRaceVehicle[client.index][0] = false;
          returnToRaceVehicle[client.index][1] = 0;
        }
      }
    }
  }
});

// ----------------------------------------------------------------------------

function onPlayerCommand( cmd, text, client) {
  if(cmd == "stats" ) {
    message( "📈 [#FFFFFF][" + client.name + "] [#999999]Deaths: " + deaths[client.index] + ", Times Killed: " + timesKilled[client.index] + ", Kills: " + kills[client.index]);
    return true;
  }

  if(cmd == "die") {
    client.player.health = 1;
    return true;
  }
	
  if(cmd == "car" || cmd == "veh" || cmd == "spawncar" ) {
    if(!text.tointeger()) {
      messageClient("/" + cmd.tostring() + " <number>", client);
      return false;
    }
    
    local position = getPosInFrontOfPos(client.player.position, client.player.heading, 5);
    gta.createVehicle(text.tointeger(), position, client.player.heading);
  }

  if(cmd == "pos") {
    print(client.player.position.x + "  " + client.player.position.y + "  " + client.player.position.z + " " + client.player.heading);
  }
	 
  if(cmd == "race") {
    triggerNetworkEvent("clearweapons", client);
    raceEnd();
	  local randomRace = raceChoose();
    raceLoad(randomRace);
    foreach(i, v in getClients()) {
      if(status[v.index] == playerStatus.idle) {
        preEventPosition[v.index] = v.player.position;
        if(v.player.vehicle) {
          destroyElement(v.player.vehicle);
        }
        raceJoin(v);
      }
    }
    message(client.name + " started race " + serverEvent.name + "!", orange);
    serverEvent.countdownTimer = setInterval(eventCountdown, 1000);
    serverEvent.countdownTick = 4;
	}

	if(cmd == "angle") {
    print(client.player.heading);
    return true;
  }
};

// ----------------------------------------------------------------------------

function raceChoose() {
	local racesFile = openFile("events/races/races.txt", false);
	if(!racesFile) {
		print("[ERROR] Could not load races directory file!");
		thisResource.stop();
		return false;
	}
	
  local thisGameRaces = [];
  local racesFileData = racesFile.readBytes(racesFile.length);
  local racesLines = split(racesFileData, "\r\n");
  foreach(i, v in racesLines) {
    if(v.len() > 0) {
      local splitLine = split(v, " ");
      if(splitLine.len() == 2) {
        if(splitLine[0].tointeger() == server.game) {
          thisGameRaces.push(splitLine[1].tostring());
        }
      }
    }
  }
  
	local randomRaceID = random(0, thisGameRaces.len());
	return thisGameRaces[randomRaceID];
}

// ----------------------------------------------------------------------------

function raceLoad(raceName) {
	local raceFile = openFile("events/races/" + server.game.tostring() + "/" + raceName.tostring() + ".txt", false);
	if(!raceFile) {
		print("[ERROR] Could not load race data from " + raceName + ".txt!");
		return false;
	}

  serverEvent = raceData(raceFile.readBytes(raceFile.length));
  return true;
}

// ----------------------------------------------------------------------------

function raceJoin(client) { 
  local spawnSlot = serverEvent.participants.len();
  local startPos = Vec3(serverEvent.spawns[spawnSlot][0].x, serverEvent.spawns[spawnSlot][0].y, serverEvent.spawns[spawnSlot][0].z);  
  local tempRaceVehicle = gta.createVehicle(119, startPos, serverEvent.spawns[spawnSlot][1]);

  // A couple of ugly workarounds. I'll file bug reports. We should be able to set a player's position via server and avoid the delay with warping into a vehicle
  triggerNetworkEvent("pos", client, startPos.x, startPos.y, startPos.z, 274.085);
  setTimeout(function() { triggerNetworkEvent("engine", client, tempRaceVehicle, false); }, 250);
  setTimeout(function() { client.player.warpIntoVehicle(tempRaceVehicle, 0); }, 1000);

  lastRaceCP[client.index] = [startPos, tempRaceVehicle.heading];
  raceCP[client.index] = 1;
  raceVehicle[client.index] = tempRaceVehicle;
  status[client.index] = playerStatus.event;

  serverEvent.participants.push(client);
}

// ----------------------------------------------------------------------------

function raceStarted() { 
  foreach(i, v in serverEvent.participants) {
    local nextX = serverEvent.checkpoints[raceCP[v.index]+1][0].x;
    local nextY = serverEvent.checkpoints[raceCP[v.index]+1][0].y;
    local nextZ = serverEvent.checkpoints[raceCP[v.index]+1][0].z;

    triggerNetworkEvent("makepoint", v, serverEvent.checkpoints[raceCP[v.index]][0].x, serverEvent.checkpoints[raceCP[v.index]][0].y, serverEvent.checkpoints[raceCP[v.index]][0].z, COLOUR_YELLOW, serverEvent.checkpoints[raceCP[v.index]][1], nextX, nextY, nextZ); 
    triggerNetworkEvent("engine", v, raceVehicle[v.index], true);
  }
}

// ----------------------------------------------------------------------------

function raceSphere(client) {
  if(raceCP[client.index] == serverEvent.checkpoints.len()-1) {
    message(client.name + " wins " + serverEvent.name + "!", orange);
    raceEnd();
  } else {
    lastRaceCP[client.index] = [client.player.vehicle.position, client.player.vehicle.heading];
    raceCP[client.index]++;

    local nextX = 0.0;
    local nextY = 0.0;
    local nextZ = 0.0;
    local colour = COLOUR_RED;

    if(raceCP[client.index] < serverEvent.checkpoints.len()-1) {
      colour = COLOUR_YELLOW;
      nextX = serverEvent.checkpoints[raceCP[client.index]+1][0].x;
      nextY = serverEvent.checkpoints[raceCP[client.index]+1][0].y;
      nextZ = serverEvent.checkpoints[raceCP[client.index]+1][0].z;
    }

    triggerNetworkEvent("movepoint", client, serverEvent.checkpoints[raceCP[client.index]][0].x, serverEvent.checkpoints[raceCP[client.index]][0].y, serverEvent.checkpoints[raceCP[client.index]][0].z, colour, serverEvent.checkpoints[raceCP[client.index]][1], nextX, nextY, nextZ);
  }
}

// ----------------------------------------------------------------------------

function raceEnd() {
  if(serverEvent != null) {
    if(serverEvent.countdownTimer != null) {
      clearTimeout(serverEvent.countdownTimer);
    }

    foreach(i, v in serverEvent.participants) {
      triggerNetworkEvent("removepoint", v);
      if(v.player.vehicle) {
        destroyElement(v.player.vehicle);
      }
      if (preEventPosition[v.index].x) triggerNetworkEvent("pos", v, preEventPosition[v.index].x, preEventPosition[v.index].y, preEventPosition[v.index].z, 0.0);
      giveClientWeapons(v);
      preEventPosition[v.index] = false;
      status[v.index] = playerStatus.idle;
    }
  }
}

// ----------------------------------------------------------------------------

function raceKick(client) { 
  triggerNetworkEvent("removepoint", client);

  raceCP[client.index] = 0;
  lastRaceCP[client.index] = [false, 0.0];

  if(raceVehicle[client.index]) {
    destroyElement(raceVehicle[client.index]);
  }
  raceVehicle[client.index] = false;

  status[client.index] = playerStatus.idle;

  messageClient("🏴 You have been kicked from the race!", client, red);

  triggerNetworkEvent("pos", client, preEventPosition[client.index].x, preEventPosition[client.index].y, preEventPosition[client.index].z, 0.0);
  giveClientWeapons(client);

  foreach(i, v in serverEvent.participants) {
    if(v == client) {
      serverEvent.participants.remove(i);

      if(serverEvent.participants.len() == 1) {
        local winner = serverEvent.participants.pop();
        message("🏁 " + winner.name + " wins " + serverEvent.name + "!", green);
        raceEnd();
      } else if(serverEvent.participants.len() == 0) {
        message("Nobody won " + serverEvent.name + "!", orange);
        raceEnd();
      }
    }
  }
}

// ----------------------------------------------------------------------------

addNetworkHandler("enterpoint", function(client) {
  raceSphere(client);
});

// ----------------------------------------------------------------------------

function saveAllPlayerStats() {

}

// ----------------------------------------------------------------------------

function saveRaceHighScores() {
  
}

// ----------------------------------------------------------------------------

function getPosInFrontOfPos(pos, angle, distance) {
	local x = (pos.x+((cos(angle+(PI/2)))*distance));
	local y = (pos.y+((sin(angle+(PI/2)))*distance));
	local z = pos.z;

	return Vec3(x, y, z);
}

// ----------------------------------------------------------------------------

function getPosBehindPos(pos, angle, distance) {
	local x = (pos.x+((cos(angle-(PI/2)))*distance));
	local y = (pos.y+((sin(angle-(PI/2)))*distance));
	local z = pos.z;

	return Vec3(x,y,z);
}

// ----------------------------------------------------------------------------

function returnToRaceVehicleCounter(client) {
  if(returnToRaceVehicle[client.index][0] && returnToRaceVehicle[client.index][1]) {
    local startTime = returnToRaceVehicle[client.index][1];
    local elapsedTime = time()-startTime;
    if(elapsedTime >= returnToRaceVehicleTimeLimit) {
      local timer = returnToRaceVehicle[client.index][0];
      clearInterval(timer);
      returnToRaceVehicle[client.index] = [false, 0];
      raceKick(client);      
    } else {
      local remainingTime = returnToRaceVehicleTimeLimit-elapsedTime;
      messageClient("⚠️ You have " + remainingTime.tostring() + " seconds to return to your race car!", client, yellow);
    }
  }
}

// ----------------------------------------------------------------------------

function random(min, max) {
  return rand()%(max.tointeger()-min.tointeger());
}

// ----------------------------------------------------------------------------

function eventCountdown() {
  serverEvent.countdownTick--;
  if(serverEvent.countdownTick == 0) {
    message("GO", green);
    clearInterval(serverEvent.countdownTimer);
    serverEvent.countdownTimer = null;
    serverEvent.countdownTick = 4;
    raceStarted();
  } else {
    message(serverEvent.countdownTick.tostring(), yellow);
  }
}

// ----------------------------------------------------------------------------

function giveClientWeapons(client) {
  // A stupid hacky method.
  setTimeout(function() { triggerNetworkEvent("giveweapons", client, spawnWeapons); }, 1000);
}

// ----------------------------------------------------------------------------