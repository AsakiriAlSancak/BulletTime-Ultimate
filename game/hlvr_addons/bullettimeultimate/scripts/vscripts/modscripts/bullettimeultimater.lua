
local soundLoopDurations = { }

local numberOfStartingSounds = 4

local bulletTimeDuration = 7

local bulletTimeCooldown = 0
			
BulletTimer = class(

    {
        UPDATE_INTERVAL;
		objBulletTime;
		objStartingSound;
		objLoopSound;
		objEndingSound;
		objHeartBeatSound;
		soundnameLoop;
		soundnameStarting;
		soundnameEnding;
		soundnameHeartbeat;
		volumeHeartbeatSound;
		volumeLoopSound;
		volumeStartingSound;
		timeHeartBeatSound;
		timeEntryToBulletTime;
		timeChangeOfScale;
		timescaleHost;
		isGripReleaseNeded;
		isHoldingWithTwoHands;
		isInBulletTime;
		isWillEnterBulletTime;
		indexStartingSound;
		timeScaleShouldBeFixed;
		
        constructor = function (self)

            print("Initializing custom Bullet Timer ...")
			
			self.objBulletTime = self:CreateBulletTimeObj()
			self.objStartingSound = self:CreateSoundObj('starting')
			self.objLoopSound = self:CreateSoundObj('loop')
			self.objEndingSound = self:CreateSoundObj('ending')
			self.objHeartBeatSound = self:CreateSoundObj('heartbeat')
						
			self.soundnameLoop = "Addon.BulletTime_Loop"
			self.soundnameHeartbeat = "Addon.BulletTime_Heartbeat_01"
			
			soundLoopDurations[self.soundnameHeartbeat]=1
			
            self.UPDATE_INTERVAL = BulletTimer.DEFAULT_UPDATE_INTERVAL
			
			self.isInBulletTime = false
			self.isWillEnterBulletTime = false
			self.timeEntryToBulletTime = 0
			self.isGripReleaseNeded = false
			self.isHoldingWithTwoHands = false
		
			self.volumeLoopSound = 1
			self.volumeStartingSound = 0.8
			self.volumeHeartbeatSound=14
			
			self.timeHeartBeatSound = Time()
			
			self.timescaleHost = 1.0
			self.timeScaleShouldBeFixed = false
			
            if IsServer() then
				self.objBulletTime:SetThink(function() return self:BaseBulletTimerLogic() end, "BulletTimerUpdate")
			end
            
        end;

        BaseBulletTimerLogic = function (self)
			self:CheckBulletTime()
            return self.UPDATE_INTERVAL

        end;

		CreateBulletTimeObj = function (self)

            local objBulletTime = SpawnEntityFromTableSynchronous("info_target", {
                targetname = "bullet_timer" ;
                spawnflags = {
                    [1] = 1;
                };
            } )
            
			local player = Entities:GetLocalPlayer()
			objBulletTime:SetAbsOrigin(player:GetAbsOrigin())
			
            objBulletTime:SetParent(player, "")
			
            return objBulletTime

        end;
		
		CreateSoundObj = function (self,identifier)

            local soundObj = SpawnEntityFromTableSynchronous("info_target", {
                targetname = "bullet_timer_"..identifier.."_sound_obj" ;
                spawnflags = {
                    [1] = 1;
                };
            } )
            
			local player = Entities:GetLocalPlayer()
			
			soundObj:SetAbsOrigin(player:GetAbsOrigin())
            soundObj:SetParent(self.objBulletTime, "")
			

            return soundObj

        end;
		
		CheckBulletTime = function (self)

			local player = Entities:GetLocalPlayer()
			
			if player == nil then return end
			
			local difference = Time() - self.timeEntryToBulletTime
			local heldHand = 1
			if Convars:GetBool("hlvr_left_hand_primary") then heldHand = 0 end
			
			literalHandType = player:GetHMDAvatar():GetVRHand(heldHand):GetLiteralHandType()
			
			local firePressed = player:IsDigitalActionOnForHand(literalHandType, 7)
			local gripPressed = player:IsDigitalActionOnForHand(literalHandType, 6) 
						
			if self.isGripReleaseNeded and not gripPressed then self.isGripReleaseNeded = false end
						
			if self.isInBulletTime then
									
				if self.timescaleHost > 0.5 then 
					
					if Time() - self.timeChangeOfScale > 0.05 then 
						self.timescaleHost = self.timescaleHost - 0.05
						self:ChangeTimescale()
					end
					
				elseif self.timeScaleShouldBeFixed then
					self.timeScaleShouldBeFixed = false
					self.timescaleHost = 0.5
					self:ChangeTimescale()
				end
			
				local lclTimeHeartbeatReducer = 0.0
				if player:GetHealth()<50 then
					lclTimeHeartbeatReducer = 0.25
				end
				
				if Time() - self.timeHeartBeatSound > soundLoopDurations[self.soundnameHeartbeat] - lclTimeHeartbeatReducer then
				
					self.objHeartBeatSound:StopSound(self.soundnameHeartbeat)
					self.objHeartBeatSound:EmitSound(self.soundnameHeartbeat)
					self.objHeartBeatSound:EmitSoundParams(self.soundnameHeartbeat, 0, self.volumeHeartbeatSound,0)
					
					self.timeHeartBeatSound = Time()
					
				end
					
				if not gripPressed or Time() - self.timeEntryToBulletTime > bulletTimeDuration then
				
					if self.isHoldingWithTwoHands then self.isGripReleaseNeded = true end
					
					self.isInBulletTime = false
					self.timeScaleShouldBeFixed = true
					
					self.timeChangeOfScale = Time()
					
					self.objHeartBeatSound:StopSound(self.soundnameHeartbeat)
					
					self.objStartingSound:StopSound(self.soundnameStarting)
					self.objLoopSound:StopSound(self.soundnameLoop)
					
					self.objEndingSound:EmitSound(self.soundnameEnding)
					self.objEndingSound:EmitSoundParams(self.soundnameEnding, 0, self.volumeStartingSound,0)
					
				end
			else
					
				self.isWillEnterBulletTime= self.isHoldingWithTwoHands and gripPressed and not self.isGripReleaseNeded and not firePressed
												
				if self.timescaleHost < 1.0 then 
					if Time() - self.timeChangeOfScale > 0.05 then 
						self.timescaleHost = self.timescaleHost + 0.05
						self:ChangeTimescale()
					end
				elseif self.timeScaleShouldBeFixed then
					self.timeScaleShouldBeFixed = false
					self.timescaleHost = 1
					self:ChangeTimescale()
				end
				
			end
							
			if self.isWillEnterBulletTime then
								
				self.isWillEnterBulletTime = false
				self.isInBulletTime = true
				self.timeScaleShouldBeFixed = true
				self.timeEntryToBulletTime = Time()
				self.timeChangeOfScale = Time()
				self.timeHeartBeatSound = Time()
				
				self.indexStartingSound = RandomInt(1, numberOfStartingSounds)
				self.soundnameStarting = "Addon.BulletTime_Startup_0"..self.indexStartingSound
				self.soundnameEnding = "Addon.BulletTime_Ending_0"..self.indexStartingSound
				
				self.objLoopSound:StopSound(self.soundnameLoop)
				self.objEndingSound:StopSound(self.soundnameEnding)
				self.objStartingSound:EmitSound(self.soundnameStarting)
				self.objStartingSound:EmitSoundParams(self.soundnameStarting, 0, self.volumeStartingSound,0)
				self.objLoopSound:EmitSound(self.soundnameLoop)
				self.objLoopSound:EmitSoundParams(self.soundnameLoop, 0, self.volumeLoopSound,0)
				self.objHeartBeatSound:StopSound(self.soundnameHeartbeat)
				self.objHeartBeatSound:EmitSound(self.soundnameHeartbeat)
				self.objHeartBeatSound:EmitSoundParams(self.soundnameHeartbeat, 0, self.volumeHeartbeatSound,0)
								
			end
		  
		end;
		
		ChangeTimescale = function (self)

			self.timeChangeOfScale = Time()
            local strConsole = "host_timescale "..self.timescaleHost.."; phys_timescale "..self.timescaleHost.."; r_particle_timescale "..self.timescaleHost..";"
			SendToConsole(strConsole)
			SendToServerConsole(strConsole)

        end;
		
		
    },

    {
        __class__name = "BulletTimer";

        DEFAULT_UPDATE_INTERVAL = 1 / 48;
    },

    nil

)

function Precache(context)
	print("BulletTimer: Precaching bullettime sound events.")
	PrecacheResource("soundfile", "soundevents/bullettimeultimate_soundevents.vsndevts", context)
end
