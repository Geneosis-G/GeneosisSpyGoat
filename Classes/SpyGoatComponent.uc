class SpyGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StaticMeshComponent hatMesh;
var StaticMeshComponent glassesMesh;
var SkeletalMesh moneyMesh;
var ParticleSystem moneyRainTemplate;
var SoundCue moneySound;
var SoundCue triggerSound;
var int moneyLimit;
var int randVal;
var bool spawnRealMoney;
var bool isRagdollKeyPressed;
var float triggerRadius;
var bool isRightClicking;
var bool isLickPressed;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		hatMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( hatMesh, 'hairSocket' );
		glassesMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( glassesMesh, 'hairSocket' );

		randVal=Rand(100);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			SpawnMoney();
		}

		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			if(!gMe.mIsRagdoll)
			{
				gMe.mLockBones=true;
			}
		}

		if(newKey == 'THREE' || newKey == 'XboxTypeS_RightShoulder')
		{
			if(isRightClicking)
			{
				SpawnExplosiveActor();
			}
		}


		if(newKey == 'TWO' || newKey == 'XboxTypeS_RightTrigger')
		{
			if(isRightClicking)
			{
				TriggerExplosion();
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			isRightClicking=true;
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			isLickPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			if(!gMe.mIsRagdoll)
			{
				gMe.mLockBones=false;
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			isRightClicking=false;
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			isLickPressed=false;
		}
	}
}

function SpawnMoney()
{
	local vector spawnLocation;
	local rotator spawnRotation;
	local Money newMoney;

	gMe.PlaySound( moneySound );

	gMe.mesh.GetSocketWorldLocationAndRotation('grabSocket', spawnLocation, spawnRotation);
	if(IsZero(spawnLocation))
	{
		spawnLocation=gMe.Location + (vect(0, 0, 1) * gMe.GetCollisionHeight()) + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
		spawnRotation=gMe.Rotation;
	}
	spawnLocation += Normal(Vector(gMe.Rotation)) * 20;

	gMe.WorldInfo.MyEmitterPool.SpawnEmitter(moneyRainTemplate, spawnLocation, spawnRotation, gMe);

	if(spawnRealMoney && randVal < moneyLimit)
	{
		randVal=Rand(100);
		spawnLocation.Z += -20;
		newMoney = gMe.Spawn( class'Money',,, spawnLocation, spawnRotation );
		newMoney.CollisionComponent.WakeRigidBody();
		//newMoney.ApplyImpulse( Vector( gMe.Rotation ), 1.f, newMoney.Location );
		moneyLimit=0;
	}

	spawnRealMoney=false;
	if(gMe.IsTimerActive(NameOf( UpgradeMoneyLimit ), self))
	{
		gMe.ClearTimer(NameOf( UpgradeMoneyLimit ), self);
	}
	gMe.SetTimer(1.f, false, NameOf( UpgradeMoneyLimit ), self);
}

function UpgradeMoneyLimit()
{
	moneyLimit++;
	if(!spawnRealMoney)
	{
		moneyLimit++;
	}
	spawnRealMoney=true;
	gMe.SetTimer(1.f, false, NameOf( UpgradeMoneyLimit ), self);
}

function SpawnExplosiveActor()
{
	local vector spawnLocation;
	local ExplosiveActor expAct;
	local DynamicSMActor actToCopy;

	gMe.Mesh.GetSocketWorldLocationAndRotation( 'Demonic', spawnLocation );
	if(IsZero(spawnLocation))
	{
		spawnLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	expAct = gMe.Spawn( class'ExplosiveActor',,, spawnLocation,,, true);
	actToCopy=DynamicSMActor(gMe.mGrabbedItem);
	if(actToCopy != none)
	{
		expAct.ChangeSkin(actToCopy.StaticMeshComponent, actToCopy.DrawScale, actToCopy.DrawScale3D);
	}
	else
	{
		expAct.CollisionComponent.WakeRigidBody();
	}
}

function TriggerExplosion()
{
	local actor hitActor, expActor;
	local GGExplosiveActorWreckable wAct;
	local float minDist, newDist;
	local bool onlySpawned;

	minDist = -1;
	foreach gMe.CollidingActors( class'Actor', hitActor, triggerRadius, gMe.Location,, class'GGExplosiveActorInterface')
	{
		wAct = GGExplosiveActorWreckable(hitActor);
		if(wAct != none && wAct.StaticMeshComponent.StaticMesh == wAct.mWreckageMesh)
			continue;

		if(!isLickPressed && ExplosiveActor(hitActor)==none)
			continue;

		newDist=VSize(hitActor.Location - gMe.Location);
		if(minDist == -1 || newDist < minDist)
		{
			minDist=newDist;
			expActor=hitActor;
		}
	}

	if(expActor != none)
	{
		gMe.PlaySound( triggerSound );
		expActor.TakeDamage(1000, none, expActor.Location, vect(0, 0, 0), class'GGDamageTypeExplosiveActor',, gMe);
	}
}

defaultproperties
{
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Hats.Mesh.Hat'
	End Object
	hatMesh=StaticMeshComp1

	Begin Object class=StaticMeshComponent Name=StaticMeshComp2
		StaticMesh=StaticMesh'Hats.Mesh.Glasses'
	End Object
	glassesMesh=StaticMeshComp2

	moneySound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Magician_Card_Trick_Cue'
	triggerSound=SoundCue'Goat_Sounds.Effect_slot_machine_wheel_stop_final_Cue'

	moneyRainTemplate=ParticleSystem'MMO_Effects.Effects.Effects_ShredderRain_01'

	triggerRadius=5000.f
}