class ExplosiveActor extends GGExplosiveActorContent
placeable;

function ChangeSkin(StaticMeshComponent comp, float newDrawScale, vector newDrawScale3D)
{
	local GGPhysicalMaterialProperty newPhysProp;
	local PhysicalMaterial oldPhysMat;
	local MaterialInterface mat;
	local ExplosiveActor ea;
	local int index;

	oldPhysMat=GetKActorPhysMaterial();
	//WorldInfo.Game.Broadcast(self, "oldPhysMat=" $ oldPhysMat);
	SetStaticMesh(comp.StaticMesh, comp.Translation, comp.Rotation, comp.Scale3D);
	foreach comp.Materials(mat, index)
	{
		StaticMeshComponent.SetMaterial(index, mat);
	}
	SetDrawScale(newDrawScale);
	SetDrawScale3D(newDrawScale3D);

	//Fix collision
	ea=Spawn(class'ExplosiveActor',,, Location, Rotation, self, true);
	newPhysProp=GGPhysicalMaterialProperty(ea.GetKActorPhysMaterial().GetPhysicalMaterialProperty(class'GGPhysicalMaterialProperty'));
	//WorldInfo.Game.Broadcast(self, "newPhysProp=" $ newPhysProp);
	if(newPhysProp == none || newPhysProp.GetExplosionDamage() <= 0)
	{
		//WorldInfo.Game.Broadcast(self, "override");
		ea.GetKActorPhysMaterial().PhysicalMaterialProperty=oldPhysMat.PhysicalMaterialProperty;
	}

	Destroy();
	ea.CollisionComponent.WakeRigidBody();
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false
}