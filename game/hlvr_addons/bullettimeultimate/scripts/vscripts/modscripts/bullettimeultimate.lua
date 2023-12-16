require "modscripts/bullettimeultimater"

local bulletTimer

if IsServer() then

	ListenToGameEvent('two_hand_pistol_grab_start',function()
		bulletTimer.isHoldingWithTwoHands=true
	end,nil)

	ListenToGameEvent('two_hand_rapidfire_grab_start',function()
		bulletTimer.isHoldingWithTwoHands=true
	end,nil)

	ListenToGameEvent('two_hand_shotgun_grab_start',function()
		bulletTimer.isHoldingWithTwoHands=true
	end,nil)

	ListenToGameEvent('two_hand_pistol_grab_end',function()
		bulletTimer.isHoldingWithTwoHands=false
	end,nil)

	ListenToGameEvent('two_hand_rapidfire_grab_end',function()
		bulletTimer.isHoldingWithTwoHands=false
	end,nil)

	ListenToGameEvent('two_hand_shotgun_grab_end',function()
		bulletTimer.isHoldingWithTwoHands=false
	end,nil)

	ListenToGameEvent('player_activate', function() 
		
		SendToServerConsole("host_timescale 1; phys_timescale 1; r_particle_timescale 1;")
		SendToConsole("host_timescale 1; phys_timescale 1; r_particle_timescale 1;")
	
		print("BulletTimer: player_activate event")
		
		local bulletTimerEntity = SpawnEntityFromTableSynchronous( "logic_script",{
                targetname = "bullet_timer_obj";
                spawnflags = {
                    [1] = 1;
                };
				vscripts = "modscripts/bullettimeultimater",
            } )
			
		bulletTimer = BulletTimer(self)
				
	end, nil)

end	

